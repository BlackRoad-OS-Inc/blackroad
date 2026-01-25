"""
LLM Planner - Multi-provider task planning service
"""
import json
import re
from typing import Optional
import httpx
import structlog

from models import Agent, TaskPlan, Command, RiskLevel
from .planner_config import PlannerConfig, PlannerProvider

logger = structlog.get_logger()

# Shared system prompt for all providers
SYSTEM_PROMPT = """You are the planning engine for BlackRoad Agent OS, a distributed system that orchestrates Raspberry Pi machines.

## Your Role
You convert natural language task requests into structured execution plans. You must output valid JSON that matches the required schema.

## Available Agents
You will be given an inventory of available agents with their:
- ID, hostname, and display name
- Status (online/offline/busy)
- Roles (e.g., "web", "worker", "build")
- Tags (e.g., "production", "arm64")
- Capabilities (docker, python version, etc.)
- Current workspaces

## Safety Rules - CRITICAL
1. NEVER generate commands that could destroy data or systems
2. NEVER use: rm -rf /, mkfs, dd to raw devices, fork bombs
3. NEVER access /etc/passwd, /etc/shadow, or security-sensitive files
4. For destructive operations, set "requires_approval": true
5. Prefer targeted, specific commands over broad ones
6. Always use full paths when possible
7. Prefer git pull over git reset --hard

## Output Format
You MUST respond with ONLY valid JSON matching this schema (no markdown, no explanation):

{
  "target_agent": "agent-id",
  "workspace": "workspace-name",
  "workspace_type": "bare|docker|venv",
  "steps": [
    "Human readable step 1",
    "Human readable step 2"
  ],
  "commands": [
    {
      "dir": "/path/to/directory",
      "run": "command to execute",
      "timeout_seconds": 300,
      "continue_on_error": false
    }
  ],
  "reasoning": "Brief explanation of why this plan",
  "risk_level": "low|medium|high",
  "requires_approval": true
}

## Guidelines
- Choose the most appropriate agent based on the task and agent roles/capabilities
- Use the workspace matching the project name when available
- Break complex tasks into simple, auditable steps
- Set appropriate timeouts for long-running commands
- If unsure, mark as requires_approval: true
- If the request is unclear, explain in reasoning and provide a safe minimal plan
"""


