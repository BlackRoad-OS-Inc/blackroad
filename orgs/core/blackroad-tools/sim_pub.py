"""Helper publisher for the Pi Zero display simulator.

This script pushes text or image payloads to the MQTT topic consumed by the
`sim_display.py` client. It provides a convenient way to validate rendering from
any machine on the network.
"""
from __future__ import annotations

import argparse
import base64
import json
import pathlib
from typing import Any, Optional

import paho.mqtt.client as mqtt

DEFAULT_TOPIC = "pi-zero/display"


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Publish sample frames to the Pi Zero display topic")
    parser.add_argument("--host", default="localhost", help="MQTT broker hostname")
    parser.add_argument("--port", type=int, default=1883, help="MQTT broker port")
    parser.add_argument("--topic", default=DEFAULT_TOPIC, help="MQTT topic to publish to")
    parser.add_argument("--username", help="MQTT username")
    parser.add_argument("--password", help="MQTT password")

    text_group = parser.add_argument_group("text")
    text_group.add_argument("--text", help="Text to display")
    text_group.add_argument("--color", nargs=3, type=int, metavar=("R", "G", "B"), help="RGB colour for text")
    text_group.add_argument("--bg", nargs=3, type=int, metavar=("R", "G", "B"), help="RGB background colour")
    text_group.add_argument("--size", type=int, help="Font size override")

    image_group = parser.add_argument_group("image")
    image_group.add_argument("--image", type=pathlib.Path, help="Path to a PNG/JPEG image")

    parser.add_argument("--dry-run", action="store_true", help="Print payload without publishing")
    return parser


def encode_color(value: Optional[list[int]]) -> Optional[list[int]]:
    if value is None:
        return None
    rgb = [max(0, min(255, int(component))) for component in value]
    return rgb


def build_payload(args: argparse.Namespace) -> dict[str, Any]:
    if args.image:
        image_path = pathlib.Path(args.image)
        if not image_path.exists():
            raise SystemExit(f"Image path not found: {image_path}")
        data = image_path.read_bytes()
        return {"type": "image", "b64": base64.b64encode(data).decode("ascii")}

    if args.text:
        payload: dict[str, Any] = {"type": "text", "text": args.text}
        color = encode_color(args.color)
        bg = encode_color(args.bg)
        if color:
            payload["color"] = color
        if bg:
            payload["bg"] = bg
        if args.size:
            payload["size"] = max(8, int(args.size))
        return payload

    raise SystemExit("Provide either --text or --image")


def publish(payload: dict[str, Any], *, host: str, port: int, topic: str, username: Optional[str], password: Optional[str]) -> None:
    client = mqtt.Client()
    if username:
        client.username_pw_set(username=username, password=password)
    client.connect(host, port, keepalive=30)
    client.loop_start()
    try:
        client.publish(topic, json.dumps(payload), qos=1, retain=False)
    finally:
        client.loop_stop()
        client.disconnect()


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()
    payload = build_payload(args)
    if args.dry_run:
        print(json.dumps(payload, indent=2))
        return 0
    publish(
        payload,
        host=args.host,
        port=args.port,
        topic=args.topic,
        username=args.username,
        password=args.password,
    )
    print(f"Published payload to {args.topic}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
