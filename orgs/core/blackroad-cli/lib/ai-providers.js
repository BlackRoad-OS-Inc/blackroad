import axios from 'axios';
import { spawn } from 'child_process';

export class ClaudeProvider {
  constructor(apiKey = process.env.ANTHROPIC_API_KEY) {
    this.apiKey = apiKey;
    this.conversationHistory = [];
    this.model = 'claude-3-5-sonnet-20241022';
  }

  async chat(message) {
    if (!this.apiKey) {
      return '{red-fg}[Error: ANTHROPIC_API_KEY not set]{/red-fg}\n' +
        '{gray-fg}Set it with: export ANTHROPIC_API_KEY=your-key{/gray-fg}';
    }

    this.conversationHistory.push({
      role: 'user',
      content: message
    });

    try {
      const response = await axios.post(
        'https://api.anthropic.com/v1/messages',
        {
          model: this.model,
          max_tokens: 1024,
          messages: this.conversationHistory
        },
        {
          headers: {
            'x-api-key': this.apiKey,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json'
          }
        }
      );

      const assistantMessage = response.data.content[0].text;

      this.conversationHistory.push({
        role: 'assistant',
        content: assistantMessage
      });

      return `{cyan-fg}You:{/cyan-fg} ${message}\n\n` +
        `{green-fg}Claude:{/green-fg} ${assistantMessage}\n`;

    } catch (error) {
      return `{red-fg}[Error: ${error.message}]{/red-fg}\n`;
    }
  }

  clear() {
    this.conversationHistory = [];
    return '{yellow-fg}Conversation cleared!{/yellow-fg}\n';
  }
}

export class OllamaProvider {
  constructor() {
    this.currentModel = 'llama3.2';
    this.conversationHistory = [];
    this.baseUrl = 'http://localhost:11434';
  }

  async chat(message) {
    this.conversationHistory.push({
      role: 'user',
      content: message
    });

    try {
      const response = await axios.post(
        `${this.baseUrl}/api/chat`,
        {
          model: this.currentModel,
          messages: this.conversationHistory,
          stream: false
        }
      );

      const assistantMessage = response.data.message.content;

      this.conversationHistory.push({
        role: 'assistant',
        content: assistantMessage
      });

      return `{cyan-fg}You:{/cyan-fg} ${message}\n\n` +
        `{green-fg}${this.currentModel}:{/green-fg} ${assistantMessage}\n`;

    } catch (error) {
      if (error.code === 'ECONNREFUSED') {
        return '{red-fg}[Error: Ollama not running]{/red-fg}\n' +
          '{gray-fg}Start it with: ollama serve{/gray-fg}\n';
      }
      return `{red-fg}[Error: ${error.message}]{/red-fg}\n`;
    }
  }

  async switchModel(modelName) {
    try {
      // Test if model exists
      const response = await axios.post(
        `${this.baseUrl}/api/show`,
        { name: modelName }
      );

      this.currentModel = modelName;
      this.conversationHistory = [];

      return `{green-fg}Switched to ${modelName}!{/green-fg}\n` +
        '{gray-fg}Conversation history cleared.{/gray-fg}\n';

    } catch (error) {
      return `{red-fg}[Error: Model "${modelName}" not found]{/red-fg}\n` +
        '{gray-fg}Available models: llama3.2, codellama, mistral{/gray-fg}\n';
    }
  }

  async listModels() {
    try {
      const response = await axios.get(`${this.baseUrl}/api/tags`);
      const models = response.data.models || [];

      let output = '{cyan-fg}Available models:{/cyan-fg}\n';
      models.forEach(model => {
        const isCurrent = model.name === this.currentModel;
        output += isCurrent
          ? `  {green-fg}● ${model.name}{/green-fg} (current)\n`
          : `    ${model.name}\n`;
      });

      return output;

    } catch (error) {
      return `{red-fg}[Error: ${error.message}]{/red-fg}\n`;
    }
  }

  clear() {
    this.conversationHistory = [];
    return '{yellow-fg}Conversation cleared!{/yellow-fg}\n';
  }
}

export class InternetProvider {
  async fetch(url) {
    try {
      const response = await axios.get(url, {
        timeout: 10000,
        headers: {
          'User-Agent': 'BlackRoad-CLI/1.0'
        }
      });

      return `{green-fg}✓ Fetched ${url}{/green-fg}\n` +
        `{gray-fg}Status: ${response.status}{/gray-fg}\n` +
        `{gray-fg}Size: ${JSON.stringify(response.data).length} bytes{/gray-fg}\n\n` +
        `${JSON.stringify(response.data, null, 2).substring(0, 1000)}...\n`;

    } catch (error) {
      return `{red-fg}[Error fetching ${url}: ${error.message}]{/red-fg}\n`;
    }
  }

  async ping(host) {
    return new Promise((resolve) => {
      const proc = spawn('ping', ['-c', '4', host], {
        stdio: 'pipe'
      });

      let output = '';
      proc.stdout.on('data', (data) => output += data.toString());

      proc.on('close', (code) => {
        if (code === 0) {
          resolve(`{green-fg}✓ ${host} is reachable{/green-fg}\n${output}`);
        } else {
          resolve(`{red-fg}✗ ${host} is unreachable{/red-fg}\n`);
        }
      });

      proc.on('error', () => {
        resolve(`{red-fg}[Error: ping failed]{/red-fg}\n`);
      });
    });
  }

  async curl(url) {
    return new Promise((resolve) => {
      const proc = spawn('curl', ['-s', '-L', url], {
        stdio: 'pipe'
      });

      let output = '';
      proc.stdout.on('data', (data) => output += data.toString());

      proc.on('close', () => {
        resolve(output.substring(0, 2000) + '\n{gray-fg}... (truncated){/gray-fg}\n');
      });

      proc.on('error', () => {
        resolve(`{red-fg}[Error: curl failed]{/red-fg}\n`);
      });
    });
  }
}
