"""Minimal email adapter for the Prism console.

The real deployment integrates with transactional email services.  Here we
support two execution modes:

``SMTP``
    When ``PRISM_EMAIL_SMTP_HOST`` is set the message is sent using the provided
    connection details.

``Log file``
    If no SMTP configuration is available the message is appended to a log file
    so that the console can run offline without raising errors.
"""

from __future__ import annotations

import os
import smtplib
from dataclasses import dataclass
from email.message import EmailMessage
from pathlib import Path
from collections.abc import Iterable

DEFAULT_LOG_FILE = Path("logs/outbox.log")


@dataclass(slots=True)
class EmailConfig:
    host: str | None = None
    port: int = 587
    username: str | None = None
    password: str | None = None
    sender: str | None = None
    use_tls: bool = True
    log_file: Path = DEFAULT_LOG_FILE

    @classmethod
    def from_env(cls) -> "EmailConfig":
        host = os.getenv("PRISM_EMAIL_SMTP_HOST")
        port = int(os.getenv("PRISM_EMAIL_SMTP_PORT", "587"))
        username = os.getenv("PRISM_EMAIL_SMTP_USERNAME")
        password = os.getenv("PRISM_EMAIL_SMTP_PASSWORD")
        sender = os.getenv("PRISM_EMAIL_FROM")
        use_tls = os.getenv("PRISM_EMAIL_SMTP_USE_TLS", "true").lower() != "false"
        log_file = Path(os.getenv("PRISM_EMAIL_LOG_FILE", DEFAULT_LOG_FILE))
        return cls(host, port, username, password, sender, use_tls, log_file)


def _deliver_via_smtp(message: EmailMessage, config: EmailConfig) -> None:
    server = smtplib.SMTP(config.host, config.port, timeout=10)
    try:
        server.ehlo()
        if config.use_tls:
            server.starttls()
            server.ehlo()
        if config.username and config.password:
            server.login(config.username, config.password)
        server.send_message(message)
    finally:
        server.quit()


def _deliver_to_log(message: EmailMessage, log_file: Path) -> None:
    log_file.parent.mkdir(parents=True, exist_ok=True)
    with log_file.open("a", encoding="utf-8") as file:
        file.write("\n" + "-" * 80 + "\n")
        file.write(message.as_string())
        file.write("\n")


def send(to: str | Iterable[str], subject: str, body: str) -> None:
    """Send an email using the configured backend."""

    config = EmailConfig.from_env()
    if isinstance(to, str):
        recipients = [to]
    elif isinstance(to, Iterable):
        seen: set[str] = set()
        recipients = []
        for address in to:
            if address not in seen:
                recipients.append(address)
                seen.add(address)
    else:
        recipients = [str(to)]
    if not recipients:
        raise ValueError("At least one recipient must be supplied")

    message = EmailMessage()
    message["To"] = ", ".join(recipients)
    message["Subject"] = subject
    message["From"] = config.sender or (config.username or "noreply@example.com")
    message.set_content(body)

    if config.host:
        _deliver_via_smtp(message, config)
    else:
        _deliver_to_log(message, config.log_file)


__all__ = ["send", "EmailConfig"]
