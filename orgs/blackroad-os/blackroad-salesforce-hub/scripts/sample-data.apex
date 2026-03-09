// BLACKROAD FA CRM - SAMPLE DATA

// HOUSEHOLDS
Client_Household__c chen = new Client_Household__c(
    Name = 'Chen Household',
    Total_AUM__c = 1200000,
    Household_Status__c = 'Active',
    Risk_Tolerance__c = 'Moderate',
    Annual_Fee__c = 12000
);
insert chen;

Client_Household__c okonkwo = new Client_Household__c(
    Name = 'Okonkwo Household',
    Total_AUM__c = 3000000,
    Household_Status__c = 'Active',
    Risk_Tolerance__c = 'Moderately Aggressive',
    Annual_Fee__c = 30000
);
insert okonkwo;

Client_Household__c reyes = new Client_Household__c(
    Name = 'Reyes Household',
    Total_AUM__c = 8500000,
    Household_Status__c = 'Active',
    Risk_Tolerance__c = 'Moderate',
    Annual_Fee__c = 85000
);
insert reyes;

Client_Household__c hartley = new Client_Household__c(
    Name = 'Hartley Household',
    Total_AUM__c = 4700000,
    Household_Status__c = 'Deceased Primary',
    Risk_Tolerance__c = 'Conservative',
    Annual_Fee__c = 47000
);
insert hartley;

Client_Household__c williams = new Client_Household__c(
    Name = 'Williams Household',
    Total_AUM__c = 450000,
    Household_Status__c = 'Prospect',
    Risk_Tolerance__c = 'Moderate'
);
insert williams;

// FINANCIAL ACCOUNTS
insert new Financial_Account__c(Name='Margaret Chen IRA', Household__c=chen.Id, Account_Type__c='Traditional IRA', Current_Value__c=680000, Custodian__c='Ameriprise', Is_Liquid__c=true);
insert new Financial_Account__c(Name='Chen Joint Brokerage', Household__c=chen.Id, Account_Type__c='Joint Brokerage', Current_Value__c=340000, Custodian__c='Ameriprise', Is_Liquid__c=true);
insert new Financial_Account__c(Name='Aisha Okonkwo 403(b)', Household__c=okonkwo.Id, Account_Type__c='403(b)', Current_Value__c=2100000, Custodian__c='Ameriprise', Is_Liquid__c=true);
insert new Financial_Account__c(Name='James Okonkwo Brokerage', Household__c=okonkwo.Id, Account_Type__c='Individual Brokerage', Current_Value__c=890000, Custodian__c='Ameriprise', Is_Liquid__c=true);
insert new Financial_Account__c(Name='Hartley Trust', Household__c=hartley.Id, Account_Type__c='Trust', Current_Value__c=2710000, Custodian__c='Ameriprise', Is_Liquid__c=true);
insert new Financial_Account__c(Name='Hartley IRA', Household__c=hartley.Id, Account_Type__c='Traditional IRA', Current_Value__c=1100000, Custodian__c='Ameriprise', Is_Liquid__c=true);

// LIQUIDITY EVENT
insert new Liquidity_Event__c(Household__c=reyes.Id, Event_Type__c='Business Sale', Gross_Proceeds__c=9350000, Estimated_Tax__c=1385000, Net_Proceeds__c=7965000, QSBS_Eligible__c='Yes - Verified', Status__c='Due Diligence');

// MORTALITY EVENT  
insert new Mortality_Event__c(Household__c=hartley.Id, Date_of_Death__c=Date.today().addDays(-7), Death_Certificate_Received__c=true, Executor_Name__c='Michael Hartley', Total_Estate_Value__c=4700000, Probate_Required__c=true, Status__c='Documents Gathering');

// COMPLIANCE LOGS
insert new Compliance_Log__c(Household__c=chen.Id, Log_Type__c='Phone Call', Description__c='Client reported spouse death. Initiated emergency distribution.', Auto_Generated__c=false);
insert new Compliance_Log__c(Household__c=reyes.Id, Log_Type__c='Meeting', Description__c='Business sale planning. Reviewed QSBS eligibility.', Auto_Generated__c=false);
insert new Compliance_Log__c(Household__c=hartley.Id, Log_Type__c='Document Received', Description__c='Death certificate received.', Auto_Generated__c=true);

System.debug('✅ FA CRM Sample Data Created!');
System.debug('5 Households, 6 Accounts, 1 Liquidity Event, 1 Mortality Event, 3 Compliance Logs');
