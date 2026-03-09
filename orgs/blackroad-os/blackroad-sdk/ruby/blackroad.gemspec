# frozen_string_literal: true

require_relative "lib/blackroad/version"

Gem::Specification.new do |spec|
  spec.name = "blackroad"
  spec.version = Blackroad::VERSION
  spec.authors = ["BlackRoad OS, Inc."]
  spec.email = ["sdk@blackroad.io"]

  spec.summary = "Official Ruby SDK for the BlackRoad API"
  spec.description = "Ruby client library for interacting with the BlackRoad API. Manage agents, tasks, and memory for your AI infrastructure."
  spec.homepage = "https://docs.blackroad.io/sdk/ruby"
  spec.license = "SEE LICENSE IN LICENSE"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/BlackRoad-OS/blackroad-sdk-ruby"
  spec.metadata["changelog_uri"] = "https://github.com/BlackRoad-OS/blackroad-sdk-ruby/blob/main/CHANGELOG.md"
  spec.metadata["documentation_uri"] = "https://docs.blackroad.io/sdk/ruby"

  spec.files = Dir.glob("lib/**/*") + ["README.md", "LICENSE"]
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday", "~> 2.0"
  spec.add_dependency "faraday-retry", "~> 2.0"

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop", "~> 1.0"
end
