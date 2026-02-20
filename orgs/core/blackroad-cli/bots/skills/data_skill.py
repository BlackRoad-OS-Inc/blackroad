"""Data/Analytics utility skills for ETL, statistics, and time series.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.

This software is proprietary and confidential. Unauthorized copying, transfer,
or reproduction of this file, via any medium, is strictly prohibited.

Licensed for non-commercial testing and evaluation purposes only.
Commercial use requires a separate license agreement with BlackRoad OS, Inc.

For licensing inquiries: legal@blackroad.io
"""

from __future__ import annotations

import csv
import io
import json
import re
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Callable, Dict, List, Optional, Tuple, Union

import numpy as np


@dataclass
class TimeSeriesPoint:
    """A single point in a time series."""

    timestamp: datetime
    value: float
    labels: Optional[Dict[str, str]] = None


@dataclass
class AnomalyResult:
    """Result of anomaly detection."""

    index: int
    timestamp: Optional[datetime]
    value: float
    z_score: float
    is_anomaly: bool


# ============================================================================
# CSV/Data Parsing
# ============================================================================


def parse_csv(
    content: str,
    delimiter: str = ",",
    has_header: bool = True,
) -> Tuple[List[str], List[Dict[str, Any]]]:
    """Parse CSV content into headers and rows."""
    reader = csv.reader(io.StringIO(content), delimiter=delimiter)
    rows = list(reader)

    if not rows:
        return [], []

    if has_header:
        headers = rows[0]
        data = [dict(zip(headers, row)) for row in rows[1:]]
    else:
        headers = [f"col_{i}" for i in range(len(rows[0]))]
        data = [dict(zip(headers, row)) for row in rows]

    return headers, data


def to_csv(
    data: List[Dict[str, Any]],
    columns: Optional[List[str]] = None,
) -> str:
    """Convert list of dicts to CSV string."""
    if not data:
        return ""

    if columns is None:
        columns = list(data[0].keys())

    output = io.StringIO()
    writer = csv.DictWriter(output, fieldnames=columns)
    writer.writeheader()
    writer.writerows(data)

    return output.getvalue()


def flatten_json(
    obj: Dict[str, Any],
    separator: str = ".",
    prefix: str = "",
) -> Dict[str, Any]:
    """Flatten nested JSON into dot-notation keys."""
    result = {}

    for key, value in obj.items():
        new_key = f"{prefix}{separator}{key}" if prefix else key

        if isinstance(value, dict):
            result.update(flatten_json(value, separator, new_key))
        elif isinstance(value, list):
            for i, item in enumerate(value):
                if isinstance(item, dict):
                    result.update(flatten_json(item, separator, f"{new_key}[{i}]"))
                else:
                    result[f"{new_key}[{i}]"] = item
        else:
            result[new_key] = value

    return result


def unflatten_json(obj: Dict[str, Any], separator: str = ".") -> Dict[str, Any]:
    """Unflatten dot-notation keys back into nested JSON."""
    result: Dict[str, Any] = {}

    for key, value in obj.items():
        parts = key.replace("[", ".").replace("]", "").split(separator)
        current = result

        for i, part in enumerate(parts[:-1]):
            if part.isdigit():
                part = int(part)  # type: ignore
            if part not in current:
                # Check if next part is numeric (array)
                next_part = parts[i + 1]
                if next_part.isdigit():
                    current[part] = []
                else:
                    current[part] = {}
            current = current[part]

        final_key = parts[-1]
        if final_key.isdigit():
            final_key = int(final_key)  # type: ignore
        current[final_key] = value

    return result


# ============================================================================
# Statistics
# ============================================================================


def descriptive_stats(values: List[float]) -> Dict[str, float]:
    """Calculate descriptive statistics for a list of values."""
    if not values:
        return {}

    arr = np.array(values)

    return {
        "count": len(values),
        "min": float(np.min(arr)),
        "max": float(np.max(arr)),
        "mean": float(np.mean(arr)),
        "median": float(np.median(arr)),
        "std": float(np.std(arr)),
        "var": float(np.var(arr)),
        "sum": float(np.sum(arr)),
        "p25": float(np.percentile(arr, 25)),
        "p75": float(np.percentile(arr, 75)),
        "p90": float(np.percentile(arr, 90)),
        "p95": float(np.percentile(arr, 95)),
        "p99": float(np.percentile(arr, 99)),
        "iqr": float(np.percentile(arr, 75) - np.percentile(arr, 25)),
        "range": float(np.max(arr) - np.min(arr)),
        "skew": float(skewness(arr)),
        "kurtosis": float(kurtosis(arr)),
    }


def skewness(arr: np.ndarray) -> float:
    """Calculate skewness of an array."""
    n = len(arr)
    if n < 3:
        return 0.0
    mean = np.mean(arr)
    std = np.std(arr)
    if std == 0:
        return 0.0
    return float(np.mean(((arr - mean) / std) ** 3))


def kurtosis(arr: np.ndarray) -> float:
    """Calculate excess kurtosis of an array."""
    n = len(arr)
    if n < 4:
        return 0.0
    mean = np.mean(arr)
    std = np.std(arr)
    if std == 0:
        return 0.0
    return float(np.mean(((arr - mean) / std) ** 4) - 3)


