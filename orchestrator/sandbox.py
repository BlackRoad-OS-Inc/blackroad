import multiprocessing
from typing import Any, Callable

from sdk import plugin_api
from metrics import record


class BotExecutionError(Exception):
    pass


def run_in_sandbox(callable: Callable[[], Any], timeout_s: int = 5, mem_mb: int = 128) -> Any:
    """Execute callable in a subprocess with time/memory limits."""

    def _target(q):
        try:
            q.put(callable())
        except Exception as e:  # pragma: no cover - forwarded
            q.put(e)

    q: multiprocessing.Queue[Any] = multiprocessing.Queue()
    proc = multiprocessing.Process(target=_target, args=(q,))
    proc.start()
    proc.join(timeout_s)
    if proc.is_alive():
        proc.terminate()
        proc.join()
        record("sandbox_timeout")
        raise BotExecutionError("timeout")
    result = q.get() if not q.empty() else None
    if isinstance(result, Exception):
        raise result
    return result
