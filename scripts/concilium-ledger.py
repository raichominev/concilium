#!/usr/bin/env python3
"""Record a ratified concilium review as one row of a project's LEDGER.tsv.

    python concilium-ledger.py parse <review-output>
    python concilium-ledger.py append <LEDGER.tsv> <review-output> --final "[V-probe]"
        --claim "<the claim that was reviewed>" [--parent ID] [--commit REF]
        [--detail DOC] [--gate "<expected result, written before the review>"] [--dry-run]

The ledger is the project-starter-kit format: ten columns, or eleven with `gate`.
The row takes the PHASE-LOG date and reviewer, the reviewer's proposed tag and the
tag that YOU assign after checking the probe (`--final`). The proposal alone is
never recorded. `[C]` is refused: an unverified review measured nothing.

A final `[X]` with `--parent` becomes a `retraction` of that row; every other
final tag becomes a `measurement`. The row is appended; the bytes before it are
not touched. Run the kit's `ledger_check.py validate` afterwards.

parse exits 1 when the output has no usable VERDICT-PROPOSAL and PHASE-LOG
blocks, or when they still hold the contract's template text. It never guesses.

Python 3, no dependencies.
"""

import argparse
import csv
import re
import sys
from collections import Counter

BLOCKS = ("PROBE", "ALT", "CAVEAT", "VERDICT-PROPOSAL", "PHASE-LOG")
HEADER_RE = re.compile(r"^[\s#*>-]*(" + "|".join(BLOCKS) + r")\**\s*:\**\s*(.*)$")
TAG_RE = re.compile(r"\[(V-[a-z]+|C|X)\]")
BASE_HEADER = ["date", "id", "parent_id", "kind", "change", "result",
               "verdict", "evidence", "commit", "detail"]
GATE_HEADER = BASE_HEADER + ["gate"]


def last_blocks(lines):
    """Map block name -> text of its LAST occurrence (up to the first blank line)."""
    found = {}
    current = None
    for line in lines:
        m = HEADER_RE.match(line)
        if m:
            current = m.group(1)
            found[current] = [m.group(2).strip()] if m.group(2).strip() else []
            continue
        if current is None:
            continue
        if line.startswith(">>") or (not line.strip() and found[current]):
            current = None
            continue
        if line.strip():
            found[current].append(line.strip())
    return {k: " ".join(v) for k, v in found.items() if v}


def parse(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        blocks = last_blocks(f.read().splitlines())
    verdict = blocks.get("VERDICT-PROPOSAL")
    log = blocks.get("PHASE-LOG")
    if not verdict or not log:
        raise ValueError("no VERDICT-PROPOSAL or PHASE-LOG block")
    tags = set(TAG_RE.findall(verdict))
    if len(tags) != 1:
        raise ValueError(f"VERDICT-PROPOSAL holds {len(tags)} distinct tags, expected 1")
    model = re.search(r"reviewer\(([^)<>]+)\)", log)
    date = re.search(r"\b(\d{4}-\d{2}-\d{2})\b", log)
    if not model or not date:
        raise ValueError("PHASE-LOG has no reviewer(<model>) or no date")
    return {
        "proposed": "[" + tags.pop() + "]",
        "verdict": verdict,
        "model": model.group(1).strip(),
        "date": date.group(1),
        "phase_log": log,
    }


def clean(text):
    return re.sub(r"\s+", " ", text or "").strip()


def next_id(ids):
    numbered = [re.fullmatch(r"(.*?)(\d+)", i) for i in ids]
    numbered = [m for m in numbered if m]
    if not numbered:
        return "L-1"
    prefix = Counter(m.group(1) for m in numbered).most_common(1)[0][0]
    top = max(int(m.group(2)) for m in numbered if m.group(1) == prefix)
    return f"{prefix}{top + 1}"


def build_row(header, ids, review, args):
    final = args.final.strip()
    if not TAG_RE.fullmatch(final):
        raise ValueError(f"--final {final!r} is not a tag like [V-probe], [X]")
    if final == "[C]":
        raise ValueError("final tag [C] is unverified; nothing to record")
    if args.parent and args.parent not in ids:
        raise ValueError(f"--parent {args.parent} is not in the ledger")
    retraction = final == "[X]" and args.parent
    change = f"Concilium review by {review['model']} of: {args.claim}"
    if retraction:
        change = f"Retracts {args.parent}. {change}"
    rec = {
        "date": review["date"],
        "id": next_id(ids),
        "parent_id": args.parent or "",
        "kind": "retraction" if retraction else "measurement",
        "change": change,
        "result": f"{final} ratified (reviewer proposed {review['verdict']}) PHASE-LOG: {review['phase_log']}",
        "verdict": "KEPT",
        "evidence": args.review,
        "commit": args.commit or "",
        "detail": args.detail or args.review,
        "gate": args.gate or "",
    }
    return [clean(rec[col]) for col in header]


def append(args):
    with open(args.ledger, encoding="utf-8-sig", newline="") as f:
        raw = f.read()
    rows = list(csv.reader(raw.splitlines(), delimiter="\t", quoting=csv.QUOTE_NONE))
    if not rows or rows[0] not in (BASE_HEADER, GATE_HEADER):
        raise ValueError(f"{args.ledger} is not a project-starter-kit ledger")
    ids = [r[1] for r in rows[1:] if len(r) > 1 and r[1]]
    row = build_row(rows[0], ids, parse(args.review), args)
    newline = "\r\n" if "\r\n" in raw else "\n"
    text = ("" if raw.endswith(("\n", "\r")) else newline) + "\t".join(row) + newline
    if not args.dry_run:
        with open(args.ledger, "a", encoding="utf-8", newline="") as f:
            f.write(text)
    print("\t".join(row))


def main():
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    sub = parser.add_subparsers(dest="cmd", required=True)
    p = sub.add_parser("parse")
    p.add_argument("review")
    a = sub.add_parser("append")
    a.add_argument("ledger")
    a.add_argument("review")
    a.add_argument("--final", required=True)
    a.add_argument("--claim", required=True)
    a.add_argument("--parent")
    a.add_argument("--commit")
    a.add_argument("--detail")
    a.add_argument("--gate")
    a.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    try:
        if args.cmd == "parse":
            for key, value in parse(args.review).items():
                print(f"{key}: {value}")
        else:
            append(args)
    except (ValueError, OSError) as e:
        print(f"concilium-ledger: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
