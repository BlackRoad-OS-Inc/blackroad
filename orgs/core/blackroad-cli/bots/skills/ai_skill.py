"""AI/ML utility skills for agent inference and embeddings.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, transfer,
or reproduction of this file, via any medium, is strictly prohibited.

Licensed for non-commercial testing and evaluation purposes only.
Commercial use requires a separate license agreement with BlackRoad OS, Inc.

For licensing inquiries: legal@blackroad.io
"""

from __future__ import annotations

import hashlib
import json
import re
from typing import Any, Dict, List, Optional, Tuple

import numpy as np


def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
    """Compute cosine similarity between two vectors."""
    norm_a = np.linalg.norm(a)
    norm_b = np.linalg.norm(b)
    if norm_a == 0 or norm_b == 0:
        return 0.0
    return float(np.dot(a, b) / (norm_a * norm_b))


def euclidean_distance(a: np.ndarray, b: np.ndarray) -> float:
    """Compute Euclidean distance between two vectors."""
    return float(np.linalg.norm(a - b))


def normalize_embedding(embedding: np.ndarray) -> np.ndarray:
    """L2 normalize an embedding vector."""
    norm = np.linalg.norm(embedding)
    if norm == 0:
        return embedding
    return embedding / norm


def batch_normalize(embeddings: np.ndarray) -> np.ndarray:
    """L2 normalize a batch of embeddings (N x D matrix)."""
    norms = np.linalg.norm(embeddings, axis=1, keepdims=True)
    norms = np.where(norms == 0, 1, norms)
    return embeddings / norms


def top_k_similar(
    query: np.ndarray,
    embeddings: np.ndarray,
    k: int = 5,
) -> List[Tuple[int, float]]:
    """Find top-k most similar embeddings to query.

    Returns list of (index, similarity_score) tuples.
    """
    query_norm = normalize_embedding(query)
    emb_norm = batch_normalize(embeddings)
    similarities = emb_norm @ query_norm
    top_indices = np.argsort(similarities)[-k:][::-1]
    return [(int(i), float(similarities[i])) for i in top_indices]


def chunk_text(
    text: str,
    chunk_size: int = 512,
    overlap: int = 50,
) -> List[str]:
    """Split text into overlapping chunks for RAG processing."""
    if chunk_size <= overlap:
        raise ValueError("chunk_size must be greater than overlap")

    words = text.split()
    chunks = []
    start = 0

    while start < len(words):
        end = start + chunk_size
        chunk = " ".join(words[start:end])
        chunks.append(chunk)
        start = end - overlap

    return chunks


def semantic_chunk(
    text: str,
    max_chunk_size: int = 512,
) -> List[str]:
    """Split text at sentence boundaries for better semantic coherence."""
    # Split on sentence endings
    sentences = re.split(r'(?<=[.!?])\s+', text)

    chunks = []
    current_chunk = []
    current_size = 0

    for sentence in sentences:
        words = sentence.split()
        sentence_size = len(words)

        if current_size + sentence_size > max_chunk_size and current_chunk:
            chunks.append(" ".join(current_chunk))
            current_chunk = []
            current_size = 0

        current_chunk.append(sentence)
        current_size += sentence_size

    if current_chunk:
        chunks.append(" ".join(current_chunk))

    return chunks


def simple_tokenize(text: str) -> List[str]:
    """Simple whitespace + punctuation tokenizer."""
    text = text.lower()
    text = re.sub(r'[^\w\s]', ' ', text)
    return text.split()


def token_count(text: str) -> int:
    """Estimate token count (rough approximation: words * 1.3)."""
    words = len(text.split())
    return int(words * 1.3)


def truncate_to_tokens(text: str, max_tokens: int) -> str:
    """Truncate text to approximately max_tokens."""
    estimated_words = int(max_tokens / 1.3)
    words = text.split()
    if len(words) <= estimated_words:
        return text
    return " ".join(words[:estimated_words]) + "..."


