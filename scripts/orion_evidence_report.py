#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import json
import re
import shlex
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from typing import Iterable, TextIO


ORION_RECORD_START = "seq="
STEAM_ID_PATTERN = re.compile(r"^STEAM_[0-5]:[0-1]:\d+$")
SOURCE_LOG_PREFIX_PATTERN = re.compile(r'^L \d{2}/\d{2}/\d{4} - \d{2}:\d{2}:\d{2}: "?')


@dataclass(frozen=True)
class OrionEvidenceRecord:
    sequence: int | None
    session: str
    evidence_type: str
    score: float
    action: str
    client: str
    steamid: str
    player_name: str
    map_name: str
    mode: str
    source_line: int
    server: str
    details: dict[str, str] = field(default_factory=dict)


@dataclass
class OrionEvidenceGroup:
    session: str
    evidence_type: str
    steamid: str
    player_name: str
    action: str
    count: int = 0
    max_score: float = 0.0
    last_map_name: str = ""
    last_details: dict[str, str] = field(default_factory=dict)


def strip_source_log_prefix(line: str) -> str:
    stripped = line.strip()
    prefix_match = SOURCE_LOG_PREFIX_PATTERN.match(stripped)
    if prefix_match is None:
        return stripped.replace('\\"', '"')

    without_prefix = stripped[prefix_match.end() :]
    if prefix_match.group(0).endswith('"') and without_prefix.endswith('"'):
        without_prefix = without_prefix[:-1]
    return without_prefix.replace('\\"', '"')


def split_key_value_tokens(record_text: str) -> dict[str, str]:
    lexer = shlex.shlex(record_text, posix=True)
    lexer.whitespace_split = True
    lexer.commenters = ""

    fields: dict[str, str] = {}
    try:
        for token in lexer:
            if "=" not in token:
                continue
            key, value = token.split("=", 1)
            if key:
                fields[key] = value
    except ValueError:
        for key, value in re.findall(r'(\w+)=("[^"]*"|\S+)', record_text):
            fields[key] = value[1:-1] if value.startswith('"') and value.endswith('"') else value

    return fields


def parse_optional_int(value: str | None) -> int | None:
    if value is None:
        return None
    try:
        return int(value)
    except ValueError:
        return None


def parse_optional_float(value: str | None) -> float:
    if value is None:
        return 0.0
    try:
        return float(value)
    except ValueError:
        return 0.0


def parse_details(details_text: str) -> dict[str, str]:
    if not details_text:
        return {}
    return split_key_value_tokens(details_text)


def parse_orion_evidence_line(
    line: str,
    *,
    source_line: int = 1,
    session_label: str = "default",
    server_label: str = "BLACKWATCH",
) -> OrionEvidenceRecord | None:
    record_start = line.find(ORION_RECORD_START)
    if record_start < 0:
        return None

    record_text = strip_source_log_prefix(line)
    record_start = record_text.find(ORION_RECORD_START)
    if record_start > 0:
        record_text = record_text[record_start:]

    fields = split_key_value_tokens(record_text)
    if not fields:
        return None

    return OrionEvidenceRecord(
        sequence=parse_optional_int(fields.get("seq")),
        session=fields.get("session", session_label),
        evidence_type=fields.get("type", "unknown"),
        score=parse_optional_float(fields.get("score")),
        action=fields.get("action", "observe"),
        client=fields.get("client", "unknown"),
        steamid=fields.get("steamid", "unknown"),
        player_name=fields.get("name", ""),
        map_name=fields.get("map", "unknown"),
        mode=fields.get("mode", "unknown"),
        source_line=source_line,
        server=server_label,
        details=parse_details(fields.get("details", "")),
    )


def parse_orion_evidence_lines(
    lines: Iterable[str],
    *,
    session_label: str = "default",
    server_label: str = "BLACKWATCH",
) -> list[OrionEvidenceRecord]:
    records: list[OrionEvidenceRecord] = []
    for source_line, line in enumerate(lines, start=1):
        record = parse_orion_evidence_line(
            line,
            source_line=source_line,
            session_label=session_label,
            server_label=server_label,
        )
        if record is not None:
            records.append(record)
    return records


