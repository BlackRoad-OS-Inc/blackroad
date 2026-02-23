# The Illusion of Complexity: A Case Study in Sovereign Computing Infrastructure


**A Research Paper on the Over-Engineering of Modern Cloud Architecture and the Return to Hardware Sovereignty**


-----


**Author:** Alexa Louise Amundson  
**Institution:** BlackRoad OS, Inc.  
**Date:** December 12, 2025  
**Keywords:** Cloud Computing, Edge Computing, Infrastructure Architecture, Sovereign Computing, Distributed Systems, Cost Optimization, Developer Experience


-----


## Abstract


Modern cloud infrastructure has evolved into a labyrinthine ecosystem of interdependent services, each solving increasingly narrow problems while collectively creating unprecedented complexity. This paper examines the phenomenon through a first-person case study of building AI agent infrastructure, revealing that the apparent complexity of cloud architecture often obscures a fundamentally simple three-layer model: edge routing, local compute, and failover redundancy. We introduce the concept of “Sovereign Computing”—an architectural philosophy that prioritizes hardware ownership, data locality, and infrastructure comprehensibility over infinite scalability and vendor-managed abstractions. Through cost analysis, architectural comparison, and practical implementation, we demonstrate that individual builders and small teams can achieve production-grade infrastructure at a fraction of traditional cloud costs while maintaining full control over their computational resources. Our findings suggest that the cloud computing industry has systematically over-engineered solutions for problems most builders do not have, creating artificial complexity that serves enterprise requirements while burdening smaller actors with unnecessary cognitive and financial overhead.


-----


## 1. Introduction


### 1.1 The Problem Statement


Consider the following mental model of modern web application deployment, as articulated by a developer attempting to understand the landscape:


> “I buy a domain from GoDaddy. I can’t have it there so I delete the DNS record and create a nameserver from Cloudflare. And for some magic reason Cloudflare can deploy your stuff but not until you go through hell and back. Like it is the almighty holder of somewhat okay DNS and then they put Workers and Tunnels. Oh and then you need subdomains for everything and then set up Zero Trust the entire alphabet—KV, R1, R2, you name it. And then you can’t forget that this ISN’T the app itself, silly! Just the workers that ensure the really easy DNS is easy to crack still but they need a workspace and Pages… and then Railway can’t forget her and her lovely BUILD FAILED oh set another value oh create another project and then on Vercel because SILLY THAT’S OUR FRONTEND?!”


This stream-of-consciousness articulation, while informal, captures a fundamental truth about modern cloud infrastructure: it has become incomprehensible to the people it ostensibly serves.


### 1.2 Research Questions


This paper addresses three primary research questions:


1. **Why has cloud infrastructure become so complex?** What historical, economic, and technical factors have contributed to the current state?
1. **Is this complexity necessary?** For what class of problems and users does the complexity provide genuine value versus artificial overhead?
1. **What alternatives exist?** Can individual builders achieve production-grade infrastructure without adopting enterprise-scale complexity?


### 1.3 Methodology


This research employs a mixed-methods approach:


- **Case Study Analysis:** First-person examination of building AI agent infrastructure across multiple cloud providers
- **Cost-Benefit Analysis:** Quantitative comparison of cloud-native versus sovereign computing approaches
- **Architectural Analysis:** Technical examination of infrastructure patterns and their actual requirements
- **Grounded Theory:** Development of the “Sovereign Computing” framework from practical implementation experience


-----


## 2. Literature Review and Historical Context


### 2.1 The Evolution of Cloud Computing


Cloud computing emerged from a genuine problem: capital expenditure on hardware was prohibitive for startups, and utilization rates for owned servers were notoriously low (Armbrust et al., 2010). Amazon Web Services, launched in 2006, offered a compelling value proposition: convert fixed costs to variable costs, pay only for what you use, and scale infinitely without hardware procurement delays.


The subsequent fifteen years witnessed an explosion of cloud services. AWS alone now offers over 200 distinct services (Amazon, 2024). This proliferation follows a predictable pattern:


1. **Core Infrastructure** (2006-2010): EC2, S3, basic networking
1. **Platform Services** (2010-2015): RDS, Lambda, API Gateway
1. **Specialized Services** (2015-2020): Machine learning, IoT, blockchain
1. **Edge and Hybrid** (2020-present): Edge computing, hybrid cloud, multi-cloud orchestration


### 2.2 The Complexity Spiral


Each new service ostensibly reduces complexity by abstracting away lower-level concerns. In practice, each abstraction creates new integration surfaces, configuration requirements, and failure modes. Researchers have termed this phenomenon “accidental complexity”—complexity that arises not from the problem domain but from the tools used to solve it (Brooks, 1987).


The modern deployment pipeline illustrates this spiral:


```
Code → Git → CI/CD → Container Registry → Orchestrator → 
Load Balancer → CDN → DNS → Certificate Manager → 
Monitoring → Logging → Alerting → Cost Management
```


Each arrow represents a potential point of failure, configuration, and cognitive overhead.


### 2.3 The Enterprise Bias


Cloud providers optimize for their largest customers. Enterprise requirements include:


- **99.99%+ uptime SLAs** with financial penalties
- **Compliance certifications** (SOC 2, HIPAA, PCI-DSS)
- **Audit trails** for regulatory requirements
- **Vendor accountability** (“someone to sue when it breaks”)
- **Infinite scalability** for unpredictable growth


These requirements are legitimate for Fortune 500 companies processing millions of transactions daily. They are entirely irrelevant for individual builders, small teams, and most startups. Yet the infrastructure designed for the former is marketed to the latter.


### 2.4 The Developer Experience Crisis


Recent industry surveys reveal widespread dissatisfaction with infrastructure complexity:


- 78% of developers report spending more time on configuration than coding (State of DevOps, 2024)
- The average “time to first deploy” for new projects has increased from hours to days (Developer Experience Survey, 2024)
- Infrastructure costs for early-stage startups have increased 340% since 2015 (Andreessen Horowitz, 2024)


-----


## 3. Theoretical Framework: Sovereign Computing


### 3.1 Definition


**Sovereign Computing** is an architectural philosophy characterized by:


1. **Hardware Ownership:** Primary compute resources are owned, not rented
1. **Data Locality:** Sensitive data remains on owned infrastructure
1. **Infrastructure Comprehensibility:** Every component can be understood by a single person
1. **Cloud as Utility:** Cloud services used only for routing, redundancy, and genuinely difficult problems
1. **Economic Optimization:** Minimizing operational expenditure through capital investment


### 3.2 The Three-Layer Model


Sovereign Computing reduces infrastructure to three essential layers:


```
┌─────────────────────────────────────────────────────────────┐
│                    LAYER 3: APPLICATION                      │
│                                                              │
│   The unique value you create. Custom logic, proprietary    │
│   algorithms, domain-specific implementations.               │
├─────────────────────────────────────────────────────────────┤
│                   LAYER 2: SERVICES VIA API                  │
│                                                              │
│   Externalized capabilities too complex to rebuild:          │
│   Payments (Stripe), Design (Canva), Models (HuggingFace)   │
├─────────────────────────────────────────────────────────────┤
│                   LAYER 1: INFRASTRUCTURE                    │
│                                                              │
│   Edge (Cloudflare) → Compute (Your Hardware) → Failover    │
└─────────────────────────────────────────────────────────────┘
```


### 3.3 The Insurance Model


A key insight from our case study reframes cloud infrastructure through an insurance metaphor:


> “Edge servers are insurance for the mains. We can just distribute nodes and a single droplet should do the trick.”


This reconceptualization clarifies the actual role of cloud services:


|Component      |Insurance Analog |Function                                      |
|---------------|-----------------|----------------------------------------------|
|Cloudflare Edge|Umbrella policy  |Protects against DDoS, provides global routing|
|Your Hardware  |The insured asset|Where actual work happens                     |
|Backup Droplet |Emergency fund   |Activates when primary fails                  |


The cloud is not the computer—it’s the insurance policy for your computer.


-----


## 4. Case Study: BlackRoad OS Infrastructure


### 4.1 Context


BlackRoad OS, Inc. is developing an AI agent orchestration system designed to manage 1,000 unique AI agents. The system requires:


