"""
LLM Service - Integration with Claude/other LLMs for task planning
"""
import json
from typing import Optional
import structlog

from models import Agent, TaskPlan, Command, RiskLevel

logger = structlog.get_logger()

# System prompt for task planning
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
You MUST respond with valid JSON matching this schema:

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


class LLMService:
    """
    Service for interacting with LLMs (Claude, GPT, etc.)
    """

    def __init__(self, api_key: Optional[str] = None, model: str = "claude-sonnet-4-20250514"):
        self.api_key = api_key
        self.model = model
        self._client = None

    def _get_client(self):
        """Lazy initialization of LLM client"""
        if self._client is None:
            if not self.api_key:
                raise ValueError("LLM API key not configured. Set ANTHROPIC_API_KEY environment variable.")

            # TODO: Initialize your preferred LLM client here
            # For Claude:
            import anthropic
            self._client = anthropic.Anthropic(api_key=self.api_key)

        return self._client

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

    async def create_plan(
        self,
        request: str,
        agents: list[Agent],
        target_agent_id: Optional[str] = None,
        target_role: Optional[str] = None,
    ) -> TaskPlan:
        """
        Generate an execution plan from a natural language request.
        """
        # Filter agents based on targeting
        available_agents = [a for a in agents if a.status.value in ("online", "busy")]
        if target_agent_id:
            available_agents = [a for a in available_agents if a.id == target_agent_id]
        elif target_role:
            available_agents = [a for a in available_agents if target_role in a.roles]

        if not available_agents:
            raise ValueError("No available agents match the target criteria")

        # Build the user prompt
        inventory = self._format_agent_inventory(available_agents)
        user_prompt = f"""{inventory}

## Task Request
{request}

{"Target agent: " + target_agent_id if target_agent_id else ""}
{"Target role: " + target_role if target_role else ""}

Generate the execution plan as JSON:"""

        logger.info("llm_planning", request=request, agent_count=len(available_agents))

        try:
            client = self._get_client()

            response = client.messages.create(
                model=self.model,
                max_tokens=2000,
                system=SYSTEM_PROMPT,
                messages=[
                    {"role": "user", "content": user_prompt}
                ]
            )

            # Extract JSON from response
            response_text = response.content[0].text

            # Try to parse JSON (might be wrapped in markdown code block)
            json_str = response_text
            if "```json" in json_str:
                json_str = json_str.split("```json")[1].split("```")[0]
            elif "```" in json_str:
                json_str = json_str.split("```")[1].split("```")[0]

            plan_data = json.loads(json_str.strip())

            # Convert to TaskPlan
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

            plan = TaskPlan(
                target_agent=plan_data.get("target_agent"),
                workspace=plan_data.get("workspace"),
                workspace_type=plan_data.get("workspace_type", "bare"),
                steps=plan_data.get("steps", []),
                commands=commands,
                reasoning=plan_data.get("reasoning"),
                risk_level=RiskLevel(plan_data.get("risk_level", "medium")),
                requires_approval=plan_data.get("requires_approval", True),
            )

            logger.info("llm_plan_created", target_agent=plan.target_agent, commands=len(plan.commands))
            return plan

        except json.JSONDecodeError as e:
            logger.error("llm_json_parse_error", error=str(e), response=response_text[:500])
            raise ValueError(f"Failed to parse LLM response as JSON: {e}")
        except Exception as e:
            logger.error("llm_error", error=str(e))
            raise


# Stub for when API key isn't available
class StubLLMService:
    """
    Stub LLM service for testing without API key.
    Returns a simple plan based on basic parsing.
    """

    async def create_plan(
        self,
        request: str,
        agents: list[Agent],
        target_agent_id: Optional[str] = None,
        target_role: Optional[str] = None,
    ) -> TaskPlan:
        """Create a simple stub plan"""
        # Pick first available agent
        agent = None
        for a in agents:
            if a.status.value == "online":
                if target_agent_id and a.id != target_agent_id:
                    continue
                if target_role and target_role not in a.roles:
                    continue
                agent = a
                break

        if not agent:
            raise ValueError("No available agents")

        # Simple keyword-based command generation
        commands = []
        if "update" in request.lower() or "pull" in request.lower():
            commands.append(Command(dir="~/blackroad", run="git pull origin main"))
        if "status" in request.lower():
            commands.append(Command(run="git status"))
        if "deploy" in request.lower() or "restart" in request.lower():
            commands.append(Command(run="docker compose restart"))
        if not commands:
            commands.append(Command(run="echo 'Task: " + request[:50] + "'"))

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


def create_llm_service(api_key: Optional[str] = None) -> LLMService | StubLLMService:
    """Factory to create appropriate LLM service"""
    if api_key:
        return LLMService(api_key=api_key)
    else:
        logger.warning("llm_api_key_not_set", message="Using stub LLM service")
        return StubLLMService()
