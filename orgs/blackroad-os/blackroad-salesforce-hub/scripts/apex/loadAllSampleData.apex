// ============================================
// BLACKROAD HUB - SAMPLE DATA LOADER
// Loads sample data for all 3 CRM products
// ============================================

// ----- FINANCIAL ADVISOR CRM -----
// Note: Client_Household__c only has Name field in current deployment
List<Client_Household__c> households = new List<Client_Household__c>();
households.add(new Client_Household__c(Name='Johnson Family - $1.25M AUM'));
households.add(new Client_Household__c(Name='Martinez Family - $3.5M AUM'));
households.add(new Client_Household__c(Name='Thompson Trust - $8.75M AUM'));
households.add(new Client_Household__c(Name='Williams Estate - $2.1M AUM'));
households.add(new Client_Household__c(Name='Park Family - $5.6M AUM'));
insert households;
System.debug('Created ' + households.size() + ' FA households');

// ----- GENERAL CRM -----
// Companies
List<Company__c> companies = new List<Company__c>();
companies.add(new Company__c(Name='Acme Corporation', Industry__c='Technology', Company_Size__c='201-500', Annual_Revenue__c=50000000, Account_Status__c='Customer'));
companies.add(new Company__c(Name='GlobalTech Solutions', Industry__c='Technology', Company_Size__c='501-1000', Annual_Revenue__c=120000000, Account_Status__c='Customer'));
companies.add(new Company__c(Name='Midwest Manufacturing', Industry__c='Manufacturing', Company_Size__c='1000+', Annual_Revenue__c=250000000, Account_Status__c='Prospect'));
companies.add(new Company__c(Name='HealthFirst Clinic', Industry__c='Healthcare', Company_Size__c='51-200', Annual_Revenue__c=15000000, Account_Status__c='Customer'));
companies.add(new Company__c(Name='EduLearn Academy', Industry__c='Education', Company_Size__c='11-50', Annual_Revenue__c=3000000, Account_Status__c='Prospect'));
insert companies;

// Leads
List<Lead__c> leads = new List<Lead__c>();
leads.add(new Lead__c(Name='Sarah Wilson', Email__c='sarah.wilson@acme.com', Company_Name__c='Acme Corp', Job_Title__c='VP of Sales', Lead_Status__c='Qualified', Lead_Source__c='Website'));
leads.add(new Lead__c(Name='Michael Brown', Email__c='m.brown@globaltech.io', Company_Name__c='GlobalTech', Job_Title__c='CTO', Lead_Status__c='Contacted', Lead_Source__c='Referral'));
leads.add(new Lead__c(Name='Jennifer Lee', Email__c='jlee@midwest.com', Company_Name__c='Midwest Mfg', Job_Title__c='Operations Director', Lead_Status__c='New', Lead_Source__c='Trade Show'));
leads.add(new Lead__c(Name='David Garcia', Email__c='dgarcia@healthfirst.org', Company_Name__c='HealthFirst', Job_Title__c='IT Manager', Lead_Status__c='Qualified', Lead_Source__c='Cold Call'));
leads.add(new Lead__c(Name='Emily Taylor', Email__c='etaylor@edulearn.edu', Company_Name__c='EduLearn', Job_Title__c='Principal', Lead_Status__c='New', Lead_Source__c='Email Campaign'));
insert leads;

// Deals
List<Deal__c> deals = new List<Deal__c>();
deals.add(new Deal__c(Name='Acme Enterprise License', Company__c=companies[0].Id, Amount__c=150000, Stage__c='Negotiation', Probability__c=75, Close_Date__c=Date.today().addDays(30)));
deals.add(new Deal__c(Name='GlobalTech Platform Upgrade', Company__c=companies[1].Id, Amount__c=280000, Stage__c='Proposal', Probability__c=50, Close_Date__c=Date.today().addDays(45)));
deals.add(new Deal__c(Name='Midwest ERP Implementation', Company__c=companies[2].Id, Amount__c=500000, Stage__c='Discovery', Probability__c=25, Close_Date__c=Date.today().addDays(90)));
deals.add(new Deal__c(Name='HealthFirst Cloud Migration', Company__c=companies[3].Id, Amount__c=95000, Stage__c='Closed Won', Probability__c=100, Close_Date__c=Date.today().addDays(-10)));
insert deals;
System.debug('Created ' + companies.size() + ' companies, ' + leads.size() + ' leads, ' + deals.size() + ' deals');

// ----- AGENCY CRM -----
// Agents
List<Agent__c> agents = new List<Agent__c>();
agents.add(new Agent__c(Name='Robert Anderson', Email__c='randerson@agency.com', Phone__c='555-0101', Agent_Type__c='Both', License_Number__c='INS-123456', Commission_Rate__c=0.15, Status__c='Active'));
agents.add(new Agent__c(Name='Lisa Chen', Email__c='lchen@agency.com', Phone__c='555-0102', Agent_Type__c='Real Estate', License_Number__c='RE-789012', Commission_Rate__c=0.03, Status__c='Active'));
agents.add(new Agent__c(Name='James Wilson', Email__c='jwilson@agency.com', Phone__c='555-0103', Agent_Type__c='Insurance', License_Number__c='INS-345678', Commission_Rate__c=0.12, Status__c='Active'));
agents.add(new Agent__c(Name='Maria Rodriguez', Email__c='mrodriguez@agency.com', Phone__c='555-0104', Agent_Type__c='Both', License_Number__c='DUAL-901234', Commission_Rate__c=0.10, Status__c='Active'));
insert agents;

