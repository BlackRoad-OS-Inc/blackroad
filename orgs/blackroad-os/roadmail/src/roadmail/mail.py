"""
RoadMail - Email Sending for BlackRoad
Send emails with templates, attachments, and tracking.
"""

from dataclasses import dataclass, field
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.base import MIMEBase
from email import encoders
from enum import Enum
from typing import Any, Callable, Dict, List, Optional, Tuple
import asyncio
import base64
import logging
import re
import smtplib
import uuid

logger = logging.getLogger(__name__)


class EmailStatus(str, Enum):
    PENDING = "pending"
    SENDING = "sending"
    SENT = "sent"
    FAILED = "failed"
    BOUNCED = "bounced"
    DELIVERED = "delivered"
    OPENED = "opened"
    CLICKED = "clicked"


@dataclass
class Attachment:
    filename: str
    content: bytes
    content_type: str = "application/octet-stream"


@dataclass
class EmailAddress:
    email: str
    name: str = ""

    def __str__(self) -> str:
        if self.name:
            return f"{self.name} <{self.email}>"
        return self.email


@dataclass
class Email:
    id: str
    to: List[EmailAddress]
    subject: str
    body_text: str = ""
    body_html: str = ""
    from_addr: Optional[EmailAddress] = None
    reply_to: Optional[EmailAddress] = None
    cc: List[EmailAddress] = field(default_factory=list)
    bcc: List[EmailAddress] = field(default_factory=list)
    attachments: List[Attachment] = field(default_factory=list)
    headers: Dict[str, str] = field(default_factory=dict)
    status: EmailStatus = EmailStatus.PENDING
    created_at: datetime = field(default_factory=datetime.now)
    sent_at: Optional[datetime] = None
    error: Optional[str] = None
    tracking_id: Optional[str] = None
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class EmailTemplate:
    id: str
    name: str
    subject: str
    body_text: str = ""
    body_html: str = ""
    variables: List[str] = field(default_factory=list)

    def render(self, context: Dict[str, Any]) -> Tuple[str, str, str]:
        subject = self.subject
        body_text = self.body_text
        body_html = self.body_html
        
        for key, value in context.items():
            placeholder = f"{{{{{key}}}}}"
            subject = subject.replace(placeholder, str(value))
            body_text = body_text.replace(placeholder, str(value))
            body_html = body_html.replace(placeholder, str(value))
        
        return subject, body_text, body_html


class SMTPTransport:
    def __init__(self, host: str, port: int, username: str = "", password: str = "", use_tls: bool = True):
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.use_tls = use_tls

    def send(self, email: Email) -> bool:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = email.subject
        msg["From"] = str(email.from_addr)
        msg["To"] = ", ".join(str(addr) for addr in email.to)
        
        if email.cc:
            msg["Cc"] = ", ".join(str(addr) for addr in email.cc)
        if email.reply_to:
            msg["Reply-To"] = str(email.reply_to)
        
        for key, value in email.headers.items():
            msg[key] = value
        
        if email.body_text:
            msg.attach(MIMEText(email.body_text, "plain"))
        if email.body_html:
            msg.attach(MIMEText(email.body_html, "html"))
        
        for attachment in email.attachments:
            part = MIMEBase(*attachment.content_type.split("/"))
            part.set_payload(attachment.content)
            encoders.encode_base64(part)
            part.add_header("Content-Disposition", f"attachment; filename={attachment.filename}")
            msg.attach(part)
        
        try:
            with smtplib.SMTP(self.host, self.port) as server:
                if self.use_tls:
                    server.starttls()
                if self.username:
                    server.login(self.username, self.password)
                
                recipients = [addr.email for addr in email.to + email.cc + email.bcc]
                server.sendmail(email.from_addr.email, recipients, msg.as_string())
            return True
        except Exception as e:
            logger.error(f"SMTP error: {e}")
            raise


class MockTransport:
    def __init__(self):
        self.sent_emails: List[Email] = []

    def send(self, email: Email) -> bool:
        logger.info(f"Mock sending email to {[str(addr) for addr in email.to]}")
        self.sent_emails.append(email)
        return True


