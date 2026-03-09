import faiss
import numpy as np

# Create index
dimension = 1536
index = faiss.IndexFlatL2(dimension)

# For large scale, use IVF
nlist = 100
quantizer = faiss.IndexFlatL2(dimension)
index_ivf = faiss.IndexIVFFlat(quantizer, dimension, nlist)

# Add vectors
vectors = np.random.random((10000, dimension)).astype('float32')
index_ivf.train(vectors)
index_ivf.add(vectors)

# Search
query = np.random.random((1, dimension)).astype('float32')
distances, indices = index_ivf.search(query, k=10)
print(f"Nearest neighbors: {indices}")

# Save/Load
faiss.write_index(index_ivf, "blackroad.index")
loaded_index = faiss.read_index("blackroad.index")
