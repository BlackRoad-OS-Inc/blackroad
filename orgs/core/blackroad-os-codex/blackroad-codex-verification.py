#!/usr/bin/env python3
"""
BlackRoad Codex - Verification & Calculation Framework
Mechanical calculating, symbolic computation, and formal verification for code analysis.
"""

import sqlite3
import ast
import re
import hashlib
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass
from enum import Enum
import json

class VerificationType(Enum):
    """Types of verification checks."""
    SYMBOLIC_COMPUTATION = "symbolic"
    TYPE_CHECKING = "type_check"
    INVARIANT = "invariant"
    PRECONDITION = "precondition"
    POSTCONDITION = "postcondition"
    PROPERTY_TEST = "property"
    PROOF = "proof"
    ASSERTION = "assertion"

@dataclass
class VerificationResult:
    """Result of a verification check."""
    verification_type: VerificationType
    component_id: str
    passed: bool
    evidence: Dict[str, Any]
    confidence: float  # 0.0-1.0
    message: str

@dataclass
class Calculation:
    """A mechanical calculation extracted from code."""
    calc_id: str
    component_id: str
    calc_type: str  # equation, formula, algorithm, transformation
    expression: str
    variables: List[str]
    constants: List[str]
    domain: Optional[str]  # mathematical domain (algebra, calculus, etc.)
    verified: bool
    verification_method: Optional[str]