class Mailer:
    def __init__(self, transport: Any = None, default_from: EmailAddress = None):
        self.transport = transport or MockTransport()
        self.default_from = default_from or EmailAddress("noreply@example.com")
        self.templates: Dict[str, EmailTemplate] = {}
        self.sent_emails: Dict[str, Email] = {}
        self.hooks: Dict[str, List[Callable]] = {
            "before_send": [], "after_send": [], "on_error": []
        }

    def add_hook(self, event: str, handler: Callable) -> None:
        if event in self.hooks:
            self.hooks[event].append(handler)

    def _emit(self, event: str, email: Email) -> None:
        for handler in self.hooks.get(event, []):
            try:
                handler(email)
            except Exception as e:
                logger.error(f"Hook error: {e}")

    def register_template(self, template: EmailTemplate) -> None:
        self.templates[template.id] = template

    def send(self, to: List[str], subject: str, body_text: str = "", body_html: str = "", **kwargs) -> Email:
        recipients = [EmailAddress(email=addr) if isinstance(addr, str) else addr for addr in to]
        
        email = Email(
            id=str(uuid.uuid4())[:12],
            to=recipients,
            subject=subject,
            body_text=body_text,
            body_html=body_html,
            from_addr=kwargs.get("from_addr", self.default_from),
            tracking_id=str(uuid.uuid4())[:8],
            **{k: v for k, v in kwargs.items() if k != "from_addr"}
        )
        
        self._emit("before_send", email)
        email.status = EmailStatus.SENDING
        
        try:
            self.transport.send(email)
            email.status = EmailStatus.SENT
            email.sent_at = datetime.now()
            self._emit("after_send", email)
        except Exception as e:
            email.status = EmailStatus.FAILED
            email.error = str(e)
            self._emit("on_error", email)
        
        self.sent_emails[email.id] = email
        return email

    def send_template(self, template_id: str, to: List[str], context: Dict[str, Any] = None, **kwargs) -> Optional[Email]:
        template = self.templates.get(template_id)
        if not template:
            logger.error(f"Template not found: {template_id}")
            return None
        
        subject, body_text, body_html = template.render(context or {})
        return self.send(to, subject, body_text, body_html, **kwargs)

    async def send_async(self, *args, **kwargs) -> Email:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, lambda: self.send(*args, **kwargs))

    def send_bulk(self, emails: List[Dict[str, Any]]) -> List[Email]:
        results = []
        for email_data in emails:
            result = self.send(**email_data)
            results.append(result)
        return results

    def get_email(self, email_id: str) -> Optional[Email]:
        return self.sent_emails.get(email_id)

    def stats(self) -> Dict[str, int]:
        emails = list(self.sent_emails.values())
        return {
            "total": len(emails),
            "sent": len([e for e in emails if e.status == EmailStatus.SENT]),
            "failed": len([e for e in emails if e.status == EmailStatus.FAILED]),
            "pending": len([e for e in emails if e.status == EmailStatus.PENDING])
        }


class EmailBuilder:
    def __init__(self):
        self._to: List[EmailAddress] = []
        self._cc: List[EmailAddress] = []
        self._bcc: List[EmailAddress] = []
        self._subject: str = ""
        self._body_text: str = ""
        self._body_html: str = ""
        self._attachments: List[Attachment] = []
        self._from: Optional[EmailAddress] = None
        self._reply_to: Optional[EmailAddress] = None

    def to(self, *addresses: str) -> "EmailBuilder":
        self._to.extend(EmailAddress(email=addr) for addr in addresses)
        return self

    def cc(self, *addresses: str) -> "EmailBuilder":
        self._cc.extend(EmailAddress(email=addr) for addr in addresses)
        return self

    def bcc(self, *addresses: str) -> "EmailBuilder":
        self._bcc.extend(EmailAddress(email=addr) for addr in addresses)
        return self

    def from_address(self, email: str, name: str = "") -> "EmailBuilder":
        self._from = EmailAddress(email=email, name=name)
        return self

    def reply_to(self, email: str, name: str = "") -> "EmailBuilder":
        self._reply_to = EmailAddress(email=email, name=name)
        return self

    def subject(self, subject: str) -> "EmailBuilder":
        self._subject = subject
        return self

    def text(self, body: str) -> "EmailBuilder":
        self._body_text = body
        return self

    def html(self, body: str) -> "EmailBuilder":
        self._body_html = body
        return self

    def attach(self, filename: str, content: bytes, content_type: str = "application/octet-stream") -> "EmailBuilder":
        self._attachments.append(Attachment(filename, content, content_type))
        return self

    def build(self) -> Dict[str, Any]:
        return {
            "to": [addr.email for addr in self._to],
            "subject": self._subject,
            "body_text": self._body_text,
            "body_html": self._body_html,
            "cc": self._cc,
            "bcc": self._bcc,
            "from_addr": self._from,
            "reply_to": self._reply_to,
            "attachments": self._attachments
        }


def example_usage():
    mailer = Mailer()
    
    mailer.register_template(EmailTemplate(
        id="welcome",
        name="Welcome Email",
        subject="Welcome to {{app_name}}, {{name}}!",
        body_text="Hi {{name}},\n\nWelcome to {{app_name}}!\n\nBest,\nThe Team",
        body_html="<h1>Hi {{name}},</h1><p>Welcome to {{app_name}}!</p><p>Best,<br>The Team</p>"
    ))
    
    email = mailer.send(
        to=["alice@example.com"],
        subject="Hello!",
        body_text="This is a test email.",
        body_html="<h1>Hello!</h1><p>This is a test email.</p>"
    )
    print(f"Sent email: {email.id} - {email.status.value}")
    
    email = mailer.send_template(
        "welcome",
        to=["bob@example.com"],
        context={"name": "Bob", "app_name": "BlackRoad"}
    )
    print(f"Sent template email: {email.id} - {email.status.value}")
    
    email_data = (EmailBuilder()
        .to("charlie@example.com")
        .cc("manager@example.com")
        .subject("Monthly Report")
        .text("Please find the report attached.")
        .html("<p>Please find the report attached.</p>")
        .attach("report.txt", b"Report content here", "text/plain")
        .build())
    
    email = mailer.send(**email_data)
    print(f"Sent builder email: {email.id}")
    
    print(f"\nStats: {mailer.stats()}")

