#!/usr/bin/env python3
"""Static, non-executing analysis for the L4D2 Reborn Trainer sample."""

from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
import struct
import zipfile
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable


FEATURE_KEYWORDS: dict[str, list[bytes]] = {
    "aim": [b"aim", b"silent", b"perfect", b"human", b"smooth", b"bone", b"hitbox", b"trigger"],
    "visual": [b"esp", b"glow", b"chams", b"wall", b"outline", b"EntityGlowEffects", b"RenderGlowModels"],
    "weapon": [b"nospread", b"norecoil", b"rapidfire", b"weapon_", b"spread", b"recoil"],
    "movement": [b"bhop", b"bunny", b"strafe", b"fakelag", b"speed", b"teleport"],
    "injection": [b"inject", b"LoadLibrary", b"CreateRemoteThread", b"WriteProcessMemory", b"IsDebuggerPresent"],
    "overlay": [b"Direct3D", b"EndScene", b"Present", b"obs", b"discord", b"anti obs"],
    "game_state": [b"entity", b"survivor", b"infected", b"client.dll", b"m_hActiveWeapon", b"m_hMyWeapons"],
}


@dataclass(frozen=True)
class PeSection:
    name: str
    virtual_size: int
    raw_size: int
    entropy: float
    characteristics: str


