const https = require('https');

class BlackRoadAPI {
  constructor(apiKey) {
    this.apiKey = apiKey;
    this.baseUrl = process.env.BLACKROAD_API_URL || 'https://api.blackroad.io/v1';
  }

  async request(method, endpoint, body = null) {
    const url = new URL(`${this.baseUrl}${endpoint}`);

    const options = {
      method,
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json',
        'User-Agent': 'blackroad-slack/1.0.0',
      },
    };

    return new Promise((resolve, reject) => {
      const req = https.request(url, options, (res) => {
        let data = '';
        res.on('data', (chunk) => data += chunk);
        res.on('end', () => {
          try {
            resolve(JSON.parse(data));
          } catch (e) {
            resolve(data);
          }
        });
      });

      req.on('error', reject);

      if (body) {
        req.write(JSON.stringify(body));
      }
      req.end();
    });
  }

  // Health
  async health() {
    return this.request('GET', '/health');
  }

  // Agents
  async listAgents(params = {}) {
    const query = new URLSearchParams(params).toString();
    const endpoint = query ? `/agents?${query}` : '/agents';
    const result = await this.request('GET', endpoint);
    return result.agents || [];
  }

  async getAgent(agentId) {
    return this.request('GET', `/agents/${agentId}`);
  }

  async agentStats() {
    return this.request('GET', '/agents/stats');
  }

  // Tasks
  async listTasks(params = {}) {
    const query = new URLSearchParams(params).toString();
    const endpoint = query ? `/tasks?${query}` : '/tasks';
    const result = await this.request('GET', endpoint);
    return result.tasks || [];
  }

  async getTask(taskId) {
    return this.request('GET', `/tasks/${taskId}`);
  }

  async dispatchTask(title, options = {}) {
    return this.request('POST', '/tasks', {
      title,
      priority: options.priority || 'medium',
      description: options.description,
      division: options.division,
    });
  }

  async completeTask(taskId, result) {
    return this.request('PUT', `/tasks/${taskId}`, {
      status: 'completed',
      result,
    });
  }

  async taskStats() {
    return this.request('GET', '/tasks/stats');
  }

  // Memory
  async queryMemory(params = {}) {
    const query = new URLSearchParams({ limit: 10, ...params }).toString();
    const result = await this.request('GET', `/memory?${query}`);
    return result.entries || [];
  }

  async logMemory(action, entity, details, tags = []) {
    return this.request('POST', '/memory', {
      action,
      entity,
      details,
      tags,
    });
  }

  async memoryStats() {
    return this.request('GET', '/memory/stats');
  }
}

module.exports = { BlackRoadAPI };
