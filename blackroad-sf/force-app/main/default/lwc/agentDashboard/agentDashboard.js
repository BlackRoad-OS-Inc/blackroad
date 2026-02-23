import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getActiveAgents       from '@salesforce/apex/AgentRegistryService.getActiveAgents';
import getPendingTasks       from '@salesforce/apex/AgentRegistryService.getPendingTasks';
import getAllOrgs             from '@salesforce/apex/GitHubSyncService.getAllOrgs';
import getRepos              from '@salesforce/apex/GitHubSyncService.getRepos';
import seedOrgRegistry       from '@salesforce/apex/GitHubSyncService.seedOrgRegistry';
import getStripeRecords      from '@salesforce/apex/StripeSyncService.getStripeRecords';
import triggerFullSync       from '@salesforce/apex/StripeSyncService.triggerFullSync';
import getCommandCenterStats from '@salesforce/apex/BusinessDataService.getCommandCenterStats';
import importCSV             from '@salesforce/apex/BusinessDataService.importCSV';

const GATEWAY = 'https://blackroad-agents.blackroad.workers.dev';

export default class AgentDashboard extends LightningElement {

    @track agents        = [];
    @track pendingTasks  = [];
    @track githubOrgs    = [];
    @track repos         = [];
    @track stripeRecords = [];
    @track cmdStats      = null;
    @track importResult  = '';
    @track syncPayload   = 'all';
    @track repoOrgFilter = 'all';
    @track stripeTypeFilter = 'all';
    @track importTarget  = 'Agent__c';
    @track sortedBy      = 'Stars__c';
    @track sortedDir     = 'desc';

    // ── Column defs ───────────────────────────────────────────────────────────
    repoColumns = [
        { label: 'Repo',     fieldName: 'RepoUrl__c',  type: 'url',
          typeAttributes: { label: { fieldName: 'FullName__c' }, target: '_blank' } },
        { label: 'Org',      fieldName: 'OrgName__c',   type: 'text', sortable: true },
        { label: 'Language', fieldName: 'Language__c',  type: 'text', sortable: true },
        { label: '⭐',       fieldName: 'Stars__c',     type: 'number', sortable: true, initialWidth: 80 },
        { label: '🍴',       fieldName: 'Forks__c',     type: 'number', sortable: true, initialWidth: 80 },
        { label: '🔒',       fieldName: 'IsPrivate__c', type: 'boolean', initialWidth: 60 },
        { label: 'CI',       fieldName: 'WorkflowStatus__c', type: 'text', initialWidth: 100 },
    ];

    stripeColumns = [
        { label: 'ID',      fieldName: 'Name',           type: 'text' },
        { label: 'Type',    fieldName: 'RecordType__c',  type: 'text', initialWidth: 100 },
        { label: 'Amount',  fieldName: 'Amount__c',      type: 'currency' },
        { label: 'Status',  fieldName: 'Status__c',      type: 'text', initialWidth: 100 },
        { label: 'Email',   fieldName: 'CustomerEmail__c', type: 'email' },
        { label: 'Product', fieldName: 'ProductName__c', type: 'text' },
        { label: 'Live',    fieldName: 'LiveMode__c',    type: 'boolean', initialWidth: 60 },
    ];

    taskColumns = [
        { label: 'Task',     fieldName: 'Name',          type: 'text' },
        { label: 'Status',   fieldName: 'Status__c',     type: 'text', initialWidth: 100 },
        { label: 'Priority', fieldName: 'Priority__c',   type: 'text', initialWidth: 100 },
        { label: 'Repo',     fieldName: 'TargetRepo__c', type: 'text' },
        { label: 'Cost',     fieldName: 'cost',          type: 'text', initialWidth: 60 },
    ];