@dataclass(frozen=True)
class TrainerFileReport:
    name: str
    size_bytes: int
    sha256: str
    kind: str
    pe_machine: str | None
    pe_timestamp: int | None
    pe_sections: list[PeSection]
    zip_entries: list[dict[str, int | str]]
    feature_hits: dict[str, list[str]]


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as file_handle:
        for chunk in iter(lambda: file_handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest().upper()


def shannon_entropy(data: bytes) -> float:
    if not data:
        return 0.0
    counts = [0] * 256
    for value in data:
        counts[value] += 1
    length = len(data)
    return -sum((count / length) * math.log2(count / length) for count in counts if count)


def ascii_strings(data: bytes, minimum_length: int = 5) -> list[bytes]:
    return re.findall(rb"[\x20-\x7e]{" + str(minimum_length).encode() + rb",}", data)


def parse_pe_sections(data: bytes) -> tuple[str | None, int | None, list[PeSection]]:
    if data[:2] != b"MZ" or len(data) < 0x40:
        return None, None, []

    pe_offset = struct.unpack_from("<I", data, 0x3C)[0]
    if pe_offset + 24 > len(data) or data[pe_offset : pe_offset + 4] != b"PE\0\0":
        return None, None, []

    machine, section_count, timestamp, _, _, optional_header_size, _ = struct.unpack_from("<HHIIIHH", data, pe_offset + 4)
    section_table_offset = pe_offset + 24 + optional_header_size
    sections: list[PeSection] = []

    for index in range(section_count):
        section_offset = section_table_offset + (index * 40)
        if section_offset + 40 > len(data):
            break

        name = data[section_offset : section_offset + 8].split(b"\0")[0].decode("latin1", "replace")
        virtual_size, _, raw_size, raw_pointer = struct.unpack_from("<IIII", data, section_offset + 8)
        characteristics = struct.unpack_from("<I", data, section_offset + 36)[0]
        section_data = data[raw_pointer : raw_pointer + raw_size] if raw_pointer + raw_size <= len(data) else b""
        sections.append(
            PeSection(
                name=name,
                virtual_size=virtual_size,
                raw_size=raw_size,
                entropy=round(shannon_entropy(section_data), 3),
                characteristics=hex(characteristics),
            )
        )

    return hex(machine), timestamp, sections


def classify_strings(strings: Iterable[bytes]) -> dict[str, list[str]]:
    feature_hits: dict[str, list[str]] = {feature: [] for feature in FEATURE_KEYWORDS}
    seen: set[tuple[str, str]] = set()

    for raw_string in strings:
        lowered = raw_string.lower()
        decoded = raw_string.decode("latin1", "replace")[:220]
        for feature, keywords in FEATURE_KEYWORDS.items():
            if any(keyword.lower() in lowered for keyword in keywords):
                key = (feature, decoded)
                if key not in seen:
                    seen.add(key)
                    feature_hits[feature].append(decoded)

    return {feature: hits for feature, hits in feature_hits.items() if hits}


def analyze_file(path: Path) -> TrainerFileReport:
    data = path.read_bytes()
    pe_machine, pe_timestamp, pe_sections = parse_pe_sections(data)
    zip_entries: list[dict[str, int | str]] = []
    file_kind = "pe" if pe_machine else "file"

    if zipfile.is_zipfile(path):
        file_kind = "zip"
        with zipfile.ZipFile(path) as archive:
            for entry in archive.infolist():
                zip_entries.append({"name": entry.filename, "size": entry.file_size, "crc32": hex(entry.CRC)})

    return TrainerFileReport(
        name=path.name,
        size_bytes=path.stat().st_size,
        sha256=sha256_file(path),
        kind=file_kind,
        pe_machine=pe_machine,
        pe_timestamp=pe_timestamp,
        pe_sections=pe_sections,
        zip_entries=zip_entries,
        feature_hits=classify_strings(ascii_strings(data)),
    )


def analyze_trainer(trainer_root: Path) -> list[TrainerFileReport]:
    if not trainer_root.exists() or not trainer_root.is_dir():
        raise FileNotFoundError(f"trainer root not found: {trainer_root}")
    return [analyze_file(path) for path in sorted(trainer_root.iterdir()) if path.is_file()]


def render_markdown(reports: list[TrainerFileReport], trainer_root: Path) -> str:
    lines = [
        "# Reborn Trainer Static Analysis",
        "",
        f"Trainer root: `{trainer_root}`",
        "",
        "This report is produced by static analysis only. The binaries are not executed.",
        "",
        "## File inventory",
        "",
        "| File | Kind | Size | SHA-256 |",
        "|---|---:|---:|---|",
    ]

    for report in reports:
        lines.append(f"| `{report.name}` | {report.kind} | {report.size_bytes} | `{report.sha256}` |")

    lines.extend(["", "## PE and archive structure", ""])
    for report in reports:
        lines.append(f"### {report.name}")
        if report.pe_machine:
            lines.append(f"- PE machine: `{report.pe_machine}`")
            lines.append(f"- PE timestamp: `{report.pe_timestamp}`")
            for section in report.pe_sections:
                lines.append(
                    f"- Section `{section.name}`: virtual={section.virtual_size}, raw={section.raw_size}, "
                    f"entropy={section.entropy}, characteristics={section.characteristics}"
                )
        if report.zip_entries:
            for entry in report.zip_entries:
                lines.append(f"- Zip entry `{entry['name']}`: size={entry['size']}, crc32={entry['crc32']}")
        if not report.pe_machine and not report.zip_entries:
            lines.append("- No PE or archive structure detected.")
        lines.append("")

    lines.extend(["## Feature string clusters", ""])
    for report in reports:
        lines.append(f"### {report.name}")
        if not report.feature_hits:
            lines.append("- No feature strings matched Orion clusters.")
        for feature, hits in report.feature_hits.items():
            lines.append(f"- **{feature}** ({len(hits)} hits)")
            for hit in hits[:25]:
                safe_hit = hit.replace("|", "\\|")
                lines.append(f"  - `{safe_hit}`")
            if len(hits) > 25:
                lines.append(f"  - ... {len(hits) - 25} additional hits omitted from markdown")
        lines.append("")

    lines.extend(
        [
            "## Orion defensive mapping",
            "",
            "| Cheat capability | Observed local evidence | Server observable | Orion control |",
            "|---|---|---|---|",
            "| DLL injection | `LoadLibraryA`, `WriteProcessMemory`, `CreateRemoteThread` | none directly server-side | do not rely on signatures; detect behavior and reduce transmitted state |",
            "| ESP / glow / chams | `EntityGlowEffects`, `RenderGlowModels`, chams/glow strings | suspicious awareness, ghost/inactive entity access | visibility guard + reaction evidence |",
            "| Silent / perfect aim | `Silent`, `Perfect Silent`, aim bone/hitbox strings | attack windows, angle deltas, target switches, hit/death correlation | aim analyzer |",
            "| Humanized aim | `Human`, `smooth`, aim mode strings | long-window statistical consistency beyond human variance | rolling score with decay |",
            "| Nospread / norecoil | nospread/no recoil guidance strings | improbable hits by weapon/range/movement | shot probability scoring |",
            "| Bhop / movement automation | strafe/fakelag/movement strings | jump timing, velocity gain, tick anomalies | movement analyzer |",
            "| Anti-OBS / Discord | anti-observation strings | none server-side | server evidence, not screenshots |",
        ]
    )
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--trainer-root", required=True, type=Path)
    parser.add_argument("--json", action="store_true", help="emit JSON instead of markdown")
    args = parser.parse_args()

    reports = analyze_trainer(args.trainer_root)
    if args.json:
        print(json.dumps([asdict(report) for report in reports], indent=2))
    else:
        print(render_markdown(reports, args.trainer_root))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
