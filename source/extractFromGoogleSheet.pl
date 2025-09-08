#!/usr/bin/env python3
"""
Extract specified Google Sheets tabs into Markdown files.

Usage examples:
  ./source/extractFromGoogleSheet.pl \
    --sheet-url "https://docs.google.com/spreadsheets/d/1Hx0HNsCKG1aR8htJTIpYsOcLiOSVUyo_n85mV6d_TSU/edit?usp=sharing" \
    --tabs "Targeted Sequencing" "Chromatin-Related"

Assumptions:
- The Google Sheet is publicly readable (no auth). We use the CSV export endpoint.
- Output Markdown files are created at the repository root, kebab-cased from tab names.

"""

import argparse
import csv
import io
import logging
import os
import re
import sys
import urllib.parse
import urllib.request

logger = logging.getLogger(__name__)


def parse_args(argv=None):
    p = argparse.ArgumentParser(description="Extract Google Sheets tabs to Markdown tables")
    p.add_argument("--sheet-url", required=False, help="Google Sheet URL (view link)")
    p.add_argument("--tabs", nargs="+", required=False, help="Tab (sheet) names to export")
    p.add_argument("--outdir", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))), help="Output directory (default: repo root)")
    return p.parse_args(argv)


def kebab_case(name: str) -> str:
    s = name.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return s or "sheet"


def sheet_id_from_url(url: str) -> str:
    # Expect: https://docs.google.com/spreadsheets/d/<ID>/edit...
    parts = urllib.parse.urlparse(url)
    path_parts = parts.path.split("/")
    try:
        idx = path_parts.index("d")
        return path_parts[idx + 1]
    except (ValueError, IndexError):
        raise ValueError("Could not parse sheet ID from URL: %s" % url)


def fetch_csv_for_tab(sheet_id: str, tab_name: str) -> str:
    # Use export endpoint with gid lookup by sheet name via tq? not available without API.
    # Instead, use the 'export?format=csv&sheet=<name>' variant which supports sheet name.
    params = {"format": "csv", "sheet": tab_name}
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?" + urllib.parse.urlencode(params)
    logger.debug("Fetching CSV from: %s", url)
    with urllib.request.urlopen(url) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        data = resp.read().decode(charset, errors="replace")
        return data


def csv_to_markdown_table(csv_text: str) -> str:
    # Read CSV into rows
    reader = csv.reader(io.StringIO(csv_text))
    rows = [row for row in reader]
    if not rows:
        return "(No data)\n"

    # Determine column count (max across rows)
    cols = max(len(r) for r in rows)

    # Normalize rows to same length
    norm_rows = [r + [""] * (cols - len(r)) for r in rows]

    # Build Markdown
    out = io.StringIO()
    # Header: if first row non-empty, use as header; else create generic headers
    header = norm_rows[0] if any(c.strip() for c in norm_rows[0]) else [f"Col {i+1}" for i in range(cols)]
    print("| " + " | ".join(h if h != None else "" for h in header) + " |", file=out)
    print("|" + "|".join(["-" * (len(h) if isinstance(h, str) else 3) or "---" for h in header]) + "|", file=out)
    for r in norm_rows[1:]:
        print("| " + " | ".join(r) + " |", file=out)
    return out.getvalue()


def write_markdown(outdir: str, tab_name: str, md_content: str) -> str:
    filename = f"{kebab_case(tab_name)}.md"
    path = os.path.join(outdir, filename)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"## {tab_name}\n\n")
        fh.write(md_content)
    return path


def main(argv=None):
    args = parse_args(argv)
    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')

    if args.sheet_url:
        sheet_id = sheet_id_from_url(args.sheet_url)
    else:
        sheet_id = sheet_id_from_url('https://docs.google.com/spreadsheets/d/1Hx0HNsCKG1aR8htJTIpYsOcLiOSVUyo_n85mV6d_TSU/edit?usp=sharing')
    logger.info("Using sheet id: %s", sheet_id)

    os.makedirs(args.outdir, exist_ok=True)

    outputs = []
    if args.tabs:
        tabs = args.tabs
    else:
        tabs = ["Targeted Sequencing", "Chromatin-Related"]
        tabs = ["Targeted Sequencing"]
    logger.info("Using tabs: %s", tabs)

    for tab in tabs:
        try:
            logger.info("Processing tab: %s", tab)
            csv_text = fetch_csv_for_tab(sheet_id, tab)
            md_table = csv_to_markdown_table(csv_text)
            out_path = write_markdown(args.outdir, tab, md_table)
            outputs.append(out_path)
            logger.info("Wrote %s", out_path)
        except Exception as e:
            logger.error("Failed to process tab '%s': %s", tab, e)
            raise

    print("\n".join(outputs))


if __name__ == "__main__":
    sys.exit(main())
