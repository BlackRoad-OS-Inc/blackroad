/**
 * BlackRoad OS — Case Trigger Handler
 * Service Request lifecycle → Agent Training pipeline
 *
 * Case Status mapping to PR lifecycle:
 *   New           → PR Opened
 *   Working       → Review In Progress
 *   Escalated     → Changes Requested
 *   Closed        → Merged / Deployed
 */
public with sharing class CaseTriggerHandler {

    private static final String GATEWAY = 'https://blackroad-agents.blackroad.workers.dev';

    public static void handle(List<Case> newCases, Map<Id, Case> oldMap) {
        List<AgentTask__c>      tasksToInsert      = new List<AgentTask__c>();
        List<AgentDeployment__c> deploysToInsert   = new List<AgentDeployment__c>();
        List<AgentMemory__c>    memoriesToInsert    = new List<AgentMemory__c>();
        List<Id>                trainingCasesToFire = new List<Id>();

        for (Case c : newCases) {
            Case old = oldMap != null ? oldMap.get(c.Id) : null;
            Boolean isNew     = old == null;
            Boolean justClosed = !isNew && old.Status != 'Closed' && c.Status == 'Closed';
            Boolean justApproved = !isNew
                && c.ReviewStatus__c == 'approved'
                && (old.ReviewStatus__c != 'approved');
            Boolean statusChanged = !isNew && old.Status != c.Status;

            // ── PR Opened → create AgentTask to review ──────────────────────
            if (isNew && String.isNotBlank(c.PullRequestUrl__c)) {
                tasksToInsert.add(new AgentTask__c(
                    Name          = 'Review PR: ' + c.Subject,
                    TaskId__c     = 'pr-review-' + c.Id,
                    Description__c = 'New pull request opened.\n'
                                   + 'Branch: ' + (c.Branch__c ?? 'unknown') + '\n'
                                   + 'Repo: '   + (c.BaseRepo__c ?? 'unknown') + '\n'
                                   + 'PR URL: ' + (c.PullRequestUrl__c ?? '') + '\n'
                                   + 'Diff: '   + (c.DiffSummary__c ?? ''),
                    Priority__c   = 'high',
                    Status__c     = 'pending',
                    TargetRepo__c = c.BaseRepo__c,
                    Model__c      = 'qwen2.5-coder:7b',
                    CostUSD__c    = 0
                ));
            }

            // ── PR Approved → create deploy task ────────────────────────────
            if (justApproved) {
                deploysToInsert.add(new AgentDeployment__c(
                    TargetRepo__c    = c.BaseRepo__c,
                    TargetOrg__c     = 'BlackRoad-OS-Inc',
                    DeployType__c    = 'pr_merge',
                    Status__c        = 'queued',
                    TriggerSource__c = 'salesforce_case',
                    CommitSHA__c     = c.Branch__c,
                    CostUSD__c       = 0,
                    DeployedAt__c    = DateTime.now(),
                    Notes__c         = 'Auto-triggered by Case approval: ' + c.CaseNumber
                ));
            }

            // ── Case Closed = PR Merged → fire agent training if flagged ────
            if (justClosed && c.IsAgentTraining__c) {
                trainingCasesToFire.add(c.Id);

                // Log training trigger to memory chain
                memoriesToInsert.add(new AgentMemory__c(
                    Name          = 'train-' + c.CaseNumber,
                    MemoryType__c = 'training_trigger',
                    Content__c    = 'Training project "' + (c.TrainingProject__c ?? c.Subject)
                                  + '" triggered via Case ' + c.CaseNumber
                                  + '. Checkpoint: ' + (c.ModelCheckpoint__c ?? 'latest')
                                  + '. Data: ' + (c.TrainingDataPath__c ?? ''),
                    TruthState__c = '1 (True)',
                    Confidence__c = 100,
                    MemoryHash__c = EncodingUtil.convertToHex(
                        Crypto.generateDigest('SHA-256',
                            Blob.valueOf(c.Id + DateTime.now().getTime())))
                ));

                // Fire the training Flow via Platform Event (async)
                AgentTrainingEvent__e evt = new AgentTrainingEvent__e(
                    CaseId__c         = c.Id,
                    TrainingProject__c = c.TrainingProject__c,
                    ModelCheckpoint__c = c.ModelCheckpoint__c,
                    DataPath__c        = c.TrainingDataPath__c,
                    AgentId__c         = c.AgentId__c
                );
                EventBus.publish(evt);
            }

            // ── Any status change → log to memory ───────────────────────────
            if (statusChanged) {
                memoriesToInsert.add(new AgentMemory__c(
                    Name          = 'case-status-' + c.CaseNumber + '-' + c.Status,
                    MemoryType__c = 'pr_lifecycle',
                    Content__c    = 'Case ' + c.CaseNumber + ' [' + c.Subject + '] → '
                                  + old.Status + ' → ' + c.Status
                                  + '. PR: ' + (c.PullRequestUrl__c ?? 'none'),
                    TruthState__c = '1 (True)',
                    Confidence__c = 100,
                    MemoryHash__c = EncodingUtil.convertToHex(
                        Crypto.generateDigest('SHA-256',
                            Blob.valueOf(c.Id + c.Status + DateTime.now().getTime())))
                ));
            }
        }

        if (!tasksToInsert.isEmpty())   insert tasksToInsert;
        if (!deploysToInsert.isEmpty()) insert deploysToInsert;
        if (!memoriesToInsert.isEmpty()) insert memoriesToInsert;
    }
}
