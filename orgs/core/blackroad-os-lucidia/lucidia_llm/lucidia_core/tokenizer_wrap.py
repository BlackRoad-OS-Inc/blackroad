"""Tokenizer wrapper for Lucidia."""


class TokenizerWrapper:
    def __init__(self, tokenizer):
        self.tokenizer = tokenizer

    def encode(self, text):
        """Encode text into token ids (placeholder)."""
        raise NotImplementedError("Encode method not implemented")

    def decode(self, token_ids):
        """Decode token ids into text (placeholder)."""
        raise NotImplementedError("Decode method not implemented")
