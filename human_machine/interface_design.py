from __future__ import annotations

from dataclasses import dataclass, field
from typing import Dict, List

@dataclass
class InterfaceElement:
    """
    Represents a UI element in a human-machine interface.

    Attributes
    ----------
    name : str
        Identifier of the element.
    element_type : str
        Type of element (e.g., "button", "slider").
    properties : Dict[str, str]
        Optional dictionary of element-specific properties.
    """
    name: str
    element_type: str
    properties: Dict[str, str] = field(default_factory=dict)

class InterfaceDesigner:
    """
    A simple interface builder that collects elements and renders them.
    """
    def __init__(self) -> None:
        self.elements: List[InterfaceElement] = []

    def add_element(self, element: InterfaceElement) -> None:
        """Add a new interface element to the design."""
        self.elements.append(element)

    def render(self) -> str:
        """
        Produce a human-readable representation of the interface.

        Returns
        -------
        str
            A multiline string describing each element.
        """
        lines = []
        for e in self.elements:
            props = ", ".join(f"{k}={v}" for k, v in e.properties.items()) if e.properties else ""
            lines.append(f"{e.element_type.capitalize()} '{e.name}'" + (f" ({props})" if props else ""))
        return "\n".join(lines)

if __name__ == "__main__":
    designer = InterfaceDesigner()
    designer.add_element(InterfaceElement("Submit", "button", {"color": "blue"}))
    designer.add_element(InterfaceElement("Volume", "slider", {"min": "0", "max": "10"}))
    print(designer.render())