def correlation(x: List[float], y: List[float]) -> float:
    """Calculate Pearson correlation coefficient."""
    if len(x) != len(y) or len(x) < 2:
        return 0.0
    return float(np.corrcoef(x, y)[0, 1])


def covariance(x: List[float], y: List[float]) -> float:
    """Calculate covariance between two variables."""
    if len(x) != len(y) or len(x) < 2:
        return 0.0
    return float(np.cov(x, y)[0, 1])


def histogram(
    values: List[float],
    bins: int = 10,
) -> Tuple[List[int], List[float]]:
    """Create histogram counts and bin edges."""
    counts, edges = np.histogram(values, bins=bins)
    return list(counts), list(edges)


# ============================================================================
# Time Series
# ============================================================================


def moving_average(
    values: List[float],
    window: int = 5,
) -> List[float]:
    """Calculate simple moving average."""
    if window <= 0 or window > len(values):
        return values

    arr = np.array(values)
    cumsum = np.cumsum(np.insert(arr, 0, 0))
    ma = (cumsum[window:] - cumsum[:-window]) / window

    # Pad beginning with first available averages
    result = list(arr[:window-1]) + list(ma)
    return [float(v) for v in result]


def exponential_moving_average(
    values: List[float],
    alpha: float = 0.3,
) -> List[float]:
    """Calculate exponential moving average."""
    if not values:
        return []

    result = [values[0]]
    for v in values[1:]:
        ema = alpha * v + (1 - alpha) * result[-1]
        result.append(ema)

    return result


def detect_trend(values: List[float]) -> Dict[str, Any]:
    """Detect linear trend in values using least squares."""
    if len(values) < 2:
        return {"slope": 0, "intercept": 0, "r_squared": 0, "direction": "flat"}

    x = np.arange(len(values))
    y = np.array(values)

    # Linear regression
    A = np.vstack([x, np.ones(len(x))]).T
    slope, intercept = np.linalg.lstsq(A, y, rcond=None)[0]

    # R-squared
    y_pred = slope * x + intercept
    ss_res = np.sum((y - y_pred) ** 2)
    ss_tot = np.sum((y - np.mean(y)) ** 2)
    r_squared = 1 - (ss_res / ss_tot) if ss_tot > 0 else 0

    # Direction
    if slope > 0.01:
        direction = "increasing"
    elif slope < -0.01:
        direction = "decreasing"
    else:
        direction = "flat"

    return {
        "slope": float(slope),
        "intercept": float(intercept),
        "r_squared": float(r_squared),
        "direction": direction,
    }


def detect_anomalies(
    values: List[float],
    threshold: float = 3.0,
    timestamps: Optional[List[datetime]] = None,
) -> List[AnomalyResult]:
    """Detect anomalies using z-score method."""
    if len(values) < 3:
        return []

    arr = np.array(values)
    mean = np.mean(arr)
    std = np.std(arr)

    if std == 0:
        return []

    z_scores = (arr - mean) / std
    anomalies = []

    for i, (v, z) in enumerate(zip(values, z_scores)):
        is_anomaly = abs(z) > threshold
        ts = timestamps[i] if timestamps and i < len(timestamps) else None
        anomalies.append(AnomalyResult(
            index=i,
            timestamp=ts,
            value=v,
            z_score=float(z),
            is_anomaly=is_anomaly,
        ))

    return [a for a in anomalies if a.is_anomaly]


def seasonal_decompose(
    values: List[float],
    period: int,
) -> Dict[str, List[float]]:
    """Simple seasonal decomposition (additive model)."""
    if period <= 0 or len(values) < period * 2:
        return {"trend": values, "seasonal": [0] * len(values), "residual": [0] * len(values)}

    # Calculate trend using moving average
    trend = moving_average(values, period)

    # Calculate seasonal component
    detrended = [v - t for v, t in zip(values, trend)]
    seasonal = []
    for i in range(len(values)):
        # Average of same position across periods
        positions = [detrended[j] for j in range(i % period, len(detrended), period)]
        seasonal.append(np.mean(positions))

    # Residual
    residual = [v - t - s for v, t, s in zip(values, trend, seasonal)]

    return {
        "trend": trend,
        "seasonal": seasonal,
        "residual": residual,
    }


def resample_timeseries(
    timestamps: List[datetime],
    values: List[float],
    interval: timedelta,
    aggregation: str = "mean",
) -> Tuple[List[datetime], List[float]]:
    """Resample time series to a different interval."""
    if not timestamps or not values:
        return [], []

    agg_funcs: Dict[str, Callable] = {
        "mean": np.mean,
        "sum": np.sum,
        "min": np.min,
        "max": np.max,
        "first": lambda x: x[0] if x else 0,
        "last": lambda x: x[-1] if x else 0,
        "count": len,
    }

    agg_func = agg_funcs.get(aggregation, np.mean)

    # Group by interval
    start = min(timestamps)
    end = max(timestamps)
    buckets: Dict[datetime, List[float]] = {}

    current = start
    while current <= end:
        buckets[current] = []
        current += interval

    for ts, val in zip(timestamps, values):
        # Find bucket
        bucket_start = start
        while bucket_start + interval <= ts:
            bucket_start += interval
        if bucket_start in buckets:
            buckets[bucket_start].append(val)

    # Aggregate
    result_ts = []
    result_vals = []
    for ts in sorted(buckets.keys()):
        if buckets[ts]:
            result_ts.append(ts)
            result_vals.append(float(agg_func(buckets[ts])))

    return result_ts, result_vals


