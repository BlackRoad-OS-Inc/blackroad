"""
Lucidia Code Models - Data structures for multi-language code analysis
Supports 50+ programming languages with intelligent analysis
"""

from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
from enum import Enum
from datetime import datetime


# ═══════════════════════════════════════════════════════════════════════════════
# LANGUAGE DEFINITIONS - 50+ Languages
# ═══════════════════════════════════════════════════════════════════════════════

class ProgrammingLanguage(str, Enum):
    # Web & Frontend
    JAVASCRIPT = "javascript"
    TYPESCRIPT = "typescript"
    HTML = "html"
    CSS = "css"
    SCSS = "scss"
    LESS = "less"
    VUE = "vue"
    SVELTE = "svelte"

    # Backend & Systems
    PYTHON = "python"
    JAVA = "java"
    CSHARP = "csharp"
    CPP = "cpp"
    C = "c"
    GO = "go"
    RUST = "rust"
    KOTLIN = "kotlin"
    SCALA = "scala"
    RUBY = "ruby"
    PHP = "php"
    PERL = "perl"

    # Mobile
    SWIFT = "swift"
    OBJECTIVE_C = "objective-c"
    DART = "dart"

    # Data Science & ML
    R = "r"
    JULIA = "julia"
    MATLAB = "matlab"

    # Functional
    HASKELL = "haskell"
    ELIXIR = "elixir"
    ERLANG = "erlang"
    CLOJURE = "clojure"
    FSHARP = "fsharp"
    OCAML = "ocaml"
    LISP = "lisp"
    SCHEME = "scheme"
    RACKET = "racket"

    # Scripting & Shell
    BASH = "bash"
    POWERSHELL = "powershell"
    LUA = "lua"
    AWK = "awk"
    SED = "sed"

    # Database & Query
    SQL = "sql"
    PLSQL = "plsql"
    GRAPHQL = "graphql"
    MONGODB = "mongodb"

    # Config & Data
    JSON = "json"
    YAML = "yaml"
    TOML = "toml"
    XML = "xml"
    MARKDOWN = "markdown"

    # Low-level & Assembly
    ASSEMBLY = "assembly"
    WEBASSEMBLY = "webassembly"
    LLVM = "llvm"

    # Smart Contracts
    SOLIDITY = "solidity"
    VYPER = "vyper"
    MOVE = "move"

    # Game Development
    GDScript = "gdscript"
    GLSL = "glsl"
    HLSL = "hlsl"

    # Legacy & Specialized
    COBOL = "cobol"
    FORTRAN = "fortran"
    PASCAL = "pascal"
    DELPHI = "delphi"
    BASIC = "basic"
    PROLOG = "prolog"

    # Modern & Emerging
    ZIG = "zig"
    NIM = "nim"
    CRYSTAL = "crystal"
    V = "v"
    MOJO = "mojo"

    # Other
    REGEX = "regex"
    LATEX = "latex"
    PSEUDOCODE = "pseudocode"


class LanguageParadigm(str, Enum):
    IMPERATIVE = "imperative"
    OBJECT_ORIENTED = "object-oriented"
    FUNCTIONAL = "functional"
    PROCEDURAL = "procedural"
    DECLARATIVE = "declarative"
    EVENT_DRIVEN = "event-driven"
    CONCURRENT = "concurrent"
    LOGIC = "logic"
    REACTIVE = "reactive"


class DifficultyLevel(str, Enum):
    BEGINNER = "beginner"
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"
    EXPERT = "expert"
    COMPETITIVE = "competitive"


