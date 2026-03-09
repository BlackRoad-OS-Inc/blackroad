"""AutoML module - Automated Machine Learning."""

from mlpipeline_core.automl.search import AutoMLSearch, AutoMLConfig, AutoMLResult
from mlpipeline_core.automl.preprocessing import AutoPreprocessor, FeatureSelector
from mlpipeline_core.automl.ensemble import AutoEnsemble, EnsembleStrategy

__all__ = [
    "AutoMLSearch",
    "AutoMLConfig",
    "AutoMLResult",
    "AutoPreprocessor",
    "FeatureSelector",
    "AutoEnsemble",
    "EnsembleStrategy",
]