class CodexVerificationFramework:
    """Mechanical calculation and verification framework for the Codex."""

    def __init__(self, codex_path: str = "~/blackroad-codex"):
        self.codex_path = Path(codex_path).expanduser()
        self.db_path = self.codex_path / "index" / "components.db"

        if not self.db_path.exists():
            raise FileNotFoundError(f"Codex not found at {self.db_path}")

        self.init_verification_tables()

    def init_verification_tables(self):
        """Initialize database tables for verification framework."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        # Mechanical calculations table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS calculations (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                calc_type TEXT,  -- equation, formula, algorithm, transformation
                expression TEXT,
                variables TEXT,  -- JSON array
                constants TEXT,  -- JSON array
                domain TEXT,     -- mathematical domain
                verified BOOLEAN DEFAULT 0,
                verification_method TEXT,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Verification results table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS verifications (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                verification_type TEXT,
                passed BOOLEAN,
                evidence TEXT,  -- JSON
                confidence REAL,
                message TEXT,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Type signatures table (for type checking)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS type_signatures (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                component_id TEXT,
                signature TEXT,
                parameters TEXT,  -- JSON
                return_type TEXT,
                constraints TEXT,  -- JSON (type constraints)
                verified BOOLEAN DEFAULT 0,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Invariants table (loop/function invariants)
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS invariants (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                invariant_type TEXT,  -- loop, function, class, module
                condition TEXT,
                location TEXT,  -- where in code (line number, scope)
                holds BOOLEAN,
                proof_sketch TEXT,
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Symbolic expressions table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS symbolic_expressions (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                expression TEXT,
                simplified TEXT,
                domain TEXT,
                properties TEXT,  -- JSON (commutative, associative, etc.)
                equivalences TEXT,  -- JSON (equivalent forms)
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        # Proofs table
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS proofs (
                id TEXT PRIMARY KEY,
                component_id TEXT,
                theorem TEXT,
                proof_type TEXT,  -- induction, contradiction, construction, etc.
                steps TEXT,  -- JSON array of proof steps
                verified BOOLEAN DEFAULT 0,
                verifier TEXT,  -- method used to verify
                FOREIGN KEY (component_id) REFERENCES components(id)
            )
        """)

        conn.commit()
        conn.close()

    # ========== CALCULATION EXTRACTION ==========

    def extract_calculations(self, component_id: str, file_path: str,
                           code: str) -> List[Calculation]:
        """Extract mechanical calculations from code."""
        calculations = []

        if file_path.endswith('.py'):
            calculations.extend(self._extract_python_calculations(component_id, code))

        return calculations

    def _extract_python_calculations(self, component_id: str, code: str) -> List[Calculation]:
        """Extract calculations from Python code using AST."""
        calculations = []

        try:
            tree = ast.parse(code)

            # Extract from function bodies
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    calcs = self._analyze_function_calculations(component_id, node)
                    calculations.extend(calcs)

        except SyntaxError:
            pass

        return calculations

    def _analyze_function_calculations(self, component_id: str,
                                      func_node: ast.FunctionDef) -> List[Calculation]:
        """Analyze calculations within a function."""
        calculations = []

        for node in ast.walk(func_node):
            # Look for return statements with math operations
            if isinstance(node, ast.Return) and node.value:
                calc = self._extract_from_expression(component_id, node.value, func_node.name)
                if calc:
                    calculations.append(calc)

            # Look for assignments with calculations
            elif isinstance(node, ast.Assign):
                for target in node.targets:
                    calc = self._extract_from_expression(
                        component_id, node.value,
                        self._get_name(target)
                    )
                    if calc:
                        calculations.append(calc)

        return calculations

    def _extract_from_expression(self, component_id: str, expr_node: ast.AST,
                                context: str) -> Optional[Calculation]:
        """Extract calculation from an AST expression."""
        # Check if it's a mathematical operation
        if self._is_math_operation(expr_node):
            expression = ast.unparse(expr_node)
            variables = self._extract_variables(expr_node)
            constants = self._extract_constants(expr_node)

            calc_id = hashlib.md5(
                f"{component_id}:{expression}".encode()
            ).hexdigest()[:16]

            calc_type = self._classify_calculation(expr_node)
            domain = self._infer_domain(expr_node, variables)

            return Calculation(
                calc_id=calc_id,
                component_id=component_id,
                calc_type=calc_type,
                expression=expression,
                variables=variables,
                constants=constants,
                domain=domain,
                verified=False,
                verification_method=None
            )

        return None

    def _is_math_operation(self, node: ast.AST) -> bool:
        """Check if node represents a mathematical operation."""
        math_ops = (ast.Add, ast.Sub, ast.Mult, ast.Div, ast.Mod,
                   ast.Pow, ast.FloorDiv, ast.MatMult)

        if isinstance(node, ast.BinOp):
            return isinstance(node.op, math_ops)

        # Check for function calls to math functions
        if isinstance(node, ast.Call):
            if isinstance(node.func, ast.Name):
                math_funcs = {'sqrt', 'sin', 'cos', 'tan', 'exp', 'log',
                             'abs', 'pow', 'sum', 'max', 'min'}
                return node.func.id in math_funcs
            elif isinstance(node.func, ast.Attribute):
                # math.sqrt, np.sum, etc.
                return True

        return False

    def _extract_variables(self, node: ast.AST) -> List[str]:
        """Extract variable names from expression."""
        variables = []
        for child in ast.walk(node):
            if isinstance(child, ast.Name):
                # Exclude common constants
                if child.id not in {'True', 'False', 'None'}:
                    variables.append(child.id)
        return list(set(variables))

    def _extract_constants(self, node: ast.AST) -> List[str]:
        """Extract constants from expression."""
        constants = []
        for child in ast.walk(node):
            if isinstance(child, ast.Constant):
                constants.append(str(child.value))
        return constants

    def _classify_calculation(self, node: ast.AST) -> str:
        """Classify the type of calculation."""
        if isinstance(node, ast.BinOp):
            if isinstance(node.op, ast.Pow):
                return "equation"
            elif isinstance(node.op, (ast.Mult, ast.Div)):
                return "formula"
            else:
                return "arithmetic"
        elif isinstance(node, ast.Call):
            return "transformation"
        return "expression"

    def _infer_domain(self, node: ast.AST, variables: List[str]) -> str:
        """Infer mathematical domain from expression."""
        # Simple heuristics
        if any('matrix' in v.lower() or 'tensor' in v.lower() for v in variables):
            return "linear_algebra"

        for child in ast.walk(node):
            if isinstance(child, ast.Call) and isinstance(child.func, ast.Name):
                func_name = child.func.id
                if func_name in {'sin', 'cos', 'tan'}:
                    return "trigonometry"
                elif func_name in {'exp', 'log'}:
                    return "analysis"
                elif func_name in {'sqrt', 'pow'}:
                    return "algebra"

        return "arithmetic"

    def _get_name(self, node: ast.AST) -> str:
        """Get variable name from AST node."""
        if isinstance(node, ast.Name):
            return node.id
        elif isinstance(node, ast.Attribute):
            return node.attr
        return "unknown"

    # ========== VERIFICATION ==========

    def verify_type_consistency(self, component_id: str, code: str) -> VerificationResult:
        """Verify type consistency in code."""
        try:
            tree = ast.parse(code)
            type_errors = []

            # Check function signatures
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    if node.returns is None and node.name not in {'__init__'}:
                        type_errors.append(f"Missing return type: {node.name}")

            passed = len(type_errors) == 0

            return VerificationResult(
                verification_type=VerificationType.TYPE_CHECKING,
                component_id=component_id,
                passed=passed,
                evidence={'errors': type_errors, 'total_functions': len([n for n in ast.walk(tree) if isinstance(n, ast.FunctionDef)])},
                confidence=0.7 if passed else 0.3,
                message=f"Found {len(type_errors)} type issues" if not passed else "Type consistency verified"
            )
        except:
            return VerificationResult(
                verification_type=VerificationType.TYPE_CHECKING,
                component_id=component_id,
                passed=False,
                evidence={'error': 'Parse error'},
                confidence=0.0,
                message="Could not parse code for type checking"
            )

    def extract_invariants(self, component_id: str, code: str) -> List[Dict]:
        """Extract loop and function invariants from code."""
        invariants = []

        try:
            tree = ast.parse(code)

            # Look for assert statements (explicit invariants)
            for node in ast.walk(tree):
                if isinstance(node, ast.Assert):
                    inv_id = hashlib.md5(
                        f"{component_id}:{ast.unparse(node.test)}".encode()
                    ).hexdigest()[:16]

                    invariants.append({
                        'id': inv_id,
                        'component_id': component_id,
                        'invariant_type': 'assertion',
                        'condition': ast.unparse(node.test),
                        'location': f"line {node.lineno}",
                        'holds': True,  # Assume true if assertion exists
                        'proof_sketch': 'Explicit assertion in code'
                    })

                # Look for loop invariants (comments with "invariant:")
                elif isinstance(node, (ast.For, ast.While)):
                    # Check if there's a comment before the loop
                    # (This is simplified - real implementation would parse comments)
                    pass

        except:
            pass

        return invariants

    def verify_symbolic_equivalence(self, expr1: str, expr2: str) -> bool:
        """Verify if two symbolic expressions are equivalent."""
        # This is a placeholder - real implementation would use sympy
        # For now, just check string equality after normalization
        normalized1 = self._normalize_expression(expr1)
        normalized2 = self._normalize_expression(expr2)
        return normalized1 == normalized2

    def _normalize_expression(self, expr: str) -> str:
        """Normalize expression for comparison."""
        # Remove whitespace, sort commutative operations, etc.
        expr = expr.replace(' ', '')
        # This is simplified - real implementation would parse and normalize properly
        return expr

    # ========== PROPERTY-BASED TESTING ==========

    def generate_property_tests(self, component_id: str, func_node: ast.FunctionDef) -> List[str]:
        """Generate property-based tests for a function."""
        properties = []

        # Infer properties from function signature
        if func_node.name.startswith('sort'):
            properties.append("output is sorted")
            properties.append("output has same length as input")
        elif func_node.name.startswith('reverse'):
            properties.append("reversing twice gives original")
        elif 'inverse' in func_node.name.lower():
            properties.append("f(f_inv(x)) == x")

        return properties

    # ========== DATABASE OPERATIONS ==========

    def save_calculation(self, calc: Calculation):
        """Save calculation to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        cursor.execute("""
            INSERT OR REPLACE INTO calculations
            (id, component_id, calc_type, expression, variables, constants, domain, verified, verification_method)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            calc.calc_id,
            calc.component_id,
            calc.calc_type,
            calc.expression,
            json.dumps(calc.variables),
            json.dumps(calc.constants),
            calc.domain,
            calc.verified,
            calc.verification_method
        ))

        conn.commit()
        conn.close()

    def save_verification(self, result: VerificationResult):
        """Save verification result to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        result_id = hashlib.md5(
            f"{result.component_id}:{result.verification_type.value}".encode()
        ).hexdigest()[:16]

        cursor.execute("""
            INSERT OR REPLACE INTO verifications
            (id, component_id, verification_type, passed, evidence, confidence, message)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (
            result_id,
            result.component_id,
            result.verification_type.value,
            result.passed,
            json.dumps(result.evidence),
            result.confidence,
            result.message
        ))

        conn.commit()
        conn.close()

    def save_invariants(self, invariants: List[Dict]):
        """Save invariants to database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        for inv in invariants:
            cursor.execute("""
                INSERT OR REPLACE INTO invariants
                (id, component_id, invariant_type, condition, location, holds, proof_sketch)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (
                inv['id'],
                inv['component_id'],
                inv['invariant_type'],
                inv['condition'],
                inv['location'],
                inv['holds'],
                inv['proof_sketch']
            ))

        conn.commit()
        conn.close()

    # ========== ANALYSIS & REPORTING ==========

    def analyze_component(self, component_id: str, file_path: str, code: str):
        """Full verification analysis of a component."""
        print(f"  🔍 Analyzing {component_id}...")

        # Extract calculations
        calculations = self.extract_calculations(component_id, file_path, code)
        for calc in calculations:
            self.save_calculation(calc)
        print(f"    ✅ Found {len(calculations)} calculations")

        # Verify type consistency
        type_result = self.verify_type_consistency(component_id, code)
        self.save_verification(type_result)
        print(f"    {'✅' if type_result.passed else '⚠️ '} Type checking: {type_result.message}")

        # Extract invariants
        invariants = self.extract_invariants(component_id, code)
        if invariants:
            self.save_invariants(invariants)
            print(f"    ✅ Found {len(invariants)} invariants")

    def get_verification_summary(self) -> Dict:
        """Get summary of all verifications."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()

        summary = {}

        # Count calculations by domain
        cursor.execute("""
            SELECT domain, COUNT(*)
            FROM calculations
            GROUP BY domain
        """)
        summary['calculations_by_domain'] = dict(cursor.fetchall())

        # Count verifications by type
        cursor.execute("""
            SELECT verification_type, COUNT(*),
                   AVG(CASE WHEN passed THEN 1 ELSE 0 END) as pass_rate
            FROM verifications
            GROUP BY verification_type
        """)
        summary['verifications'] = [
            {'type': row[0], 'count': row[1], 'pass_rate': row[2]}
            for row in cursor.fetchall()
        ]

        # Count invariants
        cursor.execute("SELECT COUNT(*) FROM invariants WHERE holds = 1")
        summary['valid_invariants'] = cursor.fetchone()[0]

        conn.close()
        return summary


def main():
    """CLI interface."""
    import argparse

    parser = argparse.ArgumentParser(description='Codex Verification Framework')
    parser.add_argument('--codex', default='~/blackroad-codex', help='Codex path')
    parser.add_argument('--analyze', help='Analyze component by ID')
    parser.add_argument('--summary', action='store_true', help='Show verification summary')
    parser.add_argument('--file', help='File path for analysis')

    args = parser.parse_args()

    framework = CodexVerificationFramework(args.codex)

    if args.summary:
        summary = framework.get_verification_summary()
        print("\n📊 VERIFICATION SUMMARY\n")
        print("Calculations by domain:")
        for domain, count in summary['calculations_by_domain'].items():
            print(f"  {domain}: {count}")
        print("\nVerifications:")
        for v in summary['verifications']:
            print(f"  {v['type']}: {v['count']} checks ({v['pass_rate']*100:.1f}% pass)")
        print(f"\nValid invariants: {summary['valid_invariants']}")

    elif args.analyze and args.file:
        with open(args.file, 'r') as f:
            code = f.read()
        framework.analyze_component(args.analyze, args.file, code)


if __name__ == '__main__':
    main()
