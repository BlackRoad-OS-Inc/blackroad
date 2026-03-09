// Load Complete Sample Data for All 3 CRMs with Custom Fields
// Run with: sf apex run --file scripts/apex/loadCompleteSampleData.apex --target-org blackroad-hub

// ============================================
// GENERAL CRM - Company, Lead, Deal
// ============================================

// Companies with full data
List<Company__c> companies = new List<Company__c>();
companies.add(new Company__c(
    Name = 'TechCorp Inc',
    Industry__c = 'Technology',
    Company_Size__c = '51-200',
    Website__c = 'https://techcorp.example.com',
    Phone__c = '(555) 123-4567',
    Address__c = '123 Tech Park Drive, San Francisco, CA 94105',
    Annual_Revenue__c = 5000000,
    Account_Status__c = 'Customer',
    Description__c = 'Leading technology solutions provider specializing in cloud infrastructure and AI services.'
));
companies.add(new Company__c(
    Name = 'Healthcare Plus',
    Industry__c = 'Healthcare',
    Company_Size__c = '201-500',
    Website__c = 'https://healthcareplus.example.com',
    Phone__c = '(555) 234-5678',
    Address__c = '456 Medical Center Blvd, Boston, MA 02115',
    Annual_Revenue__c = 15000000,
    Account_Status__c = 'Customer',
    Description__c = 'Comprehensive healthcare management and patient care solutions.'
));
companies.add(new Company__c(
    Name = 'FinanceFirst Bank',
    Industry__c = 'Finance',
    Company_Size__c = '1000+',
    Website__c = 'https://financefirst.example.com',
    Phone__c = '(555) 345-6789',
    Address__c = '789 Wall Street, New York, NY 10005',
    Annual_Revenue__c = 50000000,
    Account_Status__c = 'Prospect',
    Description__c = 'Regional banking institution with focus on small business lending.'
));
companies.add(new Company__c(
    Name = 'EduLearn Academy',
    Industry__c = 'Education',
    Company_Size__c = '11-50',
    Website__c = 'https://edulearn.example.com',
    Phone__c = '(555) 456-7890',
    Address__c = '321 Campus Way, Austin, TX 78701',
    Annual_Revenue__c = 2000000,
    Account_Status__c = 'Partner',
    Description__c = 'Online learning platform for professional development and certifications.'
));
insert companies;
System.debug('Created ' + companies.size() + ' Companies');

// Leads
List<Lead__c> leads = new List<Lead__c>();
leads.add(new Lead__c(Name = 'Sarah Wilson - TechCorp Expansion'));
leads.add(new Lead__c(Name = 'Michael Chen - Healthcare RFP'));
leads.add(new Lead__c(Name = 'Jennifer Brown - Finance Consulting'));
leads.add(new Lead__c(Name = 'David Martinez - Education Partnership'));
leads.add(new Lead__c(Name = 'Emily Davis - Manufacturing Pilot'));
insert leads;
System.debug('Created ' + leads.size() + ' Leads');

// Deals
List<Deal__c> deals = new List<Deal__c>();
deals.add(new Deal__c(Name = 'TechCorp Cloud Migration - Q1'));
deals.add(new Deal__c(Name = 'Healthcare Plus EMR Integration'));
deals.add(new Deal__c(Name = 'FinanceFirst Compliance Suite'));
deals.add(new Deal__c(Name = 'EduLearn LMS Deployment'));
insert deals;
System.debug('Created ' + deals.size() + ' Deals');

// ============================================
// AGENCY CRM - Agent, Client, Policy, Listing, Commission
// ============================================

// Agents
List<Agent__c> agents = new List<Agent__c>();
agents.add(new Agent__c(Name = 'Robert Anderson - Senior Agent'));
agents.add(new Agent__c(Name = 'Lisa Thompson - Insurance Specialist'));
agents.add(new Agent__c(Name = 'James Wilson - Real Estate Expert'));
agents.add(new Agent__c(Name = 'Maria Garcia - Commercial Specialist'));
insert agents;
System.debug('Created ' + agents.size() + ' Agents');

// Clients
List<Client__c> clients = new List<Client__c>();
clients.add(new Client__c(Name = 'John Smith'));
clients.add(new Client__c(Name = 'Susan Johnson'));
clients.add(new Client__c(Name = 'William Brown'));
clients.add(new Client__c(Name = 'Patricia Davis'));
clients.add(new Client__c(Name = 'Christopher Lee'));
insert clients;
System.debug('Created ' + clients.size() + ' Clients');

// Policies
List<Policy__c> policies = new List<Policy__c>();
policies.add(new Policy__c(Name = 'POL-2024-001 - Home Insurance'));
policies.add(new Policy__c(Name = 'POL-2024-002 - Auto Insurance'));
policies.add(new Policy__c(Name = 'POL-2024-003 - Life Insurance'));
policies.add(new Policy__c(Name = 'POL-2024-004 - Business Insurance'));
policies.add(new Policy__c(Name = 'POL-2024-005 - Health Insurance'));
insert policies;
System.debug('Created ' + policies.size() + ' Policies');

// Listings
List<Listing__c> listings = new List<Listing__c>();
listings.add(new Listing__c(Name = '123 Oak Street - 3BR/2BA'));
listings.add(new Listing__c(Name = '456 Maple Avenue - 4BR/3BA'));
listings.add(new Listing__c(Name = '789 Pine Lane - 2BR/1BA Condo'));
listings.add(new Listing__c(Name = '321 Cedar Court - 5BR/4BA Luxury'));
listings.add(new Listing__c(Name = '555 Commercial Plaza - Office Space'));
insert listings;
System.debug('Created ' + listings.size() + ' Listings');

// Commissions (auto-number name, no Name field needed)
List<Commission__c> commissions = new List<Commission__c>();
commissions.add(new Commission__c());
commissions.add(new Commission__c());
commissions.add(new Commission__c());
commissions.add(new Commission__c());
insert commissions;
System.debug('Created ' + commissions.size() + ' Commissions');

// ============================================
// SUMMARY
// ============================================
System.debug('=== SAMPLE DATA LOAD COMPLETE ===');
System.debug('General CRM: ' + companies.size() + ' Companies, ' + leads.size() + ' Leads, ' + deals.size() + ' Deals');
System.debug('Agency CRM: ' + agents.size() + ' Agents, ' + clients.size() + ' Clients, ' + policies.size() + ' Policies, ' + listings.size() + ' Listings, ' + commissions.size() + ' Commissions');
System.debug('TOTAL RECORDS: ' + (companies.size() + leads.size() + deals.size() + agents.size() + clients.size() + policies.size() + listings.size() + commissions.size()));
