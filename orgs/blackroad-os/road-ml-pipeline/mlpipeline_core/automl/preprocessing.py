"""AutoML Preprocessing - Automated Feature Engineering.

Copyright (c) 2024-2026 BlackRoad OS, Inc. All rights reserved.
"""

from __future__ import annotations

import logging
import math
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from enum import Enum, auto
from typing import Any, Callable, Dict, List, Optional, Set, Tuple, Type, Union

import numpy as np

logger = logging.getLogger(__name__)


class FeatureType(Enum):
    """Feature data types."""

    NUMERIC = auto()
    CATEGORICAL = auto()
    TEXT = auto()
    DATETIME = auto()
    BINARY = auto()
    ORDINAL = auto()
    UNKNOWN = auto()


class ScalingMethod(Enum):
    """Scaling methods."""

    STANDARD = "standard"
    MINMAX = "minmax"
    ROBUST = "robust"
    MAXABS = "maxabs"
    LOG = "log"
    QUANTILE = "quantile"
    NONE = "none"


class EncodingMethod(Enum):
    """Categorical encoding methods."""

    ONEHOT = "onehot"
    LABEL = "label"
    TARGET = "target"
    BINARY = "binary"
    FREQUENCY = "frequency"
    ORDINAL = "ordinal"


class ImputationMethod(Enum):
    """Missing value imputation methods."""

    MEAN = "mean"
    MEDIAN = "median"
    MODE = "mode"
    CONSTANT = "constant"
    KNN = "knn"
    ITERATIVE = "iterative"
    DROP = "drop"


@dataclass
class FeatureInfo:
    """Information about a feature."""

    name: str
    dtype: FeatureType
    cardinality: Optional[int] = None
    null_ratio: float = 0.0
    unique_ratio: float = 0.0
    is_constant: bool = False
    suggested_encoding: Optional[EncodingMethod] = None
    suggested_scaling: Optional[ScalingMethod] = None


class Transformer(ABC):
    """Abstract feature transformer."""

    @abstractmethod
    def fit(self, X: Any) -> "Transformer":
        """Fit transformer."""
        pass

    @abstractmethod
    def transform(self, X: Any) -> Any:
        """Transform features."""
        pass

    def fit_transform(self, X: Any) -> Any:
        """Fit and transform."""
        return self.fit(X).transform(X)


class StandardScaler(Transformer):
    """Standard scaling (zero mean, unit variance)."""

    def __init__(self):
        self.mean_: Optional[np.ndarray] = None
        self.std_: Optional[np.ndarray] = None

    def fit(self, X: Any) -> "StandardScaler":
        """Compute mean and std."""
        X = np.asarray(X)
        self.mean_ = np.mean(X, axis=0)
        self.std_ = np.std(X, axis=0)
        self.std_[self.std_ == 0] = 1.0
        return self

    def transform(self, X: Any) -> np.ndarray:
        """Apply scaling."""
        X = np.asarray(X)
        return (X - self.mean_) / self.std_


class MinMaxScaler(Transformer):
    """Min-max scaling to [0, 1]."""

    def __init__(self, feature_range: Tuple[float, float] = (0, 1)):
        self.feature_range = feature_range
        self.min_: Optional[np.ndarray] = None
        self.scale_: Optional[np.ndarray] = None

    def fit(self, X: Any) -> "MinMaxScaler":
        """Compute min and scale."""
        X = np.asarray(X)
        self.min_ = np.min(X, axis=0)
        data_range = np.max(X, axis=0) - self.min_
        data_range[data_range == 0] = 1.0
        self.scale_ = (self.feature_range[1] - self.feature_range[0]) / data_range
        return self

    def transform(self, X: Any) -> np.ndarray:
        """Apply scaling."""
        X = np.asarray(X)
        return (X - self.min_) * self.scale_ + self.feature_range[0]


class LabelEncoder(Transformer):
    """Encode labels to integers."""

    def __init__(self):
        self.classes_: Optional[List[Any]] = None
        self.class_to_idx_: Dict[Any, int] = {}

    def fit(self, X: Any) -> "LabelEncoder":
        """Fit encoder."""
        self.classes_ = sorted(set(X))
        self.class_to_idx_ = {c: i for i, c in enumerate(self.classes_)}
        return self

    def transform(self, X: Any) -> np.ndarray:
        """Transform to integers."""
        return np.array([self.class_to_idx_.get(x, -1) for x in X])

    def inverse_transform(self, X: Any) -> List[Any]:
        """Transform back to original values."""
        return [self.classes_[i] if 0 <= i < len(self.classes_) else None for i in X]


