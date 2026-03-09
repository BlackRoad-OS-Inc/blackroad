# CLAUDE.md - Lucidia Agents

This file provides guidance for AI assistants working with the Lucidia Agents codebase.

## Project Overview

Lucidia Agents is an AI agents framework designed to create, orchestrate, and deploy intelligent autonomous agents. The project aims to provide a modular, extensible architecture for building agent-based systems.

**Repository Status**: New project - foundational structure being established.

## Project Structure

```
lucidia-agents/
├── src/                    # Source code
│   ├── agents/             # Agent implementations
│   ├── core/               # Core framework components
│   ├── memory/             # Memory and context management
│   ├── tools/              # Tool definitions and implementations
│   ├── orchestration/      # Multi-agent orchestration
│   └── utils/              # Utility functions
├── tests/                  # Test files
│   ├── unit/               # Unit tests
│   └── integration/        # Integration tests
├── docs/                   # Documentation
├── examples/               # Example implementations
├── config/                 # Configuration files
└── scripts/                # Build and deployment scripts
```

## Technology Stack

- **Language**: TypeScript (recommended for type safety in agent systems)
- **Runtime**: Node.js
- **Package Manager**: npm or pnpm
- **Testing**: Jest or Vitest
- **Linting**: ESLint with TypeScript support
- **Formatting**: Prettier

## Development Commands

Once the project is set up, standard commands will include:

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Run tests
npm test

# Run tests in watch mode
npm run test:watch

# Build for production
npm run build

# Lint code
npm run lint

# Format code
npm run format

# Type check
npm run typecheck
```

## Code Conventions

### TypeScript Guidelines

1. **Use strict TypeScript configuration** - Enable strict mode in tsconfig.json
2. **Define explicit types** - Avoid `any`; use proper interfaces and type definitions
3. **Use interfaces for agent contracts** - Define clear interfaces for agent capabilities
4. **Prefer immutability** - Use `readonly` where appropriate

### Agent Development Patterns

1. **Agent Interface**: All agents should implement a base `Agent` interface
2. **Tool Registration**: Tools should be registered declaratively with type-safe schemas
3. **Memory Management**: Use the provided memory abstractions for context persistence
4. **Error Handling**: Agents should handle errors gracefully with proper logging

### Naming Conventions

- **Files**: Use kebab-case for file names (`my-agent.ts`)
- **Classes**: Use PascalCase (`class MyAgent`)
- **Functions/Variables**: Use camelCase (`const myFunction`)
- **Constants**: Use UPPER_SNAKE_CASE (`const MAX_RETRIES`)
- **Interfaces**: Prefix with `I` only if needed to avoid conflicts (`Agent` preferred over `IAgent`)
- **Types**: Use PascalCase (`type AgentConfig`)

### Directory Conventions

- Place agent implementations in `src/agents/`
- Place shared tools in `src/tools/`
- Keep tests co-located or in parallel `tests/` structure
- Configuration schemas go in `src/config/` or `config/`

## Testing Requirements

1. **Unit Tests**: Required for all utility functions and core logic
2. **Integration Tests**: Required for agent workflows and tool integrations
3. **Test Coverage**: Aim for >80% coverage on core modules
4. **Naming**: Test files should be named `*.test.ts` or `*.spec.ts`

### Running Tests

```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.ts

# Run with coverage
npm test -- --coverage
```

## Git Workflow

### Branch Naming

- Feature branches: `feature/description`
- Bug fixes: `fix/description`
- Refactoring: `refactor/description`
- Documentation: `docs/description`

### Commit Messages

Use conventional commits format:

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

### Pull Request Guidelines

1. Keep PRs focused and reasonably sized
2. Include tests for new functionality
3. Update documentation as needed
4. Ensure all CI checks pass

## Architecture Guidelines

### Agent Design Principles

1. **Single Responsibility**: Each agent should have a clear, focused purpose
2. **Composability**: Agents should be composable for complex workflows
3. **Observability**: Include logging and tracing for debugging
4. **Statelessness**: Prefer stateless agents; externalize state to memory systems

### Tool Design Principles

1. **Idempotency**: Tools should be idempotent where possible
2. **Schema Validation**: All tool inputs/outputs should have schemas
3. **Error Messages**: Provide clear, actionable error messages
4. **Timeouts**: Implement appropriate timeouts for external calls

### Memory Architecture

1. **Short-term Memory**: For conversation/task context
2. **Long-term Memory**: For persistent knowledge and learning
3. **Working Memory**: For current task state

## Security Considerations

1. **Input Validation**: Always validate and sanitize inputs
2. **Secret Management**: Never hardcode secrets; use environment variables
3. **Principle of Least Privilege**: Agents should request minimal permissions
4. **Audit Logging**: Log security-relevant actions

## Performance Guidelines

1. **Async Operations**: Use async/await for I/O operations
2. **Batching**: Batch API calls where possible
3. **Caching**: Implement caching for repeated queries
4. **Resource Limits**: Set appropriate limits on memory and execution time

## AI Assistant Guidelines

When working on this codebase, AI assistants should:

### Do

- Read existing code before making changes
- Follow established patterns in the codebase
- Write tests for new functionality
- Use TypeScript types properly
- Keep changes focused and minimal
- Commit with descriptive messages

### Don't

- Make changes without understanding context
- Introduce new dependencies without justification
- Skip error handling
- Ignore existing conventions
- Over-engineer solutions
- Leave debug code or console.logs in production code

### Code Review Checklist

Before submitting changes, verify:

- [ ] Code compiles without errors
- [ ] All tests pass
- [ ] New code has appropriate test coverage
- [ ] No security vulnerabilities introduced
- [ ] Documentation updated if needed
- [ ] Follows project conventions
- [ ] No unnecessary complexity added

## Environment Setup

### Prerequisites

- Node.js >= 18.x
- npm >= 9.x (or pnpm >= 8.x)
- Git

### Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd lucidia-agents

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Configure environment variables
# Edit .env with your settings
```

### Environment Variables

Key environment variables (to be defined in `.env`):

```bash
# API Keys
OPENAI_API_KEY=           # OpenAI API key (if using)
ANTHROPIC_API_KEY=        # Anthropic API key (if using)

# Configuration
LOG_LEVEL=info            # Logging level (debug, info, warn, error)
NODE_ENV=development      # Environment (development, production, test)
```

## Troubleshooting

### Common Issues

1. **TypeScript compilation errors**: Run `npm run typecheck` to identify issues
2. **Test failures**: Check test output, run individual tests for isolation
3. **Dependency issues**: Delete `node_modules` and run `npm install`

### Getting Help

- Check existing documentation in `/docs`
- Review similar patterns in the codebase
- Create an issue for bugs or feature requests

---

*This CLAUDE.md was created for the initial setup of the Lucidia Agents project. Update this file as the project evolves to reflect current architecture, conventions, and workflows.*
