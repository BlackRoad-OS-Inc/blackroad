import { LightningElement, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getConnectedCRMs from '@salesforce/apex/BlackRoadHubController.getConnectedCRMs';
import getCRMProducts from '@salesforce/apex/BlackRoadHubController.getCRMProducts';
import getHubStats from '@salesforce/apex/BlackRoadHubController.getHubStats';
import getHouseholdsNeedingAttention from '@salesforce/apex/BlackRoadHubController.getHouseholdsNeedingAttention';
import getRecentComplianceLogs from '@salesforce/apex/BlackRoadHubController.getRecentComplianceLogs';
import syncCRM from '@salesforce/apex/BlackRoadHubController.syncCRM';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class BlackroadHubDashboard extends NavigationMixin(LightningElement) {
    @track stats = {};
    @track connectedCRMs = [];
    @track crmProducts = [];
    @track householdsNeedingAttention = [];
    @track complianceLogs = [];

    crmColumns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'CRM_Type__c', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        { label: 'Vertical', fieldName: 'Vertical__c', type: 'text' },
        { label: 'Records', fieldName: 'Record_Count__c', type: 'number' },
        {
            type: 'action',
            typeAttributes: { rowActions: [
                { label: 'Sync', name: 'sync' },
                { label: 'View', name: 'view' }
            ]}
        }
    ];

    householdColumns = [
        { label: 'Household', fieldName: 'Name', type: 'text' },
        { label: 'AUM', fieldName: 'Total_AUM__c', type: 'currency' },
        { label: 'Status', fieldName: 'Household_Status__c', type: 'text' },
        { label: 'Next Review', fieldName: 'Next_Review_Date__c', type: 'date' },
        {
            type: 'action',
            typeAttributes: { rowActions: [
                { label: 'View', name: 'view' },
                { label: 'Schedule Review', name: 'schedule' }
            ]}
        }
    ];

    logColumns = [
        { label: 'Log #', fieldName: 'Name', type: 'text' },
        { label: 'Type', fieldName: 'Log_Type__c', type: 'text' },
        { label: 'Description', fieldName: 'Description__c', type: 'text' },
        { label: 'Date', fieldName: 'CreatedDate', type: 'date' }
    ];

    @wire(getHubStats)
    wiredStats({ error, data }) {
        if (data) {
            this.stats = data;
        } else if (error) {
            console.error('Error loading stats:', error);
        }
    }

    @wire(getConnectedCRMs)
    wiredCRMs({ error, data }) {
        if (data) {
            this.connectedCRMs = data;
        } else if (error) {
            console.error('Error loading CRMs:', error);
        }
    }

    @wire(getCRMProducts)
    wiredProducts({ error, data }) {
        if (data) {
            this.crmProducts = data;
        } else if (error) {
            console.error('Error loading products:', error);
        }
    }

    @wire(getHouseholdsNeedingAttention)
    wiredHouseholds({ error, data }) {
        if (data) {
            this.householdsNeedingAttention = data;
        } else if (error) {
            console.error('Error loading households:', error);
        }
    }

    @wire(getRecentComplianceLogs, { recordLimit: 10 })
    wiredLogs({ error, data }) {
        if (data) {
            this.complianceLogs = data;
        } else if (error) {
            console.error('Error loading logs:', error);
        }
    }

    get formattedAUM() {
        if (!this.stats.totalAUM) return '$0';
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(this.stats.totalAUM);
    }

    get totalPending() {
        return (this.stats.pendingDistributions || 0) + 
               (this.stats.activeMortalityEvents || 0) + 
               (this.stats.activeLiquidityEvents || 0);
    }

    handleAddCRM() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Connected_CRM__c',
                actionName: 'new'
            }
        });
    }

    handleCRMAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'sync') {
            this.syncCRMInstance(row.Id);
        } else if (action.name === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Connected_CRM__c',
                    actionName: 'view'
                }
            });
        }
    }

    handleHouseholdAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        if (action.name === 'view') {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: row.Id,
                    objectApiName: 'Client_Household__c',
                    actionName: 'view'
                }
            });
        }
    }

    async syncCRMInstance(crmId) {
        try {
            const result = await syncCRM({ crmId: crmId });
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: result,
                    variant: 'success'
                })
            );
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                })
            );
        }
    }
}