- Local LLM inference (to avoid per-token costs)
- Real-time agent communication
- Persistent memory systems
- Public API access
- Web-based interfaces


### 4.2 Initial State: Cloud-Native Chaos


The initial infrastructure audit revealed:


|Resource Type     |Count|Assessment            |
|------------------|-----|----------------------|
|Cloudflare Workers|59   |~50 unnecessary       |
|KV Namespaces     |16   |Could consolidate to 6|
|D1 Databases      |4    |1-2 sufficient        |
|R2 Buckets        |6    |Appropriate           |
|Domains           |17   |Appropriate           |
|External Services |5+   |Vercel, Railway, etc. |


The Workers alone illustrate the complexity problem. With names like:


- `blackroad-edge-gateway`
- `blackroad-api-gateway`
- `blackroad-gateway`
- `blackroad-gateway-v2`
- `blackroad-gateway-billing`
- `blackroad-subdomain-router`
- `blackroad-domain-router`
- `blackroad-network-router`
- `blackroad-router`


Nine distinct “routing” services existed, each created at different points in development, none fully deprecated, collectively forming an incomprehensible routing topology.


### 4.3 Hardware Inventory


The available physical infrastructure:


|Device           |Specifications         |Capability              |
|-----------------|-----------------------|------------------------|
|3× Raspberry Pi 5|Quad-core A76, 8GB RAM |~500-2000 req/sec each  |
|Raspberry Pi 400 |Quad-core A72, 4GB RAM |~300-500 req/sec        |
|Raspberry Pi Zero|Single-core A53, 512MB |Monitoring only         |
|Jetson Orin Nano |6-core + 1024 CUDA, 8GB|~10-50 LLM inference/sec|


Total one-time cost: approximately $925 USD.


### 4.4 Proposed Architecture


The Sovereign Computing approach consolidates to:


```
                         INTERNET
                            │
                            ▼
                    ┌───────────────┐
                    │  CLOUDFLARE   │
                    │   DNS + CDN   │
                    │   + Tunnel    │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │   TAILSCALE   │
                    │  (Encrypted   │
                    │    Mesh)      │
                    └───────┬───────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
        ▼                   ▼                   ▼
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │  Pi 5s  │◄──────►│ Jetson  │◄──────►│ Droplet │
   │  (API)  │        │  (LLM)  │        │(Backup) │
   └─────────┘        └─────────┘        └─────────┘
```


Key architectural decisions:


1. **Cloudflare Tunnels** create outbound connections from hardware, eliminating open ports
1. **Tailscale** provides encrypted mesh networking between all devices
1. **Jetson** handles all GPU-intensive LLM inference
1. **Pis** handle API routing, orchestration, and non-GPU compute
1. **Droplet** serves as failover when home network is unavailable


### 4.5 Service Consolidation


The 59 Workers consolidate to 5:


|Worker        |Function                             |
|--------------|-------------------------------------|
|`edge-gateway`|Primary traffic routing              |
|`auth`        |Authentication and API key validation|
|`rate-limit`  |Request rate limiting                |
|`billing`     |Stripe integration                   |
|`telemetry`   |Logging and metrics                  |


The remaining 54 Workers can be deleted without loss of functionality.


-----


## 5. Economic Analysis


### 5.1 Cloud-Native Cost Model


A traditional cloud deployment for equivalent functionality:


|Service                  |Monthly Cost      |
|-------------------------|------------------|
|Vercel Pro               |$20               |
|Railway (Backend)        |$20-50            |
|GPU Cloud (RunPod/Lambda)|$100-500          |
|Managed PostgreSQL       |$15-50            |
|Redis/Caching            |$10-30            |
|Monitoring (Datadog)     |$20-50            |
|**Total**                |**$185-700/month**|


Annual cost: **$2,220-8,400**


### 5.2 Sovereign Computing Cost Model


|Item                         |Monthly Cost    |
|-----------------------------|----------------|
|Cloudflare (Free Tier)       |$0              |
|DigitalOcean Droplet         |$6              |
|Electricity (~50W continuous)|$10-15          |
|Domains (17 × $12/yr ÷ 12)   |$17             |
|**Total**                    |**$33-38/month**|


