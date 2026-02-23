/**
 * BlackRoad OS — GitHub Sync Service
 * Pulls all 17 orgs + 1825+ repos from GitHub API into Salesforce
 * Salesforce IS our GitHub now. $0.
 */
public with sharing class GitHubSyncService {

    // All 17 BlackRoad GitHub orgs
    public static final List<String> ALL_ORGS = new List<String>{
        'BlackRoad-OS-Inc',
        'BlackRoad-OS',
        'blackboxprogramming',
        'BlackRoad-AI',
        'BlackRoad-Cloud',
        'BlackRoad-Security',
        'BlackRoad-Media',
        'BlackRoad-Foundation',
        'BlackRoad-Interactive',
        'BlackRoad-Hardware',
        'BlackRoad-Labs',
        'BlackRoad-Studio',
        'BlackRoad-Ventures',
        'BlackRoad-Education',
        'BlackRoad-Gov',
        'Blackbox-Enterprises',
        'BlackRoad-Archive'
    };

    // Org metadata: purpose + known repo counts
    private static final Map<String, String> ORG_PURPOSE = new Map<String, String>{
        'BlackRoad-OS-Inc'      => 'Corporate core — 7 private repos',
        'BlackRoad-OS'          => 'Core platform — 1332+ repos',
        'blackboxprogramming'   => 'Primary dev account — 68 repos',
        'BlackRoad-AI'          => 'AI/ML stack — vLLM, Ollama, DeepSeek, Qwen',
        'BlackRoad-Cloud'       => 'Cloud infrastructure — K8s, Terraform, Nomad',
        'BlackRoad-Security'    => 'Security tools — Trivy, Falco, Wazuh',
        'BlackRoad-Media'       => 'Media & content',
        'BlackRoad-Foundation'  => 'CRM, project management',
        'BlackRoad-Interactive' => 'Gaming & interactive',
        'BlackRoad-Hardware'    => 'IoT & Raspberry Pi',
        'BlackRoad-Labs'        => 'Research & experiments',
        'BlackRoad-Studio'      => 'Creative tools',
        'BlackRoad-Ventures'    => 'Business & finance',
        'BlackRoad-Education'   => 'Education & LMS',
        'BlackRoad-Gov'         => 'Governance & civic',
        'Blackbox-Enterprises'  => 'Enterprise automation — n8n, Airbyte, Temporal',
        'BlackRoad-Archive'     => 'Archived projects & IPFS'
    };

    // ── Seed all 17 orgs into OrgRegistry__c ─────────────────────────────────
    @AuraEnabled
    public static String seedOrgRegistry() {
        List<OrgRegistry__c> orgs = new List<OrgRegistry__c>();
        for (String orgSlug : ALL_ORGS) {
            orgs.add(new OrgRegistry__c(
                Name          = orgSlug,
                GithubOrg__c  = orgSlug,
                DisplayName__c = orgSlug.replace('-', ' '),
                Purpose__c    = ORG_PURPOSE.get(orgSlug),
                OrgUrl__c     = 'https://github.com/' + orgSlug,
                IsActive__c   = true,
                SyncStatus__c = 'pending',
                TotalAgents__c = 0,
                MonthlyCost__c = 0
            ));
        }
        upsert orgs GithubOrg__c;
        return 'Seeded ' + orgs.size() + ' orgs. Cost: $0.';
    }

    // ── Sync one org's repos from GitHub API (callout) ───────────────────────
    @future(callout=true)
    public static void syncOrgRepos(String orgSlug, String githubToken) {
        Integer page = 1;
        List<GitHubRepo__c> toUpsert = new List<GitHubRepo__c>();

        while (page <= 10) {  // max 1000 repos per org (100 per page)
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.github.com/orgs/' + orgSlug
                + '/repos?type=all&sort=pushed&per_page=100&page=' + page);
            req.setMethod('GET');
            req.setHeader('Authorization', 'Bearer ' + githubToken);
            req.setHeader('Accept', 'application/vnd.github.v3+json');
            req.setHeader('X-GitHub-Api-Version', '2022-11-28');
            req.setTimeout(30000);

            HttpResponse res = new Http().send(req);
            if (res.getStatusCode() != 200) break;

            List<Object> repos = (List<Object>) JSON.deserializeUntyped(res.getBody());
            if (repos.isEmpty()) break;

            for (Object r : repos) {
                Map<String, Object> repo = (Map<String, Object>) r;
                toUpsert.add(new GitHubRepo__c(
                    Name           = (String) repo.get('name'),
                    RepoId__c      = String.valueOf(repo.get('id')),
                    OrgName__c     = orgSlug,
                    FullName__c    = (String) repo.get('full_name'),
                    Description__c = (String) repo.get('description'),
                    Language__c    = (String) repo.get('language'),
                    Stars__c       = (Integer) repo.get('stargazers_count'),
                    Forks__c       = (Integer) repo.get('forks_count'),
                    OpenIssues__c  = (Integer) repo.get('open_issues_count'),
                    IsPrivate__c   = (Boolean) repo.get('private'),
                    IsFork__c      = (Boolean) repo.get('fork'),
                    IsArchived__c  = (Boolean) repo.get('archived'),
                    DefaultBranch__c = (String) repo.get('default_branch'),
                    RepoUrl__c     = (String) repo.get('html_url'),
                    MonthlyCost__c = 0
                ));
            }
            if (repos.size() < 100) break;
            page++;
        }

        if (!toUpsert.isEmpty()) {
            Database.upsert(toUpsert, GitHubRepo__c.RepoId__c, false);
        }

        // Update org sync status
        List<OrgRegistry__c> org = [SELECT Id FROM OrgRegistry__c WHERE GithubOrg__c = :orgSlug LIMIT 1];
        if (!org.isEmpty()) {
            org[0].SyncStatus__c  = 'synced';
            org[0].LastSyncedAt__c = DateTime.now();
            org[0].TotalRepos__c  = toUpsert.size();
            update org[0];
        }
    }

    // ── Get latest workflow run for a repo ───────────────────────────────────
    @AuraEnabled
    public static String getWorkflowStatus(String owner, String repo, String githubToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.github.com/repos/' + owner + '/' + repo
            + '/actions/runs?per_page=1');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + githubToken);
        req.setHeader('Accept', 'application/vnd.github.v3+json');
        req.setTimeout(15000);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) return 'unknown';

        Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        List<Object> runs = (List<Object>) body.get('workflow_runs');
        if (runs == null || runs.isEmpty()) return 'no_runs';

        Map<String, Object> run = (Map<String, Object>) runs[0];
        return (String) run.get('conclusion') + '|' + (String) run.get('html_url');
    }

    // ── Get all repos (SOQL) ─────────────────────────────────────────────────
    @AuraEnabled(cacheable=true)
    public static List<GitHubRepo__c> getRepos(String orgFilter) {
        if (String.isNotBlank(orgFilter) && orgFilter != 'all') {
            return [SELECT Id, Name, RepoId__c, OrgName__c, FullName__c, Language__c,
                           Stars__c, Forks__c, OpenIssues__c, IsPrivate__c, IsFork__c,
                           IsArchived__c, RepoUrl__c, WorkflowStatus__c, LastPushAt__c
                    FROM GitHubRepo__c
                    WHERE OrgName__c = :orgFilter
                    ORDER BY Stars__c DESC NULLS LAST, Name
                    LIMIT 1000];
        }
        return [SELECT Id, Name, RepoId__c, OrgName__c, FullName__c, Language__c,
                       Stars__c, Forks__c, OpenIssues__c, IsPrivate__c, IsFork__c,
                       IsArchived__c, RepoUrl__c, WorkflowStatus__c, LastPushAt__c
                FROM GitHubRepo__c
                ORDER BY OrgName__c, Stars__c DESC NULLS LAST
                LIMIT 2000];
    }

    @AuraEnabled(cacheable=true)
    public static List<OrgRegistry__c> getAllOrgs() {
        return [SELECT Id, Name, GithubOrg__c, DisplayName__c, Purpose__c,
                       TotalRepos__c, TotalAgents__c, IsActive__c, OrgUrl__c,
                       SyncStatus__c, LastSyncedAt__c
                FROM OrgRegistry__c
                ORDER BY Name];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getGitHubStats() {
        Map<String, Object> stats = new Map<String, Object>();
        stats.put('totalRepos',    [SELECT COUNT() FROM GitHubRepo__c]);
        stats.put('totalOrgs',     [SELECT COUNT() FROM OrgRegistry__c]);
        stats.put('privateRepos',  [SELECT COUNT() FROM GitHubRepo__c WHERE IsPrivate__c = true]);
        stats.put('forks',         [SELECT COUNT() FROM GitHubRepo__c WHERE IsFork__c = true]);
        stats.put('archived',      [SELECT COUNT() FROM GitHubRepo__c WHERE IsArchived__c = true]);
        stats.put('syncedOrgs',    [SELECT COUNT() FROM OrgRegistry__c WHERE SyncStatus__c = 'synced']);
        return stats;
    }
}
