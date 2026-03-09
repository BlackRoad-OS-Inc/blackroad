"""
BlackRoad Quantum Setup Script
Legacy setup.py for backward compatibility
Prefer pyproject.toml for configuration
"""

from setuptools import setup

# Read the long description from README
with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="blackroad-quantum",
    version="2.0.0",
    author="BlackRoad OS",
    author_email="quantum@blackroad.io",
    description="Quantum computing on $200 hardware - 3.5× faster than IBM/Google/Microsoft",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/BlackRoad-OS/blackroad-os-quantum",
    project_urls={
        "Bug Tracker": "https://github.com/BlackRoad-OS/blackroad-os-quantum/issues",
        "Documentation": "https://blackroad-os-quantum.readthedocs.io",
        "Source Code": "https://github.com/BlackRoad-OS/blackroad-os-quantum",
        "Changelog": "https://github.com/BlackRoad-OS/blackroad-os-quantum/blob/main/CHANGELOG.md",
    },
    packages=["bloche"],
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Science/Research",
        "Intended Audience :: Developers",
        "Intended Audience :: Education",
        "Topic :: Scientific/Engineering :: Physics",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Operating System :: OS Independent",
    ],
    python_requires=">=3.8",
    install_requires=[
        "numpy>=1.20.0",
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=4.0.0",
            "black>=23.0.0",
            "flake8>=6.0.0",
            "mypy>=1.0.0",
        ],
        "docs": [
            "sphinx>=6.0.0",
            "sphinx-rtd-theme>=1.2.0",
        ],
        "benchmarks": [
            "matplotlib>=3.5.0",
            "scipy>=1.8.0",
        ],
    },
    package_data={
        "bloche": ["py.typed"],
    },
)