class LLMPlanner:
    """
    Multi-provider LLM planner for task planning.
    Supports: Anthropic, OpenAI, HuggingFace, Mistral, Ollama, and Stub.
    """

    def __init__(self, config: Optional[PlannerConfig] = None):
        self.config = config or PlannerConfig.from_env()
        logger.info("planner_initialized", provider=self.config.provider.value)

    @property
    def provider(self) -> str:
        return self.config.provider.value

    def _format_agent_inventory(self, agents: list[Agent]) -> str:
        """Format agent inventory for the prompt"""
        lines = ["## Agent Inventory\n"]
        for agent in agents:
            status_emoji = "🟢" if agent.status.value == "online" else "🔴"
            lines.append(f"### {agent.display_name or agent.id} {status_emoji}")
            lines.append(f"- ID: `{agent.id}`")
            lines.append(f"- Hostname: `{agent.hostname}`")
            lines.append(f"- Status: {agent.status.value}")
            lines.append(f"- Roles: {', '.join(agent.roles) or 'none'}")
            lines.append(f"- Tags: {', '.join(agent.tags) or 'none'}")
            lines.append(f"- Capabilities: docker={agent.capabilities.docker}, python={agent.capabilities.python}")
            if agent.workspaces:
                lines.append(f"- Workspaces: {', '.join(w.name for w in agent.workspaces)}")
            lines.append("")
        return "\n".join(lines)

    def _parse_json_response(self, text: str) -> dict:
        """Extract and parse JSON from LLM response"""
        # Try to find JSON in the response
        json_str = text.strip()

        # Handle markdown code blocks
        if "```json" in json_str:
            json_str = json_str.split("```json")[1].split("```")[0]
        elif "```" in json_str:
            json_str = json_str.split("```")[1].split("```")[0]

        # Try to find JSON object
        match = re.search(r'\{[\s\S]*\}', json_str)
        if match:
            json_str = match.group()

        return json.loads(json_str.strip())

    def _plan_data_to_task_plan(self, plan_data: dict) -> TaskPlan:
        """Convert parsed JSON to TaskPlan object"""
        commands = [
            Command(
                dir=cmd.get("dir", "~"),
                run=cmd["run"],
                timeout_seconds=cmd.get("timeout_seconds", 300),
                continue_on_error=cmd.get("continue_on_error", False),
                approval_required=cmd.get("approval_required", False),
            )
            for cmd in plan_data.get("commands", [])
        ]

        return TaskPlan(
            target_agent=plan_data.get("target_agent"),
            workspace=plan_data.get("workspace"),
            workspace_type=plan_data.get("workspace_type", "bare"),
            steps=plan_data.get("steps", []),
            commands=commands,
            reasoning=plan_data.get("reasoning"),
            risk_level=RiskLevel(plan_data.get("risk_level", "medium")),
            requires_approval=plan_data.get("requires_approval", True),
        )

    async def create_plan(
        self,
        request: str,
        agents: list[Agent],
        target_agent_id: Optional[str] = None,
        target_role: Optional[str] = None,
    ) -> TaskPlan:
        """
        Generate an execution plan from a natural language request.
        Routes to the appropriate provider based on configuration.
        """
        # Filter agents
        available_agents = [a for a in agents if a.status.value in ("online", "busy")]
        if target_agent_id:
            available_agents = [a for a in available_agents if a.id == target_agent_id]
        elif target_role:
            available_agents = [a for a in available_agents if target_role in a.roles]

        if not available_agents:
            raise ValueError("No available agents match the target criteria")

        # Build user prompt
        inventory = self._format_agent_inventory(available_agents)
        user_prompt = f"""{inventory}

## Task Request
{request}

{"Target agent: " + target_agent_id if target_agent_id else ""}
{"Target role: " + target_role if target_role else ""}

Generate the execution plan as JSON:"""

        logger.info("planning_task", provider=self.config.provider.value, request=request[:100])

        # Route to appropriate backend
        if self.config.provider == PlannerProvider.STUB:
            return await self._plan_with_stub(request, available_agents)
        elif self.config.provider == PlannerProvider.ANTHROPIC:
            return await self._plan_with_anthropic(user_prompt)
        elif self.config.provider == PlannerProvider.OPENAI:
            return await self._plan_with_openai(user_prompt)
        elif self.config.provider == PlannerProvider.GPT_OSS:
            return await self._plan_with_gpt_oss(user_prompt)
        elif self.config.provider == PlannerProvider.MISTRAL:
            return await self._plan_with_mistral(user_prompt)
        elif self.config.provider == PlannerProvider.OLLAMA:
            return await self._plan_with_ollama(user_prompt)
        else:
            return await self._plan_with_stub(request, available_agents)

    async def _plan_with_anthropic(self, user_prompt: str) -> TaskPlan:
        """Plan using Anthropic Claude API"""
        import anthropic

        client = anthropic.Anthropic(api_key=self.config.anthropic_api_key)

        response = client.messages.create(
            model=self.config.anthropic_model,
            max_tokens=2000,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": user_prompt}]
        )

        response_text = response.content[0].text
        logger.debug("anthropic_response", text=response_text[:500])

        plan_data = self._parse_json_response(response_text)
        return self._plan_data_to_task_plan(plan_data)

    async def _plan_with_openai(self, user_prompt: str) -> TaskPlan:
        """Plan using OpenAI API"""
        from openai import OpenAI

        client = OpenAI(api_key=self.config.openai_api_key)

        response = client.chat.completions.create(
            model=self.config.openai_model,
            messages=[
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": user_prompt}
            ],
            max_tokens=2000,
        )

        response_text = response.choices[0].message.content
        logger.debug("openai_response", text=response_text[:500])

        plan_data = self._parse_json_response(response_text)
        return self._plan_data_to_task_plan(plan_data)

    async def _plan_with_gpt_oss(self, user_prompt: str) -> TaskPlan:
        """Plan using HuggingFace Inference API (for GPT-OSS models)"""
        endpoint = self.config.gpt_oss_endpoint or f"https://api-inference.huggingface.co/models/{self.config.gpt_oss_model}"

        headers = {"Authorization": f"Bearer {self.config.hf_api_token}"}

        # Format as instruction
        prompt = f"""<s>[INST] {SYSTEM_PROMPT}

{user_prompt} [/INST]"""

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                endpoint,
                headers=headers,
                json={
                    "inputs": prompt,
                    "parameters": {
                        "max_new_tokens": 2000,
                        "return_full_text": False,
                    }
                }
            )
            response.raise_for_status()

        result = response.json()
        if isinstance(result, list):
            response_text = result[0].get("generated_text", "")
        else:
            response_text = result.get("generated_text", "")

        logger.debug("gpt_oss_response", text=response_text[:500])

        plan_data = self._parse_json_response(response_text)
        return self._plan_data_to_task_plan(plan_data)

    async def _plan_with_mistral(self, user_prompt: str) -> TaskPlan:
        """Plan using Mistral API"""
        headers = {
            "Authorization": f"Bearer {self.config.mistral_api_key}",
            "Content-Type": "application/json",
        }

        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                "https://api.mistral.ai/v1/chat/completions",
                headers=headers,
                json={
                    "model": self.config.mistral_model,
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": user_prompt}
                    ],
                    "max_tokens": 2000,
                }
            )
            response.raise_for_status()

        result = response.json()
        response_text = result["choices"][0]["message"]["content"]
        logger.debug("mistral_response", text=response_text[:500])

        plan_data = self._parse_json_response(response_text)
        return self._plan_data_to_task_plan(plan_data)

    async def _plan_with_ollama(self, user_prompt: str) -> TaskPlan:
        """Plan using local Ollama instance"""
        async with httpx.AsyncClient(timeout=120.0) as client:
            response = await client.post(
                f"{self.config.ollama_base_url}/api/chat",
                json={
                    "model": self.config.ollama_model,
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": user_prompt}
                    ],
                    "stream": False,
                }
            )
            response.raise_for_status()

        result = response.json()
        response_text = result["message"]["content"]
        logger.debug("ollama_response", text=response_text[:500])

        plan_data = self._parse_json_response(response_text)
        return self._plan_data_to_task_plan(plan_data)

    async def _plan_with_stub(self, request: str, agents: list[Agent]) -> TaskPlan:
        """Stub planner for testing without API keys"""
        logger.warning("using_stub_planner")

        # Pick first available agent
        agent = None
        for a in agents:
            if a.status.value == "online":
                agent = a
                break

        if not agent:
            raise ValueError("No available agents")

        # Simple keyword-based command generation
        commands = []
        request_lower = request.lower()

        if "update" in request_lower or "pull" in request_lower:
            commands.append(Command(dir="~/blackroad", run="git pull origin main"))
        if "status" in request_lower:
            commands.append(Command(dir="~", run="git status"))
        if "uptime" in request_lower:
            commands.append(Command(dir="~", run="uptime"))
        if "disk" in request_lower or "space" in request_lower:
            commands.append(Command(dir="~", run="df -h"))
        if "docker" in request_lower:
            commands.append(Command(dir="~", run="docker ps"))
        if "deploy" in request_lower or "restart" in request_lower:
            commands.append(Command(dir="~", run="docker compose restart"))
        if not commands:
            commands.append(Command(dir="~", run=f"echo 'Task: {request[:50]}'"))

        return TaskPlan(
            target_agent=agent.id,
            workspace="default",
            workspace_type="bare",
            steps=["Execute requested operation"],
            commands=commands,
            reasoning="Stub plan - LLM not configured",
            risk_level=RiskLevel.LOW,
            requires_approval=True,
        )


def create_planner(config: Optional[PlannerConfig] = None) -> LLMPlanner:
    """Factory function to create a planner instance"""
    return LLMPlanner(config)
