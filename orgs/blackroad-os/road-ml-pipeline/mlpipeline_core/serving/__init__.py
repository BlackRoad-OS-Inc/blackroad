"""Serving module - Model serving infrastructure."""

from mlpipeline_core.serving.endpoint import Endpoint, EndpointConfig
from mlpipeline_core.serving.predictor import Predictor, PredictionResult

__all__ = ["Endpoint", "EndpointConfig", "Predictor", "PredictionResult"]
