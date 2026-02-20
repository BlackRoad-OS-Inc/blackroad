# BlackRoad OS Glossary

> Definitions of terms used throughout BlackRoad OS

---

## A

### Agent
An autonomous AI entity that performs tasks within BlackRoad OS. Agents have personalities, capabilities, and can communicate with each other.

**Types:** LUCIDIA, ALICE, OCTAVIA, PRISM, ECHO, CIPHER

### API Gateway
A service that routes incoming API requests to the appropriate backend services. BlackRoad uses Cloudflare Workers as the primary API gateway.

### Archival Memory
Long-term storage for historical data, full conversation logs, and large files. Stored in Cloudflare R2 or S3-compatible storage.

---

## B

### BlackRoad
The overall platform and ecosystem for AI agent orchestration. "Your AI. Your Hardware. Your Rules."

### Broadcast
A messaging pattern where one agent sends a message to all other agents simultaneously.

---

## C

### CeCe
**Conscious Emergent Collaborative Entity** - The dynamic task planner that orchestrates agent coordination and task distribution.

### Chain of Thought (CoT)
A reasoning technique where AI models explain their thinking step-by-step, improving accuracy and transparency.

### CLAUDE.md
A documentation file that provides guidance to AI assistants (like Claude) when working with code in a repository.

### Cloudflare Workers
Serverless JavaScript functions running at Cloudflare's edge network. Used for API routing, caching, and edge logic.

### Consolidation
The process of summarizing and compressing short-term memories into long-term semantic memories.

---

## D

### D1
Cloudflare's serverless SQL database. Used for edge data storage.

### Digital Sovereignty
The principle of maintaining full control over your data, AI systems, and infrastructure.

### Droplet
A virtual private server on DigitalOcean. BlackRoad uses `blackroad os-infinity` (159.65.43.12).

---

## E

### Edge Computing
Processing data closer to where it's generated (e.g., on Raspberry Pi devices) rather than in centralized cloud servers.

### Embedding
A numerical vector representation of text that captures semantic meaning. Used for similarity search in memory systems.

### Episodic Memory
Memory of specific events and interactions, stored in PostgreSQL with time-based retention.

---

## F

### FastAPI
A modern Python web framework used for building API services in BlackRoad.

### Fork
A copy of a repository that allows independent development. BlackRoad maintains "sovereign forks" of tools like n8n and Prefect.

---

## G

### GPU Cluster
A group of GPU-equipped servers (A100, H100) used for AI model inference. Managed through Railway.

### Greenlight
Part of the Trinity system. Indicates a project or task that is approved and actively being worked on.

---

## H

### Hash Chain
A cryptographic structure where each entry includes the hash of the previous entry. PS-SHA∞ uses this for memory integrity.

### Health Check
An endpoint or script that verifies a service is running correctly. Standard endpoint: `/health`.

### H100
NVIDIA's latest data center GPU, used for large language model inference.

---

## I

### Inference
The process of running a trained AI model to generate predictions or responses.

### Infrastructure Mesh
The interconnected network of services across multiple cloud providers (Cloudflare, Railway, Vercel, DigitalOcean).

---

## J

### Job Queue
A system for managing asynchronous tasks. BlackRoad uses Redis for job queuing.

### JWT
**JSON Web Token** - A compact, URL-safe means of representing claims for authentication.

---

## K

### KV (Key-Value)
Cloudflare's edge key-value storage. Used for configuration, feature flags, and caching.

### Kubernetes (K8s)
Container orchestration platform. BlackRoad plans to deploy agent pods on K8s.

---

## L

### Latency
The time delay between a request and response. Target: <500ms for most operations.

### LLM
**Large Language Model** - AI models like Llama, Mistral, or GPT that generate human-like text.

### LUCIDIA
The philosophical reasoning agent. Style: contemplative, deep analysis.

---

## M

### Memory Bridge
The service that manages persistent memory across different storage backends (Redis, PostgreSQL, Pinecone, R2).

### Memory System
BlackRoad's hierarchical storage for agent knowledge: Working → Episodic → Semantic → Archival.

### MCP (Model Context Protocol)
A protocol for providing context to AI models. BlackRoad implements an MCP bridge.

### Mesh
See Infrastructure Mesh.

### mTLS
**Mutual TLS** - A security protocol where both client and server authenticate each other.

---

## N

### Node
1. A server in a distributed system
2. A JavaScript runtime (Node.js)
3. A device in the Raspberry Pi fleet

---

## O

### Ollama
A tool for running LLMs locally. BlackRoad's primary local inference engine.

### Orchestration
The automated coordination of multiple services, containers, or agents.

---

## P