def pseudonymize_steamid(steamid: str, salt: str) -> str:
    if not steamid or steamid == "unknown":
        return "unknown"
    digest = hashlib.sha256(f"{salt}:{steamid}".encode("utf-8")).hexdigest()
    return f"steamid_sha256:{digest[:16]}"


def display_steamid(steamid: str, *, redact_steamids: bool, redaction_salt: str) -> str:
    if redact_steamids and STEAM_ID_PATTERN.match(steamid):
        return pseudonymize_steamid(steamid, redaction_salt)
    return steamid


def group_orion_evidence(
    records: Iterable[OrionEvidenceRecord],
    *,
    redact_steamids: bool = False,
    redaction_salt: str = "project-orion",
) -> list[OrionEvidenceGroup]:
    groups: dict[tuple[str, str, str, str], OrionEvidenceGroup] = {}

    for record in records:
        steamid = display_steamid(record.steamid, redact_steamids=redact_steamids, redaction_salt=redaction_salt)
        group_key = (record.session, record.evidence_type, steamid, record.action)
        if group_key not in groups:
            groups[group_key] = OrionEvidenceGroup(
                session=record.session,
                evidence_type=record.evidence_type,
                steamid=steamid,
                player_name=record.player_name,
                action=record.action,
            )

        group = groups[group_key]
        group.count += 1
        group.max_score = max(group.max_score, record.score)
        group.last_map_name = record.map_name
        group.last_details = record.details

    return sorted(groups.values(), key=lambda group: (-group.max_score, -group.count, group.session, group.evidence_type))


def evidence_record_to_dict(
    record: OrionEvidenceRecord,
    *,
    redact_steamids: bool,
    redaction_salt: str,
) -> dict[str, object]:
    return {
        "session": record.session,
        "server": record.server,
        "source_line": record.source_line,
        "seq": record.sequence,
        "type": record.evidence_type,
        "score": record.score,
        "action": record.action,
        "client": record.client,
        "steamid": display_steamid(record.steamid, redact_steamids=redact_steamids, redaction_salt=redaction_salt),
        "name": record.player_name,
        "map": record.map_name,
        "mode": record.mode,
        "details": record.details,
    }


def build_corpus_summary(
    records: list[OrionEvidenceRecord],
    *,
    session_label: str,
    server_label: str,
    min_score: float,
    redact_steamids: bool,
    redaction_salt: str,
) -> dict[str, object]:
    filtered_records = [record for record in records if record.score >= min_score]
    events = [
        evidence_record_to_dict(record, redact_steamids=redact_steamids, redaction_salt=redaction_salt)
        for record in filtered_records
    ]

    type_counts = Counter(record.evidence_type for record in filtered_records)
    action_counts = Counter(record.action for record in filtered_records)
    mode_counts = Counter(record.mode for record in filtered_records)
    map_counts = Counter(record.map_name for record in filtered_records)

    score_by_type: dict[str, list[float]] = defaultdict(list)
    player_event_counts: Counter[str] = Counter()
    player_max_scores: dict[str, float] = defaultdict(float)

    for record in filtered_records:
        score_by_type[record.evidence_type].append(record.score)
        steamid = display_steamid(record.steamid, redact_steamids=redact_steamids, redaction_salt=redaction_salt)
        player_event_counts[steamid] += 1
        player_max_scores[steamid] = max(player_max_scores[steamid], record.score)

    return {
        "schema_version": "orion-corpus-v1",
        "session": {
            "label": session_label,
            "server": server_label,
            "record_count": len(filtered_records),
            "min_score": min_score,
            "redacted_steamids": redact_steamids,
        },
        "counts": {
            "by_type": dict(sorted(type_counts.items())),
            "by_action": dict(sorted(action_counts.items())),
            "by_mode": dict(sorted(mode_counts.items())),
            "by_map": dict(sorted(map_counts.items())),
        },
        "score_summary_by_type": {
            evidence_type: {
                "count": len(scores),
                "max_score": max(scores),
                "average_score": round(sum(scores) / len(scores), 3),
            }
            for evidence_type, scores in sorted(score_by_type.items())
        },
        "players": [
            {
                "steamid": steamid,
                "event_count": count,
                "max_score": player_max_scores[steamid],
            }
            for steamid, count in sorted(player_event_counts.items(), key=lambda item: (-item[1], item[0]))
        ],
        "events": events,
    }


