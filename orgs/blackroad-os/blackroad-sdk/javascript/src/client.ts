/**
 * BlackRoad API Client
 */

import { AgentAPI } from './agents';
import { TaskAPI } from './tasks';
import { MemoryAPI } from './memory';
import { ClientConfig, HealthStatus } from './types';
import {
  BlackRoadError,
  AuthenticationError,
  RateLimitError,
  NotFoundError,
  ValidationError,
  ConnectionError,
} from './errors';

const DEFAULT_BASE_URL = 'https://api.blackroad.io/v1';
const DEFAULT_TIMEOUT = 30000;
const DEFAULT_MAX_RETRIES = 3;

export class BlackRoadClient {
  private apiKey: string;
  private baseUrl: string;
  private timeout: number;
  private maxRetries: number;

  public agents: AgentAPI;
  public tasks: TaskAPI;
  public memory: MemoryAPI;

  /**
   * Initialize the BlackRoad client.
   *
   * @example
   * ```typescript
   * const client = new BlackRoadClient({ apiKey: 'your-api-key' });
   *
   * // List agents
   * const agents = await client.agents.list();
   *
   * // Dispatch a task
   * const task = await client.tasks.dispatch({
   *   title: 'Deploy service',
   *   priority: 'high',
   *   division: 'Security'
   * });
   * ```
   */
  constructor(config: ClientConfig = {}) {
    this.apiKey = config.apiKey || process.env.BLACKROAD_API_KEY || '';

    if (!this.apiKey) {
      throw new AuthenticationError(
        'API key required. Set BLACKROAD_API_KEY environment variable or pass apiKey in config.'
      );
    }

    this.baseUrl = (config.baseUrl || process.env.BLACKROAD_API_URL || DEFAULT_BASE_URL).replace(/\/$/, '');
    this.timeout = config.timeout || DEFAULT_TIMEOUT;
    this.maxRetries = config.maxRetries || DEFAULT_MAX_RETRIES;

    // Initialize API modules
    this.agents = new AgentAPI(this);
    this.tasks = new TaskAPI(this);
    this.memory = new MemoryAPI(this);
  }

  /**
   * Make an API request.
   */
  async request<T>(
    method: string,
    endpoint: string,
    options: { data?: Record<string, unknown>; params?: Record<string, unknown> } = {}
  ): Promise<T> {
    let url = `${this.baseUrl}/${endpoint.replace(/^\//, '')}`;

    if (options.params) {
      const searchParams = new URLSearchParams();
      for (const [key, value] of Object.entries(options.params)) {
        if (value !== undefined && value !== null) {
          searchParams.append(key, String(value));
        }
      }
      const queryString = searchParams.toString();
      if (queryString) {
        url += `?${queryString}`;
      }
    }

    const headers: Record<string, string> = {
      'Authorization': `Bearer ${this.apiKey}`,
      'Content-Type': 'application/json',
      'User-Agent': 'blackroad-js/1.0.0',
    };

    for (let attempt = 0; attempt < this.maxRetries; attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(() => controller.abort(), this.timeout);

        const response = await fetch(url, {
          method,
          headers,
          body: options.data ? JSON.stringify(options.data) : undefined,
          signal: controller.signal,
        });

        clearTimeout(timeoutId);

        if (!response.ok) {
          const errorBody = await response.text();

          switch (response.status) {
            case 401:
              throw new AuthenticationError('Invalid API key');
            case 404:
              throw new NotFoundError(`Resource not found: ${endpoint}`);
            case 422:
              throw new ValidationError(`Validation error: ${errorBody}`);
            case 429:
              const retryAfter = parseInt(response.headers.get('Retry-After') || '1', 10);
              if (attempt < this.maxRetries - 1) {
                await this.sleep(retryAfter * 1000);
                continue;
              }
              throw new RateLimitError('Rate limit exceeded', retryAfter);
            default:
              throw new BlackRoadError(`API error (${response.status}): ${errorBody}`, 'API_ERROR', response.status);
          }
        }

        return await response.json();
      } catch (error) {
        if (error instanceof BlackRoadError) {
          throw error;
        }

        if (error instanceof Error && error.name === 'AbortError') {
          if (attempt < this.maxRetries - 1) {
            await this.sleep(Math.pow(2, attempt) * 1000);
            continue;
          }
          throw new ConnectionError('Request timed out');
        }

        if (attempt < this.maxRetries - 1) {
          await this.sleep(Math.pow(2, attempt) * 1000);
          continue;
        }

        throw new ConnectionError(`Connection failed: ${error instanceof Error ? error.message : 'Unknown error'}`);
      }
    }

    throw new BlackRoadError('Max retries exceeded');
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  /**
   * Make a GET request.
   */
  async get<T>(endpoint: string, params?: Record<string, unknown>): Promise<T> {
    return this.request<T>('GET', endpoint, { params });
  }

  /**
   * Make a POST request.
   */
  async post<T>(endpoint: string, data?: Record<string, unknown>): Promise<T> {
    return this.request<T>('POST', endpoint, { data });
  }

  /**
   * Make a PUT request.
   */
  async put<T>(endpoint: string, data?: Record<string, unknown>): Promise<T> {
    return this.request<T>('PUT', endpoint, { data });
  }

  /**
   * Make a DELETE request.
   */
  async delete<T>(endpoint: string): Promise<T> {
    return this.request<T>('DELETE', endpoint);
  }

  /**
   * Check API health status.
   */
  async health(): Promise<HealthStatus> {
    return this.get<HealthStatus>('/health');
  }

  /**
   * Get API version.
   */
  async version(): Promise<string> {
    const response = await this.get<{ version: string }>('/version');
    return response.version;
  }
}
