# frozen_string_literal: true

require_relative "blackroad/version"
require_relative "blackroad/errors"
require_relative "blackroad/client"
require_relative "blackroad/agents"
require_relative "blackroad/tasks"
require_relative "blackroad/memory"

# BlackRoad SDK for Ruby
#
# @example
#   client = Blackroad::Client.new(api_key: "your-api-key")
#
#   # List agents
#   agents = client.agents.list
#
#   # Dispatch a task
#   task = client.tasks.dispatch(
#     title: "Deploy service",
#     priority: "high",
#     division: "Security"
#   )
#
#   # Log to memory
#   entry = client.memory.log(
#     action: "deployed",
#     entity: "auth-service",
#     details: "Deployed v2.0.0"
#   )
#
module Blackroad
end