class ProblemCategory(str, Enum):
    # Fundamentals
    SYNTAX = "syntax"
    VARIABLES = "variables"
    DATA_TYPES = "data-types"
    OPERATORS = "operators"
    CONTROL_FLOW = "control-flow"
    LOOPS = "loops"
    FUNCTIONS = "functions"

    # Data Structures
    ARRAYS = "arrays"
    STRINGS = "strings"
    LINKED_LISTS = "linked-lists"
    STACKS = "stacks"
    QUEUES = "queues"
    TREES = "trees"
    GRAPHS = "graphs"
    HASH_TABLES = "hash-tables"
    HEAPS = "heaps"
    TRIES = "tries"

    # Algorithms
    SORTING = "sorting"
    SEARCHING = "searching"
    RECURSION = "recursion"
    DYNAMIC_PROGRAMMING = "dynamic-programming"
    GREEDY = "greedy"
    BACKTRACKING = "backtracking"
    DIVIDE_CONQUER = "divide-and-conquer"
    BIT_MANIPULATION = "bit-manipulation"

    # Advanced
    OOP = "oop"
    DESIGN_PATTERNS = "design-patterns"
    CONCURRENCY = "concurrency"
    MEMORY_MANAGEMENT = "memory-management"
    ERROR_HANDLING = "error-handling"
    TESTING = "testing"
    OPTIMIZATION = "optimization"

    # Domain-Specific
    WEB_DEVELOPMENT = "web-development"
    DATABASE = "database"
    API_DESIGN = "api-design"
    SECURITY = "security"
    MACHINE_LEARNING = "machine-learning"
    SYSTEM_DESIGN = "system-design"


# ═══════════════════════════════════════════════════════════════════════════════
# CODE ANALYSIS MODELS
# ═══════════════════════════════════════════════════════════════════════════════

class CodeError(BaseModel):
    """Represents a code error or issue"""
    line: int
    column: Optional[int] = None
    error_type: str  # syntax, runtime, logic, style
    severity: str  # error, warning, info, hint
    message: str
    suggestion: Optional[str] = None
    code_snippet: Optional[str] = None


class CodeMetrics(BaseModel):
    """Code quality metrics"""
    lines_of_code: int
    cyclomatic_complexity: Optional[int] = None
    cognitive_complexity: Optional[int] = None
    maintainability_index: Optional[float] = None
    test_coverage: Optional[float] = None
    duplicate_lines: Optional[int] = None
    code_smells: Optional[int] = None


class ExecutionStep(BaseModel):
    """Single step in code execution trace"""
    step_number: int
    line: int
    operation: str
    variables: Dict[str, Any] = {}
    output: Optional[str] = None
    explanation: str
    visualization: Optional[str] = None  # ASCII art or diagram


class CodeAnalysisRequest(BaseModel):
    """Request for code analysis"""
    code: str
    language: ProgrammingLanguage
    analyze_errors: bool = True
    analyze_style: bool = True
    analyze_complexity: bool = True
    suggest_improvements: bool = True
    explain_code: bool = False
    trace_execution: bool = False
    user_id: Optional[str] = None


class CodeAnalysisResponse(BaseModel):
    """Response from code analysis"""
    language: ProgrammingLanguage
    language_version: Optional[str] = None
    is_valid: bool
    errors: List[CodeError] = []
    warnings: List[CodeError] = []
    suggestions: List[str] = []
    metrics: Optional[CodeMetrics] = None
    explanation: Optional[str] = None
    execution_trace: Optional[List[ExecutionStep]] = None
    improved_code: Optional[str] = None
    analysis_time_ms: float


# ═══════════════════════════════════════════════════════════════════════════════
# CODE SOLUTION MODELS
# ═══════════════════════════════════════════════════════════════════════════════

class SolutionApproach(BaseModel):
    """A single approach to solving a problem"""
    name: str
    description: str
    time_complexity: str
    space_complexity: str
    code: str
    explanation: List[str]
    pros: List[str] = []
    cons: List[str] = []


class TestCase(BaseModel):
    """Test case for code validation"""
    input: Any
    expected_output: Any
    description: Optional[str] = None
    is_edge_case: bool = False


class CodeProblem(BaseModel):
    """A coding problem/challenge"""
    id: str
    title: str
    description: str
    difficulty: DifficultyLevel
    categories: List[ProblemCategory]
    languages: List[ProgrammingLanguage]
    constraints: List[str] = []
    examples: List[Dict[str, Any]] = []
    test_cases: List[TestCase] = []
    hints: List[str] = []
    starter_code: Dict[ProgrammingLanguage, str] = {}
    created_at: datetime = Field(default_factory=datetime.utcnow)


