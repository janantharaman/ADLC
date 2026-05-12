#!/usr/bin/env python3
"""
Fetch Salesforce Well-Architected content from architect.salesforce.com
and save as Markdown files in skills/design/references/.

Dependencies (all pre-installed):
    pip install requests beautifulsoup4 lxml

Usage:
    # Fetch all sections (86 pages)
    python scripts/fetch-well-architected.py

    # Fetch a single section
    python scripts/fetch-well-architected.py --section well-architected

    # Force re-fetch (overwrite existing files)
    python scripts/fetch-well-architected.py --force

    # Dry run — print URLs without fetching
    python scripts/fetch-well-architected.py --dry-run

    # Print all URLs from sitemap and exit
    python scripts/fetch-well-architected.py --list-urls
"""

import argparse
import re
import sys
import time
from datetime import date
from pathlib import Path
from typing import List, Optional, Tuple
from urllib.robotparser import RobotFileParser

import requests
from bs4 import BeautifulSoup, Tag

SITEMAP_URL = "https://architect.salesforce.com/sitemap-1.xml"
BASE_URL = "https://architect.salesforce.com"
ROBOTS_URL = "https://architect.salesforce.com/robots.txt"
USER_AGENT = "LKInsurance-WellArchitected-Fetcher/1.0 (+internal)"
RATE_LIMIT_SECONDS = 1.0

SECTION_CONFIG = {
    "well-architected": {
        "subdir": "wa-framework",
        "label": "well-architected",
    },
    "well-architected-tools": {
        "subdir": "wa-tools",
        "label": "well-architected-tools",
    },
    "decision-guides": {
        "subdir": "decision-guides",
        "label": "decision-guides",
    },
    "reference-diagrams": {
        "subdir": "reference-diagrams",
        "label": "reference-diagrams",
    },
}

REPO_ROOT = Path(__file__).parent.parent
OUTPUT_ROOT = REPO_ROOT / "skills" / "design" / "references"

URL_PATTERN = re.compile(
    r"^https://architect\.salesforce\.com/docs/architect/"
    r"(well-architected|well-architected-tools|decision-guides|reference-diagrams)"
    r"/guide/.+\.html$"
)


def check_robots() -> bool:
    rp = RobotFileParser()
    rp.set_url(ROBOTS_URL)
    try:
        rp.read()
    except Exception:
        # If robots.txt is unreachable, proceed conservatively but don't block
        return True
    return rp.can_fetch(USER_AGENT, BASE_URL + "/")


def fetch_sitemap(sitemap_url: str, session: requests.Session) -> List[str]:
    resp = session.get(sitemap_url, timeout=30)
    resp.raise_for_status()
    soup = BeautifulSoup(resp.text, "lxml-xml")
    urls = [loc.get_text(strip=True) for loc in soup.find_all("loc")]
    return sorted(u for u in urls if URL_PATTERN.match(u))


def classify_url(url: str) -> Optional[Tuple[str, str]]:
    # URL form: .../docs/architect/{section}/guide/{slug}.html
    for section_key in SECTION_CONFIG:
        marker = f"/docs/architect/{section_key}/guide/"
        if marker in url:
            slug = url.split(marker)[-1].rstrip("/")
            if slug.endswith(".html"):
                slug = slug[:-5]
            return section_key, slug
    return None


def output_path_for(url: str) -> Optional[Path]:
    result = classify_url(url)
    if result is None:
        return None
    section_key, slug = result
    subdir = SECTION_CONFIG[section_key]["subdir"]
    return OUTPUT_ROOT / subdir / f"{slug}.md"


def extract_title(soup: BeautifulSoup, url: str) -> str:
    title_tag = soup.find("title")
    if title_tag:
        text = title_tag.get_text(strip=True)
        # Strip everything from the first " | " onwards
        if " | " in text:
            return text.split(" | ")[0].strip()
        return text
    # Fall back to first doc-heading
    heading = soup.find("doc-heading")
    if heading and heading.get("header"):
        return heading["header"]
    # Last resort: slug from URL
    result = classify_url(url)
    if result:
        return result[1].replace("-", " ").title()
    return "Unknown"


