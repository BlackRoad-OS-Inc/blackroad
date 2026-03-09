// Insert BlackRoad General CRM as a CRM Product
CRM_Product__c generalCRM = new CRM_Product__c();
generalCRM.Name = 'BlackRoad General CRM';
generalCRM.Product_Code__c = 'GENERAL_CRM';
generalCRM.Description__c = 'General-purpose sales CRM for any industry. Includes lead management, deal pipeline, company accounts, activity tracking, and task management.';
generalCRM.Version__c = '1.0';
generalCRM.Target_Vertical__c = 'All Industries';
generalCRM.Objects_Included__c = 'Lead__c, Deal__c, Company__c, Activity__c, Task__c';
generalCRM.Flows_Included__c = '';

// Check if already exists
List<CRM_Product__c> existing = [SELECT Id FROM CRM_Product__c WHERE Product_Code__c = 'GENERAL_CRM' LIMIT 1];
if (existing.isEmpty()) {
    insert generalCRM;
    System.debug('Created GENERAL_CRM product: ' + generalCRM.Id);
} else {
    System.debug('GENERAL_CRM already exists: ' + existing[0].Id);
}
