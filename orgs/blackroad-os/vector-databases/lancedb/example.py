import lancedb
import pyarrow as pa

# Connect to LanceDB
db = lancedb.connect("./blackroad-vectors")

# Create table with schema
schema = pa.schema([
    pa.field("id", pa.string()),
    pa.field("text", pa.string()),
    pa.field("vector", pa.list_(pa.float32(), 1536)),
])

# Create or open table
table = db.create_table("embeddings", schema=schema, mode="overwrite")

# Add vectors
table.add([
    {"id": "doc1", "text": "Hello world", "vector": [0.1] * 1536},
])

# Search
results = table.search([0.1] * 1536).limit(10).to_pandas()
print(results)
