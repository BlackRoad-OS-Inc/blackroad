"""
BlackRoad Python SDK
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as f:
    long_description = f.read()

setup(
    name="blackroad",
    version="1.0.0",
    author="BlackRoad OS, Inc.",
    author_email="sdk@blackroad.io",
    description="Official Python SDK for the BlackRoad API",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/BlackRoad-OS/blackroad-sdk-python",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 5 - Production/Stable",
        "Intended Audience :: Developers",
        "License :: Other/Proprietary License",
        "Operating System :: OS Independent",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
        "Programming Language :: Python :: 3.12",
        "Topic :: Software Development :: Libraries :: Python Modules",
    ],
    python_requires=">=3.8",
    install_requires=[],  # No external dependencies - uses stdlib only
    extras_require={
        "dev": [
            "pytest>=7.0",
            "pytest-cov>=4.0",
            "black>=23.0",
            "mypy>=1.0",
        ],
    },
    keywords="blackroad api sdk agents ai infrastructure",
    project_urls={
        "Documentation": "https://docs.blackroad.io/sdk/python",
        "Source": "https://github.com/BlackRoad-OS/blackroad-sdk-python",
        "Issues": "https://github.com/BlackRoad-OS/blackroad-sdk-python/issues",
    },
)
