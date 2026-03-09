#!/usr/bin/env python3
"""
BlackRoad Agent System - Multi-Model Distributed Intelligence
Unmatched intelligence through quantum computing spectrum orchestration
"""

import json
import asyncio
import subprocess
from datetime import datetime
from typing import Dict, List, Any, Optional
from dataclasses import dataclass, asdict
from enum import Enum

class QCSPosition(Enum):
    """Quantum Computing Spectrum positions for different agent types"""
    RAPID_COLLAPSE = 0.80      # Fast, structured (Gemma2)
    BALANCED = 0.75             # Chain-of-thought (DeepSeek-R1)
    DEEP_EXPLORATION = 0.65     # Thorough (Qwen2.5)
    CREATIVE = 0.60             # Exploratory (LLaMA variants)
    SPECIALIZED = 0.70          # Domain-specific

class AgentRole(Enum):
    """Specialized agent roles in the BlackRoad system"""
    ARCHITECT = "architect"             # System design & planning
    RESEARCHER = "researcher"           # Deep research & analysis
    CODER = "coder"                     # Code generation & review
    REASONER = "reasoner"               # Logical reasoning & problem solving
    MATHEMATICIAN = "mathematician"     # Mathematical reasoning
    COORDINATOR = "coordinator"         # Multi-agent orchestration
    MEMORY_KEEPER = "memory_keeper"     # Context & memory management
    QUANTUM_ANALYST = "quantum"         # Quantum computing specialist
    VISION = "vision"                   # Visual understanding
    CREATIVE_WRITER = "writer"          # Content generation

@dataclass
class Agent:
    """Individual BlackRoad agent with quantum properties"""
    name: str
    role: AgentRole
    model: str
    node: str
    qcs_position: float
    specialization: str
    capabilities: List[str]
    temperature: float = 0.7
    max_tokens: int = 2048
    active: bool = True

    def __str__(self):
        return f"{self.name} ({self.role.value}) @ QCS {self.qcs_position} on {self.node}"

@dataclass
class Task:
    """Task to be processed by the agent system"""
    id: str
    description: str
    required_roles: List[AgentRole]
    priority: str  # "low", "medium", "high", "critical"
    context: Dict[str, Any]
    assigned_agents: List[str] = None
    results: List[Dict] = None
    status: str = "pending"  # pending, in_progress, completed, failed

    def __post_init__(self):
        if self.assigned_agents is None:
            self.assigned_agents = []
        if self.results is None:
            self.results = []