def extract_keywords(
    text: str,
    top_n: int = 10,
    min_length: int = 3,
) -> List[Tuple[str, int]]:
    """Extract top keywords by frequency."""
    # Common stopwords
    stopwords = {
        'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
        'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'been',
        'be', 'have', 'has', 'had', 'do', 'does', 'did', 'will', 'would',
        'could', 'should', 'may', 'might', 'must', 'shall', 'can', 'this',
        'that', 'these', 'those', 'it', 'its', 'they', 'them', 'their',
    }

    tokens = simple_tokenize(text)
    freq: Dict[str, int] = {}

    for token in tokens:
        if len(token) >= min_length and token not in stopwords:
            freq[token] = freq.get(token, 0) + 1

    sorted_keywords = sorted(freq.items(), key=lambda x: x[1], reverse=True)
    return sorted_keywords[:top_n]


def prompt_template(
    template: str,
    **variables: Any,
) -> str:
    """Fill a prompt template with variables.

    Uses {variable_name} syntax.
    """
    result = template
    for key, value in variables.items():
        result = result.replace(f"{{{key}}}", str(value))
    return result


def chat_to_prompt(
    messages: List[Dict[str, str]],
    system_prefix: str = "System: ",
    user_prefix: str = "User: ",
    assistant_prefix: str = "Assistant: ",
) -> str:
    """Convert chat messages to a single prompt string."""
    lines = []
    prefix_map = {
        "system": system_prefix,
        "user": user_prefix,
        "assistant": assistant_prefix,
    }

    for msg in messages:
        role = msg.get("role", "user")
        content = msg.get("content", "")
        prefix = prefix_map.get(role, "")
        lines.append(f"{prefix}{content}")

    return "\n\n".join(lines)


def content_hash(content: str) -> str:
    """Generate a deterministic hash for content deduplication."""
    return hashlib.sha256(content.encode()).hexdigest()[:16]


def mmr_rerank(
    query_embedding: np.ndarray,
    doc_embeddings: np.ndarray,
    lambda_mult: float = 0.5,
    k: int = 5,
) -> List[int]:
    """Maximal Marginal Relevance re-ranking for diversity.

    Balances relevance to query with diversity among selected docs.
    """
    query_norm = normalize_embedding(query_embedding)
    doc_norm = batch_normalize(doc_embeddings)

    # Relevance scores
    relevance = doc_norm @ query_norm

    selected = []
    remaining = list(range(len(doc_embeddings)))

    while len(selected) < k and remaining:
        mmr_scores = []

        for idx in remaining:
            # Relevance term
            rel_score = relevance[idx]

            # Diversity term (max similarity to already selected)
            if selected:
                selected_embs = doc_norm[selected]
                sim_to_selected = selected_embs @ doc_norm[idx]
                max_sim = np.max(sim_to_selected)
            else:
                max_sim = 0

            # MMR score
            mmr = lambda_mult * rel_score - (1 - lambda_mult) * max_sim
            mmr_scores.append((idx, mmr))

        # Select highest MMR
        best_idx = max(mmr_scores, key=lambda x: x[1])[0]
        selected.append(best_idx)
        remaining.remove(best_idx)

    return selected


def sparse_encode(
    text: str,
    vocab: Optional[Dict[str, int]] = None,
) -> Dict[int, float]:
    """Create sparse TF encoding of text.

    Returns dict mapping token indices to term frequencies.
    """
    tokens = simple_tokenize(text)
    tf: Dict[str, int] = {}

    for token in tokens:
        tf[token] = tf.get(token, 0) + 1

    if vocab is None:
        # Auto-create vocabulary
        vocab = {t: i for i, t in enumerate(sorted(tf.keys()))}

    sparse = {}
    total_tokens = len(tokens)

    for token, count in tf.items():
        if token in vocab:
            sparse[vocab[token]] = count / total_tokens

    return sparse
