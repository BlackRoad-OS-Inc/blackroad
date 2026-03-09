import { makeExecutableSchema } from '@graphql-tools/schema';

const typeDefs = `
  type Query {
    user(id: ID!): User
    product(id: ID!): Product
    agent(id: ID!): Agent
    products: [Product!]!
    agents: [Agent!]!
  }

  type Subscription {
    agentStatus(agentId: ID!): AgentStatus!
    deploymentUpdates: DeploymentUpdate!
  }

  type User {
    id: ID!
    name: String!
    email: String!
    products: [Product!]!
    agents: [Agent!]!
  }

  type Product {
    id: ID!
    name: String!
    description: String
    status: ProductStatus!
    deployments: [Deployment!]!
  }

  type Agent {
    id: ID!
    type: AgentType!
    name: String!
    health: HealthStatus!
    tasks: [Task!]!
  }

  enum ProductStatus { ACTIVE INACTIVE MAINTENANCE }
  enum AgentType { AI HARDWARE HYBRID }
  enum HealthStatus { HEALTHY DEGRADED DOWN }

  type Deployment { id: ID! environment: String! status: String! }
  type Task { id: ID! name: String! status: String! }
  type AgentStatus { agentId: ID! health: HealthStatus! timestamp: String! }
  type DeploymentUpdate { deploymentId: ID! status: String! progress: Int! }
`;

export const schema = makeExecutableSchema({ typeDefs });
