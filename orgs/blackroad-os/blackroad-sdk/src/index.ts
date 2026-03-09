/**
 * BlackRoad SDK
 * Official TypeScript/JavaScript client for BlackRoad APIs
 */

// Types
export interface BlackRoadConfig {
  apiKey?: string;
  baseUrl?: string;
  graphqlUrl?: string;
  webhooksUrl?: string;
  emailUrl?: string;
}

export interface RequestOptions {
  headers?: Record<string, string>;
  signal?: AbortSignal;
}

export interface GraphQLResponse<T = unknown> {
  data?: T;
  errors?: { message: string }[];
}

export type AgentStatus = 'ONLINE' | 'OFFLINE' | 'BUSY' | 'ERROR';
export type AgentType = 'INFRASTRUCTURE' | 'CODE_REVIEW' | 'SECURITY' | 'ANALYTICS' | 'GENERAL';
export type DeploymentStatus = 'PENDING' | 'IN_PROGRESS' | 'SUCCESS' | 'FAILURE' | 'CANCELLED';
export type Environment = 'PRODUCTION' | 'STAGING' | 'DEVELOPMENT';
export type WebhookEventType = 'user.created' | 'deployment.succeeded' | 'deployment.failed' | 'agent.error' | string;
export type EmailTemplate = 'welcome' | 'passwordReset' | 'deploymentSuccess' | 'usageAlert' | string;

export interface Agent {
  id: string; name: string; type: AgentType; status: AgentStatus;
  tasksCompleted: number; uptimePercent: number; lastActiveAt?: string;
}

export interface Deployment {
  id: string; service: string; version: string; status: DeploymentStatus;
  environment: Environment; startedAt: string; completedAt?: string; url?: string;
}

export interface InfrastructureStats {
  githubOrgs: number; repositories: number; cloudflarePages: number;
  devices: number; totalAiTops: number; activeAgents: number;
}

export interface Webhook {
  id: string; url: string; events: string[]; secret?: string; active: boolean;
}

// Error class
export class BlackRoadError extends Error {
  constructor(message: string, public statusCode?: number) {
    super(message);
    this.name = 'BlackRoadError';
  }
}

// HTTP Client
class HttpClient {
  constructor(private baseUrl: string, private apiKey?: string) {}

  private headers(): Record<string, string> {
    const h: Record<string, string> = { 'Content-Type': 'application/json' };
    if (this.apiKey) { h['Authorization'] = `Bearer ${this.apiKey}`; h['X-API-Key'] = this.apiKey; }
    return h;
  }

  async get<T>(path: string): Promise<T> {
    const r = await fetch(`${this.baseUrl}${path}`, { headers: this.headers() });
    if (!r.ok) throw new BlackRoadError(`HTTP ${r.status}`, r.status);
    return r.json();
  }

  async post<T>(path: string, body: unknown): Promise<T> {
    const r = await fetch(`${this.baseUrl}${path}`, {
      method: 'POST', headers: this.headers(), body: JSON.stringify(body)
    });
    if (!r.ok) throw new BlackRoadError(`HTTP ${r.status}`, r.status);
    return r.json();
  }

  async delete<T>(path: string): Promise<T> {
    const r = await fetch(`${this.baseUrl}${path}`, { method: 'DELETE', headers: this.headers() });
    if (!r.ok) throw new BlackRoadError(`HTTP ${r.status}`, r.status);
    return r.json();
  }
}

// GraphQL Client
export class GraphQLClient {
  private http: HttpClient;
  constructor(url: string, apiKey?: string) { this.http = new HttpClient(url, apiKey); }

  async query<T>(query: string, variables?: Record<string, unknown>): Promise<T> {
    const res = await this.http.post<GraphQLResponse<T>>('', { query, variables });
    if (res.errors?.length) throw new BlackRoadError(res.errors.map(e => e.message).join(', '));
    return res.data as T;
  }

  async mutation<T>(mutation: string, variables?: Record<string, unknown>): Promise<T> {
    return this.query<T>(mutation, variables);
  }

  async getInfrastructureStats(): Promise<InfrastructureStats> {
    const r = await this.query<{ infrastructureStats: InfrastructureStats }>(
      "query { infrastructureStats { githubOrgs repositories cloudflarePages devices totalAiTops activeAgents } }"
    );
    return r.infrastructureStats;
  }

  async getAgents(opts?: { type?: AgentType; status?: AgentStatus; limit?: number }): Promise<Agent[]> {
    const r = await this.query<{ agents: Agent[] }>(
      "query($type: AgentType, $status: AgentStatus, $limit: Int) { agents(type: $type, status: $status, limit: $limit) { id name type status tasksCompleted uptimePercent } }",
      opts
    );
    return r.agents;
  }

