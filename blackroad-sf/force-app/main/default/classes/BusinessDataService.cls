/**
 * BlackRoad OS — Business Data Service
 * Excel/CSV import + cross-system data sync
 * Pipe any spreadsheet into Salesforce via base64 CSV
 */
public with sharing class BusinessDataService {

    // ── Import CSV → any object (generic) ────────────────────────────────────
    @AuraEnabled
    public static String importCSV(String base64Csv, String targetObject) {
        String csvBody = EncodingUtil.base64Decode(base64Csv).toString();
        List<String> lines = csvBody.split('\n');
        if (lines.isEmpty()) return 'Empty file';

        // Parse headers from first row
        List<String> headers = lines[0].replace('\r','').split(',');
        Integer imported = 0;

        if (targetObject == 'Agent__c') {
            List<Agent__c> recs = new List<Agent__c>();
            for (Integer i = 1; i < lines.size(); i++) {
                String line = lines[i].replace('\r','').trim();
                if (String.isBlank(line)) continue;
                List<String> vals = line.split(',');
                Agent__c a = new Agent__c();
                for (Integer h = 0; h < headers.size() && h < vals.size(); h++) {
                    String hdr = headers[h].trim();
                    String val = vals[h].trim().replace('"','');
                    if      (hdr == 'Name')          a.Name           = val;
                    else if (hdr == 'AgentId__c')    a.AgentId__c     = val;
                    else if (hdr == 'Symbol__c')     a.Symbol__c      = val;
                    else if (hdr == 'Role__c')       a.Role__c        = val;
                    else if (hdr == 'Pantheon__c')   a.Pantheon__c    = val;
                    else if (hdr == 'Domain__c')     a.Domain__c      = val;
                    else if (hdr == 'OllamaModel__c')a.OllamaModel__c = val;
                    else if (hdr == 'PiIP__c')       a.PiIP__c        = val;
                    else if (hdr == 'Status__c')     a.Status__c      = val;
                }
                a.MonthlyCost__c = 0;
                a.IsTokenless__c = true;
                recs.add(a);
            }
            Database.upsert(recs, Agent__c.AgentId__c, false);
            imported = recs.size();

        } else if (targetObject == 'GitHubRepo__c') {
            List<GitHubRepo__c> recs = new List<GitHubRepo__c>();
            for (Integer i = 1; i < lines.size(); i++) {
                String line = lines[i].replace('\r','').trim();
                if (String.isBlank(line)) continue;
                List<String> vals = line.split(',');
                GitHubRepo__c r = new GitHubRepo__c();
                for (Integer h = 0; h < headers.size() && h < vals.size(); h++) {
                    String hdr = headers[h].trim();
                    String val = vals[h].trim().replace('"','');
                    if      (hdr == 'Name')        r.Name        = val;
                    else if (hdr == 'RepoId__c')   r.RepoId__c   = val;
                    else if (hdr == 'OrgName__c')  r.OrgName__c  = val;
                    else if (hdr == 'FullName__c') r.FullName__c = val;
                    else if (hdr == 'Language__c') r.Language__c = val;
                    else if (hdr == 'RepoUrl__c')  r.RepoUrl__c  = val;
                }
                r.MonthlyCost__c = 0;
                recs.add(r);
            }
            Database.upsert(recs, GitHubRepo__c.RepoId__c, false);
            imported = recs.size();

        } else if (targetObject == 'StripeRecord__c') {
            List<StripeRecord__c> recs = new List<StripeRecord__c>();
            for (Integer i = 1; i < lines.size(); i++) {
                String line = lines[i].replace('\r','').trim();
                if (String.isBlank(line)) continue;
                List<String> vals = line.split(',');
                StripeRecord__c s = new StripeRecord__c();
                for (Integer h = 0; h < headers.size() && h < vals.size(); h++) {
                    String hdr = headers[h].trim();
                    String val = vals[h].trim().replace('"','');
                    if      (hdr == 'Name')             s.Name             = val;
                    else if (hdr == 'StripeId__c')      s.StripeId__c      = val;
                    else if (hdr == 'RecordType__c')    s.RecordType__c    = val;
                    else if (hdr == 'CustomerEmail__c') s.CustomerEmail__c = val;
                    else if (hdr == 'CustomerName__c')  s.CustomerName__c  = val;
                    else if (hdr == 'ProductName__c')   s.ProductName__c   = val;
                    else if (hdr == 'Status__c')        s.Status__c        = val;
                }
                recs.add(s);
            }
            Database.upsert(recs, StripeRecord__c.StripeId__c, false);
            imported = recs.size();
        }

        return 'Imported ' + imported + ' records into ' + targetObject + '. Cost: $0.';
    }

    // ── Universal stats for command center header ─────────────────────────────
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCommandCenterStats() {
        Map<String, Object> stats = new Map<String, Object>();
        stats.put('agents',       [SELECT COUNT() FROM Agent__c]);
        stats.put('repos',        [SELECT COUNT() FROM GitHubRepo__c]);
        stats.put('orgs',         [SELECT COUNT() FROM OrgRegistry__c]);
        stats.put('tasks',        [SELECT COUNT() FROM AgentTask__c WHERE Status__c = 'pending']);
        stats.put('deployments',  [SELECT COUNT() FROM AgentDeployment__c]);
        stats.put('memories',     [SELECT COUNT() FROM AgentMemory__c]);
        stats.put('stripeCustomers', [SELECT COUNT() FROM StripeRecord__c WHERE RecordType__c = 'customer']);
        stats.put('totalCost',    '$0.00');
        stats.put('motto',        'Your AI. Your Hardware. Your Rules.');
        return stats;
    }
}
