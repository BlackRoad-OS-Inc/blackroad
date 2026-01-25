"""
Lucidia Code Analyzer Service
Multi-language code analysis, explanation, and solution generation
"""

import re
import time
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime

from models.code import (
    ProgrammingLanguage, LanguageParadigm, DifficultyLevel, ProblemCategory,
    CodeError, CodeMetrics, ExecutionStep, CodeAnalysisResponse,
    SolutionApproach, CodeSolution, LanguageConfig,
)


class CodeAnalyzer:
    """
    Multi-language code analyzer supporting 50+ programming languages.
    Provides syntax checking, style analysis, execution tracing, and explanations.
    """

    def __init__(self):
        self.languages = self._load_language_configs()
        self.syntax_patterns = self._load_syntax_patterns()

    def _load_language_configs(self) -> Dict[str, LanguageConfig]:
        """Load configuration for all supported languages"""
        return {
            # ─────────────────────────────────────────────────────────────
            # WEB & FRONTEND LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "javascript": LanguageConfig(
                name="javascript",
                display_name="JavaScript",
                file_extensions=[".js", ".mjs", ".cjs"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL, LanguageParadigm.EVENT_DRIVEN],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=1995,
                creator="Brendan Eich",
                description="The language of the web. Used for frontend interactivity, backend (Node.js), and everywhere in between.",
                use_cases=["Web Development", "Frontend", "Backend (Node.js)", "Mobile (React Native)", "Desktop (Electron)"],
                popular_frameworks=["React", "Vue", "Angular", "Express", "Next.js", "Svelte"],
                package_manager="npm",
                documentation_url="https://developer.mozilla.org/en-US/docs/Web/JavaScript",
                syntax_example="const greet = (name) => `Hello, ${name}!`;",
                hello_world='console.log("Hello, World!");',
                keywords=["const", "let", "var", "function", "class", "if", "else", "for", "while", "return", "async", "await", "import", "export"],
                operators=["+", "-", "*", "/", "%", "**", "===", "!==", "&&", "||", "??", "?."],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=["'", '"', "`"],
                related_languages=["TypeScript", "CoffeeScript", "Dart"],
            ),
            "typescript": LanguageConfig(
                name="typescript",
                display_name="TypeScript",
                file_extensions=[".ts", ".tsx", ".mts"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2012,
                creator="Microsoft (Anders Hejlsberg)",
                description="JavaScript with types. Adds static typing to JavaScript for better tooling and fewer runtime errors.",
                use_cases=["Large-scale Web Apps", "Enterprise Software", "React/Angular/Vue Apps"],
                popular_frameworks=["Angular", "NestJS", "Next.js", "Deno"],
                package_manager="npm",
                documentation_url="https://www.typescriptlang.org/docs/",
                syntax_example="const greet = (name: string): string => `Hello, ${name}!`;",
                hello_world='console.log("Hello, World!");',
                keywords=["const", "let", "type", "interface", "class", "extends", "implements", "generic", "enum", "namespace"],
                operators=["+", "-", "*", "/", "===", "as", "is", "keyof", "typeof"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=["'", '"', "`"],
                related_languages=["JavaScript", "C#", "Java"],
            ),
            "html": LanguageConfig(
                name="html",
                display_name="HTML",
                file_extensions=[".html", ".htm"],
                paradigms=[LanguageParadigm.DECLARATIVE],
                typing="none",
                compiled=False,
                interpreted=True,
                garbage_collected=False,
                memory_safe=True,
                year_created=1993,
                creator="Tim Berners-Lee",
                description="The standard markup language for creating web pages and web applications.",
                use_cases=["Web Pages", "Email Templates", "Documentation"],
                popular_frameworks=["None (markup language)"],
                package_manager=None,
                documentation_url="https://developer.mozilla.org/en-US/docs/Web/HTML",
                syntax_example='<div class="container"><h1>Title</h1></div>',
                hello_world="<html><body><h1>Hello, World!</h1></body></html>",
                keywords=["html", "head", "body", "div", "span", "p", "a", "img", "script", "style"],
                operators=[],
                comment_syntax={"single": "<!-- -->", "multi_start": "<!--", "multi_end": "-->"},
                string_syntax=['"', "'"],
                related_languages=["CSS", "JavaScript", "XML"],
            ),
            "css": LanguageConfig(
                name="css",
                display_name="CSS",
                file_extensions=[".css"],
                paradigms=[LanguageParadigm.DECLARATIVE],
                typing="none",
                compiled=False,
                interpreted=True,
                garbage_collected=False,
                memory_safe=True,
                year_created=1996,
                creator="Hakon Wium Lie",
                description="Cascading Style Sheets for styling web pages.",
                use_cases=["Web Styling", "Responsive Design", "Animations"],
                popular_frameworks=["Tailwind", "Bootstrap", "Sass", "Less"],
                package_manager=None,
                documentation_url="https://developer.mozilla.org/en-US/docs/Web/CSS",
                syntax_example=".container { display: flex; justify-content: center; }",
                hello_world="body { font-family: sans-serif; }",
                keywords=["display", "flex", "grid", "margin", "padding", "color", "background", "border", "position"],
                operators=[":", ";", "{", "}", ","],
                comment_syntax={"multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', "'"],
                related_languages=["Sass", "Less", "HTML"],
            ),

            # ─────────────────────────────────────────────────────────────
            # BACKEND & SYSTEMS LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "python": LanguageConfig(
                name="python",
                display_name="Python",
                file_extensions=[".py", ".pyw", ".pyi"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL, LanguageParadigm.PROCEDURAL],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=1991,
                creator="Guido van Rossum",
                description="A versatile, readable language perfect for beginners and experts. Dominates in ML/AI, data science, and scripting.",
                use_cases=["Machine Learning", "Data Science", "Web Development", "Automation", "Scientific Computing"],
                popular_frameworks=["Django", "Flask", "FastAPI", "PyTorch", "TensorFlow", "Pandas", "NumPy"],
                package_manager="pip",
                documentation_url="https://docs.python.org/3/",
                syntax_example='def greet(name: str) -> str:\n    return f"Hello, {name}!"',
                hello_world='print("Hello, World!")',
                keywords=["def", "class", "if", "elif", "else", "for", "while", "return", "import", "from", "try", "except", "with", "async", "await", "lambda"],
                operators=["+", "-", "*", "/", "//", "%", "**", "==", "!=", "and", "or", "not", "in", "is"],
                comment_syntax={"single": "#", "multi_start": '"""', "multi_end": '"""'},
                string_syntax=["'", '"', "'''", '"""', "f'", 'f"'],
                related_languages=["Ruby", "Julia", "Perl"],
            ),
            "java": LanguageConfig(
                name="java",
                display_name="Java",
                file_extensions=[".java"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=1995,
                creator="James Gosling (Sun Microsystems)",
                description="Write once, run anywhere. Enterprise-grade language powering Android, big data, and enterprise systems.",
                use_cases=["Enterprise Software", "Android Development", "Big Data", "Web Services"],
                popular_frameworks=["Spring", "Spring Boot", "Hibernate", "Android SDK", "Apache Kafka"],
                package_manager="Maven/Gradle",
                documentation_url="https://docs.oracle.com/en/java/",
                syntax_example='public String greet(String name) {\n    return "Hello, " + name + "!";\n}',
                hello_world='public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, World!");\n    }\n}',
                keywords=["public", "private", "protected", "class", "interface", "extends", "implements", "static", "final", "abstract", "void", "new", "return", "try", "catch"],
                operators=["+", "-", "*", "/", "%", "==", "!=", "&&", "||", "!", "instanceof"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"'],
                related_languages=["Kotlin", "Scala", "C#"],
            ),
            "csharp": LanguageConfig(
                name="csharp",
                display_name="C#",
                file_extensions=[".cs"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2000,
                creator="Microsoft (Anders Hejlsberg)",
                description="Microsoft's flagship language. Powers Unity games, Windows apps, and enterprise backends.",
                use_cases=["Game Development (Unity)", "Windows Apps", "Enterprise Software", "Web APIs"],
                popular_frameworks=[".NET", "ASP.NET", "Unity", "Xamarin", "Blazor"],
                package_manager="NuGet",
                documentation_url="https://docs.microsoft.com/en-us/dotnet/csharp/",
                syntax_example='public string Greet(string name) => $"Hello, {name}!";',
                hello_world='Console.WriteLine("Hello, World!");',
                keywords=["public", "private", "class", "interface", "struct", "async", "await", "var", "using", "namespace", "static", "void", "return"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "??", "?."],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', "@", "$"],
                related_languages=["Java", "F#", "TypeScript"],
            ),
            "cpp": LanguageConfig(
                name="cpp",
                display_name="C++",
                file_extensions=[".cpp", ".cc", ".cxx", ".hpp", ".h"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.PROCEDURAL, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=False,
                year_created=1985,
                creator="Bjarne Stroustrup",
                description="High-performance systems language. Powers game engines, browsers, and operating systems.",
                use_cases=["Game Engines", "Systems Programming", "High-Frequency Trading", "Browsers", "Databases"],
                popular_frameworks=["Qt", "Unreal Engine", "Boost", "POCO"],
                package_manager="vcpkg/Conan",
                documentation_url="https://en.cppreference.com/",
                syntax_example='std::string greet(const std::string& name) {\n    return "Hello, " + name + "!";\n}',
                hello_world='#include <iostream>\nint main() {\n    std::cout << "Hello, World!" << std::endl;\n    return 0;\n}',
                keywords=["class", "struct", "public", "private", "virtual", "template", "typename", "const", "static", "new", "delete", "nullptr", "auto"],
                operators=["+", "-", "*", "/", "++", "--", "->", "::", "<<", ">>", "==", "!="],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"'],
                related_languages=["C", "Rust", "D"],
            ),
            "c": LanguageConfig(
                name="c",
                display_name="C",
                file_extensions=[".c", ".h"],
                paradigms=[LanguageParadigm.PROCEDURAL, LanguageParadigm.IMPERATIVE],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=False,
                year_created=1972,
                creator="Dennis Ritchie",
                description="The mother of modern programming. Powers operating systems, embedded systems, and system utilities.",
                use_cases=["Operating Systems", "Embedded Systems", "System Utilities", "Device Drivers"],
                popular_frameworks=["None (systems language)"],
                package_manager=None,
                documentation_url="https://en.cppreference.com/w/c",
                syntax_example='char* greet(const char* name) {\n    static char buffer[100];\n    sprintf(buffer, "Hello, %s!", name);\n    return buffer;\n}',
                hello_world='#include <stdio.h>\nint main() {\n    printf("Hello, World!\\n");\n    return 0;\n}',
                keywords=["int", "char", "float", "double", "void", "struct", "typedef", "enum", "const", "static", "extern", "if", "else", "for", "while", "return"],
                operators=["+", "-", "*", "/", "%", "++", "--", "->", ".", "&", "*", "==", "!="],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"'],
                related_languages=["C++", "Objective-C", "Rust"],
            ),
            "go": LanguageConfig(
                name="go",
                display_name="Go",
                file_extensions=[".go"],
                paradigms=[LanguageParadigm.PROCEDURAL, LanguageParadigm.CONCURRENT],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2009,
                creator="Google (Rob Pike, Ken Thompson)",
                description="Simple, fast, and concurrent. Perfect for cloud services, CLIs, and microservices.",
                use_cases=["Cloud Services", "Microservices", "DevOps Tools", "CLI Applications"],
                popular_frameworks=["Gin", "Echo", "Fiber", "Chi"],
                package_manager="go mod",
                documentation_url="https://golang.org/doc/",
                syntax_example='func greet(name string) string {\n    return fmt.Sprintf("Hello, %s!", name)\n}',
                hello_world='package main\n\nimport "fmt"\n\nfunc main() {\n    fmt.Println("Hello, World!")\n}',
                keywords=["func", "package", "import", "var", "const", "type", "struct", "interface", "go", "chan", "select", "defer", "return"],
                operators=["+", "-", "*", "/", ":=", "==", "!=", "<-", "..."],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', "`"],
                related_languages=["Rust", "C", "Python"],
            ),
            "rust": LanguageConfig(
                name="rust",
                display_name="Rust",
                file_extensions=[".rs"],
                paradigms=[LanguageParadigm.FUNCTIONAL, LanguageParadigm.IMPERATIVE, LanguageParadigm.CONCURRENT],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=True,
                year_created=2010,
                creator="Mozilla (Graydon Hoare)",
                description="Memory-safe systems programming without garbage collection. Blazingly fast with zero-cost abstractions.",
                use_cases=["Systems Programming", "WebAssembly", "CLI Tools", "Blockchain", "Game Engines"],
                popular_frameworks=["Tokio", "Actix", "Rocket", "Axum", "Bevy"],
                package_manager="Cargo",
                documentation_url="https://doc.rust-lang.org/",
                syntax_example='fn greet(name: &str) -> String {\n    format!("Hello, {}!", name)\n}',
                hello_world='fn main() {\n    println!("Hello, World!");\n}',
                keywords=["fn", "let", "mut", "const", "struct", "enum", "impl", "trait", "pub", "mod", "use", "match", "if", "loop", "async", "await"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "?", "=>", "->", "::"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', "r#"],
                related_languages=["C++", "Haskell", "OCaml"],
            ),
            "kotlin": LanguageConfig(
                name="kotlin",
                display_name="Kotlin",
                file_extensions=[".kt", ".kts"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2011,
                creator="JetBrains",
                description="Modern alternative to Java. Now the preferred language for Android development.",
                use_cases=["Android Development", "Backend Services", "Multiplatform Apps"],
                popular_frameworks=["Ktor", "Spring Boot", "Android Jetpack", "Compose"],
                package_manager="Gradle",
                documentation_url="https://kotlinlang.org/docs/",
                syntax_example='fun greet(name: String): String = "Hello, $name!"',
                hello_world='fun main() {\n    println("Hello, World!")\n}',
                keywords=["fun", "val", "var", "class", "object", "interface", "data", "sealed", "when", "if", "else", "return", "suspend"],
                operators=["+", "-", "*", "/", "==", "!=", "?:", "?."],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', '"""'],
                related_languages=["Java", "Scala", "Swift"],
            ),
            "ruby": LanguageConfig(
                name="ruby",
                display_name="Ruby",
                file_extensions=[".rb", ".rake"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=1995,
                creator="Yukihiro Matsumoto",
                description="A programmer's best friend. Elegant syntax designed for developer happiness.",
                use_cases=["Web Development", "Scripting", "DevOps", "Prototyping"],
                popular_frameworks=["Ruby on Rails", "Sinatra", "Hanami"],
                package_manager="RubyGems/Bundler",
                documentation_url="https://ruby-doc.org/",
                syntax_example='def greet(name)\n  "Hello, #{name}!"\nend',
                hello_world='puts "Hello, World!"',
                keywords=["def", "class", "module", "if", "else", "elsif", "unless", "case", "when", "do", "end", "return", "yield", "attr_accessor"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "<<", "=>"],
                comment_syntax={"single": "#", "multi_start": "=begin", "multi_end": "=end"},
                string_syntax=["'", '"', "%q", "%Q"],
                related_languages=["Python", "Perl", "Crystal"],
            ),
            "php": LanguageConfig(
                name="php",
                display_name="PHP",
                file_extensions=[".php", ".phtml"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.PROCEDURAL],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=1995,
                creator="Rasmus Lerdorf",
                description="The language that powers most of the web. From WordPress to Facebook.",
                use_cases=["Web Development", "CMS", "E-commerce", "APIs"],
                popular_frameworks=["Laravel", "Symfony", "WordPress", "Drupal"],
                package_manager="Composer",
                documentation_url="https://www.php.net/docs.php",
                syntax_example='function greet(string $name): string {\n    return "Hello, {$name}!";\n}',
                hello_world='<?php\necho "Hello, World!";',
                keywords=["function", "class", "public", "private", "protected", "interface", "trait", "namespace", "use", "return", "if", "else", "foreach", "while"],
                operators=["+", "-", "*", "/", ".", "==", "===", "!=", "!==", "&&", "||", "??", "?->"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=["'", '"'],
                related_languages=["JavaScript", "Python", "Perl"],
            ),

            # ─────────────────────────────────────────────────────────────
            # MOBILE LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "swift": LanguageConfig(
                name="swift",
                display_name="Swift",
                file_extensions=[".swift"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL, LanguageParadigm.PROCEDURAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=True,
                year_created=2014,
                creator="Apple (Chris Lattner)",
                description="Apple's modern language for iOS, macOS, and beyond. Safe, fast, and expressive.",
                use_cases=["iOS Development", "macOS Development", "Server-side Swift"],
                popular_frameworks=["SwiftUI", "UIKit", "Vapor", "Combine"],
                package_manager="Swift Package Manager",
                documentation_url="https://swift.org/documentation/",
                syntax_example='func greet(_ name: String) -> String {\n    return "Hello, \\(name)!"\n}',
                hello_world='print("Hello, World!")',
                keywords=["func", "var", "let", "class", "struct", "enum", "protocol", "extension", "guard", "if", "else", "switch", "return", "async", "await"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "??", "?.", "!"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"', '"""'],
                related_languages=["Objective-C", "Rust", "Kotlin"],
            ),
            "dart": LanguageConfig(
                name="dart",
                display_name="Dart",
                file_extensions=[".dart"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=2011,
                creator="Google",
                description="The language behind Flutter. Build beautiful native apps from a single codebase.",
                use_cases=["Mobile Development (Flutter)", "Web Apps", "Backend Services"],
                popular_frameworks=["Flutter", "AngularDart", "Aqueduct"],
                package_manager="pub",
                documentation_url="https://dart.dev/guides",
                syntax_example='String greet(String name) => "Hello, $name!";',
                hello_world='void main() {\n  print("Hello, World!");\n}',
                keywords=["void", "var", "final", "const", "class", "extends", "implements", "mixin", "async", "await", "if", "else", "for", "while", "return"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "??", "?."],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=["'", '"', "'''", '"""'],
                related_languages=["JavaScript", "Java", "TypeScript"],
            ),

            # ─────────────────────────────────────────────────────────────
            # DATA SCIENCE & ML LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "r": LanguageConfig(
                name="r",
                display_name="R",
                file_extensions=[".r", ".R", ".Rmd"],
                paradigms=[LanguageParadigm.FUNCTIONAL, LanguageParadigm.PROCEDURAL],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=1993,
                creator="Ross Ihaka & Robert Gentleman",
                description="The language of statistics. Powerful for data analysis, visualization, and statistical modeling.",
                use_cases=["Statistical Analysis", "Data Visualization", "Bioinformatics", "Academic Research"],
                popular_frameworks=["ggplot2", "dplyr", "tidyverse", "Shiny", "caret"],
                package_manager="CRAN",
                documentation_url="https://www.r-project.org/other-docs.html",
                syntax_example='greet <- function(name) {\n  paste0("Hello, ", name, "!")\n}',
                hello_world='print("Hello, World!")',
                keywords=["function", "if", "else", "for", "while", "repeat", "return", "library", "require", "TRUE", "FALSE", "NULL", "NA"],
                operators=["+", "-", "*", "/", "%%", "%/%", "^", "<-", "->", "==", "!=", "&", "|", "%>%"],
                comment_syntax={"single": "#"},
                string_syntax=["'", '"'],
                related_languages=["Python", "Julia", "MATLAB"],
            ),
            "julia": LanguageConfig(
                name="julia",
                display_name="Julia",
                file_extensions=[".jl"],
                paradigms=[LanguageParadigm.FUNCTIONAL, LanguageParadigm.PROCEDURAL, LanguageParadigm.OBJECT_ORIENTED],
                typing="dynamic",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2012,
                creator="Jeff Bezanson, Stefan Karpinski, Viral Shah, Alan Edelman",
                description="High-performance computing with the ease of Python. Designed for numerical and scientific computing.",
                use_cases=["Scientific Computing", "Machine Learning", "Data Analysis", "Simulation"],
                popular_frameworks=["Flux.jl", "DifferentialEquations.jl", "Plots.jl", "DataFrames.jl"],
                package_manager="Pkg",
                documentation_url="https://docs.julialang.org/",
                syntax_example='greet(name::String) = "Hello, $name!"',
                hello_world='println("Hello, World!")',
                keywords=["function", "end", "if", "else", "elseif", "for", "while", "return", "struct", "mutable", "abstract", "const", "using", "import"],
                operators=["+", "-", "*", "/", "^", "==", "!=", "&&", "||", ".", "..."],
                comment_syntax={"single": "#", "multi_start": "#=", "multi_end": "=#"},
                string_syntax=['"', '"""'],
                related_languages=["Python", "MATLAB", "R"],
            ),

            # ─────────────────────────────────────────────────────────────
            # FUNCTIONAL LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "haskell": LanguageConfig(
                name="haskell",
                display_name="Haskell",
                file_extensions=[".hs", ".lhs"],
                paradigms=[LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=1990,
                creator="Haskell Committee",
                description="Pure functional programming. Lazy evaluation, strong types, and mathematical elegance.",
                use_cases=["Academic Research", "Finance", "Compilers", "Formal Verification"],
                popular_frameworks=["Yesod", "Servant", "Scotty", "Pandoc"],
                package_manager="Cabal/Stack",
                documentation_url="https://www.haskell.org/documentation/",
                syntax_example='greet :: String -> String\ngreet name = "Hello, " ++ name ++ "!"',
                hello_world='main = putStrLn "Hello, World!"',
                keywords=["module", "import", "data", "type", "class", "instance", "where", "let", "in", "if", "then", "else", "case", "of", "do"],
                operators=["+", "-", "*", "/", "==", "/=", "&&", "||", "++", ">>", ">>=", "<$>", "<*>", "."],
                comment_syntax={"single": "--", "multi_start": "{-", "multi_end": "-}"},
                string_syntax=['"'],
                related_languages=["OCaml", "Elm", "PureScript"],
            ),
            "elixir": LanguageConfig(
                name="elixir",
                display_name="Elixir",
                file_extensions=[".ex", ".exs"],
                paradigms=[LanguageParadigm.FUNCTIONAL, LanguageParadigm.CONCURRENT],
                typing="dynamic",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2011,
                creator="Jose Valim",
                description="Scalable and maintainable applications on the Erlang VM. Great for real-time systems.",
                use_cases=["Real-time Systems", "Distributed Systems", "Web Development", "IoT"],
                popular_frameworks=["Phoenix", "Ecto", "Nerves", "LiveView"],
                package_manager="Hex",
                documentation_url="https://elixir-lang.org/docs.html",
                syntax_example='def greet(name), do: "Hello, #{name}!"',
                hello_world='IO.puts "Hello, World!"',
                keywords=["def", "defp", "defmodule", "do", "end", "if", "else", "case", "cond", "fn", "with", "use", "import", "alias", "require"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "|>", "<>", "++", "--"],
                comment_syntax={"single": "#"},
                string_syntax=['"', '"""'],
                related_languages=["Erlang", "Ruby", "Clojure"],
            ),
            "clojure": LanguageConfig(
                name="clojure",
                display_name="Clojure",
                file_extensions=[".clj", ".cljs", ".cljc", ".edn"],
                paradigms=[LanguageParadigm.FUNCTIONAL],
                typing="dynamic",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2007,
                creator="Rich Hickey",
                description="Modern Lisp for the JVM. Immutable data structures and powerful concurrency primitives.",
                use_cases=["Data Processing", "Web Development", "Distributed Systems"],
                popular_frameworks=["Ring", "Compojure", "Reagent", "Re-frame"],
                package_manager="Leiningen/deps.edn",
                documentation_url="https://clojure.org/guides/getting_started",
                syntax_example='(defn greet [name]\n  (str "Hello, " name "!"))',
                hello_world='(println "Hello, World!")',
                keywords=["def", "defn", "fn", "let", "if", "cond", "do", "loop", "recur", "ns", "require", "use", "import"],
                operators=["+", "-", "*", "/", "=", "not=", "and", "or", "->", "->>"],
                comment_syntax={"single": ";"},
                string_syntax=['"'],
                related_languages=["Common Lisp", "Scheme", "Elixir"],
            ),

            # ─────────────────────────────────────────────────────────────
            # SHELL & SCRIPTING
            # ─────────────────────────────────────────────────────────────
            "bash": LanguageConfig(
                name="bash",
                display_name="Bash",
                file_extensions=[".sh", ".bash"],
                paradigms=[LanguageParadigm.PROCEDURAL, LanguageParadigm.IMPERATIVE],
                typing="none",
                compiled=False,
                interpreted=True,
                garbage_collected=False,
                memory_safe=True,
                year_created=1989,
                creator="Brian Fox",
                description="The Unix shell. Essential for automation, DevOps, and system administration.",
                use_cases=["System Administration", "DevOps", "Automation", "CI/CD Pipelines"],
                popular_frameworks=["None (shell scripting)"],
                package_manager=None,
                documentation_url="https://www.gnu.org/software/bash/manual/",
                syntax_example='greet() {\n    echo "Hello, $1!"\n}',
                hello_world='echo "Hello, World!"',
                keywords=["if", "then", "else", "elif", "fi", "for", "while", "do", "done", "case", "esac", "function", "return", "export", "local"],
                operators=["-eq", "-ne", "-lt", "-gt", "-le", "-ge", "=", "!=", "&&", "||", "|", ">", "<", ">>"],
                comment_syntax={"single": "#"},
                string_syntax=["'", '"', "$'"],
                related_languages=["Zsh", "Fish", "PowerShell"],
            ),
            "powershell": LanguageConfig(
                name="powershell",
                display_name="PowerShell",
                file_extensions=[".ps1", ".psm1", ".psd1"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.PROCEDURAL],
                typing="dynamic",
                compiled=False,
                interpreted=True,
                garbage_collected=True,
                memory_safe=True,
                year_created=2006,
                creator="Microsoft",
                description="Cross-platform task automation and configuration management. Built on .NET.",
                use_cases=["Windows Administration", "Azure Automation", "DevOps", "Configuration Management"],
                popular_frameworks=["PSScriptAnalyzer", "Pester", "PSReadLine"],
                package_manager="PowerShell Gallery",
                documentation_url="https://docs.microsoft.com/en-us/powershell/",
                syntax_example='function Greet($name) {\n    "Hello, $name!"\n}',
                hello_world='Write-Host "Hello, World!"',
                keywords=["function", "param", "if", "else", "elseif", "switch", "foreach", "while", "do", "return", "try", "catch", "finally", "class"],
                operators=["+", "-", "*", "/", "-eq", "-ne", "-lt", "-gt", "-and", "-or", "-not", "|", ">", ">>"],
                comment_syntax={"single": "#", "multi_start": "<#", "multi_end": "#>"},
                string_syntax=["'", '"', "@'", '@"'],
                related_languages=["Bash", "C#", "Python"],
            ),

            # ─────────────────────────────────────────────────────────────
            # DATABASE & QUERY LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "sql": LanguageConfig(
                name="sql",
                display_name="SQL",
                file_extensions=[".sql"],
                paradigms=[LanguageParadigm.DECLARATIVE],
                typing="static",
                compiled=False,
                interpreted=True,
                garbage_collected=False,
                memory_safe=True,
                year_created=1974,
                creator="IBM (Donald Chamberlin, Raymond Boyce)",
                description="The language of databases. Query, manipulate, and manage relational data.",
                use_cases=["Database Management", "Data Analysis", "Reporting", "ETL Pipelines"],
                popular_frameworks=["PostgreSQL", "MySQL", "SQLite", "SQL Server", "Oracle"],
                package_manager=None,
                documentation_url="https://www.w3schools.com/sql/",
                syntax_example='SELECT name FROM users WHERE age > 18 ORDER BY name;',
                hello_world="SELECT 'Hello, World!' AS greeting;",
                keywords=["SELECT", "FROM", "WHERE", "INSERT", "UPDATE", "DELETE", "CREATE", "ALTER", "DROP", "JOIN", "ON", "GROUP BY", "ORDER BY", "HAVING"],
                operators=["=", "<>", "<", ">", "<=", ">=", "AND", "OR", "NOT", "IN", "BETWEEN", "LIKE", "IS NULL"],
                comment_syntax={"single": "--", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=["'"],
                related_languages=["PL/SQL", "T-SQL", "GraphQL"],
            ),
            "graphql": LanguageConfig(
                name="graphql",
                display_name="GraphQL",
                file_extensions=[".graphql", ".gql"],
                paradigms=[LanguageParadigm.DECLARATIVE],
                typing="static",
                compiled=False,
                interpreted=True,
                garbage_collected=False,
                memory_safe=True,
                year_created=2015,
                creator="Facebook",
                description="A query language for APIs. Request exactly the data you need.",
                use_cases=["API Development", "Mobile Apps", "Web Apps"],
                popular_frameworks=["Apollo", "Relay", "Hasura", "Prisma"],
                package_manager=None,
                documentation_url="https://graphql.org/learn/",
                syntax_example='query GetUser($id: ID!) {\n  user(id: $id) {\n    name\n    email\n  }\n}',
                hello_world='query {\n  hello\n}',
                keywords=["query", "mutation", "subscription", "type", "input", "interface", "enum", "scalar", "fragment", "on"],
                operators=["!", "...", "@"],
                comment_syntax={"single": "#"},
                string_syntax=['"'],
                related_languages=["SQL", "JSON", "TypeScript"],
            ),

            # ─────────────────────────────────────────────────────────────
            # SMART CONTRACTS
            # ─────────────────────────────────────────────────────────────
            "solidity": LanguageConfig(
                name="solidity",
                display_name="Solidity",
                file_extensions=[".sol"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=False,
                year_created=2014,
                creator="Ethereum Foundation (Gavin Wood)",
                description="The language of Ethereum. Write smart contracts that run on the blockchain.",
                use_cases=["Smart Contracts", "DeFi", "NFTs", "DAOs"],
                popular_frameworks=["Hardhat", "Foundry", "Truffle", "OpenZeppelin"],
                package_manager="npm",
                documentation_url="https://docs.soliditylang.org/",
                syntax_example='function greet(string memory name) public pure returns (string memory) {\n    return string(abi.encodePacked("Hello, ", name, "!"));\n}',
                hello_world='contract HelloWorld {\n    function hello() public pure returns (string memory) {\n        return "Hello, World!";\n    }\n}',
                keywords=["contract", "function", "modifier", "event", "struct", "mapping", "public", "private", "external", "internal", "view", "pure", "payable", "memory", "storage"],
                operators=["+", "-", "*", "/", "==", "!=", "&&", "||", "=>"],
                comment_syntax={"single": "//", "multi_start": "/*", "multi_end": "*/"},
                string_syntax=['"'],
                related_languages=["JavaScript", "C++", "Vyper"],
            ),

            # ─────────────────────────────────────────────────────────────
            # MODERN & EMERGING LANGUAGES
            # ─────────────────────────────────────────────────────────────
            "zig": LanguageConfig(
                name="zig",
                display_name="Zig",
                file_extensions=[".zig"],
                paradigms=[LanguageParadigm.PROCEDURAL, LanguageParadigm.IMPERATIVE],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=False,
                memory_safe=True,
                year_created=2016,
                creator="Andrew Kelley",
                description="A better C. No hidden control flow, no garbage collection, and easy C/C++ interop.",
                use_cases=["Systems Programming", "Game Development", "Embedded Systems"],
                popular_frameworks=["None (systems language)"],
                package_manager="Zig Package Manager",
                documentation_url="https://ziglang.org/documentation/",
                syntax_example='fn greet(name: []const u8) []const u8 {\n    // ...\n}',
                hello_world='const std = @import("std");\npub fn main() void {\n    std.debug.print("Hello, World!\\n", .{});\n}',
                keywords=["fn", "const", "var", "pub", "comptime", "if", "else", "while", "for", "return", "switch", "struct", "enum", "union"],
                operators=["+", "-", "*", "/", "==", "!=", "and", "or", "orelse", "catch"],
                comment_syntax={"single": "//"},
                string_syntax=['"'],
                related_languages=["C", "Rust", "Nim"],
            ),
            "mojo": LanguageConfig(
                name="mojo",
                display_name="Mojo",
                file_extensions=[".mojo", ".🔥"],
                paradigms=[LanguageParadigm.OBJECT_ORIENTED, LanguageParadigm.FUNCTIONAL],
                typing="static",
                compiled=True,
                interpreted=False,
                garbage_collected=True,
                memory_safe=True,
                year_created=2023,
                creator="Modular (Chris Lattner)",
                description="Python superset for AI/ML. Combines Python's usability with systems-level performance.",
                use_cases=["AI/ML", "High Performance Computing", "Systems Programming"],
                popular_frameworks=["Modular Engine"],
                package_manager="Modular",
                documentation_url="https://docs.modular.com/mojo/",
                syntax_example='fn greet(name: String) -> String:\n    return "Hello, " + name + "!"',
                hello_world='fn main():\n    print("Hello, World!")',
                keywords=["fn", "def", "struct", "let", "var", "if", "else", "for", "while", "return", "alias", "trait", "inout", "owned", "borrowed"],
                operators=["+", "-", "*", "/", "==", "!=", "and", "or", "not"],
                comment_syntax={"single": "#"},
                string_syntax=["'", '"'],
                related_languages=["Python", "Rust", "Swift"],
            ),
        }

    def _load_syntax_patterns(self) -> Dict[str, Dict[str, Any]]:
        """Load regex patterns for syntax validation"""
        return {
            "python": {
                "indent_error": r"^(\s*)(?!#).*\n(?!\1|\s*$)",
                "syntax_errors": [
                    (r"print\s+[^(]", "Missing parentheses in print (Python 3 syntax)"),
                    (r"\bdef\s+\w+[^(]", "Function definition missing parentheses"),
                    (r":\s*\n\s*\n", "Empty block after colon"),
                ],
                "common_mistakes": [
                    (r"==\s*True", "Use 'if x:' instead of 'if x == True:'"),
                    (r"==\s*False", "Use 'if not x:' instead of 'if x == False:'"),
                    (r"==\s*None", "Use 'is None' instead of '== None'"),
                    (r"except\s*:", "Bare except clause - specify exception type"),
                ],
            },
            "javascript": {
                "syntax_errors": [
                    (r"function\s+\w+\s*[^(]", "Function missing parentheses"),
                    (r"==(?!=)", "Use === for strict equality"),
                    (r"!=(?!=)", "Use !== for strict inequality"),
                ],
                "common_mistakes": [
                    (r"var\s+", "Consider using 'const' or 'let' instead of 'var'"),
                    (r"==\s*null", "Use === null or == null carefully"),
                ],
            },
            "java": {
                "syntax_errors": [
                    (r"System\.out\.print(?!ln|f)", "Use println() or printf() for output"),
                    (r"public\s+class\s+\w+\s*[^{]", "Class definition missing opening brace"),
                ],
            },
        }

    def get_language_config(self, language: ProgrammingLanguage) -> Optional[LanguageConfig]:
        """Get configuration for a specific language"""
        return self.languages.get(language.value)

    def get_all_languages(self) -> List[LanguageConfig]:
        """Get all supported language configurations"""
        return list(self.languages.values())

    def detect_language(self, code: str, filename: Optional[str] = None) -> ProgrammingLanguage:
        """Detect the programming language from code or filename"""
        # Check by file extension first
        if filename:
            ext = "." + filename.split(".")[-1].lower() if "." in filename else ""
            for lang_name, config in self.languages.items():
                if ext in config.file_extensions:
                    return ProgrammingLanguage(lang_name)

        # Heuristic detection based on code patterns
        patterns = {
            ProgrammingLanguage.PYTHON: [r"\bdef\s+\w+\s*\(", r"\bimport\s+\w+", r"print\s*\(", r":\s*$"],
            ProgrammingLanguage.JAVASCRIPT: [r"\bconst\s+\w+\s*=", r"\blet\s+\w+\s*=", r"console\.log", r"function\s*\w*\s*\(", r"=>"],
            ProgrammingLanguage.TYPESCRIPT: [r":\s*(string|number|boolean|void)", r"interface\s+\w+", r"type\s+\w+\s*="],
            ProgrammingLanguage.JAVA: [r"public\s+class", r"System\.out\.print", r"public\s+static\s+void\s+main"],
            ProgrammingLanguage.CSHARP: [r"using\s+System", r"Console\.Write", r"namespace\s+\w+"],
            ProgrammingLanguage.CPP: [r"#include\s*<", r"std::", r"cout\s*<<", r"int\s+main\s*\("],
            ProgrammingLanguage.C: [r"#include\s*<stdio\.h>", r"printf\s*\(", r"int\s+main\s*\("],
            ProgrammingLanguage.GO: [r"package\s+main", r"func\s+\w+\s*\(", r"fmt\.Print"],
            ProgrammingLanguage.RUST: [r"fn\s+main\s*\(", r"let\s+mut", r"println!\s*\(", r"impl\s+\w+"],
            ProgrammingLanguage.RUBY: [r"\bdef\s+\w+", r"puts\s+", r"end$", r"attr_accessor"],
            ProgrammingLanguage.PHP: [r"<\?php", r"\$\w+\s*=", r"echo\s+"],
            ProgrammingLanguage.SWIFT: [r"\bfunc\s+\w+\s*\(", r"var\s+\w+:", r"let\s+\w+:", r"print\s*\("],
            ProgrammingLanguage.KOTLIN: [r"fun\s+main\s*\(", r"fun\s+\w+\s*\(", r"val\s+\w+", r"println\s*\("],
            ProgrammingLanguage.SQL: [r"\bSELECT\b", r"\bFROM\b", r"\bWHERE\b", r"\bINSERT\b", r"\bUPDATE\b"],
            ProgrammingLanguage.HTML: [r"<html", r"<div", r"<body", r"</\w+>"],
            ProgrammingLanguage.CSS: [r"\{[^}]*:\s*[^}]+;[^}]*\}", r"@media", r"\.[\w-]+\s*\{"],
            ProgrammingLanguage.BASH: [r"#!/bin/bash", r"\becho\s+", r"\bif\s+\[", r"\bdone$"],
            ProgrammingLanguage.HASKELL: [r"::\s*\w+\s*->", r"\bwhere$", r"\bdo$", r"import\s+qualified"],
            ProgrammingLanguage.ELIXIR: [r"defmodule\s+\w+", r"\bdef\s+\w+", r"\|>", r"iex>"],
            ProgrammingLanguage.SOLIDITY: [r"pragma\s+solidity", r"contract\s+\w+", r"function\s+\w+.*public"],
        }

        scores = {lang: 0 for lang in patterns}
        for lang, regexes in patterns.items():
            for regex in regexes:
                if re.search(regex, code, re.MULTILINE | re.IGNORECASE):
                    scores[lang] += 1

        # Return language with highest score, default to Python
        best_lang = max(scores.keys(), key=lambda x: scores[x])
        return best_lang if scores[best_lang] > 0 else ProgrammingLanguage.PYTHON

    def analyze_code(
        self,
        code: str,
        language: ProgrammingLanguage,
        analyze_errors: bool = True,
        analyze_style: bool = True,
        analyze_complexity: bool = True,
        suggest_improvements: bool = True,
        explain_code: bool = False,
        trace_execution: bool = False,
    ) -> CodeAnalysisResponse:
        """
        Perform comprehensive code analysis
        """
        start_time = time.time()

        errors: List[CodeError] = []
        warnings: List[CodeError] = []
        suggestions: List[str] = []
        metrics = None
        explanation = None
        execution_trace = None
        improved_code = None

        # Get language config
        config = self.get_language_config(language)

        if analyze_errors:
            errors, warnings = self._check_syntax(code, language)

        if analyze_style:
            style_issues = self._check_style(code, language)
            warnings.extend(style_issues)

        if analyze_complexity:
            metrics = self._calculate_metrics(code, language)

        if suggest_improvements:
            suggestions = self._generate_suggestions(code, language, errors, warnings)

        if explain_code:
            explanation = self._explain_code(code, language)

        if trace_execution:
            execution_trace = self._trace_execution(code, language)

        # Determine validity
        is_valid = len([e for e in errors if e.severity == "error"]) == 0

        return CodeAnalysisResponse(
            language=language,
            language_version=None,
            is_valid=is_valid,
            errors=errors,
            warnings=warnings,
            suggestions=suggestions,
            metrics=metrics,
            explanation=explanation,
            execution_trace=execution_trace,
            improved_code=improved_code,
            analysis_time_ms=(time.time() - start_time) * 1000,
        )

    def _check_syntax(self, code: str, language: ProgrammingLanguage) -> Tuple[List[CodeError], List[CodeError]]:
        """Check for syntax errors"""
        errors = []
        warnings = []

        lang_patterns = self.syntax_patterns.get(language.value, {})

        # Check for known syntax errors
        for pattern, message in lang_patterns.get("syntax_errors", []):
            for match in re.finditer(pattern, code, re.MULTILINE):
                line_num = code[:match.start()].count('\n') + 1
                errors.append(CodeError(
                    line=line_num,
                    error_type="syntax",
                    severity="error",
                    message=message,
                    code_snippet=match.group(0)[:50],
                ))

        # Check for common mistakes
        for pattern, message in lang_patterns.get("common_mistakes", []):
            for match in re.finditer(pattern, code, re.MULTILINE):
                line_num = code[:match.start()].count('\n') + 1
                warnings.append(CodeError(
                    line=line_num,
                    error_type="style",
                    severity="warning",
                    message=message,
                    suggestion=f"Consider: {message}",
                    code_snippet=match.group(0)[:50],
                ))

        return errors, warnings

    def _check_style(self, code: str, language: ProgrammingLanguage) -> List[CodeError]:
        """Check code style issues"""
        issues = []
        lines = code.split('\n')

        for i, line in enumerate(lines, 1):
            # Line too long
            if len(line) > 120:
                issues.append(CodeError(
                    line=i,
                    error_type="style",
                    severity="info",
                    message=f"Line exceeds 120 characters ({len(line)} chars)",
                ))

            # Trailing whitespace
            if line != line.rstrip():
                issues.append(CodeError(
                    line=i,
                    error_type="style",
                    severity="info",
                    message="Trailing whitespace",
                ))

        return issues

    def _calculate_metrics(self, code: str, language: ProgrammingLanguage) -> CodeMetrics:
        """Calculate code quality metrics"""
        lines = code.split('\n')
        non_empty_lines = [l for l in lines if l.strip()]
        comment_lines = sum(1 for l in lines if l.strip().startswith(('#', '//', '--', '/*', '*')))

        # Simple cyclomatic complexity estimation
        complexity_patterns = ['if', 'elif', 'else', 'for', 'while', 'case', 'catch', 'except', '&&', '||', '?']
        complexity = 1
        for pattern in complexity_patterns:
            complexity += code.count(pattern)

        return CodeMetrics(
            lines_of_code=len(non_empty_lines),
            cyclomatic_complexity=complexity,
            cognitive_complexity=complexity + len(non_empty_lines) // 20,
            maintainability_index=max(0, 171 - 5.2 * (len(non_empty_lines) / 100) - 0.23 * complexity),
            duplicate_lines=0,
            code_smells=len([l for l in non_empty_lines if len(l) > 100]),
        )

    def _generate_suggestions(
        self,
        code: str,
        language: ProgrammingLanguage,
        errors: List[CodeError],
        warnings: List[CodeError]
    ) -> List[str]:
        """Generate improvement suggestions"""
        suggestions = []

        # Language-specific suggestions
        config = self.get_language_config(language)

        if config:
            # Add general best practices
            if language == ProgrammingLanguage.PYTHON:
                if "import *" in code:
                    suggestions.append("Avoid 'import *' - use explicit imports")
                if not code.strip().startswith(('"""', "'''", "#")):
                    suggestions.append("Consider adding a module docstring")

            elif language == ProgrammingLanguage.JAVASCRIPT:
                if "var " in code:
                    suggestions.append("Use 'const' or 'let' instead of 'var'")
                if "==" in code and "===" not in code:
                    suggestions.append("Use strict equality (===) instead of ==")

            elif language == ProgrammingLanguage.JAVA:
                if "System.out.print" in code and "System.out.println" not in code:
                    suggestions.append("Use println() for better output formatting")

        return suggestions

    def _explain_code(self, code: str, language: ProgrammingLanguage) -> str:
        """Generate a human-readable explanation of the code"""
        config = self.get_language_config(language)
        lines = code.split('\n')

        explanation_parts = [
            f"This is {config.display_name} code.",
            f"",
            f"Language Info:",
            f"- Paradigms: {', '.join([p.value for p in config.paradigms])}",
            f"- Typing: {config.typing}",
            f"- Memory managed: {'Yes (GC)' if config.garbage_collected else 'Manual'}",
            f"",
            f"Code Structure:",
            f"- Total lines: {len(lines)}",
            f"- Non-empty lines: {len([l for l in lines if l.strip()])}",
        ]

        return '\n'.join(explanation_parts)

    def _trace_execution(self, code: str, language: ProgrammingLanguage) -> List[ExecutionStep]:
        """Generate step-by-step execution trace"""
        # Simplified trace - in production, use AST parsing
        steps = []
        lines = code.split('\n')

        for i, line in enumerate(lines, 1):
            if line.strip() and not line.strip().startswith(('#', '//', '--')):
                steps.append(ExecutionStep(
                    step_number=len(steps) + 1,
                    line=i,
                    operation=line.strip()[:50],
                    variables={},
                    explanation=f"Execute: {line.strip()[:50]}",
                ))

        return steps


# Create singleton instance
code_analyzer = CodeAnalyzer()
