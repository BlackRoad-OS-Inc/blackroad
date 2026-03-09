"""Tests for metrics module.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

import pytest

from mlpipeline_core.metrics import (
    MetricsCollector,
    ModelMetrics,
    PredictionMetrics,
    DataDriftDetector,
    PerformanceMonitor,
)


class TestModelMetrics:
    """Test ModelMetrics class."""

    def test_accuracy(self):
        """Test accuracy computation."""
        y_true = [0, 1, 1, 0, 1]
        y_pred = [0, 1, 0, 0, 1]

        acc = ModelMetrics.accuracy(y_true, y_pred)
        assert acc == 0.8

    def test_precision(self):
        """Test precision computation."""
        y_true = [0, 1, 1, 0, 1, 1]
        y_pred = [1, 1, 1, 0, 0, 1]

        prec = ModelMetrics.precision(y_true, y_pred)
        assert prec == 0.75

    def test_recall(self):
        """Test recall computation."""
        y_true = [0, 1, 1, 0, 1, 1]
        y_pred = [1, 1, 1, 0, 0, 1]

        rec = ModelMetrics.recall(y_true, y_pred)
        assert rec == 0.75

    def test_f1_score(self):
        """Test F1 score computation."""
        y_true = [0, 1, 1, 0, 1, 1]
        y_pred = [1, 1, 1, 0, 0, 1]

        f1 = ModelMetrics.f1_score(y_true, y_pred)
        assert f1 == 0.75

    def test_mse(self):
        """Test MSE computation."""
        y_true = [1.0, 2.0, 3.0, 4.0]
        y_pred = [1.1, 2.1, 2.9, 4.2]

        mse = ModelMetrics.mse(y_true, y_pred)
        assert mse == pytest.approx(0.0175, rel=0.01)

    def test_rmse(self):
        """Test RMSE computation."""
        y_true = [1.0, 2.0, 3.0, 4.0]
        y_pred = [1.0, 2.0, 3.0, 4.0]

        rmse = ModelMetrics.rmse(y_true, y_pred)
        assert rmse == 0.0

    def test_mae(self):
        """Test MAE computation."""
        y_true = [1.0, 2.0, 3.0, 4.0]
        y_pred = [1.5, 2.5, 3.5, 4.5]

        mae = ModelMetrics.mae(y_true, y_pred)
        assert mae == 0.5

    def test_r2_score(self):
        """Test R2 score computation."""
        y_true = [1.0, 2.0, 3.0, 4.0, 5.0]
        y_pred = [1.1, 2.0, 2.9, 4.1, 4.9]

        r2 = ModelMetrics.r2_score(y_true, y_pred)
        assert r2 > 0.95

    def test_confusion_matrix(self):
        """Test confusion matrix."""
        y_true = [0, 0, 1, 1]
        y_pred = [0, 1, 0, 1]

        cm = ModelMetrics.confusion_matrix(y_true, y_pred)
        assert cm[0][0] == 1  # TN
        assert cm[0][1] == 1  # FP
        assert cm[1][0] == 1  # FN
        assert cm[1][1] == 1  # TP


class TestPredictionMetrics:
    """Test PredictionMetrics class."""

    def test_record_predictions(self):
        """Test recording predictions."""
        metrics = PredictionMetrics()

        metrics.record_prediction(True, 10.0)
        metrics.record_prediction(True, 15.0)
        metrics.record_prediction(False, 20.0)

        assert metrics.total_predictions == 3
        assert metrics.successful_predictions == 2
        assert metrics.failed_predictions == 1

    def test_success_rate(self):
        """Test success rate calculation."""
        metrics = PredictionMetrics()

        metrics.record_prediction(True, 10.0)
        metrics.record_prediction(False, 15.0)

        assert metrics.success_rate == 0.5

    def test_latency_percentiles(self):
        """Test latency percentiles."""
        metrics = PredictionMetrics()

        for i in range(100):
            metrics.record_prediction(True, float(i + 1))

        assert metrics.p50_latency_ms == 50.0
        assert metrics.p95_latency_ms == 95.0


class TestDataDriftDetector:
    """Test DataDriftDetector class."""

    def test_psi_no_drift(self):
        """Test PSI with no drift."""
        detector = DataDriftDetector()
        reference = [float(i) for i in range(100)]
        detector.set_reference("feature1", reference)

        current = [float(i) for i in range(100)]
        psi = detector.compute_psi("feature1", current)

        assert psi < 0.1

    def test_psi_with_drift(self):
        """Test PSI with drift."""
        detector = DataDriftDetector()
        reference = [float(i) for i in range(100)]
        detector.set_reference("feature1", reference)

        current = [float(i + 50) for i in range(100)]
        psi = detector.compute_psi("feature1", current)

        assert psi > 0.1

    def test_ks_statistic(self):
        """Test KS statistic."""
        detector = DataDriftDetector(drift_threshold=0.3)
        reference = list(range(100))
        detector.set_reference("feature1", reference)

        current = list(range(100))
        ks, drifted = detector.compute_ks_statistic("feature1", current)

        assert not drifted
        assert ks < 0.3


class TestPerformanceMonitor:
    """Test PerformanceMonitor class."""

    def test_baseline_tracking(self):
        """Test baseline tracking."""
        monitor = PerformanceMonitor(metric_name="accuracy")
        monitor.set_baseline(0.95)

        monitor.record(0.94)
        monitor.record(0.93)

        summary = monitor.get_summary()
        assert summary["baseline"] == 0.95
        assert summary["current"] == 0.93

    def test_degradation_alert(self):
        """Test degradation alerting."""
        monitor = PerformanceMonitor(
            metric_name="accuracy",
            degradation_threshold=0.05,
        )
        monitor.set_baseline(1.0)

        monitor.record(0.90)

        alerts = monitor.get_alerts()
        assert len(alerts) == 1
        assert alerts[0]["severity"] == "warning"


class TestMetricsCollector:
    """Test MetricsCollector class."""

    def test_record_metric(self):
        """Test metric recording."""
        collector = MetricsCollector()
        collector.record_metric("requests", 100)
        collector.record_metric("requests", 150)

        series = collector.get_metric("requests")
        assert series is not None
        assert series.get_latest() == 150

    def test_labeled_metrics(self):
        """Test labeled metrics."""
        collector = MetricsCollector()
        collector.record_metric("latency", 10.0, labels={"endpoint": "/api/v1"})
        collector.record_metric("latency", 20.0, labels={"endpoint": "/api/v2"})

        v1 = collector.get_metric("latency", {"endpoint": "/api/v1"})
        v2 = collector.get_metric("latency", {"endpoint": "/api/v2"})

        assert v1.get_latest() == 10.0
        assert v2.get_latest() == 20.0

    def test_prometheus_export(self):
        """Test Prometheus format export."""
        collector = MetricsCollector()
        collector.record_metric("test_metric", 42.0)
        collector.record_prediction("model1", True, 10.0)

        output = collector.export_prometheus()
        assert "test_metric 42.0" in output
        assert "prediction_total" in output
