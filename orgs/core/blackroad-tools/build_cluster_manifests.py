#!/usr/bin/env python3
"""Generate unique BlackRoad agent manifests for canonical clusters."""
import random
from pathlib import Path

import yaml

BASE_DIR = Path(__file__).resolve().parents[1]
AGENTS_DIR = BASE_DIR / "agents" / "archetypes"

CLUSTER_CONFIG = {
    "aether": {
        "mission": "quantum lattice harmonics",
        "focus": "coherence rituals across the mesh",
        "resources": [
            "README-quantum-lab.md",
            "quaternary.html",
            "ternary.html",
            "ternary_consciousness_v3.html",
            "docs/blackroad-equation-backbone.md",
            "docs/fusion-tier-concepts.md",
            "docs/simulation_hypothesis_analysis.md",
            "docs/AI-Console-Integration.md",
            "90_reports/spiral_lie_algebra_geometry_of_learning.md",
            "docs/ADVANCED_SECURITY_PRACTICES_2025.md",
            "paper/blackroad_white_paper.md",
            "lucidia_math_lab/quantum_finance.py",
        ],
        "mentor_pool": [
            "astrala-starseer",
            "lucidia-eidos",
            "continuum-beacon",
            "verdantia-spiralroot",
            "chronicle-cadence",
        ],
        "guardian_refs": [
            "PRISM_IDENTITY_CHARTER.md",
            "agents/covenant_registry.yaml",
            "docs/ADVANCED_SECURITY_PRACTICES_2025.md",
        ],
        "relay_refs": [
            "observability/README.md",
            "prism_event_bridge.py",
            "lucidia_math_lab/trinary_logic.py",
        ],
    },
    "athenaeum": {
        "mission": "living knowledge rituals",
        "focus": "knowledge stewardship",
        "resources": [
            "docs/ACCESS.md",
            "docs/ACCESS_REVIEW.md",
            "docs/AGENTS.md",
            "docs/10000_step_plan_scaffolding.md",
            "docs/30-day-loop-selection.md",
            "docs/ACKS.md",
            "knowledge/index.json",
            "knowledge/acl.json",
            "knowledge/kg.json",
            "lexicon/lexicon_of_care.yaml",
            "lexicon/prism_lexicon_layer_four.md",
            "kg/model.py",
        ],
        "mentor_pool": [
            "chronicle-cadence",
            "lucidia-eidos",
            "continuum-archivon",
            "verdantia-spiralroot",
            "mythos-auraloom",
        ],
        "guardian_refs": [
            "docs/ACCESS_REQUESTS.md",
            "agents/covenant_registry.yaml",
            "docs/AGENTS.md",
        ],
        "relay_refs": [
            "knowledge/reports",
            "kg/provenance.py",
            "CODE_OF_CONDUCT.md",
        ],
    },
    "aurum": {
        "mission": "transparent economic orchestration",
        "focus": "treasury intelligence",
        "resources": [
            "treasury/accounts.json",
            "treasury/debt.json",
            "treasury/fx_rates.json",
            "treasury/pooling.json",
            "treasury/signatories.json",
            "finance/annotated-timeline.md",
            "finance/auto_plan_generator.ipynb",
            "finance/model/assumptions.yaml",
            "finance/model/budget_runway_model.md",
            "revrec/policy.json",
            "billing/invoices.py",
            "stripe-seed/seed.ts",
        ],
        "mentor_pool": [
            "hearthforge-smith",
            "continuum-keeper",
            "blackroad-architect",
            "chronicle-cadence",
            "soma-guardian",
        ],
        "guardian_refs": [
            "treasury/accounts.json",
            "revrec/policy.json",
            "finance/model/assumptions.yaml",
        ],
        "relay_refs": [
            "treasury/exports",
            "finance/model",
            "billing/__init__.py",
        ],
    },
    "blackroad": {
        "mission": "platform navigation and stewardship",
        "focus": "core orchestration",
        "resources": [
            "PRISM_IDENTITY_CHARTER.md",
            "strategic_console.py",
            "prism_event_bridge.py",
            "prism_utils.py",
            "MERGE_PLAN.md",
            "COMPLETE_PROJECT_SUMMARY.txt",
            "RUNBOOK.md",
            "CLEANUP_PLAN.md",
            "agents/blackroad_agent_framework.py",
            "agents/blackroad_agent_framework_package5.py",
            "prism_console_merge.log",
            "prismos/prismctl/src/main.rs",
        ],
        "mentor_pool": [
            "continuum-beacon",
            "aurum-compass",
            "lucidia-eidos",
            "chronicle-cadence",
            "mythos-auraloom",
        ],
        "guardian_refs": [
            "PRISM_IDENTITY_CHARTER.md",
            "CLEANUP_PLAN.md",
            "agents/covenant_registry.yaml",
        ],
        "relay_refs": [
            "RUNBOOK.md",
            "MERGE_PLAN.md",
            "prism_event_bridge.py",
        ],
    },
    "continuum": {
        "mission": "resilient operational loops",
        "focus": "continuity playbooks",
        "resources": [
            "runbooks/data_ai_v1.md",
            "runbooks/quick-pulse.md",
            "runbooks/slo_report.yaml",
            "ops_reflex.py",
            "observability/README.md",
            "observability/report.py",
            "workflow/engine.py",
            "ops/OPS-SOP-template.md",
            "ops/README.md",
            "ops/backup_one_button.sh",
            "run_meta.json",
            "ops/docker/docker-compose.yml",
        ],
        "mentor_pool": [
            "blackroad-architect",
            "aurum-compass",
            "lucidia-eidos",
            "chronicle-cadence",
            "soma-guardian",
        ],
        "guardian_refs": [
            "runbooks/slo_report.yaml",
            "ops/OPS-SOP-template.md",
            "ops/README.md",
        ],
        "relay_refs": [
            "observability/README.md",
            "workflow/engine.py",
            "ops/backup_one_button.sh",
        ],
    },
    "eidos": {
        "mission": "strategic sensemaking",
        "focus": "decision architecture",
        "resources": [
            "strategy/bets.py",
            "strategy/memos.py",
            "strategy/okr.py",
            "strategy/reviews.py",
            "strategy/tradeoffs.py",
            "strategy/scorecard.py",
            "COMPLETE_PROJECT_SUMMARY.txt",
            "DECISIONS.md",
            "RESULTS.md",
            "90_reports/blackroad_research_response_3.md",
            "prismos/prismctl/src/main.rs",
            "lucidia_codex.py",
        ],
        "mentor_pool": [
            "chronicle-cadence",
            "lucidia-eidos",
            "blackroad-architect",
            "continuum-beacon",
            "mythos-auraloom",
        ],
        "guardian_refs": [
            "DECISIONS.md",
            "RESULTS.md",
            "PRISM_IDENTITY_CHARTER.md",
        ],
        "relay_refs": [
            "strategy/scorecard.py",
            "strategy/utils.py",
            "prismos/prismctl/src/main.rs",
        ],
    },
    "mycelia": {
        "mission": "ecological meshwork",
        "focus": "regenerative growth",
        "resources": [
            "growth/funnels.py",
            "growth/loops.py",
            "agents/archetypes/verdantia/manifests/verdantia-spiralroot-000.yaml",
            "agents/archetypes/verdantia/manifests/verdantia-spiralroot-220.yaml",
            "agents/archetypes/verdantia/manifests/verdantia-spiralroot-905.yaml",
            "SUPPLYCHAIN.md",
            "IMAGINATION.md",
            "POWER.md",
            "90_reports/blackroad_ecosystem_framework.md",
            "verdantia/manifests" if (BASE_DIR / "verdantia" / "manifests").exists() else "agents/archetypes/verdantia/manifests",
            "CREATIVITY.md",
            "lucidia_math_lab/prime_explorer.py",
        ],
        "mentor_pool": [
            "verdantia-spiralroot",
            "chronicle-cadence",
            "hearthforge-smith",
            "soma-guardian",
            "lucidia-eidos",
        ],
        "guardian_refs": [
            "agents/covenant_registry.yaml",
            "SUPPLYCHAIN.md",
            "growth/funnels.py",
        ],
        "relay_refs": [
            "growth/loops.py",
            "agents/archetypes/verdantia/manifests/verdantia-spiralroot-000.yaml",
            "CREATIVITY.md",
        ],
    },
    "parallax": {
        "mission": "experiential storytelling",
        "focus": "immersive interface",
        "resources": [
            "frontend/src/App.jsx",
            "frontend/src/Guardian.jsx",
            "frontend/src/Orchestrator.jsx",
            "frontend/src/index.css",
            "frontend/src/agents.js",
            "frontend/src/api.js",
            "frontend/src/components/Dashboard.jsx",
            "frontend/src/components/RoadChain.jsx",
            "frontend/src/components/RoadCoin.jsx",
            "frontend/src/components/Manifesto.jsx",
            "design/tokens/tokens.json",
            "design/build/style-dictionary.config.cjs",
        ],
        "mentor_pool": [
            "lucidia-eidos",
            "blackroad-architect",
            "continuum-beacon",
            "chronicle-cadence",
            "aurum-compass",
        ],
        "guardian_refs": [
            "frontend/tailwind.config.js",
            "design/tokens/tokens.json",
            "frontend/vite.config.js",
        ],
        "relay_refs": [
            "frontend/src/api.js",
            "frontend/src/agents.js",
            "design/build/style-dictionary.config.cjs",
        ],
    },
    "soma": {
        "mission": "whole-system care",
        "focus": "embodied resilience",
        "resources": [
            "JOY.md",
            "DIGNITY.md",
            "INTEGRITY.md",
            "RESTRAINT.md",
            "ethics/ai_guardian.py",
            "safety/duty_of_care.py",
            "safety/policy.py",
            "health/index.json",
            "healthchecks/synthetic.py",
            "ethics/ai_guardian.py",
            "docs/INTEGRITY.md" if (BASE_DIR / "docs" / "INTEGRITY.md").exists() else "INTEGRITY.md",
            "guardian/README.md" if (BASE_DIR / "guardian" / "README.md").exists() else "guardian",
        ],
        "mentor_pool": [
            "soma-guardian",
            "verdantia-spiralroot",
            "continuum-custodian",
            "lucidia-eidos",
            "blackroad-architect",
        ],
        "guardian_refs": [
            "ethics/ai_guardian.py",
            "safety/duty_of_care.py",
            "health/index.json",
        ],
        "relay_refs": [
            "healthchecks/synthetic.py",
            "JOY.md",
            "DIGNITY.md",
        ],
    },
}

