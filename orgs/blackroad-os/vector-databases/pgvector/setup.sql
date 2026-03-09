-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create embeddings table
CREATE TABLE blackroad_embeddings (
    id SERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create HNSW index for fast similarity search
CREATE INDEX ON blackroad_embeddings 
USING hnsw (embedding vector_cosine_ops)
WITH (m = 16, ef_construction = 64);

-- Similarity search function
CREATE OR REPLACE FUNCTION search_similar(
    query_embedding vector(1536),
    match_count INT DEFAULT 10
)
RETURNS TABLE (id INT, content TEXT, similarity FLOAT)
AS $$
    SELECT id, content, 1 - (embedding <=> query_embedding) AS similarity
    FROM blackroad_embeddings
    ORDER BY embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE SQL;
