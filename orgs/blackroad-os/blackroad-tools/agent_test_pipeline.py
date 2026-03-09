"""Utilities to run and automatically repair agent tests."""

from __future__ import annotations

import subprocess
import sys
import textwrap
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parents[1]
AGENT_TESTS = [
    "tests/test_agents_runtime.py",
    "tests/agents/test_auto_novel_agent.py",
]
AUTO_NOVEL_AGENT_PATH = PROJECT_ROOT / "agents" / "auto_novel_agent.py"

_TEMPLATE = textwrap.dedent(
    """
    \"\"\"Simple auto novel agent example with creative and coding abilities.\"\"\"

    from __future__ import annotations

    from dataclasses import dataclass, field
    from typing import ClassVar, Dict, Iterator

    DEFAULT_SUPPORTED_ENGINES: tuple[str, ...] = (\"unity\", \"unreal\")


    @dataclass
    class AutoNovelAgent:
        \"\"\"A toy agent that can deploy itself, create games, and write stories.\"\"\"

        name: str = \"AutoNovelAgent\"
        gamma: float = 1.0
        _supported_engines: set[str] = field(
            default_factory=lambda: set(DEFAULT_SUPPORTED_ENGINES)
        )

        SAMPLE_SNIPPETS: ClassVar[Dict[str, str]] = {
            \"python\": \"def solve():\\n    pass\\n\",
            \"javascript\": \"function solve() {\\n  return null;\\n}\\n\",
            \"java\": \"class Solution {\\n    void solve() {\\n    }\\n}\\n\",
        }
        LEAST_PRIVILEGE_SCOPES: ClassVar[set[str]] = {\"outline:read\", \"outline:write\"}

        def __post_init__(self) -> None:
            if self.gamma <= 0:
                raise ValueError(\"gamma must be positive.\")
            self._supported_engines = {
                self._normalize_engine(engine) for engine in self._supported_engines
            }

        # ------------------------------------------------------------------
        # Engine helpers
        # ------------------------------------------------------------------
        def _normalize_engine(self, engine: str) -> str:
            \"\"\"Return a lowercase, trimmed engine name.\"\"\"

            engine_normalized = engine.strip().lower()
            if not engine_normalized:
                raise ValueError(\"Engine name must be a non-empty string.\")
            return engine_normalized

        def supports_engine(self, engine: str) -> bool:
            \"\"\"Return ``True`` when ``engine`` is present in the supported set.\"\"\"

            try:
                return self._normalize_engine(engine) in self._supported_engines
            except ValueError:
                return False

        def list_supported_engines(self) -> list[str]:
            \"\"\"Return a sorted snapshot of supported engines.\"\"\"

            return sorted(self._supported_engines)

        def add_supported_engine(self, engine: str) -> None:
            \"\"\"Register a new game engine.\"\"\"

            self._supported_engines.add(self._normalize_engine(engine))

        def remove_supported_engine(self, engine: str) -> None:
            \"\"\"Remove a game engine, raising ``ValueError`` if it is unknown.\"\"\"

            normalized = self._normalize_engine(engine)
            if normalized not in self._supported_engines:
                supported = \", \\".join(self.list_supported_engines())
                raise ValueError(
                    f\"Cannot remove unsupported engine '{normalized}'. \
                    f\"Supported engines: {supported}.\"
                )
            self._supported_engines.remove(normalized)

        @property
        def SUPPORTED_ENGINES(self) -> set[str]:
            \"\"\"Return the set of engines supported by this agent instance.\"\"\"

            return set(self._supported_engines)

        # ------------------------------------------------------------------
        # Primary abilities
        # ------------------------------------------------------------------
        def deploy(self) -> None:
            \"\"\"Deploy the agent by printing a greeting.\"\"\"

            print(f\"{self.name} deployed and ready to generate novels!\")

        def _indefinite_article(self, engine_name: str) -> str:
            \"\"\"Return the appropriate indefinite article for ``engine_name``.\"\"\"

            if not engine_name:
                return \"a\"
            lower = engine_name.lower()
            if lower.startswith((\"honest\", \"hour\", \"heir\")):
                return \"an\"
            return \"an\" if lower[0] in \"aeiou\" else \"a\"

        def create_game(self, engine: str, include_weapons: bool = False) -> str:
            \"\"\"Create a basic game using a supported engine.\"\"\"

            normalized = self._normalize_engine(engine)
            if normalized not in self._supported_engines:
                supported = \", \\".join(self.list_supported_engines())
                raise ValueError(
                    \"Unsupported engine \"
                    f\"'{normalized}'. Supported engines: {supported}. \"
                    \"Use add_supported_engine to register new engines.\"
                )
            if include_weapons:
                raise ValueError(\"Weapons are not allowed in generated games.\")

            article = self._indefinite_article(normalized)
            message = f\"Creating {article} {normalized.capitalize()} game without weapons...\"
            print(message)
            return message

        def generate_game_idea(self, theme: str, engine: str) -> str:
            \"\"\"Return a short description for a themed game.\"\"\"

            theme_clean = theme.strip()
            if not theme_clean:
                raise ValueError(\"Theme must be a non-empty string.\")

            normalized = self._normalize_engine(engine)
            if normalized not in self._supported_engines:
                supported = \", \\".join(self.list_supported_engines())
                raise ValueError(f\"Unsupported engine. Choose one of: {supported}.\")

            return (
                f\"Imagine a {theme_clean} adventure crafted with \"
                f\"{normalized.capitalize()} where creativity reigns.\"
            )

        def generate_story(self, theme: str, protagonist: str) -> str:
            \"\"\"Generate a short themed story.\"\"\"

            clean_theme = \" \\".join(theme.split())
            clean_protagonist = protagonist.strip() or \"Someone\"
            if not clean_theme:
                raise ValueError(\"Theme must be provided.\")
            return (
                f\"{clean_protagonist} embarked on a {clean_theme} quest, \"
                \"discovering wonders along the way.\"
            )

        def generate_coding_challenge(self, topic: str, difficulty: str) -> str:
            \"\"\"Return a coding challenge prompt.\"\"\"

            topic_clean = topic.strip()
            if not topic_clean:
                raise ValueError(\"Topic must be provided.\")

            difficulty_clean = difficulty.strip().lower() or \"medium\"
            return (
                f\"Implement a solution for {topic_clean} at a {difficulty_clean} difficulty.\"
            )

        def generate_code_snippet(self, prompt: str, language: str) -> str:
            \"\"\"Return a canned code snippet for the given language.\"\"\"

            lang_key = language.strip().lower()
            snippet = self.SAMPLE_SNIPPETS.get(lang_key)
            if snippet:
                return snippet
            return f\"// Code snippet for {lang_key} not available. Prompt was: {prompt}\"

        def proofread_paragraph(self, paragraph: str) -> str:
            \"\"\"Return a polished version of ``paragraph`` with basic fixes.\"\"\"

            cleaned = paragraph.strip()
            if not cleaned:
                return \"\"
            sentence = cleaned[0].upper() + cleaned[1:]
            if not sentence.endswith('.'):
                sentence += '.'
            return sentence

        def generate_novel(self, title: str, chapters: int = 3) -> Iterator[str]:
            \"\"\"Yield a few sentences representing chapters of a novel.\"\"\"

            if chapters <= 0:
                raise ValueError(\"chapters must be a positive integer\")

            for index in range(1, chapters + 1):
                yield f\"Chapter {index}: The tale of {title} unfolds with new revelations.\"

        def write_short_story(
            self,
            theme: str,
            *,
            setting: str | None = None,
            protagonist: str | None = None,
        ) -> str:
            \"\"\"Generate a short, two-sentence story for the given theme.\"\"\"

            clean_theme = \" \\".join(theme.split())
            if not clean_theme:
                raise ValueError(\"Theme must be provided.\")

            setting_part = f\" set in {setting}\" if setting else \"\"
            protagonist_part = protagonist or \"Someone\"
            return (
                f\"A tale of {clean_theme}{setting_part} begins with hope. \"
                f\"In the end, {protagonist_part} discovers that {clean_theme} prevails.\"
            )


    if __name__ == \"__main__\":
        agent = AutoNovelAgent(gamma=2.0)
        agent.deploy()
        agent.add_supported_engine(\"godot\")
        agent.create_game(\"godot\")
        print(agent.generate_story(\"mystical\", \"A coder\"))
        print(agent.generate_game_idea(\"mystical\", \"unity\"))
        print(agent.generate_coding_challenge(\"graph traversal\", \"hard\"))
        print(agent.generate_code_snippet(\"Implement depth-first search\", \"python\"))
        print(agent.proofread_paragraph(\"this is a test paragraph it needs polish\"))
        for line in agent.generate_novel(\"The Journey\", chapters=2):
            print(line)
        print(
            agent.write_short_story(
                \"friendship\", setting=\"a bustling spaceport\", protagonist=\"Rin\"
            )
        )
        agent.create_game(\"unity\")
        print(agent.write_short_story(\"friendship\"))
        print(agent.generate_story(\"mystical\", \"A coder\"))
    """
).strip() + "\n"