class OneHotEncoder(Transformer):
    """One-hot encoding for categorical features."""

    def __init__(self, sparse: bool = False, handle_unknown: str = "ignore"):
        self.sparse = sparse
        self.handle_unknown = handle_unknown
        self.categories_: Optional[List[List[Any]]] = None

    def fit(self, X: Any) -> "OneHotEncoder":
        """Fit encoder."""
        X = np.asarray(X)
        if X.ndim == 1:
            X = X.reshape(-1, 1)

        self.categories_ = [sorted(set(X[:, i])) for i in range(X.shape[1])]
        return self

    def transform(self, X: Any) -> np.ndarray:
        """Transform to one-hot."""
        X = np.asarray(X)
        if X.ndim == 1:
            X = X.reshape(-1, 1)

        result = []
        for i, cats in enumerate(self.categories_):
            cat_to_idx = {c: j for j, c in enumerate(cats)}
            n_cats = len(cats)

            for x in X[:, i]:
                row = [0] * n_cats
                if x in cat_to_idx:
                    row[cat_to_idx[x]] = 1
                result.append(row)

        return np.array(result).reshape(X.shape[0], -1)


class SimpleImputer(Transformer):
    """Simple imputation for missing values."""

    def __init__(
        self,
        strategy: ImputationMethod = ImputationMethod.MEAN,
        fill_value: Any = None,
    ):
        self.strategy = strategy
        self.fill_value = fill_value
        self.statistics_: Optional[np.ndarray] = None

    def fit(self, X: Any) -> "SimpleImputer":
        """Compute imputation statistics."""
        X = np.asarray(X, dtype=float)

        if self.strategy == ImputationMethod.MEAN:
            self.statistics_ = np.nanmean(X, axis=0)
        elif self.strategy == ImputationMethod.MEDIAN:
            self.statistics_ = np.nanmedian(X, axis=0)
        elif self.strategy == ImputationMethod.CONSTANT:
            self.statistics_ = np.full(X.shape[1], self.fill_value)
        else:
            self.statistics_ = np.nanmean(X, axis=0)

        return self

    def transform(self, X: Any) -> np.ndarray:
        """Impute missing values."""
        X = np.asarray(X, dtype=float)
        mask = np.isnan(X)

        for i in range(X.shape[1]):
            X[mask[:, i], i] = self.statistics_[i]

        return X


class FeatureSelector:
    """Automated feature selection.

    Methods:
    - Variance threshold
    - Correlation filter
    - Mutual information
    - Feature importance
    """

    def __init__(
        self,
        variance_threshold: float = 0.0,
        correlation_threshold: float = 0.95,
        max_features: Optional[int] = None,
    ):
        self.variance_threshold = variance_threshold
        self.correlation_threshold = correlation_threshold
        self.max_features = max_features
        self.selected_features_: Optional[List[int]] = None
        self.feature_scores_: Optional[Dict[int, float]] = None

    def fit(self, X: Any, y: Optional[Any] = None) -> "FeatureSelector":
        """Fit feature selector."""
        X = np.asarray(X)
        n_features = X.shape[1]

        selected = set(range(n_features))

        if self.variance_threshold > 0:
            variances = np.var(X, axis=0)
            low_variance = np.where(variances <= self.variance_threshold)[0]
            selected -= set(low_variance)

        if self.correlation_threshold < 1.0 and len(selected) > 1:
            selected_list = sorted(selected)
            X_subset = X[:, selected_list]
            corr_matrix = np.corrcoef(X_subset.T)

            to_remove = set()
            for i in range(len(selected_list)):
                if i in to_remove:
                    continue
                for j in range(i + 1, len(selected_list)):
                    if j in to_remove:
                        continue
                    if abs(corr_matrix[i, j]) > self.correlation_threshold:
                        to_remove.add(j)

            for idx in to_remove:
                selected.discard(selected_list[idx])

        self.selected_features_ = sorted(selected)

        if self.max_features and len(self.selected_features_) > self.max_features:
            self.selected_features_ = self.selected_features_[:self.max_features]

        return self

    def transform(self, X: Any) -> np.ndarray:
        """Select features."""
        if self.selected_features_ is None:
            raise ValueError("Not fitted")
        X = np.asarray(X)
        return X[:, self.selected_features_]

    def fit_transform(self, X: Any, y: Optional[Any] = None) -> np.ndarray:
        """Fit and transform."""
        return self.fit(X, y).transform(X)


