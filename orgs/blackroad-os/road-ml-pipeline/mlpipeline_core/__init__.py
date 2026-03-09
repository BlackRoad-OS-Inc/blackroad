"""RoadML Pipeline - Enterprise Machine Learning Pipeline System.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

A comprehensive ML pipeline framework with:
- End-to-end pipeline orchestration
- Feature store with versioning
- Model registry and lifecycle
- Training job management
- Model serving infrastructure
- Experiment tracking
- Hyperparameter optimization
- Data validation and profiling

Architecture:
    ┌─────────────────────────────────────────────────────────────────┐
    │                     RoadML Pipeline System                       │
    ├─────────────────────────────────────────────────────────────────┤
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
    │  │  Pipeline   │  │    DAG      │  │    Step     │  PIPELINE   │
    │  │ Orchestrate │  │   Execute   │  │  Process    │    LAYER    │
    │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘             │
    │         │                │                │                     │
    │  ┌──────┴────────────────┴────────────────┴──────┐             │
    │  │                Feature Store                   │             │
    │  │   ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐         │   FEATURE   │
    │  │   │Store│  │View │  │Join │  │ TTL │         │    LAYER    │
    │  │   └─────┘  └─────┘  └─────┘  └─────┘         │             │
    │  └──────────────────────┬────────────────────────┘             │
    │                         │                                       │
    │  ┌──────────────────────┴────────────────────────┐             │
    │  │              Model Registry                    │             │
    │  │   ┌────────┐  ┌────────┐  ┌────────┐         │   MODEL     │
    │  │   │Register│  │Version │  │Deploy  │         │   LAYER     │
    │  │   └────────┘  └────────┘  └────────┘         │             │
    │  └──────────────────────┬────────────────────────┘             │
    │                         │                                       │
    │  ┌──────────────────────┴────────────────────────┐             │
    │  │              Training Engine                   │             │
    │  │   ┌────────┐  ┌────────┐  ┌────────┐         │  TRAINING   │
    │  │   │ Job    │  │Distrib │  │ HPO    │         │    LAYER    │
    │  │   └────────┘  └────────┘  └────────┘         │             │
    │  └──────────────────────┬────────────────────────┘             │
    │                         │                                       │
    │  ┌──────────────────────┴────────────────────────┐             │
    │  │              Serving Infrastructure            │             │
    │  │   ┌────────┐  ┌────────┐  ┌────────┐         │   SERVING   │
    │  │   │Endpoint│  │Predict │  │Monitor │         │    LAYER    │
    │  │   └────────┘  └────────┘  └────────┘         │             │
    │  └──────────────────────────────────────────────┘             │
    └─────────────────────────────────────────────────────────────────┘

Example Usage:
    from mlpipeline_core import Pipeline, Step, FeatureStore, ModelRegistry

    # Define pipeline
    @pipeline("training-pipeline")
    def train_model():
        data = load_data()
        features = extract_features(data)
        model = train(features)
        return model

    # Feature store
    store = FeatureStore()
    store.register_feature("user_age", compute_age, ttl=3600)
    features = store.get_features(["user_age", "user_income"], entity_id="user:123")

    # Model registry
    registry = ModelRegistry()
    registry.register("my-model", model, metrics={"accuracy": 0.95})
    registry.promote("my-model", "production")

    # Serving
    endpoint = Endpoint("my-model", registry=registry)
    prediction = endpoint.predict(features)
"""

__version__ = "1.0.0"
__author__ = "BlackRoad OS"

from mlpipeline_core.pipeline.pipeline import (
    Pipeline,
    PipelineConfig,
    PipelineRun,
    PipelineStatus,
)
from mlpipeline_core.pipeline.step import (
    Step,
    StepConfig,
    StepResult,
    StepStatus,
)
from mlpipeline_core.pipeline.dag import DAG, DAGNode
from mlpipeline_core.data.dataset import (
    Dataset,
    DatasetConfig,
    DatasetVersion,
)
from mlpipeline_core.data.loader import DataLoader, BatchLoader
from mlpipeline_core.data.validator import DataValidator, ValidationResult
from mlpipeline_core.model.registry import (
    ModelRegistry,
    ModelVersion,
    ModelStage,
)
from mlpipeline_core.model.artifact import ModelArtifact, ArtifactType
from mlpipeline_core.training.job import TrainingJob, JobConfig, JobStatus
from mlpipeline_core.training.distributed import DistributedTrainer, Strategy
from mlpipeline_core.training.hpo import HPOSearch, SearchSpace, Trial
from mlpipeline_core.serving.endpoint import Endpoint, EndpointConfig
from mlpipeline_core.serving.predictor import Predictor, PredictionResult
from mlpipeline_core.experiment.tracker import (
    ExperimentTracker,
    Experiment,
    Run,
)
from mlpipeline_core.feature.store import FeatureStore, Feature, FeatureView
from mlpipeline_core.metrics.collector import MetricsCollector, ModelMetrics

__all__ = [
    # Pipeline
    "Pipeline",
    "PipelineConfig",
    "PipelineRun",
    "PipelineStatus",
    "Step",
    "StepConfig",
    "StepResult",
    "StepStatus",
    "DAG",
    "DAGNode",
    # Data
    "Dataset",
    "DatasetConfig",
    "DatasetVersion",
    "DataLoader",
    "BatchLoader",
    "DataValidator",
    "ValidationResult",
    # Model
    "ModelRegistry",
    "ModelVersion",
    "ModelStage",
    "ModelArtifact",
    "ArtifactType",
    # Training
    "TrainingJob",
    "JobConfig",
    "JobStatus",
    "DistributedTrainer",
    "Strategy",
    "HPOSearch",
    "SearchSpace",
    "Trial",
    # Serving
    "Endpoint",
    "EndpointConfig",
    "Predictor",
    "PredictionResult",
    # Experiment
    "ExperimentTracker",
    "Experiment",
    "Run",
    # Feature
    "FeatureStore",
    "Feature",
    "FeatureView",
    # Metrics
    "MetricsCollector",
    "ModelMetrics",
]
