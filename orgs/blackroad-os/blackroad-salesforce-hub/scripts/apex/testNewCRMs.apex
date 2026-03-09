// Test New CRMs Only (skip FA CRM with flow issues)
System.debug('Testing General CRM and Agency CRM...');

// General CRM
Company__c comp = new Company__c(Name='Acme Corporation');
insert comp;
System.debug('Created Company: ' + comp.Id);

Lead__c lead = new Lead__c(Name='Sarah Wilson');
insert lead;
System.debug('Created Lead: ' + lead.Id);

Deal__c deal = new Deal__c(Name='Enterprise License');
insert deal;
System.debug('Created Deal: ' + deal.Id);

// Agency CRM
Agent__c agent = new Agent__c(Name='Robert Anderson');
insert agent;
System.debug('Created Agent: ' + agent.Id);

Client__c client = new Client__c(Name='John Smith');
insert client;
System.debug('Created Client: ' + client.Id);

Policy__c policy = new Policy__c(Name='POL-2024-001');
insert policy;
System.debug('Created Policy: ' + policy.Id);

Listing__c listing = new Listing__c(Name='123 Oak Street');
insert listing;
System.debug('Created Listing: ' + listing.Id);

Commission__c comm = new Commission__c();
insert comm;
System.debug('Created Commission: ' + comm.Id);

System.debug('=== NEW CRM TEST COMPLETE ===');
