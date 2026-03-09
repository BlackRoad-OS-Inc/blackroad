// ============================================
// BLACKROAD HUB - SIMPLE DATA LOADER
// Creates minimal sample data for all 3 CRMs
// ============================================

// ----- FINANCIAL ADVISOR CRM -----
List<Client_Household__c> households = new List<Client_Household__c>();
households.add(new Client_Household__c(Name='Johnson Family - $1.25M AUM'));
households.add(new Client_Household__c(Name='Martinez Family - $3.5M AUM'));
households.add(new Client_Household__c(Name='Thompson Trust - $8.75M AUM'));
insert households;
System.debug('Created ' + households.size() + ' FA households');

// ----- GENERAL CRM -----
List<Company__c> companies = new List<Company__c>();
companies.add(new Company__c(Name='Acme Corporation'));
companies.add(new Company__c(Name='GlobalTech Solutions'));
companies.add(new Company__c(Name='Midwest Manufacturing'));
insert companies;
System.debug('Created ' + companies.size() + ' companies');

List<Lead__c> leads = new List<Lead__c>();
leads.add(new Lead__c(Name='Sarah Wilson'));
leads.add(new Lead__c(Name='Michael Brown'));
leads.add(new Lead__c(Name='Jennifer Lee'));
insert leads;
System.debug('Created ' + leads.size() + ' leads');

List<Deal__c> deals = new List<Deal__c>();
deals.add(new Deal__c(Name='Acme Enterprise License', Company__c=companies[0].Id));
deals.add(new Deal__c(Name='GlobalTech Platform Upgrade', Company__c=companies[1].Id));
deals.add(new Deal__c(Name='Midwest ERP Implementation', Company__c=companies[2].Id));
insert deals;
System.debug('Created ' + deals.size() + ' deals');

// ----- AGENCY CRM -----
List<Agent__c> agents = new List<Agent__c>();
agents.add(new Agent__c(Name='Robert Anderson'));
agents.add(new Agent__c(Name='Lisa Chen'));
agents.add(new Agent__c(Name='James Wilson'));
insert agents;
System.debug('Created ' + agents.size() + ' agents');

List<Client__c> clients = new List<Client__c>();
clients.add(new Client__c(Name='John Smith', Primary_Agent__c=agents[0].Id));
clients.add(new Client__c(Name='Amanda Johnson', Primary_Agent__c=agents[1].Id));
clients.add(new Client__c(Name='Thomas Davis', Primary_Agent__c=agents[2].Id));
insert clients;
System.debug('Created ' + clients.size() + ' clients');

List<Policy__c> policies = new List<Policy__c>();
policies.add(new Policy__c(Name='POL-2024-001', Client__c=clients[0].Id, Agent__c=agents[0].Id));
policies.add(new Policy__c(Name='POL-2024-002', Client__c=clients[1].Id, Agent__c=agents[1].Id));
policies.add(new Policy__c(Name='POL-2024-003', Client__c=clients[2].Id, Agent__c=agents[2].Id));
insert policies;
System.debug('Created ' + policies.size() + ' policies');

List<Listing__c> listings = new List<Listing__c>();
listings.add(new Listing__c(Name='123 Oak Street', Agent__c=agents[1].Id));
listings.add(new Listing__c(Name='456 Pine Avenue', Agent__c=agents[1].Id));
listings.add(new Listing__c(Name='789 Maple Drive', Agent__c=agents[0].Id));
insert listings;
System.debug('Created ' + listings.size() + ' listings');

System.debug('=== SIMPLE DATA LOAD COMPLETE ===');
