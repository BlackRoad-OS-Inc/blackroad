"""
RoadLog - Structured Logging for BlackRoad
JSON logging, log levels, context propagation, and log aggregation.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import IntEnum
from typing import Any, Callable, Dict, List, Optional, TextIO
import json
import logging
import os
import sys
import threading
import traceback
import uuid

# Log levels
class LogLevel(IntEnum):
    """Log levels."""
    DEBUG = 10
    INFO = 20
    WARNING = 30
    ERROR = 40
    CRITICAL = 50


@dataclass
class LogRecord:
    """A structured log record."""
    level: LogLevel
    message: str
    timestamp: datetime = field(default_factory=datetime.now)
    logger_name: str = "root"
    context: Dict[str, Any] = field(default_factory=dict)
    trace_id: Optional[str] = None
    span_id: Optional[str] = None
    exception: Optional[Dict[str, Any]] = None
    extra: Dict[str, Any] = field(default_factory=dict)

    def to_dict(self) -> Dict[str, Any]:
        result = {
            "timestamp": self.timestamp.isoformat(),
            "level": LogLevel(self.level).name,
            "message": self.message,
            "logger": self.logger_name,
            **self.context,
            **self.extra
        }
        
        if self.trace_id:
            result["trace_id"] = self.trace_id
        if self.span_id:
            result["span_id"] = self.span_id
        if self.exception:
            result["exception"] = self.exception
        
        return result


class LogFormatter:
    """Base log formatter."""

    def format(self, record: LogRecord) -> str:
        raise NotImplementedError


class JSONFormatter(LogFormatter):
    """JSON log formatter."""

    def __init__(self, indent: int = None):
        self.indent = indent

    def format(self, record: LogRecord) -> str:
        return json.dumps(record.to_dict(), indent=self.indent, default=str)


class TextFormatter(LogFormatter):
    """Human-readable text formatter."""

    def __init__(self, template: str = None):
        self.template = template or "[{timestamp}] {level} - {logger}: {message}"

    def format(self, record: LogRecord) -> str:
        data = record.to_dict()
        formatted = self.template.format(
            timestamp=record.timestamp.strftime("%Y-%m-%d %H:%M:%S"),
            level=LogLevel(record.level).name.ljust(8),
            logger=record.logger_name,
            message=record.message
        )
        
        # Add context
        if record.context:
            formatted += f" | context={record.context}"
        
        # Add exception
        if record.exception:
            formatted += f"\n{record.exception.get('traceback', '')}"
        
        return formatted


class ColoredFormatter(TextFormatter):
    """Colored console formatter."""

    COLORS = {
        LogLevel.DEBUG: "\033[36m",    # Cyan
        LogLevel.INFO: "\033[32m",     # Green
        LogLevel.WARNING: "\033[33m",  # Yellow
        LogLevel.ERROR: "\033[31m",    # Red
        LogLevel.CRITICAL: "\033[35m", # Magenta
    }
    RESET = "\033[0m"

    def format(self, record: LogRecord) -> str:
        color = self.COLORS.get(record.level, "")
        text = super().format(record)
        return f"{color}{text}{self.RESET}"


class LogHandler:
    """Base log handler."""

    def __init__(self, formatter: LogFormatter = None, level: LogLevel = LogLevel.DEBUG):
        self.formatter = formatter or JSONFormatter()
        self.level = level

    def handle(self, record: LogRecord) -> None:
        if record.level >= self.level:
            self.emit(record)

    def emit(self, record: LogRecord) -> None:
        raise NotImplementedError


class ConsoleHandler(LogHandler):
    """Console log handler."""

    def __init__(self, stream: TextIO = None, **kwargs):
        super().__init__(**kwargs)
        self.stream = stream or sys.stdout

    def emit(self, record: LogRecord) -> None:
        formatted = self.formatter.format(record)
        self.stream.write(formatted + "\n")
        self.stream.flush()


class FileHandler(LogHandler):
    """File log handler with rotation."""

    def __init__(
        self,
        filename: str,
        max_bytes: int = 10 * 1024 * 1024,  # 10MB
        backup_count: int = 5,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.filename = filename
        self.max_bytes = max_bytes
        self.backup_count = backup_count
        self._lock = threading.Lock()

    def _should_rotate(self) -> bool:
        if not os.path.exists(self.filename):
            return False
        return os.path.getsize(self.filename) >= self.max_bytes

    def _rotate(self) -> None:
        for i in range(self.backup_count - 1, 0, -1):
            source = f"{self.filename}.{i}"
            target = f"{self.filename}.{i + 1}"
            if os.path.exists(source):
                os.rename(source, target)
        
        if os.path.exists(self.filename):
            os.rename(self.filename, f"{self.filename}.1")

    def emit(self, record: LogRecord) -> None:
        with self._lock:
            if self._should_rotate():
                self._rotate()
            
            formatted = self.formatter.format(record)
            with open(self.filename, "a") as f:
                f.write(formatted + "\n")


class BufferedHandler(LogHandler):
    """Buffered log handler for batch processing."""

    def __init__(self, buffer_size: int = 100, flush_interval: float = 5.0, **kwargs):
        super().__init__(**kwargs)
        self.buffer_size = buffer_size
        self.flush_interval = flush_interval
        self._buffer: List[LogRecord] = []
        self._lock = threading.Lock()
        self._last_flush = datetime.now()

    def emit(self, record: LogRecord) -> None:
        with self._lock:
            self._buffer.append(record)
            
            if len(self._buffer) >= self.buffer_size:
                self._flush()
            elif (datetime.now() - self._last_flush).total_seconds() >= self.flush_interval:
                self._flush()

    def _flush(self) -> None:
        if not self._buffer:
            return
        
        records = self._buffer.copy()
        self._buffer.clear()
        self._last_flush = datetime.now()
        
        # Override in subclass to handle records
        self.process_batch(records)

    def process_batch(self, records: List[LogRecord]) -> None:
        """Override to process batch of records."""
        pass


class LogContext:
    """Thread-local logging context."""
    _context = threading.local()

    @classmethod
    def set(cls, key: str, value: Any) -> None:
        if not hasattr(cls._context, 'data'):
            cls._context.data = {}
        cls._context.data[key] = value

    @classmethod
    def get(cls, key: str, default: Any = None) -> Any:
        if not hasattr(cls._context, 'data'):
            return default
        return cls._context.data.get(key, default)

    @classmethod
    def get_all(cls) -> Dict[str, Any]:
        if not hasattr(cls._context, 'data'):
            return {}
        return cls._context.data.copy()

    @classmethod
    def clear(cls) -> None:
        cls._context.data = {}

    @classmethod
    def set_trace_id(cls, trace_id: str) -> None:
        cls.set("trace_id", trace_id)

    @classmethod
    def get_trace_id(cls) -> Optional[str]:
        return cls.get("trace_id")


class Logger:
    """Structured logger."""

    def __init__(self, name: str = "root"):
        self.name = name
        self.handlers: List[LogHandler] = []
        self.level = LogLevel.DEBUG
        self._filters: List[Callable[[LogRecord], bool]] = []

    def add_handler(self, handler: LogHandler) -> None:
        self.handlers.append(handler)

    def add_filter(self, filter_fn: Callable[[LogRecord], bool]) -> None:
        self._filters.append(filter_fn)

    def _should_log(self, record: LogRecord) -> bool:
        if record.level < self.level:
            return False
        
        for filter_fn in self._filters:
            if not filter_fn(record):
                return False
        
        return True

    def _create_record(
        self,
        level: LogLevel,
        message: str,
        extra: Dict[str, Any] = None,
        exc_info: bool = False
    ) -> LogRecord:
        exception = None
        if exc_info:
            exc_type, exc_value, exc_tb = sys.exc_info()
            if exc_type:
                exception = {
                    "type": exc_type.__name__,
                    "message": str(exc_value),
                    "traceback": traceback.format_exc()
                }

        return LogRecord(
            level=level,
            message=message,
            logger_name=self.name,
            context=LogContext.get_all(),
            trace_id=LogContext.get_trace_id(),
            extra=extra or {},
            exception=exception
        )

    def _log(self, level: LogLevel, message: str, **kwargs) -> None:
        record = self._create_record(level, message, **kwargs)
        
        if not self._should_log(record):
            return
        
        for handler in self.handlers:
            handler.handle(record)

    def debug(self, message: str, **kwargs) -> None:
        self._log(LogLevel.DEBUG, message, **kwargs)

    def info(self, message: str, **kwargs) -> None:
        self._log(LogLevel.INFO, message, **kwargs)

    def warning(self, message: str, **kwargs) -> None:
        self._log(LogLevel.WARNING, message, **kwargs)

    def error(self, message: str, exc_info: bool = False, **kwargs) -> None:
        self._log(LogLevel.ERROR, message, exc_info=exc_info, **kwargs)

    def critical(self, message: str, exc_info: bool = False, **kwargs) -> None:
        self._log(LogLevel.CRITICAL, message, exc_info=exc_info, **kwargs)

    def exception(self, message: str, **kwargs) -> None:
        self.error(message, exc_info=True, **kwargs)

    def bind(self, **kwargs) -> "BoundLogger":
        """Create a bound logger with extra context."""
        return BoundLogger(self, kwargs)


class BoundLogger:
    """Logger with bound context."""

    def __init__(self, logger: Logger, context: Dict[str, Any]):
        self._logger = logger
        self._context = context

    def _merge_extra(self, extra: Dict[str, Any] = None) -> Dict[str, Any]:
        merged = self._context.copy()
        if extra:
            merged.update(extra)
        return merged

    def debug(self, message: str, **kwargs) -> None:
        self._logger.debug(message, extra=self._merge_extra(kwargs.get("extra")))

    def info(self, message: str, **kwargs) -> None:
        self._logger.info(message, extra=self._merge_extra(kwargs.get("extra")))

    def warning(self, message: str, **kwargs) -> None:
        self._logger.warning(message, extra=self._merge_extra(kwargs.get("extra")))

    def error(self, message: str, **kwargs) -> None:
        self._logger.error(message, extra=self._merge_extra(kwargs.get("extra")), **kwargs)

    def bind(self, **kwargs) -> "BoundLogger":
        new_context = self._context.copy()
        new_context.update(kwargs)
        return BoundLogger(self._logger, new_context)


class LogManager:
    """Manage loggers and configuration."""

    _loggers: Dict[str, Logger] = {}
    _root_logger: Optional[Logger] = None

    @classmethod
    def get_logger(cls, name: str = "root") -> Logger:
        """Get or create a logger."""
        if name not in cls._loggers:
            logger = Logger(name)
            
            # Inherit handlers from root
            if cls._root_logger and name != "root":
                logger.handlers = cls._root_logger.handlers.copy()
            
            cls._loggers[name] = logger
        
        return cls._loggers[name]

    @classmethod
    def configure(
        cls,
        level: LogLevel = LogLevel.INFO,
        json_output: bool = False,
        colorize: bool = True,
        filename: Optional[str] = None
    ) -> None:
        """Configure root logger."""
        root = cls.get_logger("root")
        root.level = level
        root.handlers.clear()

        # Console handler
        if json_output:
            formatter = JSONFormatter()
        elif colorize:
            formatter = ColoredFormatter()
        else:
            formatter = TextFormatter()

        root.add_handler(ConsoleHandler(formatter=formatter))

        # File handler
        if filename:
            root.add_handler(FileHandler(filename, formatter=JSONFormatter()))

        cls._root_logger = root


# Convenience functions
def get_logger(name: str = "root") -> Logger:
    return LogManager.get_logger(name)


def configure(**kwargs) -> None:
    LogManager.configure(**kwargs)


# Example usage
def example_usage():
    """Example logging usage."""
    # Configure
    configure(level=LogLevel.DEBUG, colorize=True)

    # Get logger
    logger = get_logger("my_app")

    # Basic logging
    logger.debug("Debug message")
    logger.info("Info message")
    logger.warning("Warning message")
    logger.error("Error message")

    # With context
    LogContext.set_trace_id(str(uuid.uuid4())[:8])
    LogContext.set("user_id", "user-123")

    logger.info("User logged in")

    # Bound logger
    request_logger = logger.bind(request_id="req-456", endpoint="/api/users")
    request_logger.info("Processing request")
    request_logger.info("Request completed", extra={"duration_ms": 45})

    # Exception logging
    try:
        raise ValueError("Something went wrong")
    except Exception:
        logger.exception("An error occurred")

    # Clear context
    LogContext.clear()