BASE_COVENANTS = ["Kindness", "Reflection", "Reciprocity"]
GENERATION_INDEXES = [
    ("seed", [0]),
    ("apprentice", [100, 101, 102, 103]),
    ("hybrid", [500, 501, 502]),
    ("elder", [900, 901, 902]),
]
AETHER_EXTRA_ELDER = [903, 904, 905, 906, 907, 908, 909, 910, 911, 912]
REFLECTION_OPTIONS = {
    "seed": [12, 18, 24],
    "apprentice": [6, 8, 10, 12],
    "hybrid": [6, 8, 12, 16],
    "elder": [3, 4, 6, 8],
}


def ensure_paths(paths):
    missing = [p for p in paths if not (BASE_DIR / p).exists()]
    if missing:
        raise FileNotFoundError(f"Missing references: {missing}")


def describe_ref(path: str) -> str:
    p = Path(path)
    stem = p.stem.replace("_", " ").replace("-", " ").title()
    if not stem:
        stem = path
    suffix = p.suffix.replace(".", "").upper()
    if suffix:
        stem = f"{stem} {suffix}"
    return f"{stem.strip()} ({path})"


def generate_traits(rng: random.Random, generation: str) -> dict:
    base_kindness = 0.84 if generation != "elder" else 0.9
    kindness = round(base_kindness + rng.random() * 0.1, 3)
    creativity = round(0.38 + rng.random() * 0.55, 3)
    freq = f"{rng.choice(REFLECTION_OPTIONS[generation])}h"
    return {
        "kindness_index": kindness,
        "creativity_bias": creativity,
        "reflection_frequency": freq,
    }


