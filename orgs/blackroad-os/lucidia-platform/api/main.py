"""Lucidia Platform API - AI-powered learning that actually works."""

from fastapi import FastAPI, HTTPException, UploadFile, File, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
import base64
import uuid
from datetime import datetime

# Import routers
from routers import billing
from routers import code
from routers import memory

app = FastAPI(
    title="Lucidia API",
    description="AI-powered learning platform - the end of technical barriers",
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:3000", "https://lucidia.ai", "https://app.lucidia.ai"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(billing.router, prefix="/api/v1")
app.include_router(code.router)  # Code analysis router (50+ languages)
app.include_router(memory.router)  # 2048-style memory system


# ============================================================================
# Models
# ============================================================================

class ProblemInput(BaseModel):
    """Input for problem analysis."""
    text: Optional[str] = None
    image_base64: Optional[str] = None
    voice_transcript: Optional[str] = None
    subject: Optional[str] = None  # math, physics, chemistry, etc.
    grade_level: Optional[str] = None  # elementary, middle, high, college


class Explanation(BaseModel):
    """AI-generated explanation."""
    id: str
    problem_text: str
    subject: str
    difficulty: str
    steps: List[Dict[str, Any]]
    visualization_url: Optional[str] = None
    video_url: Optional[str] = None
    confidence: float
    created_at: datetime


class UserContext(BaseModel):
    """Persistent user learning context."""
    user_id: str
    learning_style: str  # visual, auditory, kinesthetic, reading
    strengths: List[str]
    areas_for_growth: List[str]
    recent_topics: List[str]
    session_count: int
    total_problems_solved: int


class VisualizationRequest(BaseModel):
    """Request for visual content generation."""
    concept: str
    type: str  # "2d_graph", "3d_model", "animation", "diagram"
    context: Optional[str] = None


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    version: str
    services: Dict[str, str]


# ============================================================================
# In-memory storage (replace with database in production)
# ============================================================================

user_contexts: Dict[str, UserContext] = {}
explanations_cache: Dict[str, Explanation] = {}


# ============================================================================
# Core Endpoints
# ============================================================================

@app.get("/health", response_model=HealthResponse)
async def health():
    """Health check endpoint."""
    return HealthResponse(
        status="healthy",
        version="0.1.0",
        services={
            "api": "operational",
            "ai_tutor": "operational",
            "visualizer": "operational",
            "memory": "operational",
        }
    )


@app.post("/api/v1/problems/analyze", response_model=Explanation)
async def analyze_problem(problem: ProblemInput):
    """
    Analyze a problem and generate personalized explanation.

    Accepts:
    - Text description
    - Image (base64 encoded)
    - Voice transcript

    Returns step-by-step explanation with optional visualization.
    """
    # Determine problem text from input
    problem_text = problem.text or problem.voice_transcript or "Image problem"

    # Auto-detect subject if not provided
    subject = problem.subject or _detect_subject(problem_text)

    # Generate explanation ID
    explanation_id = str(uuid.uuid4())

    # TODO: Connect to lucidia-core mathematician/physicist for actual analysis
    # For now, return structured response

    explanation = Explanation(
        id=explanation_id,
        problem_text=problem_text,
        subject=subject,
        difficulty=_assess_difficulty(problem_text),
        steps=[
            {
                "number": 1,
                "title": "Understand the Problem",
                "content": f"Let's break down what we're solving: {problem_text}",
                "visualization": None,
            },
            {
                "number": 2,
                "title": "Identify Key Concepts",
                "content": "The key mathematical concepts involved are...",
                "visualization": "concept_map",
            },
            {
                "number": 3,
                "title": "Apply the Method",
                "content": "Here's how we solve it step by step...",
                "visualization": "step_animation",
            },
            {
                "number": 4,
                "title": "Verify the Answer",
                "content": "Let's check our work to make sure it's correct...",
                "visualization": None,
            },
        ],
        visualization_url=f"/api/v1/visualizations/{explanation_id}",
        confidence=0.95,
        created_at=datetime.utcnow(),
    )

    explanations_cache[explanation_id] = explanation
    return explanation


@app.post("/api/v1/problems/upload")
async def upload_problem_image(file: UploadFile = File(...)):
    """
    Upload an image of a problem for analysis.

    Supports: PNG, JPG, PDF
    Max size: 10MB
    """
    if file.content_type not in ["image/png", "image/jpeg", "application/pdf"]:
        raise HTTPException(400, "Unsupported file type. Use PNG, JPG, or PDF.")

    contents = await file.read()
    if len(contents) > 10 * 1024 * 1024:
        raise HTTPException(400, "File too large. Max 10MB.")

    # Encode and analyze
    image_base64 = base64.b64encode(contents).decode()

    # Create problem input and analyze
    problem = ProblemInput(image_base64=image_base64)
    return await analyze_problem(problem)


@app.get("/api/v1/explanations/{explanation_id}", response_model=Explanation)
async def get_explanation(explanation_id: str):
    """Retrieve a previously generated explanation."""
    if explanation_id not in explanations_cache:
        raise HTTPException(404, "Explanation not found")
    return explanations_cache[explanation_id]


# ============================================================================
# Visualization Endpoints
# ============================================================================

@app.post("/api/v1/visualizations/generate")
async def generate_visualization(request: VisualizationRequest):
    """
    Generate visual content for a concept.

    Types:
    - 2d_graph: Interactive 2D graphs (Desmos-like)
    - 3d_model: 3D models (chemistry molecules, geometry)
    - animation: Animated explanations
    - diagram: Static diagrams with annotations
    """
    viz_id = str(uuid.uuid4())

    # TODO: Connect to lucidia-core visualizers
    return {
        "id": viz_id,
        "type": request.type,
        "concept": request.concept,
        "url": f"/api/v1/visualizations/render/{viz_id}",
        "embed_code": f'<iframe src="https://lucidia.ai/embed/{viz_id}" />',
        "status": "generating",
    }


@app.get("/api/v1/visualizations/render/{viz_id}")
async def render_visualization(viz_id: str):
    """Render a generated visualization."""
    # TODO: Return actual visualization data
    return {
        "id": viz_id,
        "type": "2d_graph",
        "data": {
            "equation": "y = x^2",
            "domain": [-10, 10],
            "range": [-10, 100],
        },
        "interactive": True,
    }


# ============================================================================
# User Context / Memory Endpoints
# ============================================================================

@app.get("/api/v1/users/{user_id}/context", response_model=UserContext)
async def get_user_context(user_id: str):
    """
    Get persistent learning context for a user.

    Lucidia remembers:
    - Learning style preferences
    - Strengths and areas for growth
    - Recent topics studied
    - Progress over time
    """
    if user_id not in user_contexts:
        # Create new context
        user_contexts[user_id] = UserContext(
            user_id=user_id,
            learning_style="visual",
            strengths=[],
            areas_for_growth=[],
            recent_topics=[],
            session_count=1,
            total_problems_solved=0,
        )

    return user_contexts[user_id]


@app.put("/api/v1/users/{user_id}/context")
async def update_user_context(user_id: str, context: UserContext):
    """Update user learning context."""
    user_contexts[user_id] = context
    return {"status": "updated", "user_id": user_id}


@app.post("/api/v1/users/{user_id}/problem-solved")
async def record_problem_solved(user_id: str, subject: str, topic: str, success: bool):
    """Record that a user solved (or attempted) a problem."""
    if user_id not in user_contexts:
        await get_user_context(user_id)

    ctx = user_contexts[user_id]
    ctx.total_problems_solved += 1

    if topic not in ctx.recent_topics:
        ctx.recent_topics.append(topic)
        if len(ctx.recent_topics) > 10:
            ctx.recent_topics.pop(0)

    if success and topic not in ctx.strengths:
        ctx.strengths.append(topic)

    return {"status": "recorded", "total_solved": ctx.total_problems_solved}


# ============================================================================
# Practice / Game Endpoints
# ============================================================================

@app.get("/api/v1/practice/generate")
async def generate_practice_problem(
    subject: str = "math",
    topic: Optional[str] = None,
    difficulty: str = "medium",
    user_id: Optional[str] = None,
):
    """
    Generate a contextual practice problem.

    Problems are presented in real-world scenarios:
    - "4 houses, 4 dogs" for division
    - "Pizza slices" for fractions
    - "Building a treehouse" for geometry
    """
    # Get user context for personalization
    context = None
    if user_id and user_id in user_contexts:
        context = user_contexts[user_id]

    # TODO: Connect to problem generator
    return {
        "id": str(uuid.uuid4()),
        "subject": subject,
        "topic": topic or "general",
        "difficulty": difficulty,
        "scenario": "You have 12 cookies to share equally among 4 friends. How many cookies does each friend get?",
        "problem": "12 ÷ 4 = ?",
        "hints": [
            "Think about grouping the cookies",
            "Each friend should get the same amount",
        ],
        "visualization_prompt": "12 cookies being distributed to 4 people",
    }


@app.post("/api/v1/practice/check")
async def check_practice_answer(
    problem_id: str,
    answer: str,
    user_id: Optional[str] = None,
):
    """Check a practice problem answer and provide feedback."""
    # TODO: Actual answer checking
    correct = answer.strip() == "3"

    return {
        "correct": correct,
        "feedback": "Great job! 12 ÷ 4 = 3. Each friend gets 3 cookies." if correct
                    else "Not quite. Try thinking about how to split 12 items into 4 equal groups.",
        "next_problem": "/api/v1/practice/generate?subject=math&topic=division",
    }


# ============================================================================
# Helper Functions
# ============================================================================

def _detect_subject(text: str) -> str:
    """Auto-detect subject from problem text."""
    text_lower = text.lower()

    if any(word in text_lower for word in ["equation", "solve", "x =", "algebra", "factor"]):
        return "algebra"
    if any(word in text_lower for word in ["triangle", "circle", "angle", "area", "perimeter"]):
        return "geometry"
    if any(word in text_lower for word in ["velocity", "force", "mass", "energy", "acceleration"]):
        return "physics"
    if any(word in text_lower for word in ["molecule", "reaction", "element", "compound"]):
        return "chemistry"
    if any(word in text_lower for word in ["cell", "organism", "dna", "evolution"]):
        return "biology"
    if any(word in text_lower for word in ["+", "-", "×", "÷", "divide", "multiply", "add", "subtract"]):
        return "arithmetic"

    return "general"


def _assess_difficulty(text: str) -> str:
    """Assess problem difficulty."""
    # Simple heuristic based on length and keywords
    if len(text) < 50:
        return "easy"
    if any(word in text.lower() for word in ["integral", "derivative", "matrix", "quantum"]):
        return "hard"
    return "medium"


# ============================================================================
# Run
# ============================================================================

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
