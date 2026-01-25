#!/usr/bin/env python3
"""
BlackRoad Codex - Symbolic Computation Engine
Symbolic math, algebraic manipulation, and equation solving for code analysis.
"""

import sqlite3
import re
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple, Any
from dataclasses import dataclass
from enum import Enum
import json

class SymbolicDomain(Enum):
    """Mathematical domains for symbolic computation."""
    ALGEBRA = "algebra"
    CALCULUS = "calculus"
    LINEAR_ALGEBRA = "linear_algebra"
    DIFFERENTIAL_EQUATIONS = "differential_equations"
    DISCRETE_MATH = "discrete_math"
    NUMBER_THEORY = "number_theory"
    GEOMETRY = "geometry"
    LOGIC = "logic"

@dataclass
class SymbolicExpression:
    """Representation of a symbolic expression."""
    expr_id: str
    original: str
    normalized: str
    domain: SymbolicDomain
    variables: Set[str]
    operators: List[str]
    properties: Dict[str, bool]  # commutative, associative, distributive, etc.
    simplified: Optional[str] = None
    latex: Optional[str] = None

@dataclass
class EquationSystem:
    """System of equations extracted from code."""
    system_id: str
    equations: List[str]
    variables: Set[str]
    constraints: List[str]
    solution_method: Optional[str] = None
    solved: bool = False
    solutions: Optional[Dict[str, str]] = None

