// BLACKROAD FA CRM - SAMPLE DATA (Basic)
// Creates records using only standard Name field (where writable)
// Objects with AutoNumber: Liquidity_Event__c, Mortality_Event__c, Compliance_Log__c

// HOUSEHOLDS (Name is Text - writable)
List<Client_Household__c> households = new List<Client_Household__c>();
households.add(new Client_Household__c(Name = 'Chen Household - $1.2M AUM'));
households.add(new Client_Household__c(Name = 'Okonkwo Household - $3M AUM'));
households.add(new Client_Household__c(Name = 'Reyes Household - $8.5M AUM'));
households.add(new Client_Household__c(Name = 'Hartley Household - $4.7M AUM'));
households.add(new Client_Household__c(Name = 'Williams Household - Prospect'));
insert households;

System.debug('Created ' + households.size() + ' households');

// FINANCIAL ACCOUNTS (Name is Text - writable)
List<Financial_Account__c> accounts = new List<Financial_Account__c>();
accounts.add(new Financial_Account__c(Name='Margaret Chen IRA - $680k'));
accounts.add(new Financial_Account__c(Name='Chen Joint Brokerage - $340k'));
accounts.add(new Financial_Account__c(Name='Aisha Okonkwo 403(b) - $2.1M'));
accounts.add(new Financial_Account__c(Name='James Okonkwo Brokerage - $890k'));
accounts.add(new Financial_Account__c(Name='Hartley Trust - $2.71M'));
accounts.add(new Financial_Account__c(Name='Hartley IRA - $1.1M'));
insert accounts;

System.debug('Created ' + accounts.size() + ' financial accounts');

// LIQUIDITY EVENTS (Name is AutoNumber LIQ-{0000})
Liquidity_Event__c le = new Liquidity_Event__c();
insert le;

System.debug('Created 1 liquidity event');

// MORTALITY EVENTS (Name is AutoNumber MORT-{0000})
Mortality_Event__c me = new Mortality_Event__c();
insert me;

System.debug('Created 1 mortality event');

// COMPLIANCE LOGS (Name is AutoNumber LOG-{000000})
List<Compliance_Log__c> logs = new List<Compliance_Log__c>();
logs.add(new Compliance_Log__c());
logs.add(new Compliance_Log__c());
logs.add(new Compliance_Log__c());
insert logs;

System.debug('Created ' + logs.size() + ' compliance logs');

System.debug('======================================');
System.debug('FA CRM Sample Data Created!');
System.debug('5 Households, 6 Accounts, 1 Liquidity Event, 1 Mortality Event, 3 Compliance Logs');
System.debug('======================================');
