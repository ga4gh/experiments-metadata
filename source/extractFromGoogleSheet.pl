#!/usr/bin/env python3
"""
Extract specified Google Sheets tabs into Markdown files.

This module provides a CLI tool that reads one or more tabs (worksheets) from a
public Google Sheet and writes each tab as a GitHub-flavored Markdown table.
It prefers exporting via sheet gid (stable ID) and includes fallbacks.

Command-line options:
- --sheet-url: The Google Sheet viewing URL. If omitted, a project default is used.
- --tabs: One or more tab names to export. Must match titles in the Sheet.
- --tab-gids: Optional explicit overrides in the form "Name=gid"; multiple allowed.
- --outdir: Output directory. Defaults to the repository root.

Environment variables:
- EXTRACT_SHEETS_DEBUG=1 enables verbose logging.
- EXTRACT_SHEETS_GIDS: Provide overrides as JSON or semicolon-separated pairs.

Written by:
Peter Woollard woollard@ebi.ac.uk on 2023-07-27 with much assistance of PyCharm's Junie Pro

Example:
  ./source/extractFromGoogleSheet.pl \
    --sheet-url "https://docs.google.com/spreadsheets/d/ID/edit" \
    --tabs "Targeted Sequencing" "Chromatin-Related"

Assumptions:
- The Google Sheet is publicly readable (no auth). CSV export endpoints are used.
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
    """Parse command-line arguments.

    Args:
        argv: Optional list of argument strings. If None, uses sys.argv[1:].

    Returns:
        argparse.Namespace: Parsed arguments with attributes sheet_url, tabs, tab_gids, outdir.
    """
    p = argparse.ArgumentParser(description="Extract Google Sheets tabs to Markdown tables")
    p.add_argument("--sheet-url", required=False, help="Google Sheet URL (view link)")
    p.add_argument("--tabs", nargs="+", required=False, help="Tab (sheet) names to export. Provide exact tab names as they appear in Google Sheets.")
    p.add_argument("--tab-gids", nargs="+", required=False, help="Optional overrides mapping tab names to gids, e.g.: --tab-gids 'Targeted Sequencing=2041814223' 'Chromatin-Related=1371550803'")
    p.add_argument("--outdir", default=os.path.dirname(os.path.dirname(os.path.abspath(__file__))), help="Output directory (default: repo root)")
    return p.parse_args(argv)


def kebab_case(name: str) -> str:
    """Convert a string to kebab-case.

    Non-alphanumeric characters are converted to dashes and consecutive dashes
    are collapsed. Lowercases the result. Returns "sheet" if input is empty.

    Args:
        name: Arbitrary string.

    Returns:
        str: kebab-cased name suitable for filenames/anchors.
    """
    s = name.strip().lower()
    s = re.sub(r"[^a-z0-9]+", "-", s)
    s = re.sub(r"-+", "-", s).strip("-")
    return s or "sheet"


def sheet_id_from_url(url: str) -> str:
    """Extract the Google Sheet ID from a standard Sheets URL.

    Expects a URL of the form https://docs.google.com/spreadsheets/d/<ID>/... .

    Args:
        url: The full sheet URL.

    Returns:
        str: The document ID string.

    Raises:
        ValueError: If the ID cannot be parsed from the URL.
    """
    # Expect: https://docs.google.com/spreadsheets/d/<ID>/edit...
    parts = urllib.parse.urlparse(url)
    path_parts = parts.path.split("/")
    try:
        idx = path_parts.index("d")
        return path_parts[idx + 1]
    except (ValueError, IndexError):
        raise ValueError("Could not parse sheet ID from URL: %s" % url)


def _fetch_gviz_metadata(sheet_id: str) -> str:
    """Fetch raw GViz metadata JSONP for a public sheet.

    Args:
        sheet_id: Google Sheets document ID.

    Returns:
        str: The raw response text (often JSON wrapped in a JS callback).
    """
    # Returns the raw JSON text (wrapped in a JS callback) from the gviz endpoint
    # which includes worksheet names and gids without requiring API auth for public sheets.
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/gviz/tq?tqx=out:json"
    logger.debug("Fetching GViz metadata from: %s", url)
    with urllib.request.urlopen(url) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace")


def _fetch_edit_bootstrap(sheet_id: str) -> str:
    """Fetch the Google Sheets edit page to parse bootstrap data.

    Args:
        sheet_id: Google Sheets document ID.

    Returns:
        str: HTML of the edit page which contains embedded JSON with sheet metadata.
    """
    # Fetch the standard edit page to parse initial bootstrap data for sheets list
    url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/edit"
    logger.debug("Fetching edit page bootstrap from: %s", url)
    with urllib.request.urlopen(url) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        return resp.read().decode(charset, errors="replace")


def _extract_name_gid_from_edit_html(html: str) -> dict:
    """Extract a mapping of sheet titles to gids from the edit page HTML.

    This uses heuristic regexes to find embedded JSON blocks where each sheet has
    properties.title and properties.sheetId. Falls back to scanning for nearby
    "title" and "sheetId" pairs.

    Args:
        html: The entire HTML of the edit page.

    Returns:
        dict: Mapping of title -> gid (as string). May be empty if parsing fails.
    """
    # Google embeds JSON in JS: window._docs_flag_initialData = JSON.parse('...'); or similar gapi configs
    # We'll try to locate occurrences of sheet titles and sheetIds in nearby JSON structures.
    import json, re as _re
    name_gid = {}
    # Try to find a JSON array/object with "sheets" each having properties.title and properties.sheetId
    # Pattern for a JSON block; we search for {"sheets": [...]}
    m = _re.search(r"(\{[^<]{0,100000}\"sheets\"\s*:\s*\[[\s\S]*?\]\s*\})", html)
    if m:
        block = m.group(1)
        try:
            data = json.loads(block)
            sheets = data.get("sheets", [])
            for sh in sheets:
                if not isinstance(sh, dict):
                    continue
                props = sh.get("properties", {})
                title = props.get("title")
                gid = props.get("sheetId")
                if isinstance(title, str) and gid is not None:
                    name_gid[title] = str(gid)
        except Exception:
            pass
    # Fallback: find pairs of "title":"..." and "sheetId":123 within a vicinity
    if not name_gid:
        for m in _re.finditer(r'\{[^{}]*?\"sheetId\"\s*:\s*(\d+)[^{}]*?\"title\"\s*:\s*\"([^\"]+)\"[^{}]*\}', html):
            gid, title = m.group(1), m.group(2)
            name_gid[title] = str(gid)
    return name_gid


def _name_to_gid_map(sheet_id: str) -> dict:
    """Build a mapping from tab names to gids for a given sheet.

    Tries GViz JSONP first with robust parsing; if that fails or returns no
    data, falls back to scraping the edit page bootstrap JSON.

    Args:
        sheet_id: Google Sheets document ID.

    Returns:
        dict: Mapping of tab title -> gid (as string).

    Raises:
        RuntimeError: If no mapping can be derived from either source.
    """
    text = _fetch_gviz_metadata(sheet_id)
    # GViz often returns a JSONP-like wrapper. Strip prefix and trailing ); safely.
    json_start = text.find("{")
    json_end = text.rfind("}")
    data = None
    if json_start != -1 and json_end != -1 and json_end >= json_start:
        import json
        core = text[json_start:json_end+1]
        try:
            data = json.loads(core)
        except Exception:
            # Remove leading junk and callback wrapper
            stripped = text
            for prefix in (")]}'", ")]}'\n", ")]}'\r\n"):
                if stripped.startswith(prefix):
                    stripped = stripped[len(prefix):]
            cb_open = stripped.find("(")
            cb_close = stripped.rfind(")")
            candidate = stripped
            if cb_open != -1 and cb_close != -1 and cb_close > cb_open:
                candidate = stripped[cb_open+1:cb_close]
            try:
                data = json.loads(candidate)
            except Exception:
                data = None
    name_gid = {}
    if isinstance(data, dict):
        if "sheets" in data and isinstance(data["sheets"], list):
            for sh in data["sheets"]:
                props = sh.get("properties", {}) if isinstance(sh, dict) else {}
                title = props.get("title")
                gid = props.get("sheetId")
                if isinstance(title, str) and gid is not None:
                    name_gid[title] = str(gid)
        # Alternative legacy path
        try:
            rows = data.get("table", {}).get("rows", [])
            for row in rows:
                c = row.get("c", []) if isinstance(row, dict) else []
                if len(c) >= 2 and isinstance(c[0], dict) and isinstance(c[1], dict):
                    gid = c[0].get("v")
                    name = c[1].get("v")
                    if isinstance(gid, (int, str)) and isinstance(name, str):
                        name_gid[name] = str(gid)
        except Exception:
            pass
    # If still empty, try parsing the edit page bootstrap
    if not name_gid:
        try:
            html = _fetch_edit_bootstrap(sheet_id)
            name_gid = _extract_name_gid_from_edit_html(html)
        except Exception:
            name_gid = {}
    if not name_gid:
        raise RuntimeError("Unable to map tab names to gids from GViz/edit metadata")
    logger.debug("Resolved tab name->gid map: %s", list(name_gid.keys()))
    return name_gid


def fetch_csv_for_tab(sheet_id: str, tab_name: str, override_gid: str = None) -> str:
    """Fetch CSV for a specific tab from a Google Sheet.

    Prefers exporting via gid, which is more reliable than the 'sheet' name
    parameter. If an override_gid is provided, it is used directly.

    Args:
        sheet_id: Google Sheets document ID.
        tab_name: The tab (worksheet) title.
        override_gid: Optional explicit gid to use.

    Returns:
        str: The CSV text for the tab.

    Raises:
        RuntimeError: If an HTML response is received (permissions or bad name).
    """
    # Prefer gid-based export for reliability, falling back to 'sheet' param if mapping fails.
    url = None
    # If override gid is provided, use it directly
    if override_gid:
        params = {"format": "csv", "gid": str(override_gid)}
        url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?" + urllib.parse.urlencode(params)
        logger.info("Using override gid %s for tab '%s'", override_gid, tab_name)
    if url is None:
        try:
            gid_map = _name_to_gid_map(sheet_id)
            # Try exact match, then case-insensitive match
            gid = gid_map.get(tab_name)
            if not gid:
                lowered = {k.lower(): v for k, v in gid_map.items()}
                gid = lowered.get(tab_name.lower())
            if gid:
                params = {"format": "csv", "gid": gid}
                url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?" + urllib.parse.urlencode(params)
                logger.debug("Fetching CSV via gid from: %s", url)
        except Exception as e:
            logger.warning("Failed to resolve gid for tab '%s': %s. Will try name parameter.", tab_name, e)
            try:
                # Log available tabs to help user
                avail = list(_name_to_gid_map(sheet_id).keys())
                logger.info("Available tabs detected: %s", avail)
            except Exception:
                pass

    if url is None:
        params = {"format": "csv", "sheet": tab_name}
        url = f"https://docs.google.com/spreadsheets/d/{sheet_id}/export?" + urllib.parse.urlencode(params)
        logger.debug("Fetching CSV via sheet name from: %s", url)

    with urllib.request.urlopen(url) as resp:
        charset = resp.headers.get_content_charset() or "utf-8"
        data = resp.read().decode(charset, errors="replace")
        if data.lstrip().startswith("<"):
            try:
                avail = list(_name_to_gid_map(sheet_id).keys())
            except Exception:
                avail = []
            hint = ("Received HTML instead of CSV for tab '%s' — check sharing permissions or tab name."
                    + (" Available tabs: %s" % avail if avail else ""))
            raise RuntimeError(hint % tab_name)
        return data


def csv_to_markdown_table(csv_text: str) -> str:
    """Convert CSV text to a GitHub-flavored Markdown table.

    Uses the first row as the header if it has any non-empty cell, otherwise
    generates generic column headers. Newlines within cells are converted to
    HTML <br> elements and vertical bars are escaped to avoid breaking the
    Markdown table structure.

    Args:
        csv_text: The CSV content as a single string.

    Returns:
        str: Markdown table text ending with a newline.
    """
    # Read CSV into rows
    reader = csv.reader(io.StringIO(csv_text))
    rows = [row for row in reader]
    if not rows:
        return "(No data)\n"

    # Determine column count (max across rows)
    cols = max(len(r) for r in rows)

    # Normalize rows to same length
    norm_rows = [r + [""] * (cols - len(r)) for r in rows]

    def sanitize_cell(val: str) -> str:
        """Prepare a single cell for Markdown table output.

        - Replace CRLF/CR/LF with <br>
        - Escape vertical bars with a backslash
        - Strip trailing/leading whitespace except keep intentional inner spaces
        """
        if val is None:
            return ""
        # Ensure string
        s = str(val)
        # Normalize newlines
        s = s.replace("\r\n", "\n").replace("\r", "\n").replace("\n", "<br>")
        # Escape pipe characters used by Markdown tables
        s = s.replace("|", "\\|")
        # Avoid accidental table alignment markers by trimming ends
        return s.strip()

    # Build Markdown
    out = io.StringIO()
    # Header: if first row non-empty, use as header; else create generic headers
    header = norm_rows[0] if any((c or "").strip() for c in norm_rows[0]) else [f"Col {i+1}" for i in range(cols)]
    header_s = [sanitize_cell(h) for h in header]
    # Use standard '---' separator for each column as per GFM
    separator = "|" + "|".join([" --- " for _ in header_s]) + "|"
    print("| " + " | ".join(header_s) + " |", file=out)
    print(separator, file=out)
    for r in norm_rows[1:]:
        row_s = [sanitize_cell(c) for c in r]
        print("| " + " | ".join(row_s) + " |", file=out)
    return out.getvalue()


def write_markdown(outdir: str, tab_name: str, md_content: str) -> str:
    """Write a Markdown table to a file named after the tab.

    The filename is the kebab-cased tab name with .md extension. The file will
    be written to the specified output directory.

    Args:
        outdir: Directory to write the file to.
        tab_name: Original tab title; also used in the file header.
        md_content: Markdown content to write.

    Returns:
        str: The full path of the written file.
    """
    filename = f"{kebab_case(tab_name)}.md"
    path = os.path.join(outdir, filename)
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(f"## {tab_name}\n\n")
        fh.write(f"These are properties for {tab_name} that are non-core, and thus not found in all sequencing experiments. \n\nSome will be unique to this type of experiment and some common to several types.\n\n")
        fh.write(f"Table of {tab_name} properties\n\n")
        fh.write(md_content)
    return path


# Hardcoded default GID mapping for known tabs
#: dict[str, str]: Default tab title to gid mapping used unless overridden.
HARDCODED_GIDS = {
    "Targeted Sequencing": "2041814223",
    "Chromatin-Related": "1371550803",
    "Chromosome Conformation": "1612247613",
    "Metagenomics": "862306389",
    "Transcriptomics": "1495274914",
}


def main(argv=None):
    """Program entry point for command-line usage.

    Parses arguments, determines the sheet ID, resolves/uses gids for the
    requested tabs, fetches each as CSV, converts to Markdown, and writes files.

    Args:
        argv: Optional list of argument strings. If None, uses sys.argv[1:].

    Returns:
        int: Zero on success; non-zero may be returned by sys.exit in __main__.
    """
    args = parse_args(argv)
    logging.basicConfig(level=logging.INFO, format='%(levelname)s - %(message)s')
    # Increase debug detail if env set
    if os.environ.get("EXTRACT_SHEETS_DEBUG"):
        logger.setLevel(logging.DEBUG)

    # Parse overrides from CLI
    override_map = dict(HARDCODED_GIDS)  # start with hardcoded defaults
    if args.tab_gids:
        for pair in args.tab_gids:
            if "=" in pair:
                name, gid = pair.split("=", 1)
                override_map[name.strip()] = gid.strip()
            else:
                logger.warning("Ignoring --tab-gids entry without '=': %s", pair)
    # Also from env: EXTRACT_SHEETS_GIDS can be JSON or 'Name=gid;Other=gid'
    env_override = os.environ.get("EXTRACT_SHEETS_GIDS")
    if env_override:
        try:
            import json
            obj = json.loads(env_override)
            if isinstance(obj, dict):
                for k, v in obj.items():
                    override_map[str(k)] = str(v)
            else:
                raise ValueError("not a dict")
        except Exception:
            # try semicolon pairs
            for chunk in env_override.split(";"):
                if not chunk.strip():
                    continue
                if "=" in chunk:
                    k, v = chunk.split("=", 1)
                    override_map[k.strip()] = v.strip()
    if override_map:
        logger.info("Using tab gid mapping for: %s", list(override_map.keys()))

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
        # Default tabs if none provided
        # tabs = ["Targeted Sequencing", "Chromatin-Related"]
        tabs = list(HARDCODED_GIDS.keys())
    logger.info("Using tabs: %s", tabs)

    for tab in tabs:
        try:
            logger.info("Processing tab: %s", tab)
            # Find override gid by exact or case-insensitive match
            override_gid = None
            if override_map:
                override_gid = override_map.get(tab)
                if override_gid is None:
                    lowered = {k.lower(): v for k, v in override_map.items()}
                    override_gid = lowered.get(tab.lower())
            csv_text = fetch_csv_for_tab(sheet_id, tab, override_gid=override_gid)
            md_table = csv_to_markdown_table(csv_text)
            out_path = write_markdown(args.outdir, tab, md_table)
            outputs.append(out_path)
            logger.info("Wrote %s", out_path)
            # logger.info(md_table)
        except Exception as e:
            logger.error("Failed to process tab '%s': %s", tab, e)
            raise

    print("\n".join(outputs))


if __name__ == "__main__":
    sys.exit(main())
