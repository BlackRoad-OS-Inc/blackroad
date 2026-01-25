"""Memory store for Lucidia: handles storing and retrieving embeddings."""


class MemoryStore:
    def __init__(self, storage_path):
        self.storage_path = storage_path

    def add(self, key, embedding):
        """Add an embedding to the store."""
        raise NotImplementedError("Memory add method not implemented")

    def query(self, embedding, top_k=5):
        """Query the store with an embedding."""
        raise NotImplementedError("Memory query method not implemented")
