"""Lucidia model definition: simple decoder-only transformer skeleton."""

class TransformerModel:
    def __init__(self, config):
        self.config = config

    def forward(self, x):
        """Forward pass placeholder."""
        raise NotImplementedError("Model forward pass not implemented")
