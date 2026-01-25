"""Command-line publisher for driving the Prism hologram scenes via MQTT."""

from __future__ import annotations

import argparse
import ast
import json
import os
import threading
import time
import uuid
from dataclasses import dataclass
from typing import Any, Dict, Iterable

import paho.mqtt.client as mqtt

DEFAULT_TOPIC = os.getenv("HOLO_MQTT_TOPIC", "prism/holo/scene")
DEFAULT_HOST = os.getenv("HOLO_MQTT_HOST", "localhost")
DEFAULT_PORT = int(os.getenv("HOLO_MQTT_PORT", "1883"))
DEFAULT_USERNAME = os.getenv("HOLO_MQTT_USERNAME")
DEFAULT_PASSWORD = os.getenv("HOLO_MQTT_PASSWORD")
DEFAULT_QOS = int(os.getenv("HOLO_MQTT_QOS", "0"))
DEFAULT_KEEPALIVE = int(os.getenv("HOLO_MQTT_KEEPALIVE", "60"))
DEFAULT_TIMEOUT = float(os.getenv("HOLO_MQTT_TIMEOUT", "5.0"))
DEFAULT_RETAIN = os.getenv("HOLO_MQTT_RETAIN", "false").lower() in {"1", "true", "yes", "on"}


@dataclass
class MQTTSettings:
    """Connection settings for the MQTT broker."""

    host: str
    port: int
    topic: str
    username: str | None
    password: str | None
    client_id: str
    qos: int
    retain: bool
    keepalive: int
    timeout: float


def _parse_value(raw: str) -> Any:
    """Best-effort conversion for parameter values.

    ``ast.literal_eval`` handles numbers, lists, dictionaries, booleans, and strings
    with explicit quotes. If parsing fails, the original string is returned so CLI
    users can pass free-form text without escaping.
    """

    text = raw.strip()
    if not text:
        return ""

    try:
        return ast.literal_eval(text)
    except (ValueError, SyntaxError):
        lowered = text.lower()
        if lowered in {"true", "false"}:
            return lowered == "true"
        return text


def parse_params(param_args: Iterable[str]) -> Dict[str, Any]:
    """Parse ``--param key=value`` pairs into a dictionary."""

    params: Dict[str, Any] = {}
    for item in param_args:
        if "=" not in item:
            raise ValueError(f"Invalid parameter '{item}'. Expected key=value format.")
        key, raw_value = item.split("=", 1)
        key = key.strip()
        if not key:
            raise ValueError(f"Invalid parameter '{item}'. Key may not be empty.")
        params[key] = _parse_value(raw_value)
    return params


def add_mqtt_arguments(parser: argparse.ArgumentParser) -> None:
    """Attach shared MQTT connection arguments to ``parser``."""

    parser.add_argument("--host", default=DEFAULT_HOST, help="MQTT broker hostname or IP address")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="MQTT broker port")
    parser.add_argument("--topic", default=DEFAULT_TOPIC, help="MQTT topic to publish scene commands")
    parser.add_argument("--username", default=DEFAULT_USERNAME, help="Optional MQTT username")
    parser.add_argument("--password", default=DEFAULT_PASSWORD, help="Optional MQTT password")
    parser.add_argument(
        "--client-id",
        default=os.getenv("HOLO_MQTT_CLIENT_ID"),
        help="MQTT client identifier (defaults to random if omitted)",
    )
    parser.add_argument(
        "--qos",
        type=int,
        choices=(0, 1, 2),
        default=DEFAULT_QOS,
        help="MQTT Quality-of-Service level",
    )
    parser.add_argument(
        "--retain",
        dest="retain",
        action=argparse.BooleanOptionalAction,
        default=DEFAULT_RETAIN,
        help="Request the broker to retain the published scene command",
    )
    parser.add_argument(
        "--keepalive",
        type=int,
        default=DEFAULT_KEEPALIVE,
        help="Keepalive interval (seconds) for the MQTT connection",
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=DEFAULT_TIMEOUT,
        help="Seconds to wait for MQTT connect/publish operations",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print the payload instead of publishing to MQTT",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Emit verbose connection and publish diagnostics",
    )