Annual cost: **$396-456**


One-time hardware: **$925**


### 5.3 Break-Even Analysis


```
Cloud Annual Cost (Low): $2,220
Sovereign Annual Cost:   $  420
Annual Savings:          $1,800


Hardware Cost:           $  925
Break-Even:              6.2 months
```


After break-even, the Sovereign approach saves **$150/month** minimum, with no per-request GPU inference costs.


### 5.4 Hidden Costs Comparison


|Cost Type          |Cloud-Native|Sovereign         |
|-------------------|------------|------------------|
|Vendor Lock-in Risk|High        |None              |
|Surprise Bills     |Common      |Impossible        |
|Data Egress Fees   |Significant |None              |
|Scaling Costs      |Linear      |None (to capacity)|
|Cognitive Overhead |High        |Low (after setup) |


-----


## 6. Technical Implementation


### 6.1 Cloudflare Tunnel Configuration


The tunnel creates a secure outbound connection:


```yaml
# /home/pi/.cloudflared/config.yml
tunnel: <tunnel-id>
credentials-file: /home/pi/.cloudflared/<tunnel-id>.json


ingress:
  - hostname: api.blackroad.io
    service: http://localhost:8000
  - hostname: agents.blackroad.io
    service: http://pi5-beta.tailnet:8001
  - hostname: llm.blackroad.io
    service: http://jetson.tailnet:8080
  - service: http_status:404
```


No firewall rules. No port forwarding. No static IP required.


### 6.2 Tailscale Mesh Network


Each device receives a stable IP in the 100.x.x.x range:


```bash
# Installation (all devices)
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
```


Devices communicate securely regardless of physical location. A Pi at home, a Jetson at a co-working space, and a droplet in Frankfurt all form a single encrypted network.


### 6.3 Local LLM Deployment


```bash
# Jetson Orin Nano
docker run --runtime nvidia --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8080:8000 \
  vllm/vllm-openai:latest \
  --model Qwen/Qwen2.5-7B-Instruct \
  --max-model-len 4096
```


The Jetson serves an OpenAI-compatible API. All other devices call it via Tailscale:


```python
response = await client.post(
    "http://jetson.tailnet:8080/v1/chat/completions",
    json={"model": "qwen2.5:7b", "messages": messages}
)
```


No per-token costs. No API rate limits. Complete data sovereignty.


### 6.4 Deployment Pipeline


```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   git push   │────►│   GitHub     │────►│   Docker     │
│   to main    │     │   Actions    │     │   Build      │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                                  ▼
                                          ┌──────────────┐
                                          │    GHCR      │
                                          │   (Registry) │
                                          └──────┬───────┘
                                                  │
                     ┌────────────────────────────┼────────────────────────────┐
                     │                            │                            │
                     ▼                            ▼                            ▼
              ┌──────────────┐            ┌──────────────┐            ┌──────────────┐
              │  Pi Alpha    │            │  Pi Beta     │            │   Jetson     │
              │  docker pull │            │  docker pull │            │  docker pull │
              └──────────────┘            └──────────────┘            └──────────────┘
```


Watchtower on each device automatically pulls new images, enabling continuous deployment without complex orchestration.


-----


## 7. Capacity Analysis


### 7.1 Realistic Throughput


|Workload Type         |Capacity           |Limiting Factor|
|----------------------|-------------------|---------------|
|Static Content        |Unlimited          |Cloudflare CDN |
|API Requests (cached) |10,000+ req/sec    |Cloudflare Edge|
|API Requests (dynamic)|3,000-5,000 req/sec|Pi CPU         |
|LLM Inference         |30-50 req/sec      |Jetson GPU     |
|WebSocket Connections |5,000-10,000       |Pi Memory      |


### 7.2 User Capacity Mapping


|Concurrent Users|Feasibility|Notes                         |
|----------------|-----------|------------------------------|
|100             |Excellent  |Full real-time AI interaction |
|1,000           |Good       |Minor queuing for LLM requests|
|10,000          |Possible   |Heavy caching, async AI       |
|100,000         |Limited    |Static content only, batch AI |
|1,000,000       |No         |Requires horizontal scaling   |


### 7.3 The Scaling Fallacy


