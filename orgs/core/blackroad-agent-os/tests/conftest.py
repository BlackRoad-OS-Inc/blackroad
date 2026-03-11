"""
Shared fixtures for blackroad-agent-os tests.

Controller tests import from controller/ (models/, core/ packages).
Agent tests import from agent/ (models.py, config.py modules) and
handle path setup themselves to avoid collisions.
"""
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent.parent

# Add controller path by default for controller tests
_controller_path = str(REPO_ROOT / "controller")
if _controller_path not in sys.path:
    sys.path.insert(0, _controller_path)
