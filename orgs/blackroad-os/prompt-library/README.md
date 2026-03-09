# BlackRoad Prompt Library

**Production-grade prompts for AI applications**

## Categories

| Category | Prompts | Use Case |
|----------|---------|----------|
| Coding | 50+ | Code generation, review, debugging |
| Analysis | 40+ | Data analysis, research, summarization |
| Creative | 30+ | Writing, brainstorming, ideation |
| System | 25+ | Agent instructions, tool definitions |

## Quick Start

```python
from blackroad_prompts import PromptLibrary

prompts = PromptLibrary()

# Get a prompt
code_review = prompts.get("coding/code-review")

# Use with variables
result = code_review.format(
    language="python",
    code=user_code,
    focus="security"
)
```

## Prompt Structure

```yaml
name: code-review
version: 1.0.0
category: coding
variables:
  - language
  - code
  - focus
template: |
  Review this {language} code for {focus} issues:
  
  ```{language}
  {code}
  ```
  
  Provide specific feedback with line numbers.
```

## Best Practices

1. **Be specific**: Include context and constraints
2. **Use examples**: Few-shot learning improves quality
3. **Structure output**: Request JSON, markdown, or specific formats
4. **Version prompts**: Track changes and A/B test

## Included Prompts

- `coding/code-review` - Security and quality review
- `coding/generate-tests` - Unit test generation
- `coding/explain-code` - Code explanation
- `analysis/summarize` - Document summarization
- `analysis/extract-data` - Structured data extraction
- `system/agent-instructions` - Agent system prompts

---

*BlackRoad OS - Prompt Engineering at Scale*
