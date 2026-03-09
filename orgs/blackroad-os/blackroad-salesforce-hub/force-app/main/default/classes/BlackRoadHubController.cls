/**
 * BlackRoad OS Hub Controller
 * Main controller for the Hub Dashboard and CRM management
 */
public with sharing class BlackRoadHubController {
    
    /**
     * Get all connected CRM instances
     */
    @AuraEnabled(cacheable=true)
    public static List<Connected_CRM__c> getConnectedCRMs() {
        return [
            SELECT Id, Name, CRM_Type__c, Instance_URL__c, Status__c, 
                   Last_Sync__c, Vertical__c, Record_Count__c
            FROM Connected_CRM__c
            ORDER BY Name
        ];
    }
    
    /**
     * Get all available CRM products/templates
     */
    @AuraEnabled(cacheable=true)
    public static List<CRM_Product__c> getCRMProducts() {
        return [
            SELECT Id, Name, Product_Code__c, Description__c, Version__c,
                   Target_Vertical__c, Objects_Included__c, Flows_Included__c
            FROM CRM_Product__c
            ORDER BY Target_Vertical__c, Name
        ];
    }
    
    /**
     * Get hub statistics
     */
    @AuraEnabled(cacheable=true)
    public static HubStats getHubStats() {
        HubStats stats = new HubStats();
        
        stats.totalCRMs = [SELECT COUNT() FROM Connected_CRM__c];
        stats.activeCRMs = [SELECT COUNT() FROM Connected_CRM__c WHERE Status__c = 'Active'];
        stats.totalHouseholds = [SELECT COUNT() FROM Client_Household__c];
        stats.totalAUM = 0;
        
        AggregateResult[] aumResult = [
            SELECT SUM(Total_AUM__c) totalAUM 
            FROM Client_Household__c
        ];
        if (aumResult.size() > 0 && aumResult[0].get('totalAUM') != null) {
            stats.totalAUM = (Decimal)aumResult[0].get('totalAUM');
        }
        
        stats.pendingDistributions = [
            SELECT COUNT() FROM Distribution_Request__c 
            WHERE Status__c NOT IN ('Completed', 'Rejected')
        ];
        
        stats.activeMortalityEvents = [
            SELECT COUNT() FROM Mortality_Event__c 
            WHERE Status__c != 'Completed'
        ];
        
        stats.activeLiquidityEvents = [
            SELECT COUNT() FROM Liquidity_Event__c 
            WHERE Status__c NOT IN ('Closed - Funds Received', 'Post-Close Planning')
        ];
        
        return stats;
    }
    
    /**
     * Get recent compliance logs
     */
    @AuraEnabled(cacheable=true)
    public static List<Compliance_Log__c> getRecentComplianceLogs(Integer recordLimit) {
        return [
            SELECT Id, Name, Log_Type__c, Description__c, CreatedDate,
                   Household__r.Name, Logged_By__r.Name, Auto_Generated__c
            FROM Compliance_Log__c
            ORDER BY CreatedDate DESC
            LIMIT :recordLimit
        ];
    }
    
    /**
     * Get households needing attention (overdue reviews, etc.)
     */
    @AuraEnabled(cacheable=true)
    public static List<Client_Household__c> getHouseholdsNeedingAttention() {
        Date today = Date.today();
        return [
            SELECT Id, Name, Total_AUM__c, Primary_Contact__r.Name,
                   Last_Review_Date__c, Next_Review_Date__c, Household_Status__c
            FROM Client_Household__c
            WHERE Next_Review_Date__c <= :today
               OR Household_Status__c = 'Deceased Primary'
            ORDER BY Next_Review_Date__c ASC
            LIMIT 20
        ];
    }
    
    /**
     * Sync a connected CRM
     */
    @AuraEnabled
    public static String syncCRM(Id crmId) {
        Connected_CRM__c crm = [
            SELECT Id, Name, CRM_Type__c, API_Endpoint__c, Status__c
            FROM Connected_CRM__c
            WHERE Id = :crmId
        ];
        
        // Update status to syncing
        crm.Status__c = 'Syncing';
        update crm;
        
        // In a real implementation, this would call the external CRM API
        // For now, we'll simulate a successful sync
        crm.Last_Sync__c = DateTime.now();
        crm.Status__c = 'Active';
        update crm;
        
        return 'Sync initiated for ' + crm.Name;
    }
    
    /**
     * Create a compliance log entry
     */
    @AuraEnabled
    public static Compliance_Log__c createComplianceLog(
        Id householdId, 
        String logType, 
        String description,
        String relatedRecordId
    ) {
        Compliance_Log__c log = new Compliance_Log__c(
            Household__c = householdId,
            Log_Type__c = logType,
            Description__c = description,
            Related_Record_ID__c = relatedRecordId,
            Logged_By__c = UserInfo.getUserId(),
            Auto_Generated__c = false
        );
        insert log;
        return log;
    }
    
    /**
     * Hub statistics wrapper class
     */
    public class HubStats {
        @AuraEnabled public Integer totalCRMs { get; set; }
        @AuraEnabled public Integer activeCRMs { get; set; }
        @AuraEnabled public Integer totalHouseholds { get; set; }
        @AuraEnabled public Decimal totalAUM { get; set; }
        @AuraEnabled public Integer pendingDistributions { get; set; }
        @AuraEnabled public Integer activeMortalityEvents { get; set; }
        @AuraEnabled public Integer activeLiquidityEvents { get; set; }
    }
}