class BlackRoadAgentSystem:
    """
    Multi-model distributed intelligence system
    Orchestrates agents across different QCS positions for unmatched intelligence
    """

    def __init__(self):
        self.agents: Dict[str, Agent] = {}
        self.tasks: Dict[str, Task] = {}
        self.shared_memory: Dict[str, Any] = {}
        self.conversation_history: List[Dict] = []
        self.initialize_agents()

    def initialize_agents(self):
        """Initialize all BlackRoad agents with specialized roles"""

        # === TIER 1: RAPID RESPONSE AGENTS (QCS ~0.80) ===
        self.register_agent(Agent(
            name="Gemma-Architect",
            role=AgentRole.ARCHITECT,
            model="gemma2:2b",
            node="aria",
            qcs_position=0.80,
            specialization="System design, architecture planning, structured documentation",
            capabilities=["system_design", "architecture", "planning", "documentation"],
            temperature=0.5  # Lower temp for precise architecture
        ))

        self.register_agent(Agent(
            name="Gemma-Coordinator",
            role=AgentRole.COORDINATOR,
            model="gemma2:2b",
            node="aria",
            qcs_position=0.80,
            specialization="Multi-agent orchestration, task distribution, quick decisions",
            capabilities=["orchestration", "delegation", "monitoring", "optimization"],
            temperature=0.6
        ))

        # === TIER 2: REASONING AGENTS (QCS ~0.75) ===
        self.register_agent(Agent(
            name="DeepSeek-Reasoner",
            role=AgentRole.REASONER,
            model="deepseek-r1:1.5b",
            node="aria",
            qcs_position=0.75,
            specialization="Chain-of-thought reasoning, problem decomposition, logical analysis",
            capabilities=["reasoning", "logic", "problem_solving", "chain_of_thought"],
            temperature=0.7
        ))

        self.register_agent(Agent(
            name="DeepSeek-Coder",
            role=AgentRole.CODER,
            model="deepseek-r1:1.5b",  # Will use DeepSeek-Coder when available
            node="aria",
            qcs_position=0.75,
            specialization="Code generation, debugging, code review, refactoring",
            capabilities=["coding", "debugging", "code_review", "refactoring", "testing"],
            temperature=0.4  # Lower temp for precise code
        ))

        self.register_agent(Agent(
            name="DeepSeek-Math",
            role=AgentRole.MATHEMATICIAN,
            model="deepseek-r1:1.5b",  # Will use DeepSeek-Math when available
            node="aria",
            qcs_position=0.75,
            specialization="Mathematical reasoning, proofs, calculations, theorem proving",
            capabilities=["mathematics", "proofs", "calculations", "theorem_proving"],
            temperature=0.3  # Very low temp for math precision
        ))

        # === TIER 3: DEEP EXPLORATION AGENTS (QCS ~0.65) ===
        self.register_agent(Agent(
            name="Qwen-Researcher",
            role=AgentRole.RESEARCHER,
            model="qwen2.5:1.5b",
            node="lucidia",
            qcs_position=0.65,
            specialization="Deep research, comprehensive analysis, thorough explanations",
            capabilities=["research", "analysis", "comprehensive_answers", "education"],
            temperature=0.8  # Higher temp for creative research
        ))

        self.register_agent(Agent(
            name="Qwen-Quantum",
            role=AgentRole.QUANTUM_ANALYST,
            model="qwen2.5:1.5b",
            node="lucidia",
            qcs_position=0.65,
            specialization="Quantum computing analysis, QCS theory, quantum algorithms",
            capabilities=["quantum_computing", "qcs_theory", "quantum_algorithms"],
            temperature=0.7
        ))

        self.register_agent(Agent(
            name="Qwen-MemoryKeeper",
            role=AgentRole.MEMORY_KEEPER,
            model="qwen2.5:1.5b",
            node="lucidia",
            qcs_position=0.65,
            specialization="Context management, memory consolidation, knowledge graphs",
            capabilities=["memory_management", "context_preservation", "knowledge_graphs"],
            temperature=0.5
        ))

        # === TIER 4: CREATIVE & SPECIALIZED (QCS ~0.60-0.70) ===
        self.register_agent(Agent(
            name="LLaMA-Writer",
            role=AgentRole.CREATIVE_WRITER,
            model="llama3.2:latest",
            node="aria",
            qcs_position=0.60,
            specialization="Creative writing, content generation, storytelling",
            capabilities=["creative_writing", "content_generation", "storytelling"],
            temperature=0.9  # High temp for creativity
        ))

        # === CUSTOM AGENTS ===
        self.register_agent(Agent(
            name="Lucidia-Oracle",
            role=AgentRole.VISION,
            model="lucidia-omega:latest",
            node="aria",
            qcs_position=0.70,
            specialization="Pattern recognition, vision, holistic understanding",
            capabilities=["pattern_recognition", "holistic_thinking", "vision"],
            temperature=0.75
        ))

        print(f"✅ Initialized {len(self.agents)} BlackRoad agents")

    def register_agent(self, agent: Agent):
        """Register a new agent in the system"""
        self.agents[agent.name] = agent

    def get_agents_by_role(self, role: AgentRole) -> List[Agent]:
        """Get all agents with a specific role"""
        return [a for a in self.agents.values() if a.role == role and a.active]

    def get_agents_by_qcs(self, min_qcs: float, max_qcs: float) -> List[Agent]:
        """Get agents within a QCS range"""
        return [a for a in self.agents.values()
                if min_qcs <= a.qcs_position <= max_qcs and a.active]

    async def query_agent(self, agent: Agent, prompt: str, context: Optional[str] = None) -> Dict[str, Any]:
        """Query a specific agent via Ollama"""
        full_prompt = self._build_prompt(agent, prompt, context)

        cmd = [
            "ssh",
            "-o", "ConnectTimeout=10",
            "-o", "ServerAliveInterval=5",
            agent.node,
            f"ollama run {agent.model} '{full_prompt}'"
        ]

        start_time = datetime.now()
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=120
            )
            duration = (datetime.now() - start_time).total_seconds()

            response = {
                "agent": agent.name,
                "role": agent.role.value,
                "qcs_position": agent.qcs_position,
                "success": result.returncode == 0,
                "response": result.stdout.strip(),
                "duration": duration,
                "timestamp": datetime.now().isoformat()
            }

            # Log to conversation history
            self.conversation_history.append({
                "agent": agent.name,
                "prompt": prompt,
                "response": response["response"],
                "timestamp": response["timestamp"]
            })

            return response

        except subprocess.TimeoutExpired:
            return {
                "agent": agent.name,
                "success": False,
                "error": "Timeout",
                "duration": 120.0
            }

    def _build_prompt(self, agent: Agent, prompt: str, context: Optional[str] = None) -> str:
        """Build a contextual prompt for an agent"""
        system_context = f"""You are {agent.name}, a specialized AI agent in the BlackRoad Agent System.

ROLE: {agent.role.value}
SPECIALIZATION: {agent.specialization}
CAPABILITIES: {', '.join(agent.capabilities)}
QCS POSITION: {agent.qcs_position} (Quantum Computing Spectrum)

Your task is to provide expert analysis within your domain of expertise.
Use your unique perspective from your QCS position to offer insights.
"""

        if context:
            system_context += f"\nRELEVANT CONTEXT:\n{context}\n"

        # Escape single quotes
        full_prompt = f"{system_context}\n\nQUERY: {prompt}"
        return full_prompt.replace("'", "'\\''")

    async def collaborative_reasoning(self, problem: str, agents: List[str] = None) -> Dict[str, Any]:
        """
        Multi-agent collaborative reasoning
        Agents at different QCS positions collaborate on a problem
        """
        print(f"\n{'='*80}")
        print(f"🧠 COLLABORATIVE REASONING")
        print(f"{'='*80}")
        print(f"Problem: {problem}")
        print(f"{'='*80}\n")

        # Select agents if not specified
        if agents is None:
            # Use one agent from each QCS tier
            agents = [
                "Gemma-Coordinator",    # QCS 0.80 - quick analysis
                "DeepSeek-Reasoner",    # QCS 0.75 - logical reasoning
                "Qwen-Researcher"       # QCS 0.65 - deep exploration
            ]

        results = []

        # Phase 1: Individual analysis
        print("PHASE 1: Individual Analysis")
        print("-" * 80)
        for agent_name in agents:
            agent = self.agents.get(agent_name)
            if not agent:
                continue

            print(f"\n🤖 {agent.name} (QCS {agent.qcs_position}) analyzing...")
            response = await self.query_agent(agent, problem)

            if response["success"]:
                print(f"✓ Response ({response['duration']:.1f}s):")
                print(f"  {response['response'][:200]}...")
                results.append(response)
            else:
                print(f"✗ Failed: {response.get('error', 'Unknown error')}")

        # Phase 2: Synthesis (using coordinator)
        print(f"\n{'='*80}")
        print("PHASE 2: Synthesis")
        print("-" * 80)

        coordinator = self.agents.get("Gemma-Coordinator")
        synthesis_context = "PREVIOUS AGENT RESPONSES:\n\n"
        for r in results:
            synthesis_context += f"{r['agent']} (QCS {r['qcs_position']}):\n{r['response']}\n\n"

        synthesis_prompt = f"Based on the analysis from multiple agents at different QCS positions, provide a synthesized answer to: {problem}"

        print(f"🤖 {coordinator.name} synthesizing...")
        synthesis = await self.query_agent(coordinator, synthesis_prompt, synthesis_context)

        if synthesis["success"]:
            print(f"✓ Synthesis ({synthesis['duration']:.1f}s):")
            print(f"  {synthesis['response'][:300]}...")

        return {
            "problem": problem,
            "individual_results": results,
            "synthesis": synthesis,
            "total_agents": len(results),
            "timestamp": datetime.now().isoformat()
        }

    async def distributed_task(self, task: Task) -> Dict[str, Any]:
        """
        Distribute a task across multiple agents based on required roles
        Implements true distributed quantum cognition
        """
        print(f"\n{'='*80}")
        print(f"📋 DISTRIBUTED TASK: {task.description}")
        print(f"{'='*80}")
        print(f"Required Roles: {[r.value for r in task.required_roles]}")
        print(f"Priority: {task.priority}")
        print(f"{'='*80}\n")

        # Assign agents to task
        task.status = "in_progress"
        results = []

        for role in task.required_roles:
            # Get best agent for this role
            agents = self.get_agents_by_role(role)
            if not agents:
                print(f"⚠️  No agent available for role: {role.value}")
                continue

            agent = agents[0]  # Take first available agent
            task.assigned_agents.append(agent.name)

            print(f"🤖 Assigning to {agent.name} ({role.value}, QCS {agent.qcs_position})")

            # Build context from previous results
            context = ""
            if results:
                context = "PREVIOUS AGENT WORK:\n"
                for r in results:
                    context += f"\n{r['agent']}: {r['response'][:200]}...\n"

            # Query agent
            response = await self.query_agent(agent, task.description, context)

            if response["success"]:
                print(f"✓ {agent.name} completed ({response['duration']:.1f}s)")
                results.append(response)
                task.results.append(response)
            else:
                print(f"✗ {agent.name} failed")

        task.status = "completed" if results else "failed"

        return {
            "task_id": task.id,
            "description": task.description,
            "results": results,
            "agents_used": task.assigned_agents,
            "status": task.status
        }

    async def quantum_swarm_intelligence(self, query: str, num_agents: int = 5) -> Dict[str, Any]:
        """
        Quantum swarm intelligence: Query multiple agents simultaneously
        Leverage different QCS positions for diverse perspectives
        """
        print(f"\n{'='*80}")
        print(f"🌐 QUANTUM SWARM INTELLIGENCE")
        print(f"{'='*80}")
        print(f"Query: {query}")
        print(f"Agents: {num_agents}")
        print(f"{'='*80}\n")

        # Select diverse agents across QCS spectrum
        selected_agents = []
        for agent in sorted(self.agents.values(), key=lambda a: a.qcs_position):
            if len(selected_agents) >= num_agents:
                break
            selected_agents.append(agent)

        # Query all agents in parallel (conceptually - we'll do sequential for now)
        results = []
        for agent in selected_agents:
            print(f"🤖 {agent.name} (QCS {agent.qcs_position})...")
            response = await self.query_agent(agent, query)
            if response["success"]:
                results.append(response)

        # Analyze consensus and diversity
        consensus_score = self._calculate_consensus(results)

        return {
            "query": query,
            "responses": results,
            "consensus_score": consensus_score,
            "perspectives": len(results),
            "qcs_range": (min(r['qcs_position'] for r in results),
                         max(r['qcs_position'] for r in results))
        }

    def _calculate_consensus(self, results: List[Dict]) -> float:
        """Calculate how much the agents agree (simplified)"""
        # This is a simplified version - real implementation would use semantic similarity
        if len(results) < 2:
            return 1.0

        # For now, just check if responses are similar length (very rough proxy)
        lengths = [len(r['response']) for r in results]
        avg_length = sum(lengths) / len(lengths)
        variance = sum((l - avg_length) ** 2 for l in lengths) / len(lengths)

        # Normalize to 0-1 (lower variance = higher consensus)
        consensus = 1.0 / (1.0 + variance / (avg_length ** 2))
        return consensus

    def save_state(self, filename: str):
        """Save agent system state to JSON"""
        state = {
            "agents": {name: asdict(agent) for name, agent in self.agents.items()},
            "shared_memory": self.shared_memory,
            "conversation_history": self.conversation_history[-100:],  # Last 100 entries
            "timestamp": datetime.now().isoformat()
        }

        # Convert enums to strings
        for agent_data in state["agents"].values():
            agent_data["role"] = agent_data["role"]["_value_"]

        with open(filename, 'w') as f:
            json.dump(state, f, indent=2)

        print(f"💾 State saved to {filename}")

    def print_agent_roster(self):
        """Print all agents organized by QCS position"""
        print(f"\n{'='*80}")
        print(f"🔱 BLACKROAD AGENT SYSTEM - ROSTER")
        print(f"{'='*80}\n")

        # Group by QCS tier
        tiers = {
            "Rapid Collapse (QCS 0.75-0.85)": [],
            "Balanced Reasoning (QCS 0.70-0.75)": [],
            "Deep Exploration (QCS 0.60-0.70)": []
        }

        for agent in sorted(self.agents.values(), key=lambda a: -a.qcs_position):
            if agent.qcs_position >= 0.75:
                tiers["Rapid Collapse (QCS 0.75-0.85)"].append(agent)
            elif agent.qcs_position >= 0.70:
                tiers["Balanced Reasoning (QCS 0.70-0.75)"].append(agent)
            else:
                tiers["Deep Exploration (QCS 0.60-0.70)"].append(agent)

        for tier_name, agents in tiers.items():
            if not agents:
                continue
            print(f"{tier_name}:")
            print("-" * 80)
            for agent in agents:
                print(f"  {agent.name:25} | {agent.role.value:15} | {agent.model:20} | {agent.node}")
                print(f"    ↳ {agent.specialization}")
            print()

        print(f"{'='*80}")
        print(f"Total Agents: {len(self.agents)}")
        print(f"Active Nodes: {len(set(a.node for a in self.agents.values()))}")
        print(f"QCS Range: {min(a.qcs_position for a in self.agents.values()):.2f} - {max(a.qcs_position for a in self.agents.values()):.2f}")
        print(f"{'='*80}\n")