// Clients
List<Client__c> clients = new List<Client__c>();
clients.add(new Client__c(Name='John Smith', Email__c='jsmith@email.com', Phone__c='555-1001', Client_Type__c='Policyholder', Primary_Agent__c=agents[0].Id, Source__c='Referral'));
clients.add(new Client__c(Name='Amanda Johnson', Email__c='ajohnson@email.com', Phone__c='555-1002', Client_Type__c='Buyer', Primary_Agent__c=agents[1].Id, Source__c='Website'));
clients.add(new Client__c(Name='Thomas Davis', Email__c='tdavis@email.com', Phone__c='555-1003', Client_Type__c='Seller', Primary_Agent__c=agents[1].Id, Source__c='Open House'));
clients.add(new Client__c(Name='Rachel Green', Email__c='rgreen@email.com', Phone__c='555-1004', Client_Type__c='Both', Primary_Agent__c=agents[3].Id, Source__c='Referral'));
clients.add(new Client__c(Name='Kevin Martin', Email__c='kmartin@email.com', Phone__c='555-1005', Client_Type__c='Policyholder', Primary_Agent__c=agents[2].Id, Source__c='Phone'));
insert clients;

// Policies
List<Policy__c> policies = new List<Policy__c>();
policies.add(new Policy__c(Name='POL-2024-001', Client__c=clients[0].Id, Agent__c=agents[0].Id, Policy_Type__c='Life', Premium__c=2400, Coverage_Amount__c=500000, Status__c='Active', Carrier__c='MetLife'));
policies.add(new Policy__c(Name='POL-2024-002', Client__c=clients[0].Id, Agent__c=agents[0].Id, Policy_Type__c='Auto', Premium__c=1800, Coverage_Amount__c=100000, Status__c='Active', Carrier__c='State Farm'));
policies.add(new Policy__c(Name='POL-2024-003', Client__c=clients[3].Id, Agent__c=agents[3].Id, Policy_Type__c='Home', Premium__c=3200, Coverage_Amount__c=450000, Status__c='Active', Carrier__c='Allstate'));
policies.add(new Policy__c(Name='POL-2024-004', Client__c=clients[4].Id, Agent__c=agents[2].Id, Policy_Type__c='Health', Premium__c=6000, Coverage_Amount__c=1000000, Status__c='Active', Carrier__c='Blue Cross'));
policies.add(new Policy__c(Name='POL-2024-005', Client__c=clients[3].Id, Agent__c=agents[3].Id, Policy_Type__c='Umbrella', Premium__c=800, Coverage_Amount__c=2000000, Status__c='Pending', Carrier__c='Chubb'));
insert policies;

// Listings
List<Listing__c> listings = new List<Listing__c>();
listings.add(new Listing__c(Name='123 Oak Street', Agent__c=agents[1].Id, Client__c=clients[2].Id, Property_Type__c='Single Family', List_Price__c=450000, Bedrooms__c=4, Bathrooms__c=2.5, Square_Feet__c=2400, Listing_Status__c='Active'));
listings.add(new Listing__c(Name='456 Pine Avenue #302', Agent__c=agents[1].Id, Property_Type__c='Condo', List_Price__c=285000, Bedrooms__c=2, Bathrooms__c=2, Square_Feet__c=1200, Listing_Status__c='Active'));
listings.add(new Listing__c(Name='789 Maple Drive', Agent__c=agents[3].Id, Client__c=clients[3].Id, Property_Type__c='Single Family', List_Price__c=625000, Sale_Price__c=615000, Bedrooms__c=5, Bathrooms__c=3, Square_Feet__c=3200, Listing_Status__c='Sold'));
listings.add(new Listing__c(Name='1010 Business Park Blvd', Agent__c=agents[3].Id, Property_Type__c='Commercial', List_Price__c=1200000, Square_Feet__c=8500, Listing_Status__c='Under Contract'));
insert listings;

// Commissions
List<Commission__c> commissions = new List<Commission__c>();
commissions.add(new Commission__c(Agent__c=agents[0].Id, Policy__c=policies[0].Id, Commission_Amount__c=360, Commission_Type__c='New Policy', Status__c='Paid'));
commissions.add(new Commission__c(Agent__c=agents[0].Id, Policy__c=policies[1].Id, Commission_Amount__c=270, Commission_Type__c='New Policy', Status__c='Paid'));
commissions.add(new Commission__c(Agent__c=agents[1].Id, Listing__c=listings[2].Id, Commission_Amount__c=18450, Commission_Type__c='Real Estate Sale', Status__c='Pending'));
commissions.add(new Commission__c(Agent__c=agents[3].Id, Listing__c=listings[2].Id, Commission_Amount__c=18450, Commission_Type__c='Real Estate Sale', Status__c='Pending'));
commissions.add(new Commission__c(Agent__c=agents[2].Id, Policy__c=policies[3].Id, Commission_Amount__c=720, Commission_Type__c='New Policy', Status__c='Approved'));
insert commissions;

System.debug('Created ' + agents.size() + ' agents, ' + clients.size() + ' clients, ' + policies.size() + ' policies, ' + listings.size() + ' listings, ' + commissions.size() + ' commissions');
System.debug('=== SAMPLE DATA LOAD COMPLETE ===');