def write_csv_report(groups: Iterable[OrionEvidenceGroup], output: TextIO) -> None:
    writer = csv.writer(output)
    writer.writerow(["session", "type", "steamid", "name", "action", "count", "max_score", "last_map", "last_details"])
    for group in groups:
        writer.writerow(
            [
                group.session,
                group.evidence_type,
                group.steamid,
                group.player_name,
                group.action,
                group.count,
                f"{group.max_score:.1f}",
                group.last_map_name,
                json.dumps(group.last_details, sort_keys=True),
            ]
        )


def write_markdown_report(groups: Iterable[OrionEvidenceGroup], output: TextIO) -> None:
    output.write("| Session | Type | SteamID | Name | Action | Count | Max score | Last map | Last details |\n")
    output.write("|---|---|---|---|---|---:|---:|---|---|\n")
    for group in groups:
        output.write(
            f"| {group.session} | {group.evidence_type} | {group.steamid} | {group.player_name} | "
            f"{group.action} | {group.count} | {group.max_score:.1f} | {group.last_map_name} | "
            f"{json.dumps(group.last_details, sort_keys=True)} |\n"
        )


def write_event_csv(events: Iterable[dict[str, object]], output_path: Path) -> None:
    fieldnames = [
        "session",
        "server",
        "source_line",
        "seq",
        "type",
        "score",
        "action",
        "client",
        "steamid",
        "name",
        "map",
        "mode",
        "details",
    ]
    with output_path.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=fieldnames)
        writer.writeheader()
        for event in events:
            row = dict(event)
            row["details"] = json.dumps(row["details"], sort_keys=True)
            writer.writerow(row)


def parse_arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Summarize Project Orion evidence logs into calibration corpus output.")
    parser.add_argument("log_path", type=Path, help="Path to addons/sourcemod/logs/orion.log")
    parser.add_argument("--session-label", default="default", help="Fallback session label when a log line has no session field")
    parser.add_argument("--server-label", default="BLACKWATCH", help="Server label stored in JSON/CSV output")
    parser.add_argument("--min-score", type=float, default=0.0, help="Drop records below this score from JSON/CSV corpus output")
    parser.add_argument("--format", choices=("markdown", "csv", "json"), default="markdown", help="Report format written to stdout")
    parser.add_argument("--json-out", type=Path, help="Write full corpus JSON to this path")
    parser.add_argument("--csv-out", type=Path, help="Write flat event-ledger CSV to this path")
    parser.add_argument("--redact-steamids", action="store_true", help="Pseudonymize SteamIDs in report output")
    parser.add_argument("--redaction-salt", default="project-orion", help="Salt used for deterministic SteamID pseudonyms")
    return parser.parse_args()


def main() -> int:
    args = parse_arguments()
    records = parse_orion_evidence_lines(
        args.log_path.read_text(encoding="utf-8", errors="replace").splitlines(),
        session_label=args.session_label,
        server_label=args.server_label,
    )
    summary = build_corpus_summary(
        records,
        session_label=args.session_label,
        server_label=args.server_label,
        min_score=args.min_score,
        redact_steamids=args.redact_steamids,
        redaction_salt=args.redaction_salt,
    )

    if args.json_out is not None:
        args.json_out.parent.mkdir(parents=True, exist_ok=True)
        args.json_out.write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

    if args.csv_out is not None:
        args.csv_out.parent.mkdir(parents=True, exist_ok=True)
        write_event_csv(summary["events"], args.csv_out)

    if args.format == "json":
        print(json.dumps(summary, indent=2, sort_keys=True))
        return 0

    groups = group_orion_evidence(records, redact_steamids=args.redact_steamids, redaction_salt=args.redaction_salt)
    if args.format == "csv":
        write_csv_report(groups, sys.stdout)
    else:
        write_markdown_report(groups, sys.stdout)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
