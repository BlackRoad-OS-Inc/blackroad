from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, List, Tuple


@dataclass
class DomainKnowledge:
    """
    Container for knowledge specific to a domain.

    Attributes
    ----------
    domain : str
        Name of the knowledge domain (e.g., "biology", "finance").
    facts : Dict[str, Any]
        Key-value pairs representing facts or concepts within the domain.
    """
    domain: str
    facts: Dict[str, Any]


class CrossDomainReasoner:
    """
    Naive cross-domain reasoner that finds overlapping fact keys between domains.
    """
    def __init__(self) -> None:
        self.knowledge: Dict[str, DomainKnowledge] = {}

    def add_knowledge(self, knowledge: DomainKnowledge) -> None:
        """Register domain knowledge in the reasoner."""
        self.knowledge[knowledge.domain] = knowledge

    def relate(self, domain_a: str, domain_b: str) -> List[Tuple[str, Tuple[Any, Any]]]:
        """
        Relate two domains by finding common fact keys.

        Returns a list of tuples (key, (value_a, value_b)).
        """
        facts_a = self.knowledge.get(domain_a)
        facts_b = self.knowledge.get(domain_b)
        if not facts_a or not facts_b:
            return []
        overlaps: List[Tuple[str, Tuple[Any, Any]]] = []
        for key in facts_a.facts.keys() & facts_b.facts.keys():
            overlaps.append((key, (facts_a.facts[key], facts_b.facts[key])))
        return overlaps


if __name__ == "__main__":
    reasoner = CrossDomainReasoner()
    reasoner.add_knowledge(DomainKnowledge("biology", {"cell": "basic unit", "DNA": "genetic blueprint"}))
    reasoner.add_knowledge(DomainKnowledge("computer", {"CPU": "central processor", "memory": "storage", "cell": "memory cell"}))
    print(reasoner.relate("biology", "computer"))
