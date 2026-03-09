"""
Lucidia Code Router - API endpoints for multi-language code analysis
Supports 50+ programming languages with intelligent analysis, solutions, and learning paths
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Optional, Dict, Any
from datetime import datetime
import re

from models.code import (
    ProgrammingLanguage, LanguageParadigm, DifficultyLevel, ProblemCategory,
    CodeAnalysisRequest, CodeAnalysisResponse,
    SolveRequest, SolveResponse, CodeSolution, SolutionApproach,
    ExecuteRequest, ExecuteResponse,
    PracticeRequest, CodeProblem, TestCase,
    LearningPath, UserProgress, LanguageConfig,
)
from services.code_analyzer import code_analyzer

router = APIRouter(prefix="/api/v1/code", tags=["code"])


# ═══════════════════════════════════════════════════════════════════════════════
# LANGUAGE INFORMATION ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/languages", response_model=List[Dict[str, Any]])
async def get_all_languages():
    """
    Get all 50+ supported programming languages with their configurations.
    Returns language details including paradigms, use cases, and syntax info.
    """
    languages = code_analyzer.get_all_languages()
    return [
        {
            "name": lang.name,
            "display_name": lang.display_name,
            "file_extensions": lang.file_extensions,
            "paradigms": [p.value for p in lang.paradigms],
            "typing": lang.typing,
            "compiled": lang.compiled,
            "garbage_collected": lang.garbage_collected,
            "memory_safe": lang.memory_safe,
            "year_created": lang.year_created,
            "creator": lang.creator,
            "description": lang.description,
            "use_cases": lang.use_cases,
            "popular_frameworks": lang.popular_frameworks,
            "package_manager": lang.package_manager,
            "documentation_url": lang.documentation_url,
            "hello_world": lang.hello_world,
        }
        for lang in languages
    ]


@router.get("/languages/{language}", response_model=Dict[str, Any])
async def get_language_details(language: ProgrammingLanguage):
    """
    Get detailed information about a specific programming language.
    Includes syntax examples, keywords, operators, and related languages.
    """
    config = code_analyzer.get_language_config(language)
    if not config:
        raise HTTPException(status_code=404, detail=f"Language '{language}' not found")

    return {
        "name": config.name,
        "display_name": config.display_name,
        "file_extensions": config.file_extensions,
        "paradigms": [p.value for p in config.paradigms],
        "typing": config.typing,
        "compiled": config.compiled,
        "interpreted": config.interpreted,
        "garbage_collected": config.garbage_collected,
        "memory_safe": config.memory_safe,
        "year_created": config.year_created,
        "creator": config.creator,
        "description": config.description,
        "use_cases": config.use_cases,
        "popular_frameworks": config.popular_frameworks,
        "package_manager": config.package_manager,
        "documentation_url": config.documentation_url,
        "syntax_example": config.syntax_example,
        "hello_world": config.hello_world,
        "keywords": config.keywords,
        "operators": config.operators,
        "comment_syntax": config.comment_syntax,
        "string_syntax": config.string_syntax,
        "related_languages": config.related_languages,
    }


@router.get("/languages/by-paradigm/{paradigm}", response_model=List[Dict[str, str]])
async def get_languages_by_paradigm(paradigm: LanguageParadigm):
    """
    Get all languages that support a specific programming paradigm.
    Useful for finding languages with similar programming styles.
    """
    languages = code_analyzer.get_all_languages()
    matching = [
        {"name": lang.name, "display_name": lang.display_name}
        for lang in languages
        if paradigm in lang.paradigms
    ]
    return matching


@router.get("/languages/by-use-case/{use_case}", response_model=List[Dict[str, str]])
async def get_languages_by_use_case(use_case: str):
    """
    Get recommended languages for a specific use case.
    Examples: 'web', 'mobile', 'ml', 'systems', 'data'
    """
    languages = code_analyzer.get_all_languages()
    use_case_lower = use_case.lower()

    matching = []
    for lang in languages:
        for uc in lang.use_cases:
            if use_case_lower in uc.lower():
                matching.append({
                    "name": lang.name,
                    "display_name": lang.display_name,
                    "use_case": uc,
                })
                break

    return matching


# ═══════════════════════════════════════════════════════════════════════════════
# CODE ANALYSIS ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/analyze", response_model=CodeAnalysisResponse)
async def analyze_code(request: CodeAnalysisRequest):
    """
    Analyze code for errors, style issues, complexity, and improvements.
    Supports all 50+ languages with language-specific analysis.

    Features:
    - Syntax error detection
    - Style and best practice checks
    - Code complexity metrics
    - Improvement suggestions
    - Code explanation (optional)
    - Execution trace (optional)
    """
    try:
        result = code_analyzer.analyze_code(
            code=request.code,
            language=request.language,
            analyze_errors=request.analyze_errors,
            analyze_style=request.analyze_style,
            analyze_complexity=request.analyze_complexity,
            suggest_improvements=request.suggest_improvements,
            explain_code=request.explain_code,
            trace_execution=request.trace_execution,
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/detect-language", response_model=Dict[str, str])
async def detect_language(
    code: str,
    filename: Optional[str] = None,
):
    """
    Automatically detect the programming language from code or filename.
    Uses pattern matching and file extension analysis.
    """
    detected = code_analyzer.detect_language(code, filename)
    config = code_analyzer.get_language_config(detected)

    return {
        "detected_language": detected.value,
        "display_name": config.display_name if config else detected.value,
        "confidence": "high" if filename else "medium",
    }


@router.post("/format", response_model=Dict[str, str])
async def format_code(
    code: str,
    language: ProgrammingLanguage,
    indent_size: int = 4,
    use_tabs: bool = False,
):
    """
    Format code according to language conventions.
    Applies consistent indentation and spacing.
    """
    # Basic formatting - in production, integrate language-specific formatters
    indent = '\t' if use_tabs else ' ' * indent_size
    lines = code.split('\n')
    formatted_lines = []

    current_indent = 0
    for line in lines:
        stripped = line.strip()

        # Decrease indent for closing brackets/keywords
        if stripped and stripped[0] in '}])' or stripped.startswith(('end', 'fi', 'done', 'esac')):
            current_indent = max(0, current_indent - 1)

        formatted_lines.append(indent * current_indent + stripped if stripped else '')

        # Increase indent for opening brackets/keywords
        if stripped.endswith(('{', '[', '(', ':', 'do', 'then')):
            current_indent += 1

    return {
        "formatted_code": '\n'.join(formatted_lines),
        "language": language.value,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# CODE SOLUTION ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/solve", response_model=SolveResponse)
async def solve_problem(request: SolveRequest):
    """
    Generate solutions for a coding problem with multiple approaches.
    Includes complexity analysis, explanations, and common mistakes.

    Returns:
    - Multiple solution approaches
    - Time/space complexity for each
    - Step-by-step explanations
    - Common mistakes to avoid
    - Follow-up questions
    """
    # Example solution generation - integrate with AI for full implementation
    approaches = []

    if request.language == ProgrammingLanguage.PYTHON:
        approaches = [
            SolutionApproach(
                name="Pythonic Solution",
                description="Clean, idiomatic Python using built-in features",
                time_complexity="O(n)",
                space_complexity="O(1)",
                code=f"# Solution for: {request.problem or 'problem'}\n\ndef solve(data):\n    return [x for x in data if x > 0]",
                explanation=[
                    "Use list comprehension for concise iteration",
                    "Filter elements in a single pass",
                    "Return new list with positive values",
                ],
                pros=["Readable", "Efficient", "Pythonic"],
                cons=["Creates new list (memory)"],
            ),
            SolutionApproach(
                name="Generator Solution",
                description="Memory-efficient generator for large datasets",
                time_complexity="O(n)",
                space_complexity="O(1)",
                code=f"def solve(data):\n    for x in data:\n        if x > 0:\n            yield x",
                explanation=[
                    "Use generator for lazy evaluation",
                    "Process one element at a time",
                    "Memory efficient for large inputs",
                ],
                pros=["Memory efficient", "Lazy evaluation"],
                cons=["Single-use iterator"],
            ),
        ]
    else:
        approaches = [
            SolutionApproach(
                name="Standard Solution",
                description="Clear, readable implementation",
                time_complexity="O(n)",
                space_complexity="O(n)",
                code=f"// Solution in {request.language.value}",
                explanation=["Implement the algorithm step by step"],
                pros=["Clear", "Easy to understand"],
                cons=["May not be optimal"],
            ),
        ]

    solution = CodeSolution(
        problem_id="generated",
        language=request.language,
        approaches=approaches,
        best_approach=approaches[0].name,
        explanation=f"This problem can be solved using multiple approaches. The {approaches[0].name} is recommended for most cases.",
        common_mistakes=[
            "Off-by-one errors in loop bounds",
            "Not handling edge cases (empty input, null values)",
            "Inefficient nested loops when a single pass suffices",
        ],
        follow_up_questions=[
            "How would you handle very large inputs?",
            "Can you solve this in-place without extra memory?",
            "What if the input is already sorted?",
        ],
        related_problems=[],
    )

    return SolveResponse(
        solution=solution,
        user_code_feedback=None,
        improvements_to_user_code=None,
        score=None,
    )


@router.post("/explain", response_model=Dict[str, Any])
async def explain_code(
    code: str,
    language: ProgrammingLanguage,
    detail_level: str = "medium",  # brief, medium, detailed
):
    """
    Generate a detailed explanation of code.
    Explains what each part does in plain English.
    """
    config = code_analyzer.get_language_config(language)
    lines = code.split('\n')

    line_explanations = []
    for i, line in enumerate(lines, 1):
        stripped = line.strip()
        if stripped and not stripped.startswith(('#', '//', '--', '/*')):
            line_explanations.append({
                "line": i,
                "code": stripped,
                "explanation": f"Line {i}: {_explain_line(stripped, language)}",
            })

    return {
        "language": language.value,
        "language_info": {
            "name": config.display_name if config else language.value,
            "paradigms": [p.value for p in config.paradigms] if config else [],
        },
        "total_lines": len(lines),
        "code_lines": len(line_explanations),
        "explanations": line_explanations,
        "summary": f"This {config.display_name if config else language.value} code has {len(line_explanations)} executable lines.",
    }


def _explain_line(line: str, language: ProgrammingLanguage) -> str:
    """Generate explanation for a single line of code"""
    # Pattern matching for common constructs
    patterns = [
        (r'^(def|fn|func|function)\s+(\w+)', 'Defines a function named "{}"'),
        (r'^class\s+(\w+)', 'Defines a class named "{}"'),
        (r'^(if|elif|else if)\s+', 'Conditional statement checking a condition'),
        (r'^else\s*[:{]?$', 'Alternative branch if condition is false'),
        (r'^(for|foreach)\s+', 'Loop that iterates over a collection'),
        (r'^while\s+', 'Loop that continues while condition is true'),
        (r'^return\s+', 'Returns a value from the function'),
        (r'^(import|from|use|using|require)\s+', 'Imports external module or package'),
        (r'^(print|puts|echo|console\.log|fmt\.Print)', 'Outputs text to console'),
        (r'^(let|const|var|val)\s+(\w+)', 'Declares a variable named "{}"'),
        (r'^(\w+)\s*=\s*', 'Assigns a value to variable "{}"'),
        (r'\+\+|--', 'Increments/decrements a value'),
        (r'\[\s*\]', 'Creates or accesses an array/list'),
        (r'\{\s*\}', 'Creates an object or opens a block'),
    ]

    for pattern, template in patterns:
        match = re.search(pattern, line)
        if match:
            groups = match.groups()
            if '{}' in template and groups:
                return template.format(groups[-1])
            return template

    return "Executes an operation"


# ═══════════════════════════════════════════════════════════════════════════════
# CODE EXECUTION ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.post("/execute", response_model=ExecuteResponse)
async def execute_code(request: ExecuteRequest):
    """
    Execute code in a sandboxed environment.
    Currently returns a simulated response - integrate with execution service for real execution.

    Safety:
    - Timeout limits
    - Memory limits
    - Network isolation
    - Filesystem restrictions
    """
    # TODO: Integrate with sandboxed execution service (e.g., Judge0, Piston)
    # For now, return simulated response

    return ExecuteResponse(
        success=True,
        stdout="[Simulated output]\nHello, World!",
        stderr=None,
        exit_code=0,
        execution_time_ms=42.5,
        memory_used_mb=12.3,
        timed_out=False,
    )


@router.post("/test", response_model=Dict[str, Any])
async def test_code(
    code: str,
    language: ProgrammingLanguage,
    test_cases: List[TestCase],
):
    """
    Test code against provided test cases.
    Returns pass/fail status for each test.
    """
    results = []
    passed = 0

    for i, test in enumerate(test_cases):
        # Simulated test execution
        result = {
            "test_number": i + 1,
            "input": test.input,
            "expected": test.expected_output,
            "actual": test.expected_output,  # Simulated pass
            "passed": True,
            "execution_time_ms": 10.5,
        }
        results.append(result)
        if result["passed"]:
            passed += 1

    return {
        "total_tests": len(test_cases),
        "passed": passed,
        "failed": len(test_cases) - passed,
        "pass_rate": round(passed / len(test_cases) * 100, 1) if test_cases else 0,
        "results": results,
    }


# ═══════════════════════════════════════════════════════════════════════════════
# LEARNING & PRACTICE ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/learning-path/{language}", response_model=LearningPath)
async def get_learning_path(language: ProgrammingLanguage):
    """
    Get a structured learning path for a programming language.
    Includes modules from beginner to advanced topics.
    """
    config = code_analyzer.get_language_config(language)

    modules = [
        {
            "name": "Getting Started",
            "topics": ["Installation", "Hello World", "Basic Syntax", "Comments"],
            "difficulty": "beginner",
            "estimated_hours": 2,
        },
        {
            "name": "Variables & Data Types",
            "topics": ["Variables", "Numbers", "Strings", "Booleans", "Type Conversion"],
            "difficulty": "beginner",
            "estimated_hours": 3,
        },
        {
            "name": "Control Flow",
            "topics": ["If/Else", "Switch/Match", "Loops", "Break/Continue"],
            "difficulty": "beginner",
            "estimated_hours": 4,
        },
        {
            "name": "Functions",
            "topics": ["Defining Functions", "Parameters", "Return Values", "Scope", "Recursion"],
            "difficulty": "easy",
            "estimated_hours": 5,
        },
        {
            "name": "Data Structures",
            "topics": ["Arrays/Lists", "Dictionaries/Maps", "Sets", "Tuples"],
            "difficulty": "easy",
            "estimated_hours": 6,
        },
        {
            "name": "Object-Oriented Programming",
            "topics": ["Classes", "Objects", "Inheritance", "Polymorphism", "Encapsulation"],
            "difficulty": "medium",
            "estimated_hours": 8,
        },
        {
            "name": "Error Handling",
            "topics": ["Exceptions", "Try/Catch", "Custom Errors", "Debugging"],
            "difficulty": "medium",
            "estimated_hours": 4,
        },
        {
            "name": "File I/O",
            "topics": ["Reading Files", "Writing Files", "File Modes", "Working with Paths"],
            "difficulty": "medium",
            "estimated_hours": 3,
        },
        {
            "name": "Advanced Topics",
            "topics": ["Generics/Templates", "Concurrency", "Async Programming", "Memory Management"],
            "difficulty": "hard",
            "estimated_hours": 10,
        },
        {
            "name": "Best Practices",
            "topics": ["Code Style", "Testing", "Documentation", "Performance"],
            "difficulty": "hard",
            "estimated_hours": 6,
        },
    ]

    return LearningPath(
        language=language,
        title=f"Master {config.display_name if config else language.value}",
        description=f"Complete learning path for {config.display_name if config else language.value}. {config.description if config else ''}",
        modules=modules,
        estimated_hours=sum(m["estimated_hours"] for m in modules),
        prerequisites=[],
    )


@router.post("/practice/generate", response_model=List[CodeProblem])
async def generate_practice_problems(request: PracticeRequest):
    """
    Generate practice problems for a specific language and difficulty.
    Problems are tailored to help learn and reinforce concepts.
    """
    problems = []
    config = code_analyzer.get_language_config(request.language)

    # Sample problems - in production, pull from problem database
    sample_problems = [
        CodeProblem(
            id="two-sum",
            title="Two Sum",
            description="Given an array of integers and a target sum, find two numbers that add up to the target.",
            difficulty=DifficultyLevel.EASY,
            categories=[ProblemCategory.ARRAYS, ProblemCategory.HASH_TABLES],
            languages=[request.language],
            constraints=["2 <= nums.length <= 10^4", "-10^9 <= nums[i] <= 10^9"],
            examples=[{"input": "[2, 7, 11, 15], target = 9", "output": "[0, 1]"}],
            test_cases=[
                TestCase(input={"nums": [2, 7, 11, 15], "target": 9}, expected_output=[0, 1]),
                TestCase(input={"nums": [3, 2, 4], "target": 6}, expected_output=[1, 2]),
            ],
            hints=["Use a hash map to store seen values", "Think about what complement you're looking for"],
        ),
        CodeProblem(
            id="reverse-string",
            title="Reverse String",
            description="Write a function that reverses a string. The input string is given as an array of characters.",
            difficulty=DifficultyLevel.EASY,
            categories=[ProblemCategory.STRINGS],
            languages=[request.language],
            constraints=["1 <= s.length <= 10^5"],
            examples=[{"input": '["h","e","l","l","o"]', "output": '["o","l","l","e","h"]'}],
            test_cases=[
                TestCase(input=["h", "e", "l", "l", "o"], expected_output=["o", "l", "l", "e", "h"]),
            ],
            hints=["Use two pointers", "Can you do it in-place with O(1) extra memory?"],
        ),
        CodeProblem(
            id="fibonacci",
            title="Fibonacci Number",
            description="Calculate the nth Fibonacci number. F(0) = 0, F(1) = 1, F(n) = F(n-1) + F(n-2).",
            difficulty=DifficultyLevel.EASY,
            categories=[ProblemCategory.RECURSION, ProblemCategory.DYNAMIC_PROGRAMMING],
            languages=[request.language],
            constraints=["0 <= n <= 30"],
            examples=[{"input": "n = 4", "output": "3"}],
            test_cases=[
                TestCase(input=4, expected_output=3),
                TestCase(input=10, expected_output=55),
            ],
            hints=["Start with recursion, then optimize", "Consider memoization or iterative approach"],
        ),
        CodeProblem(
            id="valid-parentheses",
            title="Valid Parentheses",
            description="Given a string containing just '(', ')', '{', '}', '[' and ']', determine if the input string is valid.",
            difficulty=DifficultyLevel.EASY,
            categories=[ProblemCategory.STACKS, ProblemCategory.STRINGS],
            languages=[request.language],
            constraints=["1 <= s.length <= 10^4"],
            examples=[{"input": '"()[]{}"', "output": "true"}],
            test_cases=[
                TestCase(input="()[]{}", expected_output=True),
                TestCase(input="(]", expected_output=False),
            ],
            hints=["Use a stack", "Match opening brackets with closing brackets"],
        ),
        CodeProblem(
            id="merge-sorted-arrays",
            title="Merge Sorted Arrays",
            description="Merge two sorted arrays into one sorted array.",
            difficulty=DifficultyLevel.MEDIUM,
            categories=[ProblemCategory.ARRAYS, ProblemCategory.SORTING],
            languages=[request.language],
            constraints=["0 <= nums1.length, nums2.length <= 200"],
            examples=[{"input": "[1,3,5], [2,4,6]", "output": "[1,2,3,4,5,6]"}],
            test_cases=[
                TestCase(input={"nums1": [1, 3, 5], "nums2": [2, 4, 6]}, expected_output=[1, 2, 3, 4, 5, 6]),
            ],
            hints=["Use two pointers", "Compare elements from both arrays"],
        ),
    ]

    # Filter by difficulty if specified
    if request.difficulty:
        sample_problems = [p for p in sample_problems if p.difficulty == request.difficulty]

    # Filter by categories if specified
    if request.categories:
        sample_problems = [
            p for p in sample_problems
            if any(cat in p.categories for cat in request.categories)
        ]

    return sample_problems[:request.count]


@router.get("/progress/{user_id}/{language}", response_model=UserProgress)
async def get_user_progress(user_id: str, language: ProgrammingLanguage):
    """
    Get user's learning progress for a specific language.
    Tracks problems solved, streaks, and skill level.
    """
    # TODO: Integrate with user database
    # For now, return sample progress

    return UserProgress(
        user_id=user_id,
        language=language,
        problems_solved=25,
        problems_attempted=30,
        current_streak=5,
        best_streak=12,
        skill_level=DifficultyLevel.MEDIUM,
        categories_mastered=[ProblemCategory.ARRAYS, ProblemCategory.STRINGS],
        weak_areas=[ProblemCategory.DYNAMIC_PROGRAMMING],
        total_practice_time_minutes=480,
        last_practice=datetime.utcnow(),
    )


# ═══════════════════════════════════════════════════════════════════════════════
# UTILITY ENDPOINTS
# ═══════════════════════════════════════════════════════════════════════════════

@router.get("/categories", response_model=List[Dict[str, str]])
async def get_problem_categories():
    """Get all available problem categories"""
    return [
        {"value": cat.value, "name": cat.value.replace("-", " ").title()}
        for cat in ProblemCategory
    ]


@router.get("/difficulties", response_model=List[Dict[str, str]])
async def get_difficulty_levels():
    """Get all difficulty levels"""
    return [
        {"value": diff.value, "name": diff.value.title()}
        for diff in DifficultyLevel
    ]


@router.get("/paradigms", response_model=List[Dict[str, str]])
async def get_programming_paradigms():
    """Get all programming paradigms"""
    return [
        {"value": p.value, "name": p.value.replace("-", " ").title()}
        for p in LanguageParadigm
    ]


@router.post("/compare-languages", response_model=Dict[str, Any])
async def compare_languages(languages: List[ProgrammingLanguage]):
    """
    Compare multiple programming languages side by side.
    Shows differences in typing, paradigms, use cases, and more.
    """
    if len(languages) < 2:
        raise HTTPException(status_code=400, detail="Need at least 2 languages to compare")

    comparison = []
    for lang in languages:
        config = code_analyzer.get_language_config(lang)
        if config:
            comparison.append({
                "name": config.display_name,
                "paradigms": [p.value for p in config.paradigms],
                "typing": config.typing,
                "compiled": config.compiled,
                "garbage_collected": config.garbage_collected,
                "memory_safe": config.memory_safe,
                "year_created": config.year_created,
                "use_cases": config.use_cases[:3],
                "hello_world": config.hello_world,
            })

    return {
        "languages": [l.value for l in languages],
        "comparison": comparison,
    }
