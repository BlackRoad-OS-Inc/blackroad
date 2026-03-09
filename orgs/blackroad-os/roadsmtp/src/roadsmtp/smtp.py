"""
RoadSMTP - SMTP Client for BlackRoad
Send emails with attachments and templates.
"""

from dataclasses import dataclass, field
from email.mime.base import MIMEBase
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email import encoders
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional, Union
import base64
import socket
import ssl
import logging

logger = logging.getLogger(__name__)


class SMTPError(Exception):
    pass


@dataclass
class SMTPConfig:
    host: str
    port: int = 587
    username: str = ""
    password: str = ""
    use_tls: bool = True
    timeout: float = 30.0


@dataclass
class Attachment:
    filename: str
    content: bytes
    content_type: str = "application/octet-stream"

    @classmethod
    def from_file(cls, path: Union[str, Path]) -> "Attachment":
        path = Path(path)
        return cls(filename=path.name, content=path.read_bytes())


@dataclass
class Email:
    to: List[str]
    subject: str
    body: str = ""
    html: str = ""
    from_addr: str = ""
    cc: List[str] = field(default_factory=list)
    bcc: List[str] = field(default_factory=list)
    reply_to: str = ""
    attachments: List[Attachment] = field(default_factory=list)
    headers: Dict[str, str] = field(default_factory=dict)

    def add_attachment(self, attachment: Attachment) -> "Email":
        self.attachments.append(attachment)
        return self

    def attach_file(self, path: Union[str, Path]) -> "Email":
        self.attachments.append(Attachment.from_file(path))
        return self


class SMTPClient:
    def __init__(self, config: SMTPConfig):
        self.config = config
        self._socket: Optional[socket.socket] = None
        self._file: Any = None

    def connect(self) -> "SMTPClient":
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.settimeout(self.config.timeout)
        self._socket.connect((self.config.host, self.config.port))
        self._file = self._socket.makefile("rb")

        self._read_response()  # Welcome
        self._command(f"EHLO localhost")

        if self.config.use_tls:
            self._command("STARTTLS")
            context = ssl.create_default_context()
            self._socket = context.wrap_socket(self._socket, server_hostname=self.config.host)
            self._file = self._socket.makefile("rb")
            self._command("EHLO localhost")

        if self.config.username and self.config.password:
            self._command("AUTH LOGIN")
            self._command(base64.b64encode(self.config.username.encode()).decode())
            self._command(base64.b64encode(self.config.password.encode()).decode())

        return self

    def _read_response(self) -> tuple:
        lines = []
        while True:
            line = self._file.readline().decode("utf-8").rstrip("\r\n")
            lines.append(line)
            if len(line) >= 4 and line[3] == " ":
                break
        code = int(lines[-1][:3])
        return code, "\n".join(lines)

    def _command(self, cmd: str) -> tuple:
        logger.debug(f"SMTP: {cmd[:50]}...")
        self._socket.sendall(f"{cmd}\r\n".encode())
        return self._read_response()

    def _build_message(self, email: Email) -> str:
        if email.attachments or email.html:
            msg = MIMEMultipart("alternative" if email.html else "mixed")
        else:
            msg = MIMEText(email.body, "plain")

        msg["Subject"] = email.subject
        msg["From"] = email.from_addr or self.config.username
        msg["To"] = ", ".join(email.to)
        if email.cc:
            msg["Cc"] = ", ".join(email.cc)
        if email.reply_to:
            msg["Reply-To"] = email.reply_to

        for key, value in email.headers.items():
            msg[key] = value

        if isinstance(msg, MIMEMultipart):
            if email.body:
                msg.attach(MIMEText(email.body, "plain"))
            if email.html:
                msg.attach(MIMEText(email.html, "html"))

            for att in email.attachments:
                part = MIMEBase(*att.content_type.split("/", 1))
                part.set_payload(att.content)
                encoders.encode_base64(part)
                part.add_header("Content-Disposition", f"attachment; filename={att.filename}")
                msg.attach(part)

        return msg.as_string()

    def send(self, email: Email) -> bool:
        from_addr = email.from_addr or self.config.username
        recipients = email.to + email.cc + email.bcc

        code, msg = self._command(f"MAIL FROM:<{from_addr}>")
        if code != 250:
            raise SMTPError(f"MAIL FROM failed: {msg}")

        for recipient in recipients:
            code, msg = self._command(f"RCPT TO:<{recipient}>")
            if code not in (250, 251):
                raise SMTPError(f"RCPT TO failed for {recipient}: {msg}")

        code, msg = self._command("DATA")
        if code != 354:
            raise SMTPError(f"DATA failed: {msg}")

        message = self._build_message(email)
        self._socket.sendall(message.encode())
        code, msg = self._command(".")
        if code != 250:
            raise SMTPError(f"Send failed: {msg}")

        return True

    def close(self) -> None:
        try:
            self._command("QUIT")
        except Exception:
            pass
        if self._socket:
            self._socket.close()

    def __enter__(self) -> "SMTPClient":
        return self.connect()

    def __exit__(self, *args) -> None:
        self.close()


class EmailBuilder:
    def __init__(self):
        self._email = Email(to=[], subject="")

    def to(self, *addresses: str) -> "EmailBuilder":
        self._email.to.extend(addresses)
        return self

    def cc(self, *addresses: str) -> "EmailBuilder":
        self._email.cc.extend(addresses)
        return self

    def bcc(self, *addresses: str) -> "EmailBuilder":
        self._email.bcc.extend(addresses)
        return self

    def subject(self, subject: str) -> "EmailBuilder":
        self._email.subject = subject
        return self

    def body(self, body: str) -> "EmailBuilder":
        self._email.body = body
        return self

    def html(self, html: str) -> "EmailBuilder":
        self._email.html = html
        return self

    def from_addr(self, addr: str) -> "EmailBuilder":
        self._email.from_addr = addr
        return self

    def attach(self, path: Union[str, Path]) -> "EmailBuilder":
        self._email.attach_file(path)
        return self

    def build(self) -> Email:
        return self._email


def email() -> EmailBuilder:
    return EmailBuilder()


def send(config: SMTPConfig, mail: Email) -> bool:
    with SMTPClient(config) as client:
        return client.send(mail)


def example_usage():
    config = SMTPConfig(
        host="smtp.example.com",
        port=587,
        username="user@example.com",
        password="password"
    )

    mail = (email()
        .to("recipient@example.com")
        .subject("Test Email")
        .body("Hello from RoadSMTP!")
        .html("<h1>Hello from RoadSMTP!</h1>")
        .build())

    with SMTPClient(config) as client:
        client.send(mail)

