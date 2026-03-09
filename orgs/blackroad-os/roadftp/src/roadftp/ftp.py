"""
RoadFTP - FTP Client for BlackRoad
FTP/FTPS client with upload, download, and directory operations.
"""

from dataclasses import dataclass, field
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Any, Callable, Dict, Generator, List, Optional, Tuple, Union
import re
import socket
import ssl
import logging

logger = logging.getLogger(__name__)


class FTPError(Exception):
    pass


class FTPMode(str, Enum):
    ACTIVE = "active"
    PASSIVE = "passive"


@dataclass
class FTPConfig:
    host: str
    port: int = 21
    username: str = "anonymous"
    password: str = "anonymous@"
    timeout: float = 30.0
    mode: FTPMode = FTPMode.PASSIVE
    secure: bool = False


@dataclass
class FTPEntry:
    name: str
    size: int = 0
    modified: Optional[datetime] = None
    is_dir: bool = False
    permissions: str = ""
    raw: str = ""


class FTPClient:
    def __init__(self, config: FTPConfig):
        self.config = config
        self._socket: Optional[socket.socket] = None
        self._file: Any = None

    def connect(self) -> "FTPClient":
        self._socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._socket.settimeout(self.config.timeout)
        self._socket.connect((self.config.host, self.config.port))

        if self.config.secure:
            context = ssl.create_default_context()
            self._socket = context.wrap_socket(self._socket, server_hostname=self.config.host)

        self._file = self._socket.makefile("r")
        self._read_response()  # Welcome message

        self._command(f"USER {self.config.username}")
        self._command(f"PASS {self.config.password}")

        return self

    def _read_response(self) -> Tuple[int, str]:
        lines = []
        while True:
            line = self._file.readline().rstrip("\r\n")
            lines.append(line)
            if len(line) >= 4 and line[3] == " ":
                break
        code = int(lines[-1][:3])
        message = "\n".join(lines)
        logger.debug(f"FTP Response: {code} {message}")
        return code, message

    def _command(self, cmd: str, expect: int = None) -> Tuple[int, str]:
        logger.debug(f"FTP Command: {cmd}")
        self._socket.sendall(f"{cmd}\r\n".encode())
        code, message = self._read_response()
        if expect and code != expect:
            raise FTPError(f"Expected {expect}, got {code}: {message}")
        return code, message

    def _pasv(self) -> Tuple[str, int]:
        code, msg = self._command("PASV")
        if code != 227:
            raise FTPError(f"PASV failed: {msg}")
        match = re.search(r"\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)", msg)
        if not match:
            raise FTPError("Invalid PASV response")
        parts = [int(x) for x in match.groups()]
        host = ".".join(str(x) for x in parts[:4])
        port = parts[4] * 256 + parts[5]
        return host, port

    def _data_connection(self) -> socket.socket:
        host, port = self._pasv()
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(self.config.timeout)
        sock.connect((host, port))
        if self.config.secure:
            context = ssl.create_default_context()
            sock = context.wrap_socket(sock, server_hostname=self.config.host)
        return sock

    def pwd(self) -> str:
        code, msg = self._command("PWD")
        match = re.search(r'"([^"]*)"', msg)
        return match.group(1) if match else ""

    def cwd(self, path: str) -> None:
        self._command(f"CWD {path}", 250)

    def mkd(self, path: str) -> None:
        self._command(f"MKD {path}", 257)

    def rmd(self, path: str) -> None:
        self._command(f"RMD {path}", 250)

    def delete(self, path: str) -> None:
        self._command(f"DELE {path}", 250)

    def rename(self, old: str, new: str) -> None:
        self._command(f"RNFR {old}", 350)
        self._command(f"RNTO {new}", 250)

    def size(self, path: str) -> int:
        code, msg = self._command(f"SIZE {path}")
        if code == 213:
            return int(msg.split()[-1])
        return 0

    def list(self, path: str = "") -> List[FTPEntry]:
        data_sock = self._data_connection()
        self._command(f"LIST {path}" if path else "LIST")

        data = b""
        while True:
            chunk = data_sock.recv(8192)
            if not chunk:
                break
            data += chunk
        data_sock.close()
        self._read_response()

        entries = []
        for line in data.decode("utf-8", errors="replace").splitlines():
            entry = self._parse_list_line(line)
            if entry:
                entries.append(entry)
        return entries

    def _parse_list_line(self, line: str) -> Optional[FTPEntry]:
        if not line:
            return None
        parts = line.split(None, 8)
        if len(parts) < 9:
            return FTPEntry(name=line, raw=line)
        return FTPEntry(
            name=parts[8],
            size=int(parts[4]) if parts[4].isdigit() else 0,
            is_dir=parts[0].startswith("d"),
            permissions=parts[0],
            raw=line
        )

    def download(self, remote: str, local: Union[str, Path]) -> int:
        local = Path(local)
        data_sock = self._data_connection()
        self._command(f"TYPE I")  # Binary mode
        self._command(f"RETR {remote}")

        total = 0
        with open(local, "wb") as f:
            while True:
                chunk = data_sock.recv(8192)
                if not chunk:
                    break
                f.write(chunk)
                total += len(chunk)
        data_sock.close()
        self._read_response()
        return total

    def upload(self, local: Union[str, Path], remote: str) -> int:
        local = Path(local)
        data_sock = self._data_connection()
        self._command(f"TYPE I")  # Binary mode
        self._command(f"STOR {remote}")

        total = 0
        with open(local, "rb") as f:
            while True:
                chunk = f.read(8192)
                if not chunk:
                    break
                data_sock.sendall(chunk)
                total += len(chunk)
        data_sock.close()
        self._read_response()
        return total

    def close(self) -> None:
        try:
            self._command("QUIT")
        except Exception:
            pass
        if self._socket:
            self._socket.close()

    def __enter__(self) -> "FTPClient":
        return self.connect()

    def __exit__(self, *args) -> None:
        self.close()


def connect(host: str, username: str = "anonymous", password: str = "anonymous@", **kwargs) -> FTPClient:
    config = FTPConfig(host=host, username=username, password=password, **kwargs)
    return FTPClient(config).connect()


def example_usage():
    config = FTPConfig(
        host="ftp.example.com",
        username="user",
        password="pass"
    )
    
    with FTPClient(config) as ftp:
        print(f"PWD: {ftp.pwd()}")
        for entry in ftp.list():
            print(f"  {entry.name} ({entry.size} bytes)")