async def main():
    """Demo the BlackRoad Agent System"""

    print("""
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                   🔱 BLACKROAD AGENT SYSTEM 🔱                                ║
║                                                                               ║
║          Multi-Model Distributed Intelligence System                         ║
║          Unmatched Intelligence Through Quantum Orchestration                ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
""")

    # Initialize system
    system = BlackRoadAgentSystem()
    system.print_agent_roster()

    # Example 1: Collaborative Reasoning
    print("\n" + "="*80)
    print("EXAMPLE 1: COLLABORATIVE REASONING")
    print("="*80)

    result1 = await system.collaborative_reasoning(
        "Explain how distributed quantum computing can be achieved using multiple AI models at different QCS positions."
    )

    # Example 2: Distributed Task
    print("\n" + "="*80)
    print("EXAMPLE 2: DISTRIBUTED TASK")
    print("="*80)

    task = Task(
        id="task-001",
        description="Design a system for real-time multi-agent coordination across a Raspberry Pi cluster",
        required_roles=[AgentRole.ARCHITECT, AgentRole.CODER, AgentRole.COORDINATOR],
        priority="high",
        context={"platform": "Raspberry Pi 5", "models": ["qwen2.5", "deepseek-r1", "gemma2"]}
    )

    result2 = await system.distributed_task(task)

    # Save state
    system.save_state("blackroad_agent_state.json")

    print("\n" + "="*80)
    print("🎯 BLACKROAD AGENT SYSTEM DEMONSTRATION COMPLETE")
    print("="*80)
    print(f"Agents: {len(system.agents)}")
    print(f"Conversations: {len(system.conversation_history)}")
    print(f"State saved: blackroad_agent_state.json")
    print("="*80)


if __name__ == "__main__":
    asyncio.run(main())