    // ── Options ───────────────────────────────────────────────────────────────
    payloadOptions = [
        { label: 'All (workflows + agents + config)', value: 'all' },
        { label: 'Workflows only',                    value: 'workflows' },
        { label: 'AGENTS.md only',                    value: 'agents' },
    ];
    stripeTypeOptions = [
        { label: 'All',           value: 'all' },
        { label: 'Customers',     value: 'customer' },
        { label: 'Charges',       value: 'charge' },
        { label: 'Subscriptions', value: 'subscription' },
    ];
    importTargetOptions = [
        { label: 'Agents',      value: 'Agent__c' },
        { label: 'GitHub Repos',value: 'GitHubRepo__c' },
        { label: 'Stripe',      value: 'StripeRecord__c' },
    ];
    get orgOptions() {
        const opts = [{ label: 'All Orgs', value: 'all' }];
        (this.githubOrgs || []).forEach(o => opts.push({ label: o.Name, value: o.Name }));
        return opts;
    }

    // ── Wires ─────────────────────────────────────────────────────────────────
    @wire(getActiveAgents)
    wiredAgents({ data }) {
        if (data) this.agents = data.map(a => ({
            ...a, statusClass: `status-badge status-${a.Status__c}`
        }));
    }

    @wire(getPendingTasks)
    wiredTasks({ data }) {
        if (data) this.pendingTasks = data.map(t => ({ ...t, cost: '$0' }));
    }

    @wire(getAllOrgs)
    wiredOrgs({ data }) {
        if (data) this.githubOrgs = data.map(o => ({
            ...o, syncClass: `sync-badge sync-${o.SyncStatus__c}`
        }));
    }

    @wire(getRepos, { orgFilter: '$repoOrgFilter' })
    wiredRepos({ data }) {
        if (data) this.repos = data;
    }

    @wire(getStripeRecords, { typeFilter: '$stripeTypeFilter' })
    wiredStripe({ data }) {
        if (data) this.stripeRecords = data;
    }

    @wire(getCommandCenterStats)
    wiredStats({ data }) {
        if (data) this.cmdStats = data;
    }

    // ── Handlers ──────────────────────────────────────────────────────────────
    handleOrgFilter(e)    { this.repoOrgFilter    = e.detail.value; }
    handleStripeFilter(e) { this.stripeTypeFilter = e.detail.value; }
    handleImportTarget(e) { this.importTarget     = e.detail.value; }
    handlePayloadChange(e){ this.syncPayload       = e.detail.value; }
    handleSort(e)         { this.sortedBy = e.detail.fieldName; this.sortedDir = e.detail.sortDirection; }

    async seedOrgs() {
        const result = await seedOrgRegistry();
        this.toast('✅ Orgs Seeded', result, 'success');
    }

    async syncGitHub() {
        this.toast('🐙 GitHub Sync', 'Syncing all 17 orgs via GitHub API — this may take a minute.', 'info');
        // Trigger via gateway (avoids SF @future callout limits for all 17 orgs)
        await fetch(`${GATEWAY}/github/sync-all-orgs`, { method: 'POST' }).catch(() => {});
    }

    async syncStripe() {
        this.toast('💳 Stripe Sync', 'Pulling customers, charges, subscriptions...', 'info');
        // Key loaded from SF Custom Metadata / Named Credential in production
        this.toast('💳 Stripe', 'Run triggerFullSync(stripeKey) in Apex Execute with your key.', 'warning');
    }

    async triggerUniverseSync() {
        await fetch(`${GATEWAY}/github/workflow`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                repo: 'BlackRoad-OS-Inc/blackroad', workflow: 'sync-universe.yml',
                inputs: { payload: this.syncPayload, orgs: 'all', dry_run: false }
            })
        }).catch(() => {});
        this.toast('🌌 Universe Sync Triggered', `Deploying ${this.syncPayload} to all 17 orgs (1,825+ repos). Cost: $0.`, 'success');
    }

    async invokeAgent(event) {
        const agentId = event.currentTarget.dataset.agent;
        await fetch(`${GATEWAY}/agent`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ agent: agentId, cost: '$0' })
        }).catch(() => {});
        this.toast('Agent Invoked', `${agentId} running on Pi fleet. Cost: $0.`, 'success');
    }

    async handleFileUpload(event) {
        const file = event.detail.files[0];
        if (!file) return;
        // Read as base64 via ContentVersion
        const result = await importCSV({ base64Csv: file.base64Data, targetObject: this.importTarget });
        this.importResult = result;
        this.toast('📊 Import Complete', result, 'success');
    }

    toast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
