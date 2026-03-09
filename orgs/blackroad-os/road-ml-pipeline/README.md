# RoadML Pipeline

**Enterprise ML Pipeline Orchestration System**

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

## Overview

RoadML Pipeline is a comprehensive machine learning pipeline orchestration system providing end-to-end ML lifecycle management with enterprise-grade features for production environments.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         RoadML Pipeline System                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                      Pipeline Orchestration                           │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────────────┐   │   │
│  │  │ Pipeline│───▶│  Step   │───▶│   DAG   │───▶│ Parallel Runner │   │   │
│  │  │  Define │    │ Execute │    │  Build  │    │   (Topological) │   │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌──────────────────────────────────────────────────────────────────────┐   │
│  │                         Data Management                               │   │
│  │  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────────────┐   │   │
│  │  │ Dataset │───▶│ Loader  │───▶│Validator│───▶│   Transform     │   │   │
│  │  │ Define  │    │  Batch  │    │ Schema  │    │   Pipeline      │   │   │
│  │  └─────────┘    └─────────┘    └─────────┘    └─────────────────┘   │   │
│  └──────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────┐    │
│  │ Feature Store  │  │ Model Registry │  │   Experiment Tracking      │    │
│  │                │  │                │  │                            │    │
│  │ - Online Store │  │ - Versioning   │  │ - Run Management           │    │
│  │ - Offline Store│  │ - Stage Mgmt   │  │ - Parameter Logging        │    │
│  │ - Point-in-time│  │ - Artifacts    │  │ - Metric Tracking          │    │
│  │ - Materialized │  │ - Promotion    │  │ - Artifact Storage         │    │
│  └────────────────┘  └────────────────┘  └────────────────────────────┘    │
│                                                                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────────────────┐    │
│  │   Training     │  │    Serving     │  │       Metrics              │    │
│  │                │  │                │  │                            │    │
│  │ - Distributed  │  │ - Endpoints    │  │ - Model Metrics            │    │
│  │ - HPO Search   │  │ - Predictors   │  │ - Drift Detection          │    │
│  │ - Checkpoints  │  │ - Auto-scale   │  │ - Performance Monitor      │    │
│  │ - Early Stop   │  │ - Batching     │  │ - Prometheus Export        │    │
│  └────────────────┘  └────────────────┘  └────────────────────────────┘    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Features

### Pipeline Orchestration
- **DAG-based Execution**: Define complex pipelines with dependencies
- **Step Decorators**: Easy-to-use decorators for defining pipeline steps
- **Parallel Execution**: Automatic parallelization of independent steps
- **Retry Logic**: Configurable retry policies for transient failures
- **Caching**: Intelligent caching of step outputs

### Feature Store
- **Online Store**: Low-latency feature serving with TTL
- **Offline Store**: Historical feature storage for training
- **Point-in-Time Correctness**: Accurate historical feature retrieval
- **Materialization**: Batch materialization from offline to online store
- **Feature Statistics**: Automated feature profiling and statistics

### Model Registry
- **Version Control**: Semantic versioning for all models
- **Stage Management**: None → Staging → Production → Archived
- **Artifact Storage**: Store model artifacts with metadata
- **Lineage Tracking**: Track model lineage and dependencies

### Training Infrastructure
- **Distributed Training**: Data/Model/Pipeline parallelism
- **Hyperparameter Optimization**: Grid, Random, Bayesian, TPE, Hyperband
- **Checkpointing**: Automatic checkpoint saving and recovery
- **Early Stopping**: Configurable early stopping strategies

### Model Serving
- **Endpoint Management**: Deploy models as HTTP endpoints
- **Auto-scaling**: Scale based on traffic and resource utilization
- **Batch Prediction**: Efficient batch inference
- **A/B Testing**: Traffic splitting for model comparison

### ML Metrics & Monitoring
- **Classification Metrics**: Accuracy, Precision, Recall, F1, AUC-ROC
- **Regression Metrics**: MSE, RMSE, MAE, R²
- **Ranking Metrics**: NDCG, MRR
- **Data Drift Detection**: PSI, KS-test for distribution monitoring
- **Performance Monitoring**: Real-time performance degradation alerts

## Installation

```bash
pip install road-ml-pipeline

# With optional dependencies
pip install road-ml-pipeline[distributed]  # Ray, Dask
pip install road-ml-pipeline[serving]      # FastAPI, gRPC
pip install road-ml-pipeline[all]          # All extras
```

## Quick Start

### Define a Pipeline

```python
from mlpipeline_core import Pipeline

pipeline = Pipeline(name="training-pipeline")

@pipeline.step(name="load_data")
def load_data():
    return {"data": [...]}

@pipeline.step(name="preprocess", depends_on=["load_data"])
def preprocess(data):
    return {"processed": transform(data)}

@pipeline.step(name="train", depends_on=["preprocess"])
def train(processed):
    model = Model()
    model.fit(processed)
    return {"model": model}

# Execute pipeline
run = pipeline.run()
```

### Feature Store

```python
from mlpipeline_core.feature import FeatureStore, Feature, FeatureView, FeatureType

store = FeatureStore(project="my-project")

# Define features
view = FeatureView(
    name="user_features",
    features=[
        Feature(name="age", dtype=FeatureType.INT),
        Feature(name="income", dtype=FeatureType.FLOAT),
    ],
    source="users_table",
    entity_columns=["user_id"],
)
store.register_feature_view(view)

# Ingest features
store.ingest("user_features", data)

# Retrieve for serving
vectors = store.get_online_features(
    ["user_features:age", "user_features:income"],
    [{"user_id": 123}],
)
```

### Model Registry

```python
from mlpipeline_core.model import ModelRegistry, ModelStage

registry = ModelRegistry()

# Register model
version = registry.register(
    name="fraud-detector",
    model=trained_model,
    metrics={"auc": 0.95, "precision": 0.92},
)

# Promote to production
registry.promote("fraud-detector", version.version, ModelStage.PRODUCTION)

# Load for inference
model = registry.load("fraud-detector", stage=ModelStage.PRODUCTION)
```

### Experiment Tracking

```python
from mlpipeline_core.experiment import ExperimentTracker

tracker = ExperimentTracker()
experiment = tracker.create_experiment(name="model-comparison")

tracker.start_run(experiment.experiment_id)
tracker.log_params({"learning_rate": 0.01, "epochs": 100})
tracker.log_metrics({"accuracy": 0.95, "loss": 0.05})
tracker.log_artifact("model.pkl")
tracker.end_run()
```

### Hyperparameter Optimization

```python
from mlpipeline_core.training import HPOSearch, SearchSpace, SearchStrategy

space = SearchSpace()
space.log_uniform("learning_rate", 1e-5, 1e-1)
space.choice("optimizer", ["adam", "sgd", "rmsprop"])
space.uniform("dropout", 0.1, 0.5)

search = HPOSearch(
    objective=train_and_evaluate,
    search_space=space,
    strategy=SearchStrategy.BAYESIAN,
    max_trials=100,
)

best_trial = search.run()
print(f"Best params: {best_trial.params}")
```

## License

Proprietary - BlackRoad OS, Inc. All rights reserved.