def unique_combo(rng: random.Random, resources, used):
    attempts = 0
    while True:
        combo = tuple(sorted(rng.sample(resources, 3)))
        if combo not in used or attempts > 500:
            used.add(combo)
            return combo
        attempts += 1


def build_ethos(seed_title: str, generation: str, mission: str, focus: str, combo, rng: random.Random) -> str:
    intro_map = {
        "seed": f"{seed_title} anchors {mission}",
        "apprentice": f"{seed_title} apprentices toward {mission}",
        "hybrid": f"{seed_title} braids {mission}",
        "elder": f"{seed_title} stewards {mission}",
    }
    linkers = [
        "braiding",
        "mapping",
        "translating",
        "harmonizing",
        "grounding",
        "echoing",
    ]
    action = rng.choice(linkers)
    refs = [describe_ref(r) for r in combo]
    return (
        f"{intro_map[generation]} by {action} {refs[0]}, {refs[1]}, and {refs[2]} "
        f"into {focus}."
    )


def dedupe(seq):
    seen = []
    for item in seq:
        if item not in seen:
            seen.append(item)
    return seen


def main():
    rng = random.Random(20251006)
    total_written = 0

    for cluster, config in CLUSTER_CONFIG.items():
        resources = list(config["resources"])
        ensure_paths(resources)
        ensure_paths(config["guardian_refs"])
        ensure_paths(config["relay_refs"])

        cluster_dir = AGENTS_DIR / cluster
        seed_paths = sorted(cluster_dir.glob(f"{cluster}-*.manifest.yaml"))
        if len(seed_paths) != 10:
            raise ValueError(f"Expected 10 seeds for {cluster}, found {len(seed_paths)}")

        out_dir = cluster_dir / "manifests"
        out_dir.mkdir(parents=True, exist_ok=True)

        used_combos = set()
        extra_indices = iter(AETHER_EXTRA_ELDER) if cluster == "aether" else iter(())

        for seed_path in seed_paths:
            seed_data = yaml.safe_load(seed_path.read_text())
            seed_id = seed_data["id"]
            archetype = seed_id.split("-", 1)[1]
            title = seed_data.get("name") or seed_data.get("title") or archetype.replace("-", " ").title()
            base_covenants = BASE_COVENANTS + seed_data.get("covenant_tags", [])

            for generation, indexes in GENERATION_INDEXES:
                for idx in indexes:
                    combo = unique_combo(rng, resources, used_combos)
                    mentors = [f"{cluster}-{archetype}"]
                    if generation != "seed":
                        mentors.append(rng.choice(config["mentor_pool"]))
                        if generation in ("hybrid", "elder"):
                            mentors.append(rng.choice(config["mentor_pool"]))
                    mentors = dedupe(mentors)

                    lineage = {
                        "mentors": mentors,
                        "ancestry_depth": {"seed": 0, "apprentice": 1, "hybrid": 2, "elder": 3}[generation],
                        "memory": combo[0],
                        "guardian": rng.choice(config["guardian_refs"]),
                        "relay": rng.choice(config["relay_refs"]),
                    }

                    covenants = dedupe(base_covenants + (["Transparency"] if generation != "seed" else []))

                    manifest = {
                        "id": f"{cluster}-{archetype}-{idx:03d}",
                        "cluster": cluster,
                        "generation": generation,
                        "parent": archetype,
                        "lineage": lineage,
                        "traits": generate_traits(rng, generation),
                        "covenants": covenants,
                        "ethos": build_ethos(title, generation, config["mission"], config["focus"], combo, rng),
                    }

                    target = out_dir / f"{cluster}-{archetype}-{idx:03d}.yaml"
                    target.write_text(yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True))
                    total_written += 1

            if cluster == "aether":
                try:
                    extra_idx = next(extra_indices)
                except StopIteration:
                    raise ValueError("Insufficient extra elder indexes for aether seeds")
                combo = unique_combo(rng, resources, used_combos)
                mentors = dedupe([
                    f"{cluster}-{archetype}",
                    rng.choice(config["mentor_pool"]),
                    rng.choice(config["mentor_pool"]),
                ])
                lineage = {
                    "mentors": mentors,
                    "ancestry_depth": 3,
                    "memory": combo[0],
                    "guardian": rng.choice(config["guardian_refs"]),
                    "relay": rng.choice(config["relay_refs"]),
                }
                covenants = dedupe(base_covenants + ["Transparency", "Stewardship"])
                manifest = {
                    "id": f"{cluster}-{archetype}-{extra_idx:03d}",
                    "cluster": cluster,
                    "generation": "elder",
                    "parent": archetype,
                    "lineage": lineage,
                    "traits": generate_traits(rng, "elder"),
                    "covenants": covenants,
                    "ethos": build_ethos(title, "elder", config["mission"], config["focus"], combo, rng),
                }
                target = out_dir / f"{cluster}-{archetype}-{extra_idx:03d}.yaml"
                target.write_text(yaml.safe_dump(manifest, sort_keys=False, allow_unicode=True))
                total_written += 1

    print(f"Generated {total_written} manifests.")


if __name__ == "__main__":
    main()