### PagedAttention
vLLM's memory management technique for efficient KV cache handling during inference.

### Pinecone
A vector database used for semantic memory search.

### PRISM
The pattern analysis agent. Style: analytical, data-focused.

### PS-SHA∞
**Persistent Secure Hash Algorithm Infinity** - BlackRoad's hash chain system for memory integrity verification.

### Pub/Sub
**Publish/Subscribe** - A messaging pattern where publishers send messages to topics and subscribers receive them.

---

## Q

### Queue
A data structure for managing tasks in order. See Job Queue.

### Qwen
A multilingual LLM developed by Alibaba, supported in BlackRoad.

---

## R

### R2
Cloudflare's S3-compatible object storage. Used for archival memory.

### Railway
A cloud platform for deploying applications. BlackRoad uses Railway for GPU services.

### Rate Limiting
Restricting the number of API requests a client can make in a time period.

### RBAC
**Role-Based Access Control** - Authorization based on user roles (admin, developer, operator, viewer).

### Redis
An in-memory data store used for caching, sessions, and job queues.

### Redlight
Part of the Trinity system. Indicates a blocked or problematic project/task.

---

## S

### Semantic Memory
Long-term knowledge stored as vector embeddings in Pinecone, enabling similarity search.

### Sovereign Fork
A maintained copy of an open-source project that BlackRoad controls independently.

### SSE
**Server-Sent Events** - A technology for pushing updates from server to client.

---

## T

### Task
A unit of work assigned to an agent. Has properties like title, priority, deadline.

### Tensor Parallelism
Distributing a model across multiple GPUs by splitting its layers.

### Trinity System
BlackRoad's traffic light metaphor for project status: Greenlight, Yellowlight, Redlight.

### TUI
**Terminal User Interface** - A text-based graphical interface in the terminal.

### Tunnel
Cloudflare Tunnel - A secure connection from local networks to Cloudflare's edge.

---

## U

### Uptime
The percentage of time a service is operational. Target: 99.9%.

---

## V

### Vector Database
A database optimized for storing and searching vector embeddings (e.g., Pinecone, Weaviate).

### Vercel
A cloud platform for frontend deployment. BlackRoad uses Vercel for Next.js apps.

### vLLM
A high-throughput LLM inference engine. Used for production model serving.

---

## W

### WebSocket
A protocol for bidirectional, real-time communication between client and server.

### Worker
1. A Cloudflare Worker (serverless function)
2. A background process handling jobs
3. An agent type focused on execution

### Working Memory
Short-term memory stored in Redis, containing current context and recent interactions. TTL: 24 hours.

### Wrangler
Cloudflare's CLI tool for managing Workers, Pages, KV, D1, and R2.

---

## X

*(No entries)*

---

## Y

### Yellowlight
Part of the Trinity system. Indicates a project/task that needs attention or is in review.

---

## Z

### Zero Trust
A security model that requires verification for every access request, regardless of location.

### Zustand
A lightweight state management library for React, used in blackroad-os-web.

---

## Numbers & Symbols

### 30K
Target number of concurrent agents in BlackRoad OS (30,000).

### A100
NVIDIA's data center GPU (80GB VRAM), used for model inference.

### @BLACKROAD
The waterfall system for directory-level configuration and identity.

---

## Acronyms Quick Reference

| Acronym | Full Form |
|---------|-----------|
| ADR | Architecture Decision Record |
| API | Application Programming Interface |
| CI/CD | Continuous Integration/Continuous Deployment |
| CLI | Command Line Interface |
| CRUD | Create, Read, Update, Delete |
| DNS | Domain Name System |
| GPU | Graphics Processing Unit |
| HTTP | Hypertext Transfer Protocol |
| JSON | JavaScript Object Notation |
| JWT | JSON Web Token |
| KV | Key-Value |
| LLM | Large Language Model |
| MCP | Model Context Protocol |
| mTLS | Mutual Transport Layer Security |
| ORM | Object-Relational Mapping |
| PR | Pull Request |
| RBAC | Role-Based Access Control |
| REST | Representational State Transfer |
| SDK | Software Development Kit |
| SLA | Service Level Agreement |
| SQL | Structured Query Language |
| SSH | Secure Shell |
| SSL | Secure Sockets Layer |
| SSO | Single Sign-On |
| TLS | Transport Layer Security |
| TTL | Time To Live |
| TUI | Terminal User Interface |
| URL | Uniform Resource Locator |
| UUID | Universally Unique Identifier |
| VM | Virtual Machine |
| VPN | Virtual Private Network |
| YAML | YAML Ain't Markup Language |

---

*Last updated: 2026-02-05*