  async getDeployments(opts?: { service?: string; status?: DeploymentStatus }): Promise<Deployment[]> {
    const r = await this.query<{ deployments: Deployment[] }>(
      "query($service: String, $status: DeploymentStatus) { deployments(service: $service, status: $status) { id service version status environment startedAt url } }",
      opts
    );
    return r.deployments;
  }

  async deploy(input: { service: string; environment: Environment; version?: string }): Promise<Deployment> {
    const r = await this.mutation<{ deploy: Deployment }>(
      "mutation($input: DeployInput!) { deploy(input: $input) { id service version status startedAt } }",
      { input }
    );
    return r.deploy;
  }
}

// Webhooks Client
export class WebhooksClient {
  private http: HttpClient;
  constructor(url: string, apiKey?: string) { this.http = new HttpClient(url, apiKey); }

  async list(): Promise<Webhook[]> {
    const r = await this.http.get<{ webhooks: Webhook[] }>('/webhooks');
    return r.webhooks;
  }

  async create(opts: { url: string; events: string[]; description?: string }): Promise<Webhook> {
    const r = await this.http.post<{ webhook: Webhook }>('/webhooks', opts);
    return r.webhook;
  }

  async get(id: string): Promise<Webhook> {
    const r = await this.http.get<{ webhook: Webhook }>("/webhooks/" + id);
    return r.webhook;
  }

  async delete(id: string): Promise<void> { await this.http.delete("/webhooks/" + id); }

  async test(id: string): Promise<unknown> {
    return this.http.post("/webhooks/" + id + "/test", {});
  }

  async trigger(event: { type: string; data: Record<string, unknown> }): Promise<void> {
    await this.http.post('/events', event);
  }

  async getEventTypes(): Promise<{ name: string; count: number; events: string[] }[]> {
    const r = await this.http.get<{ categories: { name: string; count: number; events: string[] }[] }>('/events/types');
    return r.categories;
  }
}

// Email Client
export class EmailClient {
  private http: HttpClient;
  private baseUrl: string;
  constructor(url: string, apiKey?: string) { this.http = new HttpClient(url, apiKey); this.baseUrl = url; }

  async send(req: { to: string | string[]; template: string; data: Record<string, unknown> }): Promise<{ success: boolean; emailId: string }> {
    return this.http.post('/send', req);
  }

  async getTemplates(): Promise<{ name: string; description: string; category: string }[]> {
    const r = await this.http.get<{ templates: { name: string; description: string; category: string }[] }>('/templates');
    return r.templates;
  }

  async previewTemplate(name: string): Promise<string> {
    const r = await fetch(this.baseUrl + "/templates/" + name + "/preview");
    return r.text();
  }

  async sendWelcome(to: string, data: { name: string }): Promise<{ success: boolean; emailId: string }> {
    return this.send({ to, template: 'welcome', data });
  }

  async sendDeploymentSuccess(to: string, data: { name: string; service: string; version: string }): Promise<{ success: boolean; emailId: string }> {
    return this.send({ to, template: 'deploymentSuccess', data });
  }
}

// Main Client
export class BlackRoad {
  public readonly graphql: GraphQLClient;
  public readonly webhooks: WebhooksClient;
  public readonly email: EmailClient;

  private static readonly GRAPHQL_URL = 'https://blackroad-graphql-gateway.amundsonalexa.workers.dev/graphql';
  private static readonly WEBHOOKS_URL = 'https://blackroad-webhooks.amundsonalexa.workers.dev';
  private static readonly EMAIL_URL = 'https://blackroad-email.amundsonalexa.workers.dev';

  constructor(config: BlackRoadConfig = {}) {
    this.graphql = new GraphQLClient(config.graphqlUrl || BlackRoad.GRAPHQL_URL, config.apiKey);
    this.webhooks = new WebhooksClient(config.webhooksUrl || BlackRoad.WEBHOOKS_URL, config.apiKey);
    this.email = new EmailClient(config.emailUrl || BlackRoad.EMAIL_URL, config.apiKey);
  }

  async getStats(): Promise<InfrastructureStats> { return this.graphql.getInfrastructureStats(); }
  async getAgents(): Promise<Agent[]> { return this.graphql.getAgents(); }
  async deploy(service: string, env: Environment = 'PRODUCTION'): Promise<Deployment> {
    return this.graphql.deploy({ service, environment: env });
  }
}

export default BlackRoad;