class SymbolicComputationEngine:
    """Symbolic computation engine for the Codex."""

    def __init__(self, codex_path: str = "~/blackroad-codex"):
        self.codex_path = Path(codex_path).expanduser()
        self.db_path = self.codex_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Codex not found at {self.db_path}")

        self.init_symbolic_tables()

        # Operator precedence
        self.precedence = {
            '**': 4, '^': 4,
            '*': 3, '/': 3, '%': 3,
            '+': 2, '-': 2,
            '==': 1, '!=': 1, '<': 1, '>': 1, '<=': 1, '>=': 1
        }

    def init_symbolic_tables(self):
        """Initialize database tables for symbolic computation."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Symbolic expressions table (enhanced version of existing table)
        # Check if table exists with old schema
        cursor.execute("""
            SELECT name FROM sqlite_master
            WHERE type='table' AND name='symbolic_expressions'
        """)

        if not cursor.fetchone():
            # Create new table
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS symbolic_expressions (
                    id TEXT PRIMARY KEY,
                    component_id TEXT,
                    original TEXT,
                    normalized TEXT,
                    domain TEXT,
                    variables TEXT,  -- JSON array
                    operators TEXT,  -- JSON array
                    properties TEXT,  -- JSON object
                    simplified TEXT,
                    latex TEXT,
                    FOREIGN KEY (component_id) REFERENCES components(id)
                )
            """)
        else:
            # Add missing columns if table exists
            try:
                cursor.execute("ALTER TABLE symbolic_expressions ADD COLUMN original TEXT")
            except:
                pass
            try:
                cursor.execute("ALTER TABLE symbolic_expressions ADD COLUMN normalized TEXT")
            except:
                pass
            try:
                cursor.execute("ALTER TABLE symbolic_expressions ADD COLUMN operators TEXT")
            except:
                pass
            try:
                cursor.execute("ALTER TABLE symbolic_expressions ADD COLUMN latex TEXT")
            except:
                pass

        # Equation systems table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS equation_systems (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                equations TEXT,  -- JSON array
                variables TEXT,  -- JSON array
                constraints TEXT,  -- JSON array
                solution_method TEXT,
                solved BOOLEAN DEFAULT 0,
                solutions TEXT,  -- JSON object
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Mathematical identities table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS math_identities (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                name TEXT,
                lhs TEXT,
                rhs TEXT,
                domain TEXT,
                conditions TEXT  -- JSON (when identity holds)
            )
        """)

        # Transformation rules table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS transformation_rules (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                rule_name TEXT,
                pattern TEXT,
                replacement TEXT,
                domain TEXT,
                reversible BOOLEAN
            )
        """)

        # Populate standard identities
        self._populate_standard_identities(cursor)

        conn.commit()
        conn.close()

    def _populate_standard_identities(self, cursor):
        """Populate database with standard mathematical identities."""
        identities = [
            # Algebra
            ("Commutative (add)", "a + b", "b + a", "algebra", "{}"),
            ("Commutative (mult)", "a * b", "b * a", "algebra", "{}"),
            ("Associative (add)", "(a + b) + c", "a + (b + c)", "algebra", "{}"),
            ("Associative (mult)", "(a * b) * c", "a * (b * c)", "algebra", "{}"),
            ("Distributive", "a * (b + c)", "a * b + a * c", "algebra", "{}"),
            ("Identity (add)", "a + 0", "a", "algebra", "{}"),
            ("Identity (mult)", "a * 1", "a", "algebra", "{}"),
            ("Zero property", "a * 0", "0", "algebra", "{}"),

            # Exponents
            ("Product rule", "a^m * a^n", "a^(m+n)", "algebra", "{}"),
            ("Quotient rule", "a^m / a^n", "a^(m-n)", "algebra", '{"a": "!= 0"}'),
            ("Power rule", "(a^m)^n", "a^(m*n)", "algebra", "{}"),

            # Trigonometry
            ("Pythagorean", "sin(x)^2 + cos(x)^2", "1", "calculus", "{}"),
            ("Double angle (sin)", "sin(2*x)", "2*sin(x)*cos(x)", "calculus", "{}"),
            ("Double angle (cos)", "cos(2*x)", "cos(x)^2 - sin(x)^2", "calculus", "{}"),

            # Calculus
            ("Power rule (deriv)", "d/dx(x^n)", "n*x^(n-1)", "calculus", "{}"),
            ("Sum rule (deriv)", "d/dx(f + g)", "d/dx(f) + d/dx(g)", "calculus", "{}"),
            ("Product rule (deriv)", "d/dx(f*g)", "f*d/dx(g) + g*d/dx(f)", "calculus", "{}"),

            # Logic
            ("De Morgan 1", "not (A and B)", "(not A) or (not B)", "logic", "{}"),
            ("De Morgan 2", "not (A or B)", "(not A) and (not B)", "logic", "{}"),
        ]

        for name, lhs, rhs, domain, conditions in identities:
            try:
                cursor.execute("""
                    INSERT OR IGNORE INTO math_identities (name, lhs, rhs, domain, conditions)
                    VALUES (?, ?, ?, ?, ?)
                """, (name, lhs, rhs, domain, conditions))
            except:
                pass

    # ========== EXPRESSION PARSING & NORMALIZATION ==========

    def parse_expression(self, expr: str, component_id: str) -> SymbolicExpression:
        """Parse and analyze a symbolic expression."""
        # Normalize whitespace
        expr = ' '.join(expr.split())

        # Extract variables
        variables = self._extract_variables(expr)

        # Extract operators
        operators = self._extract_operators(expr)

        # Infer domain
        domain = self._infer_symbolic_domain(expr, variables, operators)

        # Normalize expression
        normalized = self._normalize_expression(expr)

        # Detect properties
        properties = self._detect_properties(expr, variables, operators)

        # Generate expression ID
        expr_id = hashlib.md5(f"{component_id}:{normalized}".encode()).hexdigest()[:16]

        # Try to simplify
        simplified = self._simplify_expression(normalized)

        # Generate LaTeX
        latex = self._to_latex(normalized)

        return SymbolicExpression(
            expr_id=expr_id,
            original=expr,
            normalized=normalized,
            domain=domain,
            variables=variables,
            operators=operators,
            properties=properties,
            simplified=simplified,
            latex=latex
        )

    def _extract_variables(self, expr: str) -> Set[str]:
        """Extract variable names from expression."""
        # Match identifiers (letters followed by optional letters/numbers/underscores)
        pattern = r'\b[a-zA-Z_][a-zA-Z0-9_]*\b'
        matches = re.findall(pattern, expr)

        # Filter out known functions and constants
        reserved = {'sin', 'cos', 'tan', 'exp', 'log', 'sqrt', 'abs',
                   'min', 'max', 'sum', 'pi', 'e', 'True', 'False',
                   'and', 'or', 'not', 'if', 'else', 'return'}

        variables = {m for m in matches if m not in reserved}
        return variables

    def _extract_operators(self, expr: str) -> List[str]:
        """Extract mathematical operators from expression."""
        operators = []
        op_pattern = r'[\+\-\*/\^%]|==|!=|<=|>=|<|>|\*\*'

        for match in re.finditer(op_pattern, expr):
            operators.append(match.group())

        return operators

    def _infer_symbolic_domain(self, expr: str, variables: Set[str],
                              operators: List[str]) -> SymbolicDomain:
        """Infer the mathematical domain of an expression."""
        expr_lower = expr.lower()

        # Check for specific function names
        if any(f in expr_lower for f in ['sin', 'cos', 'tan', 'arcsin', 'arccos']):
            return SymbolicDomain.CALCULUS

        if any(f in expr_lower for f in ['matrix', 'dot', 'cross', 'transpose', 'det']):
            return SymbolicDomain.LINEAR_ALGEBRA

        if any(f in expr_lower for f in ['derivative', 'integral', 'limit', 'dx', 'dy']):
            return SymbolicDomain.CALCULUS

        if any(f in expr_lower for f in ['gcd', 'lcm', 'mod', 'prime', 'factor']):
            return SymbolicDomain.NUMBER_THEORY

        if any(f in expr_lower for f in ['and', 'or', 'not', 'implies', 'iff']):
            return SymbolicDomain.LOGIC

        # Default to algebra
        return SymbolicDomain.ALGEBRA

    def _normalize_expression(self, expr: str) -> str:
        """Normalize expression to canonical form."""
        # Convert ** to ^
        expr = expr.replace('**', '^')

        # Sort commutative operations (simple version)
        # Real implementation would parse into AST and normalize properly

        # Remove redundant parentheses (simplified)
        # Real implementation would use proper parsing

        return expr

    def _detect_properties(self, expr: str, variables: Set[str],
                          operators: List[str]) -> Dict[str, bool]:
        """Detect mathematical properties of an expression."""
        properties = {}

        # Check if expression only uses commutative operators
        commutative_ops = {'+', '*', 'and', 'or'}
        properties['uses_only_commutative'] = all(
            op in commutative_ops for op in operators
        )

        # Check if expression is linear in all variables
        # (simplified check - real implementation would be more sophisticated)
        properties['possibly_linear'] = '^' not in operators and '**' not in expr

        # Check if expression is polynomial
        properties['possibly_polynomial'] = not any(
            f in expr.lower() for f in ['sin', 'cos', 'tan', 'log', 'exp']
        )

        return properties

    def _simplify_expression(self, expr: str) -> Optional[str]:
        """Apply simplification rules to expression."""
        simplified = expr

        # Apply basic simplifications
        simplifications = [
            (r'\b(\w+)\s*\+\s*0\b', r'\1'),      # x + 0 = x
            (r'\b0\s*\+\s*(\w+)\b', r'\1'),      # 0 + x = x
            (r'\b(\w+)\s*\*\s*1\b', r'\1'),      # x * 1 = x
            (r'\b1\s*\*\s*(\w+)\b', r'\1'),      # 1 * x = x
            (r'\b(\w+)\s*\*\s*0\b', '0'),        # x * 0 = 0
            (r'\b0\s*\*\s*(\w+)\b', '0'),        # 0 * x = 0
            (r'\b(\w+)\s*-\s*\1\b', '0'),        # x - x = 0
        ]

        for pattern, replacement in simplifications:
            simplified = re.sub(pattern, replacement, simplified)

        return simplified if simplified != expr else None

    def _to_latex(self, expr: str) -> str:
        """Convert expression to LaTeX notation."""
        latex = expr

        # Convert operators
        latex = latex.replace('^', '^')  # Already LaTeX
        latex = latex.replace('*', r' \cdot ')
        latex = latex.replace('sqrt', r'\sqrt')
        latex = latex.replace('sin', r'\sin')
        latex = latex.replace('cos', r'\cos')
        latex = latex.replace('tan', r'\tan')

        return latex

    # ========== EQUATION SYSTEMS ==========

    def extract_equation_system(self, code: str, component_id: str) -> List[EquationSystem]:
        """Extract systems of equations from code."""
        systems = []

        # Look for patterns like:
        # y = mx + b
        # z = ax + by + c
        equation_pattern = r'(\w+)\s*=\s*([^;]+)'

        equations = []
        all_vars = set()

        for match in re.finditer(equation_pattern, code):
            lhs = match.group(1).strip()
            rhs = match.group(2).strip()

            # Filter out simple assignments (constants, function calls, etc.)
            if self._is_mathematical_equation(rhs):
                equation = f"{lhs} = {rhs}"
                equations.append(equation)

                # Extract variables
                vars_in_rhs = self._extract_variables(rhs)
                all_vars.update(vars_in_rhs)
                all_vars.add(lhs)

        if equations:
            system_id = hashlib.md5(
                f"{component_id}:{'|'.join(equations)}".encode()
            ).hexdigest()[:16]

            system = EquationSystem(
                system_id=system_id,
                equations=equations,
                variables=all_vars,
                constraints=[],
                solution_method=None,
                solved=False,
                solutions=None
            )
            systems.append(system)

        return systems

    def _is_mathematical_equation(self, expr: str) -> bool:
        """Check if expression looks like a mathematical equation."""
        # Has mathematical operators
        if any(op in expr for op in ['+', '-', '*', '/', '^', '**']):
            # Not just a function call or string literal
            if not (expr.strip().startswith('f"') or expr.strip().startswith('"')):
                return True
        return False

    # ========== ALGEBRAIC MANIPULATION ==========

    def apply_identity(self, expr: str, identity_name: str) -> Optional[str]:
        """Apply a mathematical identity to transform an expression."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            SELECT lhs, rhs FROM math_identities WHERE name = ?
        """, (identity_name,))

        result = cursor.fetchone()
        conn.close()

        if result:
            lhs_pattern, rhs_pattern = result
            # Simple pattern matching (real implementation would use symbolic matching)
            if lhs_pattern in expr:
                return expr.replace(lhs_pattern, rhs_pattern)

        return None

    def find_applicable_identities(self, expr: str) -> List[Tuple[str, str, str]]:
        """Find mathematical identities applicable to an expression."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("SELECT name, lhs, rhs FROM math_identities")
        all_identities = cursor.fetchall()
        conn.close()

        applicable = []
        for name, lhs, rhs in all_identities:
            # Simple substring matching (real implementation would use pattern matching)
            if self._pattern_matches(lhs, expr):
                applicable.append((name, lhs, rhs))

        return applicable

    def _pattern_matches(self, pattern: str, expr: str) -> bool:
        """Check if a pattern matches an expression."""
        # Simplified pattern matching
        # Real implementation would parse both and do structural matching
        pattern_ops = set(self._extract_operators(pattern))
        expr_ops = set(self._extract_operators(expr))

        return pattern_ops.issubset(expr_ops)

    # ========== DATABASE OPERATIONS ==========

    def save_expression(self, expr: SymbolicExpression, component_id: str):
        """Save symbolic expression to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Use existing column names from advanced scraper
        cursor.execute("""
            INSERT OR REPLACE INTO symbolic_expressions
            (id, component_id, expression, normalized, domain, properties, simplified, latex, operators, original)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            expr.expr_id,
            component_id,
            expr.original,  # expression column
            expr.normalized,
            expr.domain.value,
            json.dumps(expr.properties),
            expr.simplified,
            expr.latex,
            json.dumps(expr.operators),
            expr.original  # original column
        ))

        conn.commit()
        conn.close()

    def save_equation_system(self, system: EquationSystem, component_id: str):
        """Save equation system to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO equation_systems
            (id, component_id, equations, variables, constraints, solution_method, solved, solutions)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            system.system_id,
            component_id,
            json.dumps(system.equations),
            json.dumps(list(system.variables)),
            json.dumps(system.constraints),
            system.solution_method,
            system.solved,
            json.dumps(system.solutions) if system.solutions else None
        ))

        conn.commit()
        conn.close()

    # ========== ANALYSIS & REPORTING ==========

    def analyze_mathematical_code(self, component_id: str, code: str):
        """Full symbolic analysis of code."""
        print(f"  🔬 Symbolic analysis: {component_id}")

        # Extract equation systems
        systems = self.extract_equation_system(code, component_id)
        for system in systems:
            self.save_equation_system(system, component_id)
        print(f"    ✅ Found {len(systems)} equation systems")

        # Find expressions to analyze (simplified - would parse properly)
        expr_pattern = r'return\s+([^;]+)'
        expressions = []

        for match in re.finditer(expr_pattern, code):
            expr_str = match.group(1).strip()
            if self._is_mathematical_equation(expr_str):
                expr = self.parse_expression(expr_str, component_id)
                self.save_expression(expr, component_id)
                expressions.append(expr)

        print(f"    ✅ Analyzed {len(expressions)} expressions")

        return {
            'systems': len(systems),
            'expressions': len(expressions)
        }

    def get_symbolic_summary(self) -> Dict:
        """Get summary of symbolic analysis."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        summary = {}

        # Count expressions by domain
        cursor.execute("""
            SELECT domain, COUNT(*) FROM symbolic_expressions GROUP BY domain
        """)
        summary['expressions_by_domain'] = dict(cursor.fetchall())

        # Count equation systems
        cursor.execute("SELECT COUNT(*) FROM equation_systems")
        summary['total_equation_systems'] = cursor.fetchone()[0]

        # Count identities
        cursor.execute("SELECT COUNT(*) FROM math_identities")
        summary['available_identities'] = cursor.fetchone()[0]

        conn.close()
        return summary


def main():
    """CLI interface."""
    import argparse

    parser = argparse.ArgumentParser(description='Codex Symbolic Computation')
    parser.add_argument('--codex', default='~/blackroad-codex', help='Codex path')
    parser.add_argument('--analyze', help='Component ID to analyze')
    parser.add_argument('--file', help='File containing code')
    parser.add_argument('--summary', action='store_true', help='Show summary')
    parser.add_argument('--identities', action='store_true', help='List identities')

    args = parser.parse_args()

    engine = SymbolicComputationEngine(args.codex)

    if args.summary:
        summary = engine.get_symbolic_summary()
        print("\n🔬 SYMBOLIC COMPUTATION SUMMARY\n")
        print("Expressions by domain:")
        for domain, count in summary['expressions_by_domain'].items():
            print(f"  {domain}: {count}")
        print(f"\nTotal equation systems: {summary['total_equation_systems']}")
        print(f"Available identities: {summary['available_identities']}")

    elif args.identities:
        conn = sqlite3.connect(engine.db_path)
        cursor = conn.cursor()
        cursor.execute("SELECT name, lhs, rhs, domain FROM math_identities")
        print("\n📐 MATHEMATICAL IDENTITIES\n")
        for name, lhs, rhs, domain in cursor.fetchall():
            print(f"{name:30} ({domain})")
            print(f"  {lhs} = {rhs}")
        conn.close()

    elif args.analyze and args.file:
        with open(args.file, 'r') as f:
            code = f.read()
        result = engine.analyze_mathematical_code(args.analyze, code)
        print(f"\n✅ Analysis complete:")
        print(f"   Equation systems: {result['systems']}")
        print(f"   Expressions: {result['expressions']}")


if __name__ == '__main__':
    main()
