"""RoadML Metrics Collector - ML Metrics and Monitoring.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import math
import statistics
import threading
import time
from abc import ABC, abstractmethod
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Tuple, Union

import numpy as np

logger = logging.getLogger(__name__)


class MetricType(Enum):
    """Types of metrics."""

    COUNTER = auto()
    GAUGE = auto()
    HISTOGRAM = auto()
    SUMMARY = auto()


class TaskType(Enum):
    """ML task types for metric computation."""

    BINARY_CLASSIFICATION = auto()
    MULTICLASS_CLASSIFICATION = auto()
    REGRESSION = auto()
    RANKING = auto()
    CLUSTERING = auto()


@dataclass
class Metric:
    """A single metric value."""

    name: str
    value: float
    metric_type: MetricType = MetricType.GAUGE
    timestamp: datetime = field(default_factory=datetime.now)
    labels: Dict[str, str] = field(default_factory=dict)
    description: str = ""


@dataclass
class MetricSeries:
    """Time series of metric values."""

    name: str
    values: List[Tuple[datetime, float]] = field(default_factory=list)
    labels: Dict[str, str] = field(default_factory=dict)

    def add(self, value: float, timestamp: Optional[datetime] = None) -> None:
        """Add value to series."""
        self.values.append((timestamp or datetime.now(), value))

    def get_latest(self) -> Optional[float]:
        """Get latest value."""
        return self.values[-1][1] if self.values else None

    def get_mean(self, window: Optional[timedelta] = None) -> Optional[float]:
        """Get mean value, optionally within window."""
        if not self.values:
            return None

        if window:
            cutoff = datetime.now() - window
            vals = [v for t, v in self.values if t >= cutoff]
        else:
            vals = [v for _, v in self.values]

        return statistics.mean(vals) if vals else None


class ModelMetrics:
    """Compute ML model metrics.

    Supports:
    - Classification metrics (accuracy, precision, recall, F1, AUC)
    - Regression metrics (MSE, MAE, RMSE, R2)
    - Ranking metrics (NDCG, MRR)
    """

    @staticmethod
    def accuracy(y_true: List[Any], y_pred: List[Any]) -> float:
        """Compute accuracy score."""
        if len(y_true) != len(y_pred):
            raise ValueError("Length mismatch")
        if not y_true:
            return 0.0

        correct = sum(1 for t, p in zip(y_true, y_pred) if t == p)
        return correct / len(y_true)

    @staticmethod
    def precision(
        y_true: List[int],
        y_pred: List[int],
        positive_class: int = 1,
    ) -> float:
        """Compute precision score."""
        true_positives = sum(
            1 for t, p in zip(y_true, y_pred)
            if t == positive_class and p == positive_class
        )
        predicted_positives = sum(
            1 for p in y_pred if p == positive_class
        )

        return true_positives / predicted_positives if predicted_positives > 0 else 0.0

    @staticmethod
    def recall(
        y_true: List[int],
        y_pred: List[int],
        positive_class: int = 1,
    ) -> float:
        """Compute recall score."""
        true_positives = sum(
            1 for t, p in zip(y_true, y_pred)
            if t == positive_class and p == positive_class
        )
        actual_positives = sum(
            1 for t in y_true if t == positive_class
        )

        return true_positives / actual_positives if actual_positives > 0 else 0.0

    @staticmethod
    def f1_score(
        y_true: List[int],
        y_pred: List[int],
        positive_class: int = 1,
    ) -> float:
        """Compute F1 score."""
        prec = ModelMetrics.precision(y_true, y_pred, positive_class)
        rec = ModelMetrics.recall(y_true, y_pred, positive_class)

        if prec + rec == 0:
            return 0.0

        return 2 * (prec * rec) / (prec + rec)

    @staticmethod
    def confusion_matrix(
        y_true: List[int],
        y_pred: List[int],
        labels: Optional[List[int]] = None,
    ) -> List[List[int]]:
        """Compute confusion matrix."""
        if labels is None:
            labels = sorted(set(y_true) | set(y_pred))

        label_to_idx = {label: idx for idx, label in enumerate(labels)}
        n_labels = len(labels)
        matrix = [[0] * n_labels for _ in range(n_labels)]

        for t, p in zip(y_true, y_pred):
            if t in label_to_idx and p in label_to_idx:
                matrix[label_to_idx[t]][label_to_idx[p]] += 1

        return matrix

    @staticmethod
    def auc_roc(
        y_true: List[int],
        y_scores: List[float],
        positive_class: int = 1,
    ) -> float:
        """Compute Area Under ROC Curve."""
        pairs = sorted(zip(y_scores, y_true), reverse=True)

        tp, fp = 0, 0
        prev_score = None
        prev_tp, prev_fp = 0, 0
        auc = 0.0

        total_positives = sum(1 for y in y_true if y == positive_class)
        total_negatives = len(y_true) - total_positives

        if total_positives == 0 or total_negatives == 0:
            return 0.5

        for score, label in pairs:
            if prev_score is not None and score != prev_score:
                auc += (fp - prev_fp) * (tp + prev_tp) / 2
                prev_tp, prev_fp = tp, fp

            if label == positive_class:
                tp += 1
            else:
                fp += 1
            prev_score = score

        auc += (fp - prev_fp) * (tp + prev_tp) / 2

        return auc / (total_positives * total_negatives)

    @staticmethod
    def mse(y_true: List[float], y_pred: List[float]) -> float:
        """Compute Mean Squared Error."""
        if len(y_true) != len(y_pred) or not y_true:
            return 0.0

        squared_errors = [(t - p) ** 2 for t, p in zip(y_true, y_pred)]
        return sum(squared_errors) / len(squared_errors)

    @staticmethod
    def rmse(y_true: List[float], y_pred: List[float]) -> float:
        """Compute Root Mean Squared Error."""
        return math.sqrt(ModelMetrics.mse(y_true, y_pred))

    @staticmethod
    def mae(y_true: List[float], y_pred: List[float]) -> float:
        """Compute Mean Absolute Error."""
        if len(y_true) != len(y_pred) or not y_true:
            return 0.0

        abs_errors = [abs(t - p) for t, p in zip(y_true, y_pred)]
        return sum(abs_errors) / len(abs_errors)

    @staticmethod
    def r2_score(y_true: List[float], y_pred: List[float]) -> float:
        """Compute R-squared (coefficient of determination)."""
        if len(y_true) != len(y_pred) or len(y_true) < 2:
            return 0.0

        mean_y = sum(y_true) / len(y_true)
        ss_tot = sum((y - mean_y) ** 2 for y in y_true)
        ss_res = sum((t - p) ** 2 for t, p in zip(y_true, y_pred))

        if ss_tot == 0:
            return 0.0

        return 1 - (ss_res / ss_tot)

    @staticmethod
    def ndcg(
        y_true: List[float],
        y_pred: List[float],
        k: Optional[int] = None,
    ) -> float:
        """Compute Normalized Discounted Cumulative Gain."""
        if not y_true:
            return 0.0

        sorted_pairs = sorted(
            zip(y_pred, y_true),
            key=lambda x: x[0],
            reverse=True,
        )

        if k:
            sorted_pairs = sorted_pairs[:k]

        dcg = sum(
            true / math.log2(idx + 2)
            for idx, (_, true) in enumerate(sorted_pairs)
        )

        ideal_pairs = sorted(y_true, reverse=True)
        if k:
            ideal_pairs = ideal_pairs[:k]

        idcg = sum(
            true / math.log2(idx + 2)
            for idx, true in enumerate(ideal_pairs)
        )

        return dcg / idcg if idcg > 0 else 0.0

    @staticmethod
    def mrr(rankings: List[List[int]], relevant: List[int]) -> float:
        """Compute Mean Reciprocal Rank."""
        if not rankings:
            return 0.0

        reciprocal_ranks = []
        for ranking, rel in zip(rankings, relevant):
            try:
                rank = ranking.index(rel) + 1
                reciprocal_ranks.append(1.0 / rank)
            except ValueError:
                reciprocal_ranks.append(0.0)

        return sum(reciprocal_ranks) / len(reciprocal_ranks)


@dataclass
class PredictionMetrics:
    """Metrics for prediction serving."""

    total_predictions: int = 0
    successful_predictions: int = 0
    failed_predictions: int = 0
    total_latency_ms: float = 0.0
    latency_histogram: List[float] = field(default_factory=list)

    @property
    def success_rate(self) -> float:
        """Get success rate."""
        if self.total_predictions == 0:
            return 0.0
        return self.successful_predictions / self.total_predictions

    @property
    def avg_latency_ms(self) -> float:
        """Get average latency."""
        if self.total_predictions == 0:
            return 0.0
        return self.total_latency_ms / self.total_predictions

    @property
    def p50_latency_ms(self) -> float:
        """Get p50 latency."""
        if not self.latency_histogram:
            return 0.0
        sorted_latencies = sorted(self.latency_histogram)
        idx = len(sorted_latencies) // 2
        return sorted_latencies[idx]

    @property
    def p95_latency_ms(self) -> float:
        """Get p95 latency."""
        if not self.latency_histogram:
            return 0.0
        sorted_latencies = sorted(self.latency_histogram)
        idx = int(len(sorted_latencies) * 0.95)
        return sorted_latencies[min(idx, len(sorted_latencies) - 1)]

    @property
    def p99_latency_ms(self) -> float:
        """Get p99 latency."""
        if not self.latency_histogram:
            return 0.0
        sorted_latencies = sorted(self.latency_histogram)
        idx = int(len(sorted_latencies) * 0.99)
        return sorted_latencies[min(idx, len(sorted_latencies) - 1)]

    def record_prediction(
        self,
        success: bool,
        latency_ms: float,
    ) -> None:
        """Record a prediction."""
        self.total_predictions += 1
        if success:
            self.successful_predictions += 1
        else:
            self.failed_predictions += 1

        self.total_latency_ms += latency_ms
        self.latency_histogram.append(latency_ms)

        if len(self.latency_histogram) > 10000:
            self.latency_histogram = self.latency_histogram[-5000:]

    def to_dict(self) -> Dict[str, Any]:
        """Convert to dictionary."""
        return {
            "total_predictions": self.total_predictions,
            "successful_predictions": self.successful_predictions,
            "failed_predictions": self.failed_predictions,
            "success_rate": self.success_rate,
            "avg_latency_ms": self.avg_latency_ms,
            "p50_latency_ms": self.p50_latency_ms,
            "p95_latency_ms": self.p95_latency_ms,
            "p99_latency_ms": self.p99_latency_ms,
        }


class DataDriftDetector:
    """Detect data drift between training and production data.

    Implements statistical tests for distribution shift detection:
    - Kolmogorov-Smirnov test for continuous features
    - Chi-squared test for categorical features
    - Population Stability Index (PSI)
    """

    def __init__(
        self,
        reference_data: Optional[Dict[str, List[Any]]] = None,
        drift_threshold: float = 0.1,
    ):
        self.reference_data = reference_data or {}
        self.drift_threshold = drift_threshold
        self._lock = threading.RLock()

    def set_reference(self, feature_name: str, values: List[Any]) -> None:
        """Set reference distribution for a feature."""
        with self._lock:
            self.reference_data[feature_name] = values

    def compute_psi(
        self,
        feature_name: str,
        current_values: List[float],
        n_bins: int = 10,
    ) -> float:
        """Compute Population Stability Index.

        PSI < 0.1: No significant drift
        0.1 <= PSI < 0.25: Moderate drift
        PSI >= 0.25: Significant drift
        """
        if feature_name not in self.reference_data:
            return 0.0

        reference = self.reference_data[feature_name]
        if not reference or not current_values:
            return 0.0

        all_values = list(reference) + list(current_values)
        min_val, max_val = min(all_values), max(all_values)

        if min_val == max_val:
            return 0.0

        bin_width = (max_val - min_val) / n_bins
        bins = [min_val + i * bin_width for i in range(n_bins + 1)]

        def get_bin_counts(values: List[float]) -> List[float]:
            counts = [0.0] * n_bins
            for v in values:
                bin_idx = min(int((v - min_val) / bin_width), n_bins - 1)
                counts[bin_idx] += 1
            total = sum(counts)
            if total == 0:
                return [1 / n_bins] * n_bins
            return [c / total + 1e-10 for c in counts]

        ref_pcts = get_bin_counts(reference)
        curr_pcts = get_bin_counts(current_values)

        psi = sum(
            (curr - ref) * math.log(curr / ref)
            for ref, curr in zip(ref_pcts, curr_pcts)
        )

        return psi

    def compute_ks_statistic(
        self,
        feature_name: str,
        current_values: List[float],
    ) -> Tuple[float, bool]:
        """Compute Kolmogorov-Smirnov statistic.

        Returns (statistic, is_drifted).
        """
        if feature_name not in self.reference_data:
            return 0.0, False

        reference = sorted(self.reference_data[feature_name])
        current = sorted(current_values)

        if not reference or not current:
            return 0.0, False

        all_values = sorted(set(reference + current))
        max_diff = 0.0

        for val in all_values:
            ref_cdf = sum(1 for v in reference if v <= val) / len(reference)
            curr_cdf = sum(1 for v in current if v <= val) / len(current)
            max_diff = max(max_diff, abs(ref_cdf - curr_cdf))

        is_drifted = max_diff > self.drift_threshold
        return max_diff, is_drifted

    def detect_drift(
        self,
        current_data: Dict[str, List[Any]],
    ) -> Dict[str, Dict[str, Any]]:
        """Detect drift for all features.

        Returns drift report for each feature.
        """
        report = {}

        for feature_name, current_values in current_data.items():
            if feature_name not in self.reference_data:
                continue

            if all(isinstance(v, (int, float)) for v in current_values):
                psi = self.compute_psi(feature_name, current_values)
                ks_stat, ks_drifted = self.compute_ks_statistic(
                    feature_name, current_values
                )

                report[feature_name] = {
                    "psi": psi,
                    "ks_statistic": ks_stat,
                    "is_drifted": psi >= 0.1 or ks_drifted,
                    "drift_severity": "high" if psi >= 0.25 else "moderate" if psi >= 0.1 else "none",
                }
            else:
                report[feature_name] = {
                    "is_drifted": False,
                    "drift_severity": "unknown",
                }

        return report


class PerformanceMonitor:
    """Monitor model performance over time.

    Features:
    - Performance degradation detection
    - Automatic alerting
    - Trend analysis
    """

    def __init__(
        self,
        metric_name: str = "accuracy",
        degradation_threshold: float = 0.05,
        window_size: int = 100,
    ):
        self.metric_name = metric_name
        self.degradation_threshold = degradation_threshold
        self.window_size = window_size

        self._history: List[Tuple[datetime, float]] = []
        self._baseline: Optional[float] = None
        self._lock = threading.RLock()
        self._alerts: List[Dict[str, Any]] = []

    def set_baseline(self, value: float) -> None:
        """Set baseline performance value."""
        with self._lock:
            self._baseline = value

    def record(self, value: float, timestamp: Optional[datetime] = None) -> None:
        """Record performance value."""
        with self._lock:
            self._history.append((timestamp or datetime.now(), value))

            if len(self._history) > self.window_size * 2:
                self._history = self._history[-self.window_size:]

            self._check_degradation(value)

    def _check_degradation(self, current_value: float) -> None:
        """Check for performance degradation."""
        if self._baseline is None:
            return

        degradation = (self._baseline - current_value) / self._baseline

        if degradation > self.degradation_threshold:
            self._alerts.append({
                "timestamp": datetime.now(),
                "metric": self.metric_name,
                "baseline": self._baseline,
                "current": current_value,
                "degradation_pct": degradation * 100,
                "severity": "critical" if degradation > 0.2 else "warning",
            })
            logger.warning(
                f"Performance degradation detected: {self.metric_name} "
                f"dropped {degradation * 100:.1f}% from baseline"
            )

    def get_trend(self) -> Optional[str]:
        """Get performance trend.

        Returns: "improving", "degrading", or "stable"
        """
        with self._lock:
            if len(self._history) < 10:
                return None

            recent = [v for _, v in self._history[-10:]]
            older = [v for _, v in self._history[-20:-10]] if len(self._history) >= 20 else recent

            recent_avg = sum(recent) / len(recent)
            older_avg = sum(older) / len(older)

            diff = (recent_avg - older_avg) / older_avg if older_avg != 0 else 0

            if diff > 0.02:
                return "improving"
            elif diff < -0.02:
                return "degrading"
            else:
                return "stable"

    def get_alerts(self, since: Optional[datetime] = None) -> List[Dict[str, Any]]:
        """Get performance alerts."""
        with self._lock:
            if since is None:
                return self._alerts.copy()
            return [a for a in self._alerts if a["timestamp"] >= since]

    def get_summary(self) -> Dict[str, Any]:
        """Get performance summary."""
        with self._lock:
            if not self._history:
                return {}

            values = [v for _, v in self._history]

            return {
                "metric_name": self.metric_name,
                "baseline": self._baseline,
                "current": values[-1] if values else None,
                "mean": statistics.mean(values),
                "std": statistics.stdev(values) if len(values) > 1 else 0,
                "min": min(values),
                "max": max(values),
                "trend": self.get_trend(),
                "num_alerts": len(self._alerts),
                "samples": len(self._history),
            }


class MetricsCollector:
    """Central metrics collector.

    Aggregates metrics from multiple sources and provides
    unified access to all ML metrics.

    Architecture:
    ┌─────────────────────────────────────────────────────────────┐
    │                    Metrics Collector                         │
    ├─────────────────────────────────────────────────────────────┤
    │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
    │  │   Model     │  │  Prediction │  │     Data Drift      │  │
    │  │   Metrics   │  │   Metrics   │  │     Detector        │  │
    │  └─────────────┘  └─────────────┘  └─────────────────────┘  │
    ├─────────────────────────────────────────────────────────────┤
    │  ┌─────────────────────────────────────────────────────────┐│
    │  │                Performance Monitors                      ││
    │  │  - Accuracy tracking                                     ││
    │  │  - Latency monitoring                                    ││
    │  │  - Throughput metrics                                    ││
    │  └─────────────────────────────────────────────────────────┘│
    ├─────────────────────────────────────────────────────────────┤
    │  ┌─────────────────────────────────────────────────────────┐│
    │  │                  Time Series Storage                     ││
    │  │  - Metric history                                        ││
    │  │  - Aggregations                                          ││
    │  │  - Export formats                                        ││
    │  └─────────────────────────────────────────────────────────┘│
    └─────────────────────────────────────────────────────────────┘
    """

    def __init__(self, project: str = "default"):
        self.project = project
        self._metrics: Dict[str, MetricSeries] = {}
        self._prediction_metrics: Dict[str, PredictionMetrics] = {}
        self._performance_monitors: Dict[str, PerformanceMonitor] = {}
        self._drift_detectors: Dict[str, DataDriftDetector] = {}
        self._lock = threading.RLock()

        logger.info(f"MetricsCollector initialized for project: {project}")

    def record_metric(
        self,
        name: str,
        value: float,
        labels: Optional[Dict[str, str]] = None,
        timestamp: Optional[datetime] = None,
    ) -> None:
        """Record a metric value."""
        with self._lock:
            key = self._make_key(name, labels)
            if key not in self._metrics:
                self._metrics[key] = MetricSeries(name=name, labels=labels or {})
            self._metrics[key].add(value, timestamp)

    def _make_key(self, name: str, labels: Optional[Dict[str, str]]) -> str:
        """Create storage key from name and labels."""
        if not labels:
            return name
        label_str = ",".join(f"{k}={v}" for k, v in sorted(labels.items()))
        return f"{name}{{{label_str}}}"

    def get_metric(
        self,
        name: str,
        labels: Optional[Dict[str, str]] = None,
    ) -> Optional[MetricSeries]:
        """Get metric series."""
        key = self._make_key(name, labels)
        return self._metrics.get(key)

    def get_prediction_metrics(self, model_name: str) -> PredictionMetrics:
        """Get or create prediction metrics for a model."""
        with self._lock:
            if model_name not in self._prediction_metrics:
                self._prediction_metrics[model_name] = PredictionMetrics()
            return self._prediction_metrics[model_name]

    def record_prediction(
        self,
        model_name: str,
        success: bool,
        latency_ms: float,
    ) -> None:
        """Record a prediction event."""
        metrics = self.get_prediction_metrics(model_name)
        metrics.record_prediction(success, latency_ms)

    def create_performance_monitor(
        self,
        name: str,
        metric_name: str = "accuracy",
        baseline: Optional[float] = None,
        degradation_threshold: float = 0.05,
    ) -> PerformanceMonitor:
        """Create a performance monitor."""
        monitor = PerformanceMonitor(
            metric_name=metric_name,
            degradation_threshold=degradation_threshold,
        )
        if baseline is not None:
            monitor.set_baseline(baseline)

        with self._lock:
            self._performance_monitors[name] = monitor

        return monitor

    def get_performance_monitor(self, name: str) -> Optional[PerformanceMonitor]:
        """Get performance monitor by name."""
        return self._performance_monitors.get(name)

    def create_drift_detector(
        self,
        name: str,
        reference_data: Optional[Dict[str, List[Any]]] = None,
        drift_threshold: float = 0.1,
    ) -> DataDriftDetector:
        """Create a data drift detector."""
        detector = DataDriftDetector(
            reference_data=reference_data,
            drift_threshold=drift_threshold,
        )

        with self._lock:
            self._drift_detectors[name] = detector

        return detector

    def get_drift_detector(self, name: str) -> Optional[DataDriftDetector]:
        """Get drift detector by name."""
        return self._drift_detectors.get(name)

    def get_all_metrics(self) -> Dict[str, Any]:
        """Get all collected metrics."""
        with self._lock:
            return {
                "metrics": {
                    key: {
                        "name": series.name,
                        "labels": series.labels,
                        "latest": series.get_latest(),
                        "count": len(series.values),
                    }
                    for key, series in self._metrics.items()
                },
                "prediction_metrics": {
                    name: metrics.to_dict()
                    for name, metrics in self._prediction_metrics.items()
                },
                "performance_monitors": {
                    name: monitor.get_summary()
                    for name, monitor in self._performance_monitors.items()
                },
            }

    def export_prometheus(self) -> str:
        """Export metrics in Prometheus format."""
        lines = []

        with self._lock:
            for key, series in self._metrics.items():
                latest = series.get_latest()
                if latest is not None:
                    labels = ",".join(
                        f'{k}="{v}"' for k, v in series.labels.items()
                    )
                    if labels:
                        lines.append(f"{series.name}{{{labels}}} {latest}")
                    else:
                        lines.append(f"{series.name} {latest}")

            for model_name, metrics in self._prediction_metrics.items():
                lines.append(f'prediction_total{{model="{model_name}"}} {metrics.total_predictions}')
                lines.append(f'prediction_success{{model="{model_name}"}} {metrics.successful_predictions}')
                lines.append(f'prediction_latency_avg{{model="{model_name}"}} {metrics.avg_latency_ms}')
                lines.append(f'prediction_latency_p95{{model="{model_name}"}} {metrics.p95_latency_ms}')

        return "\n".join(lines)

    def reset(self) -> None:
        """Reset all metrics."""
        with self._lock:
            self._metrics.clear()
            self._prediction_metrics.clear()
            logger.info("All metrics reset")


__all__ = [
    "MetricsCollector",
    "ModelMetrics",
    "PredictionMetrics",
    "DataDriftDetector",
    "PerformanceMonitor",
    "Metric",
    "MetricSeries",
    "MetricType",
    "TaskType",
]