def build_settings(args: argparse.Namespace) -> MQTTSettings:
    client_id = args.client_id or f"holo-cli-{uuid.uuid4().hex[:8]}"
    return MQTTSettings(
        host=args.host,
        port=args.port,
        topic=args.topic,
        username=args.username,
        password=args.password,
        client_id=client_id,
        qos=args.qos,
        retain=args.retain,
        keepalive=args.keepalive,
        timeout=args.timeout,
    )


def publish_scene(
    scene: str,
    params: Dict[str, Any],
    *,
    settings: MQTTSettings,
    verbose: bool = False,
    dry_run: bool = False,
) -> None:
    """Publish a scene command to the configured MQTT topic."""

    payload = {
        "scene": scene,
        "params": params,
        "timestamp": time.time(),
    }
    payload_text = json.dumps(payload, separators=(",", ":"))

    if verbose or dry_run:
        print(f"[holo-cli] topic={settings.topic} qos={settings.qos} retain={settings.retain}")
        print(f"[holo-cli] payload={payload_text}")

    if dry_run:
        return

    connect_event = threading.Event()
    publish_event = threading.Event()
    disconnect_event = threading.Event()
    error_holder: list[Exception] = []

    client = mqtt.Client(client_id=settings.client_id, clean_session=True)

    if settings.username:
        client.username_pw_set(settings.username, settings.password)

    def on_connect(client: mqtt.Client, _userdata: Any, _flags: Dict[str, Any], rc: int, *_: Any) -> None:
        if rc != mqtt.MQTT_ERR_SUCCESS:
            error_holder.append(RuntimeError(f"MQTT connect failed with rc={rc}"))
        connect_event.set()

    def on_publish(_client: mqtt.Client, _userdata: Any, _mid: int) -> None:
        publish_event.set()

    def on_disconnect(_client: mqtt.Client, _userdata: Any, _rc: int) -> None:
        disconnect_event.set()

    client.on_connect = on_connect
    client.on_publish = on_publish
    client.on_disconnect = on_disconnect

    if verbose:
        client.on_log = lambda _client, _userdata, _level, buf: print(f"[mqtt] {buf}")

    try:
        client.connect(settings.host, settings.port, keepalive=settings.keepalive)
    except Exception as exc:  # pragma: no cover - connection issues are user dependent
        raise RuntimeError(f"Unable to connect to MQTT broker at {settings.host}:{settings.port}") from exc

    client.loop_start()
    try:
        if not connect_event.wait(settings.timeout):
            raise TimeoutError("Timed out while waiting for MQTT connection acknowledgment")
        if error_holder:
            raise error_holder[0]

        client.publish(settings.topic, payload_text, qos=settings.qos, retain=settings.retain)
        if not publish_event.wait(settings.timeout):
            raise TimeoutError("Publish acknowledgment timeout")
    finally:
        client.disconnect()
        # Wait for clean disconnect to avoid orphan threads when loop stops.
        disconnect_event.wait(timeout=1.0)
        client.loop_stop()


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish a one-shot Prism hologram scene command via MQTT.")
    parser.add_argument("--scene", required=True, help="Scene identifier (e.g. text, shapes, aurora)")
    parser.add_argument(
        "--param",
        action="append",
        default=[],
        help="Scene parameter in key=value form. Repeat for multiple entries.",
    )
    add_mqtt_arguments(parser)
    return parser


def main(argv: Iterable[str] | None = None) -> None:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        params = parse_params(args.param)
    except ValueError as exc:
        parser.error(str(exc))
        return

    settings = build_settings(args)

    try:
        publish_scene(
            args.scene,
            params,
            settings=settings,
            verbose=args.verbose,
            dry_run=args.dry_run,
        )
    except Exception as exc:
        parser.exit(status=1, message=f"error: {exc}\n")


if __name__ == "__main__":
    main()