class AutoPreprocessor:
    """Automated preprocessing pipeline.

    Features:
    - Automatic type detection
    - Missing value handling
    - Feature scaling
    - Categorical encoding
    - Feature selection
    """

    def __init__(
        self,
        numeric_scaling: ScalingMethod = ScalingMethod.STANDARD,
        categorical_encoding: EncodingMethod = EncodingMethod.ONEHOT,
        imputation: ImputationMethod = ImputationMethod.MEDIAN,
        feature_selection: bool = True,
        max_cardinality: int = 50,
    ):
        self.numeric_scaling = numeric_scaling
        self.categorical_encoding = categorical_encoding
        self.imputation = imputation
        self.feature_selection = feature_selection
        self.max_cardinality = max_cardinality

        self._feature_info: Dict[str, FeatureInfo] = {}
        self._transformers: Dict[str, Transformer] = {}
        self._selector: Optional[FeatureSelector] = None
        self._fitted = False

    def fit(self, X: Any, y: Optional[Any] = None) -> "AutoPreprocessor":
        """Fit preprocessor."""
        X = np.asarray(X)

        for i in range(X.shape[1]):
            col = X[:, i]
            info = self._analyze_feature(f"feature_{i}", col)
            self._feature_info[f"feature_{i}"] = info

            if info.dtype == FeatureType.NUMERIC:
                self._fit_numeric_transformer(f"feature_{i}", col)
            elif info.dtype == FeatureType.CATEGORICAL:
                self._fit_categorical_transformer(f"feature_{i}", col)

        if self.feature_selection:
            self._selector = FeatureSelector()
            processed = self.transform(X)
            self._selector.fit(processed, y)

        self._fitted = True
        return self

    def transform(self, X: Any) -> np.ndarray:
        """Transform features."""
        if not self._fitted:
            raise ValueError("Not fitted")

        X = np.asarray(X)
        transformed_features = []

        for i in range(X.shape[1]):
            col = X[:, i]
            name = f"feature_{i}"

            if name in self._transformers:
                transformed = self._transformers[name].transform(col.reshape(-1, 1))
                if transformed.ndim == 1:
                    transformed = transformed.reshape(-1, 1)
                transformed_features.append(transformed)
            else:
                transformed_features.append(col.reshape(-1, 1))

        result = np.hstack(transformed_features)

        if self._selector is not None:
            result = self._selector.transform(result)

        return result

    def fit_transform(self, X: Any, y: Optional[Any] = None) -> np.ndarray:
        """Fit and transform."""
        return self.fit(X, y).transform(X)

    def _analyze_feature(self, name: str, col: np.ndarray) -> FeatureInfo:
        """Analyze a single feature."""
        null_mask = np.isnan(col.astype(float)) if np.issubdtype(col.dtype, np.number) else np.array([x is None or x == "" for x in col])
        null_ratio = np.mean(null_mask)

        unique_values = len(set(col[~null_mask]))
        unique_ratio = unique_values / len(col) if len(col) > 0 else 0

        if np.issubdtype(col.dtype, np.number):
            dtype = FeatureType.NUMERIC
        elif unique_values <= self.max_cardinality:
            dtype = FeatureType.CATEGORICAL
        else:
            dtype = FeatureType.TEXT

        return FeatureInfo(
            name=name,
            dtype=dtype,
            cardinality=unique_values,
            null_ratio=null_ratio,
            unique_ratio=unique_ratio,
            is_constant=unique_values <= 1,
        )

    def _fit_numeric_transformer(self, name: str, col: np.ndarray) -> None:
        """Fit transformer for numeric feature."""
        if self.numeric_scaling == ScalingMethod.STANDARD:
            transformer = StandardScaler()
        elif self.numeric_scaling == ScalingMethod.MINMAX:
            transformer = MinMaxScaler()
        else:
            return

        imputer = SimpleImputer(strategy=self.imputation)
        col_clean = imputer.fit_transform(col.reshape(-1, 1))
        transformer.fit(col_clean)

        self._transformers[f"{name}_imputer"] = imputer
        self._transformers[name] = transformer

    def _fit_categorical_transformer(self, name: str, col: np.ndarray) -> None:
        """Fit transformer for categorical feature."""
        if self.categorical_encoding == EncodingMethod.ONEHOT:
            transformer = OneHotEncoder()
        elif self.categorical_encoding == EncodingMethod.LABEL:
            transformer = LabelEncoder()
        else:
            return

        transformer.fit(col)
        self._transformers[name] = transformer


__all__ = [
    "AutoPreprocessor",
    "FeatureSelector",
    "FeatureInfo",
    "FeatureType",
    "ScalingMethod",
    "EncodingMethod",
    "ImputationMethod",
    "StandardScaler",
    "MinMaxScaler",
    "LabelEncoder",
    "OneHotEncoder",
    "SimpleImputer",
    "Transformer",
]
