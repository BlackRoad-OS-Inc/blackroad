/**
 * Financial Advisor Service
 * Business logic for FA CRM operations
 */
public with sharing class FinancialAdvisorService {
    
    /**
     * Get household summary with all related data
     */
    @AuraEnabled(cacheable=true)
    public static HouseholdSummary getHouseholdSummary(Id householdId) {
        HouseholdSummary summary = new HouseholdSummary();
        
        // Get household details
        summary.household = [
            SELECT Id, Name, Total_AUM__c, Household_Status__c, Risk_Tolerance__c,
                   Last_Review_Date__c, Next_Review_Date__c, Annual_Fee__c,
                   Primary_Contact__r.Name, Primary_Contact__r.Email, Primary_Contact__r.Phone,
                   Secondary_Contact__r.Name, Secondary_Contact__r.Email
            FROM Client_Household__c
            WHERE Id = :householdId
        ];
        
        // Get financial accounts
        summary.accounts = [
            SELECT Id, Name, Account_Type__c, Current_Value__c, Custodian__c,
                   Registration__c, Primary_Beneficiary__c, Is_Liquid__c
            FROM Financial_Account__c
            WHERE Household__c = :householdId
            ORDER BY Current_Value__c DESC
        ];
        
        // Calculate totals
        summary.totalLiquid = 0;
        summary.totalNonLiquid = 0;
        for (Financial_Account__c acc : summary.accounts) {
            if (acc.Is_Liquid__c) {
                summary.totalLiquid += acc.Current_Value__c != null ? acc.Current_Value__c : 0;
            } else {
                summary.totalNonLiquid += acc.Current_Value__c != null ? acc.Current_Value__c : 0;
            }
        }
        
        // Get pending distributions
        summary.pendingDistributions = [
            SELECT Id, Name, Gross_Amount__c, Net_Amount__c, Status__c, 
                   Delivery_Method__c, Urgency__c, Source_Account__r.Name
            FROM Distribution_Request__c
            WHERE Household__c = :householdId
              AND Status__c NOT IN ('Completed', 'Rejected')
            ORDER BY CreatedDate DESC
        ];
        
        // Get recent compliance logs
        summary.recentLogs = [
            SELECT Id, Name, Log_Type__c, Description__c, CreatedDate
            FROM Compliance_Log__c
            WHERE Household__c = :householdId
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        
        return summary;
    }
    
    /**
     * Process a distribution request
     */
    @AuraEnabled
    public static Distribution_Request__c processDistribution(
        Id householdId,
        Id sourceAccountId,
        Decimal grossAmount,
        Decimal federalWithholding,
        Decimal stateWithholding,
        String deliveryMethod,
        String urgency,
        String reason
    ) {
        // Create distribution request
        Distribution_Request__c dist = new Distribution_Request__c(
            Household__c = householdId,
            Source_Account__c = sourceAccountId,
            Gross_Amount__c = grossAmount,
            Federal_Withholding__c = federalWithholding,
            State_Withholding__c = stateWithholding,
            Delivery_Method__c = deliveryMethod,
            Urgency__c = urgency,
            Reason__c = reason,
            Status__c = 'Pending Compliance'
        );
        
        // Auto-approve if under threshold and not emergency
        if (grossAmount <= 100000 && urgency != 'Emergency') {
            dist.Status__c = 'Approved';
            dist.Compliance_Notes__c = 'Auto-approved: Under $100K threshold';
        }
        
        insert dist;
        
        // Create compliance log
        createAutoComplianceLog(
            householdId,
            'Distribution',
            'Distribution request created: $' + grossAmount + ' from ' + sourceAccountId,
            dist.Id
        );
        
        return dist;
    }
    
    /**
     * Initiate mortality event workflow
     */
    @AuraEnabled
    public static Mortality_Event__c initiateMortalityEvent(
        Id householdId,
        Id deceasedContactId,
        Date dateOfDeath,
        String executorName,
        Id survivingSpouseId
    ) {
        Mortality_Event__c event = new Mortality_Event__c(
            Household__c = householdId,
            Deceased_Contact__c = deceasedContactId,
            Date_of_Death__c = dateOfDeath,
            Executor_Name__c = executorName,
            Surviving_Spouse__c = survivingSpouseId,
            Status__c = 'Reported'
        );
        
        insert event;
        
        // Update household status
        Client_Household__c household = new Client_Household__c(
            Id = householdId,
            Household_Status__c = 'Deceased Primary'
        );
        update household;
        
        // Create compliance log
        createAutoComplianceLog(
            householdId,
            'Account Change',
            'Mortality event initiated. Date of death: ' + dateOfDeath,
            event.Id
        );
        
        return event;
    }
    
    /**
     * Calculate distribution tax impact
     */
    @AuraEnabled
    public static TaxCalculation calculateDistributionTax(
        Decimal grossAmount,
        String accountType,
        Decimal federalRate,
        Decimal stateRate
    ) {
        TaxCalculation calc = new TaxCalculation();
        calc.grossAmount = grossAmount;
        
        // Check for early withdrawal penalty (simplified)
        calc.earlyWithdrawalPenalty = 0;
        if (accountType == 'Traditional IRA' || accountType == '401(k)') {
            // In reality, would check client age
            // calc.earlyWithdrawalPenalty = grossAmount * 0.10;
        }
        
        calc.federalTax = grossAmount * (federalRate / 100);
        calc.stateTax = grossAmount * (stateRate / 100);
        calc.totalTax = calc.federalTax + calc.stateTax + calc.earlyWithdrawalPenalty;
        calc.netAmount = grossAmount - calc.totalTax;
        
        return calc;
    }
    
    /**
     * Helper: Create auto-generated compliance log
     */
    private static void createAutoComplianceLog(Id householdId, String logType, String description, Id relatedId) {
        Compliance_Log__c log = new Compliance_Log__c(
            Household__c = householdId,
            Log_Type__c = logType,
            Description__c = description,
            Related_Record_ID__c = relatedId,
            Logged_By__c = UserInfo.getUserId(),
            Auto_Generated__c = true
        );
        insert log;
    }
    
    /**
     * Wrapper classes
     */
    public class HouseholdSummary {
        @AuraEnabled public Client_Household__c household { get; set; }
        @AuraEnabled public List<Financial_Account__c> accounts { get; set; }
        @AuraEnabled public Decimal totalLiquid { get; set; }
        @AuraEnabled public Decimal totalNonLiquid { get; set; }
        @AuraEnabled public List<Distribution_Request__c> pendingDistributions { get; set; }
        @AuraEnabled public List<Compliance_Log__c> recentLogs { get; set; }
    }
    
    public class TaxCalculation {
        @AuraEnabled public Decimal grossAmount { get; set; }
        @AuraEnabled public Decimal federalTax { get; set; }
        @AuraEnabled public Decimal stateTax { get; set; }
        @AuraEnabled public Decimal earlyWithdrawalPenalty { get; set; }
        @AuraEnabled public Decimal totalTax { get; set; }
        @AuraEnabled public Decimal netAmount { get; set; }
    }
}