def interpolate_missing(
    values: List[Optional[float]],
    method: str = "linear",
) -> List[float]:
    """Interpolate missing (None) values."""
    result = []

    # Find indices of known values
    known_indices = [i for i, v in enumerate(values) if v is not None]
    known_values = [values[i] for i in known_indices]

    if not known_indices:
        return [0.0] * len(values)

    for i in range(len(values)):
        if values[i] is not None:
            result.append(values[i])  # type: ignore
        else:
            # Linear interpolation
            # Find surrounding known values
            left_idx = max([ki for ki in known_indices if ki < i], default=known_indices[0])
            right_idx = min([ki for ki in known_indices if ki > i], default=known_indices[-1])

            if left_idx == right_idx:
                result.append(values[left_idx])  # type: ignore
            else:
                # Interpolate
                left_val = values[left_idx]
                right_val = values[right_idx]
                ratio = (i - left_idx) / (right_idx - left_idx)
                interpolated = left_val + ratio * (right_val - left_val)  # type: ignore
                result.append(interpolated)

    return result


# ============================================================================
# Aggregations
# ============================================================================


def group_by(
    data: List[Dict[str, Any]],
    key: str,
    aggregations: Dict[str, Tuple[str, str]],
) -> List[Dict[str, Any]]:
    """Group data by key and apply aggregations.

    aggregations: {output_field: (input_field, agg_func)}
    agg_func: 'sum', 'mean', 'min', 'max', 'count', 'first', 'last'
    """
    groups: Dict[Any, List[Dict[str, Any]]] = {}

    for row in data:
        group_key = row.get(key)
        if group_key not in groups:
            groups[group_key] = []
        groups[group_key].append(row)

    agg_funcs: Dict[str, Callable] = {
        "sum": sum,
        "mean": lambda x: sum(x) / len(x) if x else 0,
        "min": min,
        "max": max,
        "count": len,
        "first": lambda x: x[0] if x else None,
        "last": lambda x: x[-1] if x else None,
    }

    results = []
    for group_key, group_rows in groups.items():
        result = {key: group_key}

        for output_field, (input_field, agg_name) in aggregations.items():
            values = [row.get(input_field, 0) for row in group_rows]
            agg_func = agg_funcs.get(agg_name, lambda x: x)

            if agg_name == "count":
                result[output_field] = len(group_rows)
            else:
                numeric_values = [v for v in values if isinstance(v, (int, float))]
                result[output_field] = agg_func(numeric_values) if numeric_values else 0

        results.append(result)

    return results


def pivot_table(
    data: List[Dict[str, Any]],
    index: str,
    columns: str,
    values: str,
    agg_func: str = "sum",
) -> Dict[str, Dict[str, Any]]:
    """Create a pivot table from data."""
    pivot: Dict[str, Dict[str, List[float]]] = {}
    col_values = set()

    for row in data:
        idx = row.get(index)
        col = row.get(columns)
        val = row.get(values, 0)

        col_values.add(col)

        if idx not in pivot:
            pivot[idx] = {}
        if col not in pivot[idx]:
            pivot[idx][col] = []

        if isinstance(val, (int, float)):
            pivot[idx][col].append(val)

    agg_funcs: Dict[str, Callable] = {
        "sum": sum,
        "mean": lambda x: sum(x) / len(x) if x else 0,
        "min": min,
        "max": max,
        "count": len,
    }

    agg = agg_funcs.get(agg_func, sum)

    # Aggregate
    result = {}
    for idx, cols in pivot.items():
        result[idx] = {}
        for col in col_values:
            if col in cols:
                result[idx][col] = agg(cols[col])
            else:
                result[idx][col] = 0

    return result


def rolling_window(
    values: List[float],
    window: int,
    func: Callable[[List[float]], float],
) -> List[Optional[float]]:
    """Apply function over rolling window."""
    result: List[Optional[float]] = []

    for i in range(len(values)):
        if i < window - 1:
            result.append(None)
        else:
            window_vals = values[i - window + 1:i + 1]
            result.append(func(window_vals))

    return result


def calculate_growth_rate(
    values: List[float],
    periods: int = 1,
) -> List[Optional[float]]:
    """Calculate period-over-period growth rate."""
    if len(values) <= periods:
        return [None] * len(values)

    result: List[Optional[float]] = [None] * periods

    for i in range(periods, len(values)):
        prev = values[i - periods]
        curr = values[i]
        if prev != 0:
            rate = (curr - prev) / prev
        else:
            rate = 0
        result.append(rate)

    return result
