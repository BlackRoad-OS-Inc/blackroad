"""Lucidia Core API - AI reasoning engines."""

import os
import sympy as sp
from flask import Flask, jsonify, request

app = Flask(__name__)


@app.route("/")
def index():
    """Health check and API info."""
    return jsonify({
        "service": "Lucidia Core",
        "version": "0.1.0",
        "status": "operational",
        "engines": [
            "mathematician",
            "physicist",
            "chemist",
            "geologist",
            "analyst"
        ],
        "endpoints": {
            "/health": "Health check",
            "/math": "Evaluate mathematical expressions",
            "/derivative": "Compute derivatives",
            "/simplify": "Simplify expressions"
        }
    })


@app.route("/health")
def health():
    """Health check endpoint."""
    return jsonify({"status": "healthy"})


@app.post("/math")
def evaluate_math():
    """Evaluate a mathematical expression."""
    data = request.get_json(silent=True) or {}
    expr = data.get("expression")
    if not expr:
        return jsonify({"error": "missing expression"}), 400
    try:
        sym_expr = sp.sympify(expr)
        result = sym_expr.evalf() if sym_expr.is_number else sym_expr
        return jsonify({
            "expression": expr,
            "result": str(result),
            "simplified": str(sp.simplify(sym_expr))
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 400


@app.post("/derivative")
def derivative():
    """Compute the derivative of an expression."""
    data = request.get_json(silent=True) or {}
    expr = data.get("expression")
    var = data.get("variable", "x")
    if not expr:
        return jsonify({"error": "missing expression"}), 400
    try:
        sym_expr = sp.sympify(expr)
        x = sp.Symbol(var)
        deriv = sp.diff(sym_expr, x)
        return jsonify({
            "expression": expr,
            "variable": var,
            "derivative": str(deriv)
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 400


@app.post("/simplify")
def simplify():
    """Simplify a mathematical expression."""
    data = request.get_json(silent=True) or {}
    expr = data.get("expression")
    if not expr:
        return jsonify({"error": "missing expression"}), 400
    try:
        sym_expr = sp.sympify(expr)
        simplified = sp.simplify(sym_expr)
        return jsonify({
            "expression": expr,
            "simplified": str(simplified)
        })
    except Exception as exc:
        return jsonify({"error": str(exc)}), 400


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8080))
    app.run(host="0.0.0.0", port=port)