def inline_text(tag: Tag) -> str:
    """Convert an element's children to inline Markdown text."""
    parts = []
    for child in tag.children:
        if isinstance(child, str):
            parts.append(child)
        elif child.name in ("strong", "b"):
            parts.append(f"**{child.get_text()}**")
        elif child.name in ("em", "i"):
            parts.append(f"*{child.get_text()}*")
        elif child.name == "code":
            parts.append(f"`{child.get_text()}`")
        elif child.name == "a":
            href = child.get("href", "")
            text = child.get_text()
            if href:
                parts.append(f"[{text}]({href})")
            else:
                parts.append(text)
        elif child.name == "br":
            parts.append("\n")
        elif child.name is not None:
            parts.append(child.get_text())
        # NavigableString already handled above
    return "".join(parts).strip()


def convert_table(table_tag: Tag) -> List[str]:
    lines = []
    rows = table_tag.find_all("tr")
    if not rows:
        return lines

    table_data = []
    for row in rows:
        cells = row.find_all(["th", "td"])
        table_data.append([inline_text(c) for c in cells])

    if not table_data:
        return lines

    header = table_data[0]
    lines.append("| " + " | ".join(header) + " |")
    lines.append("| " + " | ".join(["---"] * len(header)) + " |")
    for data_row in table_data[1:]:
        # Pad or truncate to match header width
        padded = data_row + [""] * (len(header) - len(data_row))
        lines.append("| " + " | ".join(padded[: len(header)]) + " |")
    lines.append("")
    return lines


def html_to_markdown(soup: BeautifulSoup) -> str:
    """Extract main content from the page and convert to Markdown."""
    # Find the main content area — try doc-content-layout first, then main
    content = soup.find("doc-content-layout")
    if content is None:
        content = soup.find("main")
    if content is None:
        return ""

    lines: List[str] = []

    def walk(element: Tag, depth: int = 0) -> None:
        if not hasattr(element, "name") or element.name is None:
            return

        name = element.name.lower()

        # Skip non-content elements
        if name in ("script", "style", "nav", "header", "footer"):
            return
        if name == "doc-content-layout" and depth > 0:
            # Only process the top-level doc-content-layout, not nested ones
            return

        # Custom heading element used by architect.salesforce.com
        if name == "doc-heading":
            level = int(element.get("aria-level", 2))
            text = element.get("header", "").strip()
            if text:
                lines.append(f"\n{'#' * level} {text}\n")
            return

        if name == "p":
            text = inline_text(element)
            if text:
                lines.append(f"\n{text}\n")
            return

        if name == "ul":
            for li in element.find_all("li", recursive=False):
                text = inline_text(li)
                if text:
                    lines.append(f"- {text}")
            lines.append("")
            return

        if name == "ol":
            for i, li in enumerate(element.find_all("li", recursive=False), 1):
                text = inline_text(li)
                if text:
                    lines.append(f"{i}. {text}")
            lines.append("")
            return

        if name == "table":
            lines.extend(convert_table(element))
            return

        if name == "blockquote":
            text = element.get_text(strip=True)
            if text:
                lines.append(f"\n> {text}\n")
            return

        if name in ("pre", "code") and depth == 0:
            text = element.get_text()
            if text.strip():
                lines.append(f"\n```\n{text}\n```\n")
            return

        # For container elements, recurse into children
        if name in (
            "div", "section", "article", "main",
            "doc-content-layout", "doc-content-body",
            "lightning-layout", "lightning-layout-item",
        ):
            for child in element.children:
                if hasattr(child, "name"):
                    walk(child, depth + 1)
            return

        # For any other element with children, recurse
        for child in element.children:
            if hasattr(child, "name"):
                walk(child, depth + 1)

    walk(content)

    # Clean up excessive blank lines
    text = "\n".join(lines)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def detect_spa(html: str) -> bool:
    soup = BeautifulSoup(html, "lxml")
    main = soup.find("main")
    if main:
        return len(main.get_text(strip=True)) < 100
    return True