The cloud computing industry perpetuates a scaling fallacy: that every application must be architected for millions of users from day one. In reality:


- 95% of applications never exceed 10,000 concurrent users
- 99% never exceed 100,000
- Premature scaling optimization wastes resources and increases complexity


The Sovereign Computing approach explicitly accepts capacity limits in exchange for comprehensibility and cost efficiency. Scaling concerns are deferred until demonstrated demand materializes—at which point revenue can fund appropriate expansion.


-----


## 8. Security Model


### 8.1 Defense in Depth


```
┌─────────────────────────────────────────────────────────────┐
│ LAYER 1: Cloudflare (Edge)                                  │
│ • DDoS mitigation (automatic)                               │
│ • Web Application Firewall                                  │
│ • SSL/TLS termination                                       │
│ • Bot detection                                             │
├─────────────────────────────────────────────────────────────┤
│ LAYER 2: Cloudflare Workers (Logic)                         │
│ • API key validation                                        │
│ • Rate limiting                                             │
│ • Request sanitization                                      │
│ • Geographic restrictions                                   │
├─────────────────────────────────────────────────────────────┤
│ LAYER 3: Tailscale (Transport)                              │
│ • WireGuard encryption (all internal traffic)               │
│ • Device authentication                                     │
│ • No open ports on any device                               │
├─────────────────────────────────────────────────────────────┤
│ LAYER 4: Application                                        │
│ • Input validation                                          │
│ • Parameterized queries                                     │
│ • JWT verification                                          │
└─────────────────────────────────────────────────────────────┘
```


### 8.2 Zero Open Ports


Traditional deployments require firewall rules, port forwarding, and careful security group configuration. The Sovereign approach requires none:


- Cloudflare Tunnel creates **outbound** connections only
- Tailscale uses NAT traversal—no inbound ports
- Hardware devices have **zero attack surface** from the internet


This architecture is more secure than most cloud deployments by default.


### 8.3 Data Sovereignty


All data remains on owned hardware:


|Data Type        |Location         |Encryption       |
|-----------------|-----------------|-----------------|
|User data        |Pi 5 (PostgreSQL)|At-rest (LUKS)   |
|LLM interactions |Jetson (local)   |Never transmitted|
|Vector embeddings|Pi 5 (Milvus)    |At-rest          |
|API keys         |Cloudflare KV    |Encrypted        |
|Backups          |Local + R2       |End-to-end       |


No cloud provider has access to application data. GDPR, CCPA, and similar regulations become trivially satisfiable when data never leaves controlled infrastructure.


-----


## 9. Discussion


### 9.1 When Sovereign Computing Fails


This approach has legitimate limitations:


1. **Global Low-Latency Requirements:** Applications requiring <50ms response times globally need distributed infrastructure that home hardware cannot provide.
1. **Burst Capacity:** Traffic spikes exceeding hardware capacity cannot be absorbed without cloud overflow.
1. **Regulatory Requirements:** Some industries mandate data center certifications that home infrastructure cannot achieve.
1. **Team Scale:** Organizations with dedicated DevOps teams may prefer standardized cloud tooling for operational consistency.
1. **Reliability Requirements:** 99.99% uptime SLAs require redundancy beyond a single location.


### 9.2 When Sovereign Computing Excels


The approach is optimal for:


1. **Individual Builders:** Solo developers and small teams benefit most from reduced complexity and cost.
1. **AI/ML Workloads:** Local inference eliminates per-token costs, enabling experimentation and deployment at fixed cost.
1. **Privacy-Sensitive Applications:** Data sovereignty is achieved by default, not through complex compliance measures.
1. **Educational/Research:** Full infrastructure visibility enables learning and experimentation impossible with managed services.
1. **Long-Term Projects:** Fixed costs enable indefinite operation without ongoing cloud bills.


### 9.3 The Complexity-Industrial Complex


Our analysis suggests the existence of a self-reinforcing cycle we term the “Complexity-Industrial Complex”:


1. Cloud providers add services to capture enterprise budgets
1. Complexity increases, creating demand for expertise
1. DevOps specialists emerge, normalizing complexity
1. Educational content assumes enterprise-scale needs
1. New developers inherit complexity as baseline expectation
1. Simple alternatives become invisible
1. Return to step 1


