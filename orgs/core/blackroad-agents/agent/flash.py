"""Utilities for listing block devices and flashing disk images."""
"""Utilities for imaging removable devices from the Pi dashboard."""

"""Storage flashing helpers for the BlackRoad Pi dashboard."""
from __future__ import annotations

import json
import os
import subprocess
import tempfile
from pathlib import Path
from typing import Dict, Iterator, List, Optional, Tuple

LSBLK_FIELDS = ["NAME", "KNAME", "TYPE", "SIZE", "MODEL", "TRAN"]


def _run(command: List[str]) -> subprocess.CompletedProcess:
    """Run a command and return the completed process."""
    return subprocess.run(command, check=True, capture_output=True, text=True)


def list_devices() -> List[Dict[str, str]]:
    """Return block devices detected via lsblk."""
    try:
        result = _run(["lsblk", "-J", "-o", ",".join(LSBLK_FIELDS)])
    except (FileNotFoundError, subprocess.CalledProcessError):
        return []

    info = json.loads(result.stdout or "{}")
    devices: List[Dict[str, str]] = []
    for block in info.get("blockdevices", []):
        if block.get("type") != "disk":
            continue
        devices.append(
            {
                "device": f"/dev/{block.get('kname', block.get('name', ''))}",
                "name": block.get("name", ""),
                "size": block.get("size", ""),
                "model": block.get("model", ""),
                "transport": block.get("tran", ""),
            }
        )
    return devices


def _download(url: str, out: str) -> str:
    """Download a file to the specified output path."""
    import urllib.request

    urllib.request.urlretrieve(url, out)
    return out