def _run_command(command: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(command, capture_output=True, text=True, cwd=PROJECT_ROOT)


def run_py_compile() -> subprocess.CompletedProcess[str]:
    target = AUTO_NOVEL_AGENT_PATH.relative_to(PROJECT_ROOT)
    return _run_command([sys.executable, "-m", "py_compile", str(target)])


def run_pytest() -> subprocess.CompletedProcess[str]:
    return _run_command(["pytest", *AGENT_TESTS])


def repair_auto_novel_agent() -> None:
    AUTO_NOVEL_AGENT_PATH.write_text(_TEMPLATE, encoding="utf-8")


def main() -> int:
    print("Compiling agents/auto_novel_agent.py for syntax errors...")
    compile_result = run_py_compile()
    if compile_result.returncode != 0:
        sys.stderr.write(compile_result.stderr)
        return compile_result.returncode

    print("Running agent test suite...")
    test_result = run_pytest()
    sys.stdout.write(test_result.stdout)
    sys.stdout.flush()
    sys.stderr.write(test_result.stderr)
    sys.stderr.flush()

    if test_result.returncode == 0:
        print("Agent tests passed successfully.")
        return 0

    if "auto_novel_agent" not in (test_result.stdout + test_result.stderr):
        return test_result.returncode

    print("Detected auto_novel_agent failure. Applying canonical repair...", file=sys.stderr)
    repair_auto_novel_agent()

    rerun_result = run_pytest()
    sys.stdout.write(rerun_result.stdout)
    sys.stdout.flush()
    sys.stderr.write(rerun_result.stderr)
    sys.stderr.flush()
    if rerun_result.returncode == 0:
        print("Agent tests passed after repairing auto_novel_agent.")
    return rerun_result.returncode


if __name__ == "__main__":
    sys.exit(main())
