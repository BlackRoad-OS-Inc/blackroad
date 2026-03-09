# Contributing to docs

Thank you for considering contributing to this BlackRoad OS project! 🎉

## Code of Conduct

This project follows our [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you agree to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear description** of the issue
- **Steps to reproduce** the problem
- **Expected behavior**
- **Actual behavior**
- **Screenshots** (if applicable)
- **Environment details** (OS, version, etc.)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When suggesting an enhancement:

- **Use a clear title** describing the enhancement
- **Provide detailed description** of the suggested feature
- **Explain why** this enhancement would be useful
- **Include examples** of how it would work

### Pull Requests

1. **Fork** the repository
2. **Create** a new branch (`git checkout -b feature/amazing-feature`)
3. **Make** your changes
4. **Test** your changes thoroughly
5. **Commit** with clear messages (`git commit -m 'Add amazing feature'`)
6. **Push** to your fork (`git push origin feature/amazing-feature`)
7. **Open** a Pull Request

#### Pull Request Guidelines

- Follow the existing code style
- Write clear commit messages
- Update documentation as needed
- Add tests for new features
- Ensure all tests pass
- Link related issues

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/docs.git
cd docs

# Add upstream remote
git remote add upstream https://github.com/BlackRoad-OS/docs.git

# Install dependencies
npm install  # or pip install -r requirements.txt

# Run tests
npm test  # or pytest, or cargo test
```

## Coding Standards

- Follow language-specific best practices
- Write self-documenting code
- Add comments for complex logic
- Keep functions small and focused
- Use meaningful variable names

## Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(api): Add new authentication endpoint
fix(ui): Resolve button alignment issue
docs(readme): Update installation instructions
```

## BlackRoad OS Principles

When contributing, please align with our core principles:

- 🔱 **Sovereignty**: Users own their data and infrastructure
- 🔒 **Privacy**: No telemetry, tracking, or external dependencies
- 🌐 **Offline-First**: Features should work without internet
- 🎨 **Design Excellence**: Follow BlackRoad design system
- 🚀 **Production Quality**: Code should be reliable and scalable

### What We Don't Accept

- ❌ Adding external analytics or telemetry
- ❌ Required internet connectivity for core features
- ❌ Vendor lock-in mechanisms
- ❌ Cloud-only functionality
- ❌ Compromising user privacy

## Questions?

- **GitHub Issues**: For bug reports and feature requests
- **Email**: blackroad.systems@gmail.com
- **Website**: [blackroad.io](https://blackroad.io)

---

**Thank you for contributing to BlackRoad OS!** 💜

*The road remembers every contribution.* 🌌