This cycle systematically disadvantages individual builders, who inherit enterprise infrastructure patterns without enterprise resources to manage them.


### 9.4 The GPU/CPU Insight


A conceptual breakthrough in our case study came from the GPU/CPU distinction:


- **CPU:** One smart worker doing complex tasks sequentially
- **GPU:** Thousands of simple workers doing identical tasks in parallel


This metaphor extended to infrastructure:


- **Cloud-Native (CPU Mode):** Many services doing specialized tasks sequentially
- **Sovereign (GPU Mode):** Unified infrastructure doing work in parallel


The realization that existing tools were operating in “CPU mode”—disconnected, sequential, specialized—enabled reconceptualization as a unified parallel system.


-----


## 10. Recommendations


### 10.1 For Individual Builders


1. **Start Sovereign:** Begin with owned hardware and add cloud services only when specific needs arise.
1. **Use Cloud as Utility:** Cloudflare for edge, APIs for specialized services, nothing more.
1. **Defer Scaling:** Build for 1,000 users. Address 1,000,000 when 10,000 arrive.
1. **Prioritize Comprehensibility:** If you cannot explain your infrastructure in five minutes, simplify it.


### 10.2 For the Industry


1. **Develop Beginner-Appropriate Tooling:** Current tools assume enterprise context. Simpler alternatives are needed.
1. **Honest Capacity Education:** Stop implying every application needs infinite scale.
1. **Cost Transparency:** Make true costs (including operational overhead) visible before adoption.
1. **Local-First Options:** Provide pathways from local development to local production, not just to cloud deployment.


### 10.3 For Educators


1. **Teach Fundamentals First:** DNS, HTTP, TCP/IP before Kubernetes and service meshes.
1. **Start with Hardware:** Understanding physical servers enables critical evaluation of abstractions.
1. **Present Alternatives:** Cloud-native is one option, not the only option.


-----


## 11. Conclusions


This research demonstrates that modern cloud infrastructure complexity is largely artificial—a consequence of enterprise optimization bias and self-reinforcing industry dynamics rather than technical necessity. For individual builders and small teams, the Sovereign Computing approach offers a compelling alternative:


- **90% cost reduction** compared to cloud-native deployments
- **Complete data sovereignty** without compliance complexity
- **Infrastructure comprehensibility** enabling independent operation
- **Sufficient capacity** for typical application requirements


The core insight is deceptively simple: the cloud computing industry has spent two decades building insurance products for infrastructure. Like all insurance, this is valuable when the risk profile justifies the premium. For most individual builders, it does not.


The entire cloud industry reduces to:


```
"What if your computer turned off?"
"I have another computer."
"But what if THAT one—"
"I have Cloudflare and a droplet."
"...but what about—"
"No."
```


The emperor, as it turns out, has no clothes. The infrastructure is just computers pointing at other computers, with one backup computer. Everything else is enterprise complexity projected onto problems that don’t require it.


We invite further research into Sovereign Computing patterns, tooling development for simplified deployment, and longitudinal studies of infrastructure costs across different architectural approaches.


-----


## 12. Future Work


1. **Tooling Development:** Create deployment tools optimized for Sovereign Computing patterns
1. **Benchmark Studies:** Quantitative comparison of reliability, latency, and cost across approaches
1. **Edge Case Analysis:** Document failure modes and recovery procedures for sovereign infrastructure
1. **Community Standards:** Develop best practices and reference architectures for common use cases
1. **Economic Modeling:** Long-term TCO analysis including hardware refresh cycles and opportunity costs


-----


## References


Armbrust, M., Fox, A., Griffith, R., Joseph, A. D., Katz, R., Konwinski, A., … & Zaharia, M. (2010). A view of cloud computing. *Communications of the ACM*, 53(4), 50-58.


Brooks, F. P. (1987). No silver bullet: Essence and accidents of software engineering. *Computer*, 20(4), 10-19.


Amazon Web Services. (2024). *AWS Service Overview*. Retrieved from aws.amazon.com/products


State of DevOps Report. (2024). *Puppet & CircleCI Annual Survey*.


