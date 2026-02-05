# Contributing to BlackRoad OS

> Thank you for your interest in contributing to BlackRoad OS!

---

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Documentation](#documentation)
- [Community](#community)

---

## Code of Conduct

### Our Pledge

We pledge to make participation in our project a harassment-free experience for everyone, regardless of age, body size, disability, ethnicity, gender identity, level of experience, nationality, personal appearance, race, religion, or sexual identity and orientation.

### Our Standards

**Positive behaviors:**
- Using welcoming and inclusive language
- Being respectful of differing viewpoints
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

**Unacceptable behaviors:**
- Trolling, insulting comments, personal attacks
- Public or private harassment
- Publishing others' private information
- Other conduct which could be considered inappropriate

---

## Getting Started

### Types of Contributions

| Type | Description | Difficulty |
|------|-------------|------------|
| 🐛 Bug fixes | Fix reported issues | Easy-Medium |
| 📝 Documentation | Improve docs, fix typos | Easy |
| ✨ Features | Add new functionality | Medium-Hard |
| 🧪 Tests | Add test coverage | Medium |
| 🔧 Tooling | Improve dev experience | Medium |
| 🎨 Design | UI/UX improvements | Medium |

### Good First Issues

Look for issues labeled:
- `good first issue` - Great for newcomers
- `help wanted` - We need help!
- `documentation` - Doc improvements
- `bug` - Confirmed bugs

---

## Development Setup

### Prerequisites

```bash
# Required
node >= 22.0.0
python >= 3.10
rust >= 1.75 (for CLI v2)
docker >= 24.0

# Recommended
pnpm >= 9.0
uv >= 0.1 (Python)
```

### Clone & Install

```bash
# Clone the repository
git clone https://github.com/blackboxprogramming/blackroad.git
cd blackroad

# Install dependencies
pnpm install        # For JS/TS projects
uv sync             # For Python projects

# Set up environment
cp .env.example .env
# Edit .env with your values

# Verify setup
./health.sh
```

### Project Structure

```
blackroad/
├── orgs/
│   ├── core/           # Core platform repos
│   ├── ai/             # AI/ML repos
│   ├── enterprise/     # Enterprise tool forks
│   └── personal/       # Personal projects
├── repos/              # Standalone repo mirrors
├── scripts/            # Utility scripts
└── tools/              # Development tools
```

---

## Making Changes

### Branch Naming

```
feature/short-description    # New features
fix/issue-number-description # Bug fixes
docs/what-changed           # Documentation
refactor/what-changed       # Code refactoring
test/what-testing           # Test additions
```

### Commit Messages

Follow [Conventional Commits](https://conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Adding tests
- `chore`: Maintenance

**Examples:**
```
feat(agents): add task retry mechanism

fix(memory): resolve race condition in consolidation
Closes #123

docs(readme): update installation instructions
```

### Code Changes Workflow

```
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Write/update tests
5. Update documentation
6. Run linting & tests
7. Commit with good messages
8. Push to your fork
9. Open a Pull Request
```

---

## Pull Request Process

### Before Submitting

- [ ] Code follows style guidelines
- [ ] Tests pass locally
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with main

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
How has this been tested?

## Checklist
- [ ] Tests added/updated
- [ ] Documentation updated
- [ ] No breaking changes (or documented)

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** run (lint, test, build)
2. **Code review** by maintainer
3. **Changes requested** or **approved**
4. **Merged** to main branch

### Review Timeline

| PR Size | Expected Review Time |
|---------|---------------------|
| Small (<100 lines) | 1-2 days |
| Medium (100-500 lines) | 2-5 days |
| Large (>500 lines) | 5-10 days |

---

## Coding Standards

### TypeScript/JavaScript

```typescript
// Use TypeScript strict mode
// Prefer const over let
// Use async/await over callbacks
// Document public APIs with JSDoc

/**
 * Creates a new agent with the specified configuration.
 * @param config - Agent configuration options
 * @returns The created agent instance
 */
export async function createAgent(config: AgentConfig): Promise<Agent> {
  // Implementation
}
```

### Python

```python
# Follow PEP 8
# Use type hints
# Use async where appropriate
# Document with docstrings

async def create_agent(config: AgentConfig) -> Agent:
    """
    Creates a new agent with the specified configuration.

    Args:
        config: Agent configuration options

    Returns:
        The created agent instance

    Raises:
        AgentError: If agent creation fails
    """
    pass
```

### Rust

```rust
// Follow Rust idioms
// Use Result for error handling
// Document public items

/// Creates a new agent with the specified configuration.
///
/// # Arguments
///
/// * `config` - Agent configuration options
///
/// # Returns
///
/// The created agent instance
///
/// # Errors
///
/// Returns an error if agent creation fails
pub async fn create_agent(config: AgentConfig) -> Result<Agent, AgentError> {
    // Implementation
}
```

### General Guidelines

- **DRY**: Don't Repeat Yourself
- **KISS**: Keep It Simple, Stupid
- **YAGNI**: You Aren't Gonna Need It
- **Single Responsibility**: One thing per function/class
- **Meaningful Names**: Clear, descriptive identifiers

---

## Testing Guidelines

### Test Structure

```
tests/
├── unit/           # Unit tests
├── integration/    # Integration tests
├── e2e/            # End-to-end tests
└── fixtures/       # Test data
```

### Writing Tests

```typescript
describe('Agent', () => {
  describe('createAgent', () => {
    it('should create agent with valid config', async () => {
      const config = { name: 'test', type: 'worker' };
      const agent = await createAgent(config);
      expect(agent.name).toBe('test');
    });

    it('should throw error with invalid config', async () => {
      const config = { name: '' };
      await expect(createAgent(config)).rejects.toThrow('Invalid config');
    });
  });
});
```

### Test Coverage

| Component | Minimum Coverage |
|-----------|-----------------|
| Core logic | 80% |
| API endpoints | 70% |
| UI components | 60% |
| Utilities | 90% |

---

## Documentation

### What to Document

- **README.md**: Project overview, quick start
- **API.md**: API reference
- **CLAUDE.md**: AI assistant guidance
- **PLANNING.md**: Development planning
- **Code comments**: Complex logic only

### Documentation Style

- Use clear, concise language
- Include code examples
- Keep examples up to date
- Use proper formatting

---

## Community

### Communication Channels

| Channel | Purpose |
|---------|---------|
| GitHub Issues | Bug reports, features |
| GitHub Discussions | Questions, ideas |
| Discord | Real-time chat |
| Email | Private matters |

### Getting Help

1. Check existing documentation
2. Search GitHub issues
3. Ask in Discord
4. Open a new issue

### Recognition

Contributors are recognized in:
- CONTRIBUTORS.md file
- Release notes
- Annual contributor spotlight

---

## License

By contributing, you agree that your contributions will be licensed under the project's license.

---

*Thank you for contributing to BlackRoad OS! 🖤🛣️*
