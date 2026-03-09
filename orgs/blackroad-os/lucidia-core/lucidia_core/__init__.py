"""Lucidia Core - AI reasoning engines for specialized domains."""

__version__ = "0.1.0"

from pathlib import Path

# Package root for accessing agent modules
PACKAGE_ROOT = Path(__file__).parent.parent

# Import main agent classes for convenience
def get_physicist():
    """Get the Physicist reasoning engine."""
    import sys
    sys.path.insert(0, str(PACKAGE_ROOT))
    from physicist import PhysicistSeed, load_seed
    return PhysicistSeed, load_seed

def get_mathematician():
    """Get the Mathematician reasoning engine."""
    import sys
    sys.path.insert(0, str(PACKAGE_ROOT))
    from mathematician import MathematicianSeed, load_seed
    return MathematicianSeed, load_seed

def get_chemist():
    """Get the Chemist reasoning engine."""
    import sys
    sys.path.insert(0, str(PACKAGE_ROOT))
    from chemist import ChemistSeed, load_seed
    return ChemistSeed, load_seed

def get_geologist():
    """Get the Geologist reasoning engine."""
    import sys
    sys.path.insert(0, str(PACKAGE_ROOT))
    from geologist import GeologistSeed, load_seed
    return GeologistSeed, load_seed

__all__ = [
    "__version__",
    "PACKAGE_ROOT",
    "get_physicist",
    "get_mathematician",
    "get_chemist",
    "get_geologist",
]
