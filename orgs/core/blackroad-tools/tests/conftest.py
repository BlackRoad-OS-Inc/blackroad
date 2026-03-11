import sys
import os

# Add project root to sys.path at runtime, but ONLY after pytest has loaded
# This avoids the email.py shadow issue during pytest initialization
_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def pytest_configure(config):
    if _root not in sys.path:
        sys.path.insert(0, _root)
