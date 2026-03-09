// Minimal Data Loader - Only Name fields
System.debug('Starting minimal data load...');

// FA CRM
insert new Client_Household__c(Name='Johnson Family');
insert new Client_Household__c(Name='Martinez Family');
System.debug('Created 2 FA households');

// General CRM
insert new Company__c(Name='Acme Corporation');
insert new Lead__c(Name='Sarah Wilson');
insert new Deal__c(Name='Enterprise License');
System.debug('Created General CRM records');

// Agency CRM
insert new Agent__c(Name='Robert Anderson');
insert new Client__c(Name='John Smith');
insert new Policy__c(Name='POL-2024-001');
insert new Listing__c(Name='123 Oak Street');
System.debug('Created Agency CRM records');

System.debug('=== MINIMAL DATA LOAD COMPLETE ===');