class CodeSolution(BaseModel):
    """Complete solution to a coding problem"""
    problem_id: str
    language: ProgrammingLanguage
    approaches: List[SolutionApproach]
    best_approach: str  # name of recommended approach
    explanation: str
    common_mistakes: List[str] = []
    follow_up_questions: List[str] = []
    related_problems: List[str] = []


class SolveRequest(BaseModel):
    """Request to solve a coding problem"""
    problem: Optional[str] = None  # problem description
    code: Optional[str] = None  # user's attempt
    language: ProgrammingLanguage
    difficulty: Optional[DifficultyLevel] = None
    explain_step_by_step: bool = True
    show_multiple_approaches: bool = True
    include_complexity_analysis: bool = True
    user_id: Optional[str] = None


class SolveResponse(BaseModel):
    """Response with solution"""
    solution: CodeSolution
    user_code_feedback: Optional[str] = None
    improvements_to_user_code: Optional[str] = None
    score: Optional[int] = None  # 0-100


# ═══════════════════════════════════════════════════════════════════════════════
# CODE EXECUTION MODELS
# ═══════════════════════════════════════════════════════════════════════════════

class ExecuteRequest(BaseModel):
    """Request to execute code (sandboxed)"""
    code: str
    language: ProgrammingLanguage
    stdin: Optional[str] = None
    timeout_seconds: int = Field(default=10, le=30)
    memory_limit_mb: int = Field(default=128, le=512)


class ExecuteResponse(BaseModel):
    """Response from code execution"""
    success: bool
    stdout: Optional[str] = None
    stderr: Optional[str] = None
    exit_code: int
    execution_time_ms: float
    memory_used_mb: Optional[float] = None
    timed_out: bool = False


# ═══════════════════════════════════════════════════════════════════════════════
# LEARNING & PRACTICE MODELS
# ═══════════════════════════════════════════════════════════════════════════════

class LearningPath(BaseModel):
    """A structured learning path for a language"""
    language: ProgrammingLanguage
    title: str
    description: str
    modules: List[Dict[str, Any]]
    estimated_hours: int
    prerequisites: List[ProgrammingLanguage] = []


class PracticeRequest(BaseModel):
    """Request for practice problems"""
    language: ProgrammingLanguage
    categories: Optional[List[ProblemCategory]] = None
    difficulty: Optional[DifficultyLevel] = None
    count: int = Field(default=5, le=20)
    exclude_solved: bool = True
    user_id: Optional[str] = None


class UserProgress(BaseModel):
    """User's progress in a language"""
    user_id: str
    language: ProgrammingLanguage
    problems_solved: int
    problems_attempted: int
    current_streak: int
    best_streak: int
    skill_level: DifficultyLevel
    categories_mastered: List[ProblemCategory] = []
    weak_areas: List[ProblemCategory] = []
    total_practice_time_minutes: int
    last_practice: Optional[datetime] = None


# ═══════════════════════════════════════════════════════════════════════════════
# LANGUAGE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

class LanguageConfig(BaseModel):
    """Configuration for a programming language"""
    name: str
    display_name: str
    file_extensions: List[str]
    paradigms: List[LanguageParadigm]
    typing: str  # static, dynamic, gradual
    compiled: bool
    interpreted: bool
    garbage_collected: bool
    memory_safe: bool
    year_created: int
    creator: str
    description: str
    use_cases: List[str]
    popular_frameworks: List[str] = []
    package_manager: Optional[str] = None
    documentation_url: Optional[str] = None
    syntax_example: str
    hello_world: str
    keywords: List[str] = []
    operators: List[str] = []
    comment_syntax: Dict[str, str] = {}  # single, multi
    string_syntax: List[str] = []
    related_languages: List[str] = []
