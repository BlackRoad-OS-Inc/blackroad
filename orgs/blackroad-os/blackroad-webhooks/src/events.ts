/**
 * BlackRoad Webhook Event Types
 * 100+ event types across all products
 */

export const EVENT_CATEGORIES = {
  // User Events
  USER: [
    'user.created',
    'user.updated',
    'user.deleted',
    'user.login',
    'user.logout',
    'user.password_changed',
    'user.email_verified',
    'user.role_changed',
    'user.invited',
    'user.invitation_accepted',
  ],

  // Organization Events
  ORGANIZATION: [
    'organization.created',
    'organization.updated',
    'organization.deleted',
    'organization.member_added',
    'organization.member_removed',
    'organization.member_role_changed',
    'organization.billing_updated',
    'organization.plan_changed',
  ],

  // Deployment Events
  DEPLOYMENT: [
    'deployment.created',
    'deployment.started',
    'deployment.building',
    'deployment.deploying',
    'deployment.succeeded',
    'deployment.failed',
    'deployment.cancelled',
    'deployment.rolled_back',
    'deployment.promoted',
    'deployment.demoted',
  ],

  // Agent Events
  AGENT: [
    'agent.created',
    'agent.started',
    'agent.stopped',
    'agent.restarted',
    'agent.scaled',
    'agent.error',
    'agent.recovered',
    'agent.task_started',
    'agent.task_completed',
    'agent.task_failed',
    'agent.status_changed',
  ],

  // Repository Events
  REPOSITORY: [
    'repository.created',
    'repository.updated',
    'repository.deleted',
    'repository.archived',
    'repository.unarchived',
    'repository.transferred',
    'repository.visibility_changed',
  ],

  // Pull Request Events
  PULL_REQUEST: [
    'pull_request.opened',
    'pull_request.closed',
    'pull_request.merged',
    'pull_request.reopened',
    'pull_request.review_requested',
    'pull_request.review_submitted',
    'pull_request.approved',
    'pull_request.changes_requested',
    'pull_request.comment_added',
  ],

  // Issue Events
  ISSUE: [
    'issue.opened',
    'issue.closed',
    'issue.reopened',
    'issue.assigned',
    'issue.unassigned',
    'issue.labeled',
    'issue.unlabeled',
    'issue.comment_added',
  ],

  // Billing Events
  BILLING: [
    'billing.invoice_created',
    'billing.invoice_paid',
    'billing.invoice_failed',
    'billing.subscription_created',
    'billing.subscription_updated',
    'billing.subscription_cancelled',
    'billing.payment_method_added',
    'billing.payment_method_removed',
    'billing.usage_threshold_reached',
  ],

  // Security Events
  SECURITY: [
    'security.vulnerability_detected',
    'security.vulnerability_fixed',
    'security.secret_detected',
    'security.audit_log_created',
    'security.api_key_created',
    'security.api_key_revoked',
    'security.suspicious_activity',
    'security.breach_detected',
  ],

  // Infrastructure Events
  INFRASTRUCTURE: [
    'infrastructure.service_up',
    'infrastructure.service_down',
    'infrastructure.health_check_failed',
    'infrastructure.health_check_recovered',
    'infrastructure.scaling_started',
    'infrastructure.scaling_completed',
    'infrastructure.maintenance_scheduled',
    'infrastructure.maintenance_started',
    'infrastructure.maintenance_completed',
  ],

  // Device Events
  DEVICE: [
    'device.connected',
    'device.disconnected',
    'device.registered',
    'device.deregistered',
    'device.status_changed',
    'device.firmware_updated',
    'device.error',
  ],

  // API Events
  API: [
    'api.rate_limit_exceeded',
    'api.quota_exceeded',
    'api.error_spike',
    'api.latency_spike',
    'api.version_deprecated',
  ],

  // Notification Events
  NOTIFICATION: [
    'notification.sent',
    'notification.delivered',
    'notification.failed',
    'notification.opened',
    'notification.clicked',
  ],
} as const;

// Generate flat list of all events
export const ALL_EVENTS = Object.values(EVENT_CATEGORIES).flat();

// Event type
export type EventType = typeof ALL_EVENTS[number];

// Event payload interface
export interface WebhookEvent {
  id: string;
  type: EventType;
  created_at: string;
  data: Record<string, unknown>;
  organization_id?: string;
  user_id?: string;
  metadata?: Record<string, unknown>;
}

// Webhook subscription interface
export interface WebhookSubscription {
  id: string;
  url: string;
  events: EventType[];
  secret: string;
  active: boolean;
  created_at: string;
  updated_at: string;
  organization_id: string;
  description?: string;
  headers?: Record<string, string>;
  retry_policy?: {
    max_retries: number;
    retry_delay_seconds: number;
  };
}

// Webhook delivery interface
export interface WebhookDelivery {
  id: string;
  webhook_id: string;
  event_id: string;
  event_type: EventType;
  url: string;
  request_headers: Record<string, string>;
  request_body: string;
  response_status?: number;
  response_headers?: Record<string, string>;
  response_body?: string;
  delivered_at?: string;
  duration_ms?: number;
  attempt: number;
  max_attempts: number;
  status: 'pending' | 'success' | 'failed' | 'retrying';
  error?: string;
  created_at: string;
}

// Get event category
export function getEventCategory(eventType: EventType): string {
  for (const [category, events] of Object.entries(EVENT_CATEGORIES)) {
    if ((events as readonly string[]).includes(eventType)) {
      return category;
    }
  }
  return 'UNKNOWN';
}

// Validate event type
export function isValidEventType(type: string): type is EventType {
  return ALL_EVENTS.includes(type as EventType);
}
