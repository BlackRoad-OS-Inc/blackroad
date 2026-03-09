# Blackroad

Official Ruby SDK for the BlackRoad API.

## Installation

Add to your Gemfile:

```ruby
gem 'blackroad'
```

Then run:

```bash
bundle install
```

Or install directly:

```bash
gem install blackroad
```

## Quick Start

```ruby
require 'blackroad'

# Initialize the client
client = Blackroad::Client.new(api_key: 'your-api-key')
# Or set BLACKROAD_API_KEY environment variable

# List agents
agents = client.agents.list
puts "Found #{agents.length} agents"

# Dispatch a task
task = client.tasks.dispatch(
  title: 'Deploy authentication service',
  priority: 'high',
  division: 'Security'
)
puts "Created task: #{task['id']}"

# Log to memory
entry = client.memory.log(
  action: 'deployed',
  entity: 'auth-service',
  details: 'Deployed v2.0.0 to production',
  tags: ['deployment', 'security']
)
puts "Logged entry: #{entry['hash']}"
```

## Configuration

```ruby
client = Blackroad::Client.new(
  api_key: 'your-api-key',       # Required (or BLACKROAD_API_KEY env var)
  base_url: 'https://api.blackroad.io/v1', # Optional
  timeout: 30,                    # Optional, request timeout in seconds
  max_retries: 3                  # Optional, max retry attempts
)
```

## API Reference

### Agents

```ruby
# List all agents
agents = client.agents.list

# List with filters
agents = client.agents.list(type: 'ai', division: 'Security', level: 4)

# Get specific agent
agent = client.agents.get('agent-id')

# Register a new agent
agent = client.agents.register(
  name: 'my-agent',
  type: 'ai',
  division: 'Labs',
  level: 4,
  metadata: { capabilities: ['analysis', 'coding'] }
)

# Send heartbeat
client.agents.heartbeat('agent-id', load: 0.75)

# Update status
agent = client.agents.update_status('agent-id', 'busy')

# Delete agent
client.agents.delete('agent-id')

# Get statistics
stats = client.agents.stats

# Convenience methods
commanders = client.agents.commanders      # Level 2
managers = client.agents.managers          # Level 3
workers = client.agents.workers            # Level 4
security = client.agents.by_division('Security')
```

### Tasks

```ruby
# Dispatch a task
task = client.tasks.dispatch(
  title: 'Build authentication system',
  description: 'Implement OAuth2 + JWT authentication',
  priority: 'high',
  division: 'Security',
  target_level: 4,
  metadata: { estimated_hours: 8 }
)

# Get task by ID
task = client.tasks.get('task-id')

# List tasks with filters
tasks = client.tasks.list(status: 'pending', priority: 'high', division: 'AI')

# Complete a task
task = client.tasks.complete('task-id', result: 'Successfully deployed')

# Fail a task
task = client.tasks.fail('task-id', reason: 'Dependency unavailable')

# Assign to agent
task = client.tasks.assign('task-id', 'agent-id')

# Cancel task
client.tasks.cancel('task-id')

# Get statistics
stats = client.tasks.stats

# Convenience methods
pending = client.tasks.pending
in_progress = client.tasks.in_progress
urgent = client.tasks.urgent
ai_tasks = client.tasks.by_division('AI')
```

### Memory

```ruby
# Log an entry
entry = client.memory.log(
  action: 'deployed',
  entity: 'user-service',
  details: 'Deployed v2.1.0 with new auth flow',
  tags: ['deployment', 'auth'],
  metadata: { version: '2.1.0', environment: 'production' }
)

# Query entries
entries = client.memory.query(
  search: 'deployment',
  action: 'deployed',
  tags: ['production'],
  since: Time.now - 86400 * 30, # Last 30 days
  limit: 100
)

# Get entry by hash
entry = client.memory.get('entry-hash')

# Get recent entries
recent = client.memory.recent(50)

# Agent state management
state = client.memory.agent_state('agent-id')
client.memory.sync_state('agent-id', { last_task: 'task-123', load: 0.5 })

# Broadcast a message
response = client.memory.broadcast('alert', 'System maintenance at 3 PM')
puts "Broadcast ID: #{response['broadcast_id']}"

# Share a TIL
entry = client.memory.til('security', 'Always validate JWT signatures server-side')

# Get statistics
stats = client.memory.stats

# Verify hash chain
result = client.memory.verify_chain
puts "Valid: #{result['valid']}, Checked: #{result['checked']}"
```

### Health & Version

```ruby
# Check API health
health = client.health
puts health['status'] # => "healthy"

# Get API version
version = client.version
puts version # => "1.0.0"
```

## Error Handling

```ruby
begin
  agent = client.agents.get('nonexistent')
rescue Blackroad::NotFoundError => e
  puts "Agent not found: #{e.resource}"
rescue Blackroad::AuthenticationError
  puts "Invalid API key"
rescue Blackroad::RateLimitError => e
  puts "Rate limited. Retry after #{e.retry_after} seconds"
rescue Blackroad::ValidationError => e
  puts "Validation error: #{e.details}"
rescue Blackroad::ConnectionError => e
  puts "Connection error: #{e.message}"
rescue Blackroad::Error => e
  puts "API error: #{e.message}"
end
```

## Requirements

- Ruby 3.0 or higher
- Faraday 2.0+

## License

See [LICENSE](./LICENSE) for details.

## Links

- [Documentation](https://docs.blackroad.io/sdk/ruby)
- [API Reference](https://docs.blackroad.io/api)
- [GitHub](https://github.com/BlackRoad-OS/blackroad-sdk-ruby)
- [RubyGems](https://rubygems.org/gems/blackroad)