def verify_sha256(file_path: str, sha256_url: str) -> Tuple[bool, str]:
    """Fetch the expected SHA256 checksum and compare it with the local file."""
    import hashlib
    import urllib.request

    try:
        expected = (
            urllib.request.urlopen(sha256_url)
            .read()
            .decode()
            .split()[0]
            .strip()
        )
    except Exception as exc:  # noqa: BLE001 - propagate message via return value
        return False, f"error: {exc}"

    hasher = hashlib.sha256()
    with open(file_path, "rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            hasher.update(chunk)
    return hasher.hexdigest() == expected, expected


def flash(device: str, image_url: str, sha256_url: Optional[str] = None) -> Iterator[str]:
    """Flash an xz-compressed image to the specified block device."""
    tmp_dir = tempfile.gettempdir()
    xz_path = str(Path(tmp_dir) / "blackroad.img.xz")

    yield f"Downloading image: {image_url}"
    try:
        _download(image_url, xz_path)
    except Exception as exc:  # noqa: BLE001
        yield f"ERROR: download failed ({exc})"
        return

    yield f"Downloaded to {xz_path}"

    sha_source = sha256_url or os.environ.get("BLACKROAD_SHA256_URL", "").strip()
    if sha_source:
        ok, expected = verify_sha256(xz_path, sha_source)
        if ok:
            yield f"SHA256 OK: {expected}"
        else:
            yield f"WARNING: SHA256 mismatch or unavailable ({expected})"

    dd_cmd = ["dd", f"of={device}", "bs=4M", "conv=fsync", "status=progress"]
    if os.geteuid() != 0:
        dd_cmd.insert(0, "sudo")

    yield "Writing image to device..."

    try:
        with subprocess.Popen(  # noqa: P201
            ["xzcat", xz_path], stdout=subprocess.PIPE, stderr=subprocess.STDOUT
        ) as xz_proc:
            assert xz_proc.stdout is not None
            with subprocess.Popen(
                dd_cmd,
                stdin=xz_proc.stdout,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
            ) as dd_proc:
                xz_proc.stdout.close()
                assert dd_proc.stdout is not None
                for line in dd_proc.stdout:
                    yield line.strip()
                dd_return = dd_proc.wait()
            xz_return = xz_proc.wait()
    except FileNotFoundError as exc:
        yield f"ERROR: required command missing ({exc})"
        return

    if dd_return != 0 or xz_return != 0:
        yield f"ERROR: flashing failed (xz exit {xz_return}, dd exit {dd_return})"
        return

    yield "Syncing writes..."
    try:
        subprocess.run(["sync"], check=True)
    except subprocess.CalledProcessError:
        yield "WARNING: sync command reported an error"

    try:
        Path(xz_path).unlink()
    except OSError:
        pass

    yield "Flash complete"
import shlex
import subprocess
from typing import Dict, Generator, List


TMP_IMAGE_PATH = "/tmp/blackroad.img.xz"


def _sh(cmd: str) -> tuple[int, str]:
    """Run *cmd* in a shell and return ``(returncode, output)``."""

    try:
        out = subprocess.check_output(shlex.split(cmd), text=True, stderr=subprocess.STDOUT)
        return 0, out
    except subprocess.CalledProcessError as exc:  # pragma: no cover - passthrough
        return exc.returncode, exc.output


def _root_disk(path: str) -> str:
    """Strip partition suffixes from a block-device path."""

    device = path.strip()
    while device and device[-1].isdigit():
        device = device[:-1]
    if device.endswith("p"):
        device = device[:-1]
    return device


def _partition_path(device: str, part: int) -> str:
    """Return the path for ``part`` on ``device`` (handles mmc/nvme suffixes)."""

    suffix = f"p{part}" if device and device[-1].isdigit() else str(part)
    return f"{device}{suffix}"


def list_devices() -> List[Dict[str, str]] | Dict[str, str]:
    """Return removable, non-root block devices."""

    try:
        root = subprocess.check_output("findmnt -no SOURCE /", shell=True, text=True).strip()
    except subprocess.CalledProcessError as exc:
        return {"error": exc.output.strip() if exc.output else str(exc)}

    rootdisk = _root_disk(root)
    rc, out = _sh("lsblk -J -o NAME,SIZE,TYPE,MOUNTPOINT,RM,ROTA,MODEL,TRAN")
    if rc:
        return {"error": out.strip()}

    info = json.loads(out)
    devices: List[Dict[str, str]] = []

    def walk(node: Dict[str, str]) -> None:
        name = "/dev/" + node["name"]
        if node.get("type") == "disk":
            if name.startswith(rootdisk):
import shlex
import subprocess
from pathlib import Path
from typing import Iterable, Optional

__all__ = ["list_devices", "flash"]

_IMAGE_PATH = Path("/tmp/blackroad.img.xz")
_MOUNT_POINT = Path("/mnt")


def _sh(cmd: str) -> tuple[int, str]:
    """Execute *cmd* returning ``(returncode, stdout)``.

    The command is executed using ``shell=False`` with ``shlex.split`` to
    avoid surprises with shell interpretation.  Stderr is redirected to
    stdout so callers receive a combined stream.
    """

    try:
        out = subprocess.check_output(
            shlex.split(cmd), text=True, stderr=subprocess.STDOUT
        )
        return 0, out
    except subprocess.CalledProcessError as exc:  # pragma: no cover - depends on system
        return exc.returncode, exc.output


def _root_disk() -> Optional[str]:
    """Return the absolute path of the block device that backs ``/``.

    On typical installations ``findmnt -no SOURCE /`` returns a partition
    such as ``/dev/sda1`` or ``/dev/mmcblk0p2``.  We resolve that to the
    parent disk so we can exclude it from flashing targets.
    """

    try:
        root = subprocess.check_output(
            ["findmnt", "-no", "SOURCE", "/"], text=True
        ).strip()
    except subprocess.CalledProcessError:  # pragma: no cover - depends on system
        return None

    if not root:
        return None

    rc, parent = _sh(f"lsblk -no pkname {shlex.quote(root)}")
    if rc == 0 and parent.strip():
        return f"/dev/{parent.strip()}"

    # Fallback: trim trailing digits (partitions) and optional 'p'
    disk = root.rstrip("0123456789")
    if disk.endswith("p"):
        disk = disk[:-1]
    return disk or root


def _normalise_device(device: str) -> str:
    """Return ``device`` with symlinks resolved and without surrounding whitespace."""

    resolved = os.path.realpath(device.strip())
    return resolved


def _is_system_disk(device: str, rootdisk: Optional[str]) -> bool:
    if not rootdisk:
        return False
    dev = _normalise_device(device)
    rd = _normalise_device(rootdisk)
    return dev == rd or dev.startswith(f"{rd}")


def list_devices() -> list[dict[str, object]] | dict[str, str]:
    """Return metadata for removable, non-root block devices.

    The structure mirrors the ``lsblk`` JSON schema so the dashboard can
    display size/model/transport details.  On error a dict with an
    ``"error"`` key is returned.
    """

    rootdisk = _root_disk()
    rc, out = _sh("lsblk -J -o NAME,SIZE,TYPE,MOUNTPOINT,RM,ROTA,MODEL,TRAN")
    if rc != 0:
        return {"error": out.strip() or "lsblk failed"}

    try:
        info = json.loads(out)
    except json.JSONDecodeError as exc:  # pragma: no cover - depends on system
        return {"error": f"Failed to parse lsblk output: {exc}"}

    devices: list[dict[str, object]] = []

    def walk(node: dict[str, object]) -> None:
        name = f"/dev/{node['name']}"
        if node.get("type") == "disk":
            if _is_system_disk(name, rootdisk):
                return
            devices.append(
                {
                    "device": name,
                    "size": node.get("size", ""),
                    "model": node.get("model", ""),
                    "rm": node.get("rm", 0),
                    "tran": node.get("tran", ""),
                }
            )
        for child in (node.get("children") or []):
        for child in node.get("children") or []:
            walk(child)

    for node in info.get("blockdevices", []) or []:
        walk(node)

    return devices


def flash(image_url: str, device: str, safe_hdmi: bool = True, enable_ssh: bool = True) -> Generator[str, None, None]:
    """Stream progress while flashing *image_url* to *device*."""

    try:
        root = subprocess.check_output("findmnt -no SOURCE /", shell=True, text=True).strip()
    except subprocess.CalledProcessError as exc:
        yield f"ERROR: unable to determine root disk: {exc.output.strip() if exc.output else exc}"
        return

    rootdisk = _root_disk(root)
    if device.startswith(rootdisk):
        yield "ERROR: Refusing to flash the system disk."
        return

    download_cmd = f"curl -L {shlex.quote(image_url)} -o {shlex.quote(TMP_IMAGE_PATH)}"
    write_cmd = (
        f"xzcat {shlex.quote(TMP_IMAGE_PATH)} | "
        f"sudo dd of={shlex.quote(device)} bs=8M status=progress conv=fsync"
    )

    try:
        proc = subprocess.Popen(  # noqa: S603  # shell needed for pipeline streaming
            f"{download_cmd} && {write_cmd}",
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
        )
    except OSError as exc:  # pragma: no cover - system-specific failure
        yield f"ERROR: failed to start writer: {exc}"
        return

    try:
        if proc.stdout is not None:
            for line in proc.stdout:
                yield line.rstrip("\n")
        proc.wait()

        if proc.returncode != 0:
            yield f"ERROR: writer exited {proc.returncode}"
            return

        for cmd in ("sync", f"sudo partprobe {shlex.quote(device)}"):
            rc, out = _sh(cmd)
            if rc:
                yield f"ERROR: command failed ({cmd}): {out.strip()}"
                return

        bootpart = _partition_path(device, 1)
        try:
            subprocess.run(["sudo", "mount", bootpart, "/mnt"], check=True)
        except subprocess.CalledProcessError as exc:
            yield f"ERROR: failed to mount {bootpart}: {exc}"
            return

        try:
            with open("/mnt/config.txt", "a", encoding="utf-8") as cfg:
                cfg.write("\nusb_max_current_enable=1\n")
                if safe_hdmi:
                    cfg.write("hdmi_safe=1\nhdmi_force_hotplug=1\n")
            if enable_ssh:
                open("/mnt/ssh", "w", encoding="utf-8").close()
        except OSError as exc:
            yield f"ERROR: failed to update boot partition: {exc}"
        finally:
            subprocess.run(["sudo", "umount", "/mnt"], check=False)

        yield "[BLACKROAD_FLASH_DONE]"
    finally:
        try:
            if os.path.exists(TMP_IMAGE_PATH):
                os.remove(TMP_IMAGE_PATH)
        except OSError:
            pass
def _partition_name(device: str, index: int = 1) -> str:
    """Return the partition path for ``device`` (handles ``sdX`` vs ``nvme``/``mmc``)."""

    suffix = f"p{index}" if device[-1].isdigit() else f"{index}"
    return f"{device}{suffix}"


def _cleanup_image() -> None:
    try:
        _IMAGE_PATH.unlink()
    except FileNotFoundError:
        pass


def _write_file(path: Path, contents: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("a", encoding="utf-8") as handle:
        handle.write(contents)


def flash(
    image_url: str,
    device: str,
    *,
    safe_hdmi: bool = True,
    enable_ssh: bool = True,
) -> Iterable[str]:
    """Flash ``image_url`` to ``device`` yielding progress messages.

    This generator streams human-readable status strings suitable for
    forwarding over a WebSocket.  The calling code is expected to handle
    cancellation by simply stopping iteration.
    """

    if not image_url:
        yield "ERROR: image_url is required"
        return

    if not device.startswith("/dev/"):
        yield "ERROR: device path must start with /dev/"
        return

    rootdisk = _root_disk()
    if _is_system_disk(device, rootdisk):
        yield "ERROR: Refusing to flash the system disk."
        return

    if not Path(device).exists():
        yield f"ERROR: Device {device} not found"
        return

    _cleanup_image()
    download_cmd = f"curl -L {shlex.quote(image_url)} -o {_IMAGE_PATH}"
    yield f"Downloading image from {image_url}"
    rc, out = _sh(download_cmd)
    if rc != 0:
        _cleanup_image()
        yield f"ERROR: download failed ({rc})\n{out.strip()}"
        return

    write_cmd = (
        f"xzcat {_IMAGE_PATH} | sudo dd of={shlex.quote(device)} bs=8M "
        "status=progress conv=fsync"
    )
    yield "Writing image to device"
    proc = subprocess.Popen(  # noqa: S603 - command constructed above
        write_cmd,
        shell=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        bufsize=1,
    )

    try:
        assert proc.stdout is not None  # for type checkers
        for line in proc.stdout:
            yield line.rstrip("\n")
    finally:
        proc.wait()

    if proc.returncode != 0:
        _cleanup_image()
        yield f"ERROR: writer exited {proc.returncode}"
        return

    yield "Syncing data"
    subprocess.run(["sync"], check=False)
    subprocess.run(["sudo", "partprobe", device], check=False)

    boot_part = _partition_name(device, 1)
    mount_args = ["sudo", "mount", boot_part, str(_MOUNT_POINT)]
    yield f"Mounting boot partition {boot_part}"
    try:
        subprocess.run(
            mount_args,
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except subprocess.CalledProcessError as exc:
        _cleanup_image()
        stderr = exc.stderr.decode().strip() if exc.stderr else str(exc)
        yield f"ERROR: Failed to mount {boot_part}: {stderr}"
        return

    try:
        config_path = _MOUNT_POINT / "config.txt"
        if config_path.exists():
            additions = ["", "usb_max_current_enable=1"]
            if safe_hdmi:
                additions.append("hdmi_safe=1")
                additions.append("hdmi_force_hotplug=1")
            _write_file(config_path, "\n".join(additions) + "\n")
        else:
            yield "WARNING: config.txt not found; skipping HDMI tweaks"

        if enable_ssh:
            ssh_flag = _MOUNT_POINT / "ssh"
            ssh_flag.touch(exist_ok=True)
    finally:
        subprocess.run(["sudo", "umount", str(_MOUNT_POINT)], check=False)
        _cleanup_image()

    yield "[BLACKROAD_FLASH_DONE]"
"""Placeholder helpers for firmware/OS flashing routines."""
from __future__ import annotations

from typing import Any, Dict, Optional

from agent import jobs


def probe(host: Optional[str] = None, user: Optional[str] = None) -> Dict[str, Any]:
    """Check if the remote target is reachable."""
    try:
        result = jobs.run_remote("uname -a", host=host, user=user)
        ok = result.returncode == 0
        return {"ok": ok, "output": result.stdout.strip() if ok else result.stderr.strip()}
    except Exception as exc:  # pragma: no cover - defensive
        return {"ok": False, "error": str(exc)}


def reboot(host: Optional[str] = None, user: Optional[str] = None) -> Dict[str, Any]:
    """Request a remote reboot. Users must ensure they have sudo rights."""
    try:
        result = jobs.run_remote("sudo reboot", host=host, user=user)
        return {"ok": result.returncode == 0}
    except Exception as exc:  # pragma: no cover - defensive
        return {"ok": False, "error": str(exc)}


__all__ = ["probe", "reboot"]