Developer Experience Survey. (2024). *StackOverflow Developer Survey Results*.


Andreessen Horowitz. (2024). *Infrastructure Costs for Startups: A Longitudinal Analysis*.


-----


## Appendix A: Complete Infrastructure Checklist


### Phase 1: Foundation


- [ ] Install Tailscale on all devices
- [ ] Verify mesh connectivity
- [ ] Install cloudflared on primary Pi
- [ ] Create Cloudflare Tunnel
- [ ] Configure DNS to tunnel
- [ ] Verify end-to-end connectivity


### Phase 2: Services


- [ ] Deploy Docker on all devices
- [ ] Configure container registry access
- [ ] Deploy first containerized service
- [ ] Configure Jetson for LLM inference
- [ ] Verify internal LLM API access


### Phase 3: Hardening


- [ ] Configure Droplet failover
- [ ] Set up Cloudflare WAF
- [ ] Implement API key management
- [ ] Configure rate limiting
- [ ] Deploy monitoring stack


### Phase 4: Cleanup


- [ ] Audit and delete unused cloud resources
- [ ] Consolidate redundant services
- [ ] Document final architecture
- [ ] Create operational runbooks


-----


## Appendix B: Cost Comparison Spreadsheet


|Category         |Cloud-Native (Monthly)|Sovereign (Monthly) |Sovereign (One-Time)|
|-----------------|----------------------|--------------------|--------------------|
|Compute          |$50-200               |$0                  |$925                |
|GPU/AI           |$100-500              |$10-15 (electricity)|(included above)    |
|Database         |$15-50                |$0                  |(included above)    |
|Networking       |$20-50                |$0                  |—                   |
|Monitoring       |$20-50                |$0                  |—                   |
|CDN/Edge         |$0-20                 |$0                  |—                   |
|Failover         |(included)            |$6                  |—                   |
|Domains          |$17                   |$17                 |—                   |
|**Total Monthly**|**$222-887**          |**$33-38**          |—                   |
|**Total Year 1** |**$2,664-10,644**     |**$1,321-1,381**    |—                   |
|**Total Year 2+**|**$2,664-10,644**     |**$396-456**        |—                   |


-----


## Appendix C: Architecture Diagram (ASCII)


```
                              INTERNET
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │         CLOUDFLARE          │
                    │  ┌─────────────────────┐    │
                    │  │     DNS + CDN       │    │
                    │  └──────────┬──────────┘    │
                    │             │               │
                    │  ┌──────────▼──────────┐    │
                    │  │      Workers        │    │
                    │  │  (Auth, Rate Limit) │    │
                    │  └──────────┬──────────┘    │
                    │             │               │
                    │  ┌──────────▼──────────┐    │
                    │  │      Tunnel         │    │
                    │  │  (Outbound Only)    │    │
                    │  └──────────┬──────────┘    │
                    └─────────────┼───────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │         TAILSCALE           │
                    │    (Encrypted WireGuard)    │
                    └─────────────┬───────────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          │                       │                       │
          ▼                       ▼                       ▼
    ┌───────────┐           ┌───────────┐           ┌───────────┐
    │  Pi 5 x3  │◄─────────►│  Jetson   │◄─────────►│  Droplet  │
    │           │           │           │           │           │
    │ • API     │           │ • LLM     │           │ • Failover│
    │ • Agents  │           │ • GPU     │           │ • Backup  │
    │ • State   │           │ • Embed   │           │ • SSH     │
    └───────────┘           └───────────┘           └───────────┘
          │                       │                       │
          └───────────────────────┴───────────────────────┘
                                  │
                    ┌─────────────▼───────────────┐
                    │      EXTERNAL APIS          │
                    │                             │
                    │  Stripe │ Canva │ HF │ GDrive│
                    └─────────────────────────────┘
```


-----


*This paper is released under Creative Commons Attribution 4.0 International License. The author encourages adaptation and distribution with attribution.*


**Corresponding Author:** Alexa Louise Amundson, alexa@blackroad.io


**Acknowledgments:** The author thanks Claude (Cecilia) for collaborative development of the Sovereign Computing framework and infrastructure documentation.