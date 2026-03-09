"""
RoadDNS - DNS Client for BlackRoad
DNS queries and record management.
"""

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import IntEnum
from typing import Any, Dict, List, Optional, Tuple, Union
import random
import socket
import struct
import logging

logger = logging.getLogger(__name__)


class DNSError(Exception):
    pass


class RecordType(IntEnum):
    A = 1
    NS = 2
    CNAME = 5
    SOA = 6
    PTR = 12
    MX = 15
    TXT = 16
    AAAA = 28
    SRV = 33
    ANY = 255


class RecordClass(IntEnum):
    IN = 1  # Internet
    CS = 2  # CSNET
    CH = 3  # CHAOS
    HS = 4  # Hesiod


@dataclass
class DNSRecord:
    name: str
    type: RecordType
    ttl: int
    data: Any
    record_class: RecordClass = RecordClass.IN

    def __str__(self) -> str:
        return f"{self.name} {self.ttl} {self.type.name} {self.data}"


@dataclass
class DNSResponse:
    id: int
    questions: List[tuple]
    answers: List[DNSRecord]
    authority: List[DNSRecord]
    additional: List[DNSRecord]
    rcode: int = 0

    @property
    def success(self) -> bool:
        return self.rcode == 0


class DNSPacket:
    @staticmethod
    def encode_name(name: str) -> bytes:
        result = b""
        for label in name.split("."):
            if label:
                result += bytes([len(label)]) + label.encode()
        result += b"\x00"
        return result

    @staticmethod
    def decode_name(data: bytes, offset: int) -> Tuple[str, int]:
        labels = []
        jumped = False
        original_offset = offset
        max_jumps = 10
        jumps = 0

        while True:
            if offset >= len(data):
                break
            length = data[offset]
            if length == 0:
                offset += 1
                break
            if (length & 0xC0) == 0xC0:
                if not jumped:
                    original_offset = offset + 2
                pointer = ((length & 0x3F) << 8) | data[offset + 1]
                offset = pointer
                jumped = True
                jumps += 1
                if jumps > max_jumps:
                    raise DNSError("Too many jumps in name")
            else:
                offset += 1
                labels.append(data[offset:offset + length].decode())
                offset += length

        return ".".join(labels), original_offset if jumped else offset

    @staticmethod
    def build_query(name: str, record_type: RecordType, record_class: RecordClass = RecordClass.IN) -> bytes:
        transaction_id = random.randint(0, 65535)
        flags = 0x0100  # Standard query with recursion
        questions = 1
        
        header = struct.pack(">HHHHHH", transaction_id, flags, questions, 0, 0, 0)
        question = DNSPacket.encode_name(name) + struct.pack(">HH", record_type, record_class)
        
        return header + question

    @staticmethod
    def parse_response(data: bytes) -> DNSResponse:
        if len(data) < 12:
            raise DNSError("Response too short")

        header = struct.unpack(">HHHHHH", data[:12])
        trans_id, flags, qd_count, an_count, ns_count, ar_count = header
        rcode = flags & 0xF
        offset = 12

        questions = []
        for _ in range(qd_count):
            name, offset = DNSPacket.decode_name(data, offset)
            qtype, qclass = struct.unpack(">HH", data[offset:offset + 4])
            offset += 4
            questions.append((name, qtype, qclass))

        def parse_records(count: int) -> List[DNSRecord]:
            nonlocal offset
            records = []
            for _ in range(count):
                name, offset = DNSPacket.decode_name(data, offset)
                rtype, rclass, ttl, rdlength = struct.unpack(">HHIH", data[offset:offset + 10])
                offset += 10
                rdata = data[offset:offset + rdlength]
                offset += rdlength

                record_data = DNSPacket._parse_rdata(rtype, rdata, data)
                records.append(DNSRecord(
                    name=name,
                    type=RecordType(rtype),
                    ttl=ttl,
                    data=record_data,
                    record_class=RecordClass(rclass)
                ))
            return records

        answers = parse_records(an_count)
        authority = parse_records(ns_count)
        additional = parse_records(ar_count)

        return DNSResponse(
            id=trans_id,
            questions=questions,
            answers=answers,
            authority=authority,
            additional=additional,
            rcode=rcode
        )

    @staticmethod
    def _parse_rdata(rtype: int, rdata: bytes, full_data: bytes) -> Any:
        if rtype == RecordType.A and len(rdata) == 4:
            return ".".join(str(b) for b in rdata)
        if rtype == RecordType.AAAA and len(rdata) == 16:
            return ":".join(f"{rdata[i]:02x}{rdata[i+1]:02x}" for i in range(0, 16, 2))
        if rtype in (RecordType.NS, RecordType.CNAME, RecordType.PTR):
            name, _ = DNSPacket.decode_name(full_data, len(full_data) - len(rdata))
            return name
        if rtype == RecordType.MX:
            priority = struct.unpack(">H", rdata[:2])[0]
            name, _ = DNSPacket.decode_name(full_data, len(full_data) - len(rdata) + 2)
            return (priority, name)
        if rtype == RecordType.TXT:
            texts = []
            offset = 0
            while offset < len(rdata):
                length = rdata[offset]
                texts.append(rdata[offset + 1:offset + 1 + length].decode())
                offset += 1 + length
            return " ".join(texts)
        return rdata.hex()


class DNSClient:
    def __init__(self, servers: List[str] = None, timeout: float = 5.0):
        self.servers = servers or ["8.8.8.8", "8.8.4.4", "1.1.1.1"]
        self.timeout = timeout
        self._cache: Dict[tuple, Tuple[DNSResponse, datetime]] = {}

    def query(self, name: str, record_type: RecordType = RecordType.A, use_cache: bool = True) -> DNSResponse:
        cache_key = (name, record_type)
        if use_cache and cache_key in self._cache:
            response, expires = self._cache[cache_key]
            if datetime.now() < expires:
                return response

        packet = DNSPacket.build_query(name, record_type)

        for server in self.servers:
            try:
                sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
                sock.settimeout(self.timeout)
                sock.sendto(packet, (server, 53))
                data, _ = sock.recvfrom(512)
                sock.close()

                response = DNSPacket.parse_response(data)
                if response.success and response.answers:
                    min_ttl = min(r.ttl for r in response.answers)
                    self._cache[cache_key] = (response, datetime.now() + timedelta(seconds=min_ttl))
                return response
            except socket.timeout:
                continue
            except Exception as e:
                logger.error(f"DNS query failed: {e}")
                continue

        raise DNSError(f"All DNS servers failed for {name}")

    def resolve(self, name: str) -> List[str]:
        response = self.query(name, RecordType.A)
        return [r.data for r in response.answers if r.type == RecordType.A]

    def reverse(self, ip: str) -> Optional[str]:
        parts = ip.split(".")[::-1]
        ptr_name = ".".join(parts) + ".in-addr.arpa"
        response = self.query(ptr_name, RecordType.PTR)
        for r in response.answers:
            if r.type == RecordType.PTR:
                return r.data
        return None


def resolve(name: str) -> List[str]:
    return DNSClient().resolve(name)


def query(name: str, record_type: RecordType = RecordType.A) -> DNSResponse:
    return DNSClient().query(name, record_type)


def example_usage():
    client = DNSClient()

    response = client.query("example.com", RecordType.A)
    print(f"A records for example.com:")
    for record in response.answers:
        print(f"  {record}")

    ips = client.resolve("google.com")
    print(f"\nGoogle IPs: {ips}")

    mx_response = client.query("gmail.com", RecordType.MX)
    print(f"\nMX records for gmail.com:")
    for record in mx_response.answers:
        print(f"  {record}")