def build_frontmatter(url: str, section_label: str, page_title: str) -> str:
    today = date.today().isoformat()
    return f"---\nsource_url: {url}\ndate_fetched: {today}\nsection: {section_label}\npage_title: {page_title}\n---\n"


def fetch_page(url: str, session: requests.Session, verbose: bool) -> Optional[str]:
    try:
        resp = session.get(url, timeout=30)
        if resp.status_code == 200:
            return resp.text
        if resp.status_code in (404, 410):
            if verbose:
                print(f"  WARN: {resp.status_code} {url}")
            return None
        if resp.status_code in (429, 503):
            print(f"  WARN: {resp.status_code} rate-limited on {url} — skipping")
            return None
        if verbose:
            print(f"  WARN: HTTP {resp.status_code} for {url}")
        return None
    except requests.RequestException as exc:
        print(f"  ERROR: network error on {url}: {exc}")
        return None


def process_url(
    url: str,
    session: requests.Session,
    output_root: Path,
    force: bool,
    verbose: bool,
) -> str:
    out_path = output_path_for(url)
    if out_path is None:
        return "ERROR"

    if out_path.exists() and not force:
        return "SKIP"

    html = fetch_page(url, session, verbose)
    if html is None:
        return "ERROR"

    if detect_spa(html):
        print(f"  WARN: {url} appears JS-rendered (no main content). Skipping.")
        return "ERROR"

    soup = BeautifulSoup(html, "lxml")

    result = classify_url(url)
    if result is None:
        return "ERROR"
    section_key, _ = result
    section_label = SECTION_CONFIG[section_key]["label"]

    page_title = extract_title(soup, url)
    body = html_to_markdown(soup)
    frontmatter = build_frontmatter(url, section_label, page_title)

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(frontmatter + "\n" + body + "\n", encoding="utf-8")
    return "FETCH"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Fetch Salesforce Well-Architected docs into skills/design/references/"
    )
    parser.add_argument(
        "--section",
        choices=list(SECTION_CONFIG.keys()) + ["all"],
        default="all",
        help="Which section to fetch (default: all)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-fetch and overwrite existing files",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print URLs only, no HTTP requests",
    )
    parser.add_argument(
        "--list-urls",
        action="store_true",
        help="Print all sitemap URLs and exit",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=OUTPUT_ROOT,
        help=f"Output directory (default: {OUTPUT_ROOT})",
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=RATE_LIMIT_SECONDS,
        help="Seconds between requests (default: 1.0)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print per-URL status lines",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    if not check_robots():
        print("ERROR: robots.txt disallows crawling. Aborting.")
        sys.exit(1)

    session = requests.Session()
    session.headers.update({"User-Agent": USER_AGENT})

    print("Fetching sitemap...")
    all_urls = fetch_sitemap(SITEMAP_URL, session)
    print(f"Sitemap: {len(all_urls)} matching URLs found")

    if args.list_urls:
        for url in all_urls:
            print(url)
        sys.exit(0)

    if args.section != "all":
        all_urls = [u for u in all_urls if f"/{args.section}/" in u]

    if args.dry_run:
        for url in all_urls:
            print(url)
        print(f"\n{len(all_urls)} URLs (dry run — no files written)")
        sys.exit(0)

    print(f"Target: {len(all_urls)} pages → {args.output_dir}\n")

    counts = {"FETCH": 0, "SKIP": 0, "ERROR": 0}
    for i, url in enumerate(all_urls, 1):
        result = process_url(url, session, args.output_dir, args.force, args.verbose)
        counts[result] += 1
        if args.verbose or result == "ERROR":
            print(f"[{i}/{len(all_urls)}] {result:5s}  {url}")
        elif result == "FETCH":
            slug = url.split("/guide/")[-1]
            print(f"[{i}/{len(all_urls)}] FETCH  {slug}")
        if result == "FETCH" and i < len(all_urls):
            time.sleep(args.rate_limit)

    print(f"\nDone: {counts['FETCH']} fetched, {counts['SKIP']} skipped, {counts['ERROR']} errors")
    if counts["ERROR"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
