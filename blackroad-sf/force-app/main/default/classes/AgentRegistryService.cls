/**
 * BlackRoad OS — Agent Registry Service
 * Manages all 193+ agents in Salesforce (free Developer Edition)
 * $0 cost — no paid CRM subscription needed, SF Dev Edition is free forever
 */
public with sharing class AgentRegistryService {

    // Pi fleet endpoints (your hardware, your rules)
    private static final String OCTAVIA_OLLAMA  = 'http://192.168.4.38:11434';
    private static final String LUCIDIA_OLLAMA  = 'http://192.168.4.81:11434';
    private static final String CECILIA_OLLAMA  = 'http://192.168.4.89:11434';
    private static final String GATEWAY_URL     = 'https://blackroad-agents.blackroad.workers.dev';

    // ── Upsert an agent record ────────────────────────────────────────────────
    public static Agent__c upsertAgent(AgentDTO dto) {
        Agent__c a = new Agent__c(
            Name            = dto.name,
            AgentId__c      = dto.agentId,
            Symbol__c       = dto.symbol,
            Role__c         = dto.role,
            Pantheon__c     = dto.pantheon,
            Status__c       = dto.status,
            DeployTarget__c = dto.deployTarget,
            Platform__c     = dto.platform,
            Domain__c       = dto.domain,
            Personality__c  = dto.personality,
            Capabilities__c = dto.capabilities,
            OllamaModel__c  = dto.ollamaModel,
            PiIP__c         = dto.piIP,
            MonthlyCost__c  = 0,        // always $0
            IsTokenless__c  = true,     // always tokenless
            SourceRepo__c   = 'BlackRoad-OS-Inc/blackroad-agents'
        );
        upsert a AgentId__c;
        return a;
    }

    // ── Bulk load all 193 agents from catalog JSON ───────────────────────────
    @AuraEnabled
    public static String bulkLoadAgents(String catalogJson) {
        Map<String, Object> catalog = (Map<String, Object>) JSON.deserializeUntyped(catalogJson);
        List<Agent__c> toUpsert = new List<Agent__c>();
        Integer count = 0;

        // Load mythology agents
        Map<String, Object> mythAgents = (Map<String, Object>) catalog.get('mythology_agents');
        if (mythAgents != null) {
            for (String agentName : mythAgents.keySet()) {
                Map<String, Object> a = (Map<String, Object>) mythAgents.get(agentName);
                toUpsert.add(new Agent__c(
                    Name            = agentName,
                    AgentId__c      = (String) a.get('id'),
                    Symbol__c       = (String) a.get('symbol'),
                    Role__c         = (String) a.get('role'),
                    Domain__c       = (String) a.get('domain'),
                    DeployTarget__c = 'cloudflare_worker',
                    Platform__c     = 'cloudflare',
                    OllamaModel__c  = 'qwen2.5:7b',
                    Status__c       = 'active',
                    MonthlyCost__c  = 0,
                    IsTokenless__c  = true,
                    SourceRepo__c   = 'BlackRoad-OS-Inc/blackroad-agents'
                ));
                count++;
            }
        }

        // Load foundation agents
        Map<String, Object> foundAgents = (Map<String, Object>) catalog.get('foundation_agents');
        if (foundAgents != null) {
            for (String agentName : foundAgents.keySet()) {
                Map<String, Object> a = (Map<String, Object>) foundAgents.get(agentName);
                String piTarget = (String) a.get('deploy');
                toUpsert.add(new Agent__c(
                    Name            = agentName,
                    AgentId__c      = (String) a.get('id'),
                    Symbol__c       = (String) a.get('symbol'),
                    DeployTarget__c = piTarget + '_pi',
                    OllamaModel__c  = (String) a.get('model'),
                    Status__c       = 'active',
                    Pantheon__c     = 'Foundation',
                    MonthlyCost__c  = 0,
                    IsTokenless__c  = true,
                    SourceRepo__c   = 'BlackRoad-OS-Inc/blackroad-agents'
                ));
                count++;
            }
        }

        Database.upsert(toUpsert, Agent__c.AgentId__c, false);
        return 'Loaded ' + count + ' agents into Salesforce. Cost: $0.';
    }

    // ── Log a task ───────────────────────────────────────────────────────────
    @AuraEnabled
    public static AgentTask__c logTask(String agentId, String title, String description,
                                        String priority, String targetRepo) {
        Agent__c agent = [SELECT Id FROM Agent__c WHERE AgentId__c = :agentId LIMIT 1];
        AgentTask__c task = new AgentTask__c(
            Name          = title,
            Agent__c      = agent.Id,
            TaskId__c     = agentId + '-' + String.valueOf(DateTime.now().getTime()),
            Description__c = description,
            Priority__c   = priority,
            Status__c     = 'pending',
            TargetRepo__c = targetRepo,
            CostUSD__c    = 0
        );
        insert task;
        return task;
    }

    // ── Write PS-SHA∞ memory entry ───────────────────────────────────────────
    @AuraEnabled
    public static AgentMemory__c writeMemory(String agentId, String content,
                                              String memType, String prevHash) {
        Agent__c agent = [SELECT Id FROM Agent__c WHERE AgentId__c = :agentId LIMIT 1];
        String hash = EncodingUtil.convertToHex(
            Crypto.generateDigest('SHA-256',
                Blob.valueOf(agentId + content + String.valueOf(DateTime.now().getTime()))
            )
        );
        AgentMemory__c mem = new AgentMemory__c(
            Name          = hash.left(16),
            Agent__c      = agent.Id,
            MemoryHash__c = hash,
            Content__c    = content,
            MemoryType__c = memType,
            TruthState__c = '1 (True)',
            Confidence__c = 100,
            PrevHash__c   = prevHash
        );
        insert mem;
        return mem;
    }

    // ── Log a deployment ─────────────────────────────────────────────────────
    @AuraEnabled
    public static AgentDeployment__c logDeployment(String agentId, String targetOrg,
                                                     String targetRepo, String deployType) {
        Id agentSfId;
        if (String.isNotBlank(agentId)) {
            List<Agent__c> agents = [SELECT Id FROM Agent__c WHERE AgentId__c = :agentId LIMIT 1];
            if (!agents.isEmpty()) agentSfId = agents[0].Id;
        }
        AgentDeployment__c dep = new AgentDeployment__c(
            Agent__c        = agentSfId,
            TargetOrg__c    = targetOrg,
            TargetRepo__c   = targetRepo,
            DeployType__c   = deployType,
            Status__c       = 'queued',
            TriggerSource__c = 'github_actions',
            CostUSD__c      = 0,
            DeployedAt__c   = DateTime.now()
        );
        insert dep;
        return dep;
    }

    // ── SOQL helpers ─────────────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<Agent__c> getActiveAgents() {
        return [SELECT Id, Name, AgentId__c, Symbol__c, Role__c, Pantheon__c,
                       Status__c, DeployTarget__c, Domain__c, OllamaModel__c,
                       PiIP__c, BondStrength__c, MonthlyCost__c, IsTokenless__c
                FROM Agent__c
                WHERE Status__c IN ('active','spawning')
                ORDER BY Pantheon__c, Name
                LIMIT 2000];
    }

    @AuraEnabled(cacheable=true)
    public static List<AgentTask__c> getPendingTasks() {
        return [SELECT Id, Name, Agent__r.Name, Agent__r.Symbol__c,
                       Status__c, Priority__c, Description__c, TargetRepo__c, TargetOrg__c
                FROM AgentTask__c
                WHERE Status__c IN ('pending','in_progress')
                ORDER BY Priority__c, CreatedDate
                LIMIT 500];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getDashboardStats() {
        Map<String, Object> stats = new Map<String, Object>();
        stats.put('totalAgents',      [SELECT COUNT() FROM Agent__c]);
        stats.put('activeAgents',     [SELECT COUNT() FROM Agent__c WHERE Status__c = 'active']);
        stats.put('cfWorkers',        [SELECT COUNT() FROM Agent__c WHERE DeployTarget__c = 'cloudflare_worker']);
        stats.put('piAgents',         [SELECT COUNT() FROM Agent__c WHERE DeployTarget__c LIKE '%_pi']);
        stats.put('pendingTasks',     [SELECT COUNT() FROM AgentTask__c WHERE Status__c = 'pending']);
        stats.put('completedTasks',   [SELECT COUNT() FROM AgentTask__c WHERE Status__c = 'completed']);
        stats.put('totalDeployments', [SELECT COUNT() FROM AgentDeployment__c]);
        stats.put('totalMemories',    [SELECT COUNT() FROM AgentMemory__c]);
        stats.put('totalCost',        '$0.00');
        stats.put('infrastructure',   'Pi Fleet (Hailo-8 + Ollama) — Your AI. Your Hardware. Your Rules.');
        return stats;
    }

    // ── DTO ──────────────────────────────────────────────────────────────────
    public class AgentDTO {
        public String agentId, name, symbol, role, pantheon, status;
        public String deployTarget, platform, domain, personality, capabilities;
        public String ollamaModel, piIP;
    }
}
