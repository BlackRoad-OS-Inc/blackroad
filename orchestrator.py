"""Concurrency-safe orchestrator for Lucidia shard jobs."""
from __future__ import annotations

import concurrent.futures
import logging
import time
from typing import Any, Callable, Dict, Tuple

logger = logging.getLogger(__name__)


def run_shards(
    job_fn: Callable[[int], Any], *, num_shards: int = 10, timebox_seconds: int = 60
) -> Tuple[Dict[int, Any], Dict[int, str]]:
    """Execute shard jobs in parallel with a global timebox.

    Parameters
    ----------
    job_fn:
        Callable accepting a ``shard_id`` and returning a result.
    num_shards:
        Total number of shards to execute.
    timebox_seconds:
        Maximum wall clock time allowed for all shards.

    Returns
    -------
    Tuple[Dict[int, Any], Dict[int, str]]
        A tuple ``(results, errors)`` where ``results`` maps shard IDs to
        successful return values and ``errors`` maps shard IDs to error
        messages for failed or cancelled jobs.
    """

    # Ψ′:orchestrate — manage parallel shard execution
    start = time.monotonic()
    deadline = start + timebox_seconds
    results: Dict[int, Any] = {}
    errors: Dict[int, str] = {}

    with concurrent.futures.ThreadPoolExecutor(max_workers=num_shards) as executor:
        future_map = {executor.submit(job_fn, shard): shard for shard in range(num_shards)}
        while future_map and time.monotonic() < deadline:
            timeout = deadline - time.monotonic()
            done, _ = concurrent.futures.wait(
                future_map,
                timeout=timeout,
                return_when=concurrent.futures.FIRST_COMPLETED,
            )
            if not done:
                break
            for fut in done:
                shard_id = future_map.pop(fut)
                try:
                    results[shard_id] = fut.result()
                except Exception as exc:  # pragma: no cover - logging
                    logger.exception("Shard %s failed", shard_id)
                    errors[shard_id] = str(exc)
        for fut, shard_id in future_map.items():
            fut.cancel()
            errors[shard_id] = "cancelled"
        if future_map:
            logger.warning("Timebox exceeded; cancelled %d shards", len(future_map))

    return results, errors
