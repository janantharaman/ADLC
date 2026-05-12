#!/usr/bin/env python3
"""
Populate Tier 1 reference content for all ADLC phases.

Sources:
  - Fetch phases (discovery, implementation, testing, deployment):
    GitHub raw content from trailheadapps/apex-recipes and trailheadapps/lwc-recipes.
    Apex .cls files are saved as Markdown code blocks with frontmatter.

  - Copy phases (pre-sales, retrofit):
    Files copied from skills/design/references/ — no network needed.

Dependencies (all pre-installed):
    pip install requests beautifulsoup4 lxml

Usage:
    # Process all phases
    python3 scripts/fetch-phase-references.py

    # Single phase
    python3 scripts/fetch-phase-references.py --phase implementation

    # Copy-only phases (no network needed)
    python3 scripts/fetch-phase-references.py --phase pre-sales
    python3 scripts/fetch-phase-references.py --phase retrofit

    # Force re-fetch/re-copy
    python3 scripts/fetch-phase-references.py --force

    # Dry run
    python3 scripts/fetch-phase-references.py --dry-run

    # List all operations
    python3 scripts/fetch-phase-references.py --list-urls
"""

import argparse
import sys
import time
from datetime import date
from pathlib import Path
from typing import Dict, List, Optional
from urllib.parse import quote

import requests

REPO_ROOT = Path(__file__).parent.parent
DESIGN_REFS = REPO_ROOT / "skills" / "design" / "references"
SKILLS_ROOT = REPO_ROOT / "skills"

USER_AGENT = "LKInsurance-PhaseRefs-Fetcher/1.0 (+internal)"
RATE_LIMIT_SECONDS = 1.0

COPY_PHASES = {"pre-sales", "retrofit"}
FETCH_PHASES = {"discovery", "implementation", "testing", "deployment"}
ALL_PHASES = COPY_PHASES | FETCH_PHASES

# GitHub raw content base URLs
_APEX_RECIPES = "https://raw.githubusercontent.com/trailheadapps/apex-recipes/main/force-app/main/default/classes"
_LWC_RECIPES = "https://raw.githubusercontent.com/trailheadapps/lwc-recipes/main/force-app/main/default/lwc"

# Each fetch entry: {url, category, slug, lang}
# lang is used for the fenced code block type (apex, javascript, etc.)
PHASE_MANIFEST: Dict = {
    "discovery": {
        "fetch": [
            # Trigger handler pattern — core pattern reviewed during Discovery
            {"url": f"{_APEX_RECIPES}/Trigger%20Recipes/AccountTriggerHandler.cls",        "category": "trigger-patterns", "slug": "account-trigger-handler",          "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Trigger%20Recipes/MetadataTriggerHandler.cls",       "category": "trigger-patterns", "slug": "metadata-trigger-handler",         "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Trigger%20Recipes/MetadataTriggerService.cls",       "category": "trigger-patterns", "slug": "metadata-trigger-service",         "lang": "apex"},
            # Security patterns — for FLS/CRUD review in Discovery
            {"url": f"{_APEX_RECIPES}/Security%20Recipes/CanTheUser.cls",                   "category": "security-patterns", "slug": "can-the-user-recipes",            "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Security%20Recipes/StripInaccessibleRecipes.cls",    "category": "security-patterns", "slug": "strip-inaccessible-recipes",      "lang": "apex"},
            # Platform Events — for automation inventory
            {"url": f"{_APEX_RECIPES}/Platform%20Event%20Recipes/PlatformEventRecipes.cls", "category": "platform-events", "slug": "platform-events-recipes",        "lang": "apex"},
        ],
    },
    "implementation": {
        "fetch": [
            # Trigger handler framework (Shared Code)
            {"url": f"{_APEX_RECIPES}/Shared%20Code/TriggerHandler.cls",                  "category": "apex",        "slug": "trigger-handler-base",                "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Trigger%20Recipes/AccountTriggerHandler.cls",       "category": "apex",        "slug": "account-trigger-handler",             "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Trigger%20Recipes/MetadataTriggerHandler.cls",      "category": "apex",        "slug": "metadata-trigger-handler",            "lang": "apex"},
            # Async Apex patterns
            {"url": f"{_APEX_RECIPES}/Async%20Apex%20Recipes/BatchApexRecipes.cls",       "category": "apex",        "slug": "batch-apex-recipes",                  "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Async%20Apex%20Recipes/QueueableRecipes.cls",       "category": "apex",        "slug": "queueable-recipes",                   "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Async%20Apex%20Recipes/AtFutureRecipes.cls",        "category": "apex",        "slug": "at-future-recipes",                   "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Async%20Apex%20Recipes/ScheduledApexRecipes.cls",   "category": "apex",        "slug": "scheduled-apex-recipes",              "lang": "apex"},
            # Integration patterns
            {"url": f"{_APEX_RECIPES}/Integration%20Recipes/CalloutRecipes.cls",          "category": "integration", "slug": "callout-recipes",                     "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Integration%20Recipes/NamedCredentialRecipes.cls",  "category": "integration", "slug": "named-credential-recipes",            "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Integration%20Recipes/ApiServiceRecipes.cls",       "category": "integration", "slug": "api-service-recipes",                 "lang": "apex"},
            # Platform Events
            {"url": f"{_APEX_RECIPES}/Platform%20Event%20Recipes/PlatformEventRecipes.cls", "category": "apex",     "slug": "platform-events-recipes",             "lang": "apex"},
            # LWC wire service pattern
            {"url": f"{_LWC_RECIPES}/wireGetPicklistValues/wireGetPicklistValues.js",      "category": "lwc",         "slug": "wire-get-picklist-values",            "lang": "javascript"},
            {"url": f"{_LWC_RECIPES}/apexWireMethodToProperty/apexWireMethodToProperty.js","category": "lwc",         "slug": "apex-wire-method-to-property",        "lang": "javascript"},
        ],
    },
    "testing": {
        "fetch": [
            # Testing Recipes
            {"url": f"{_APEX_RECIPES}/Testing%20Recipes/TestHelper.cls",                  "category": "apex-testing", "slug": "test-helper",                         "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Testing%20Recipes/TestDouble.cls",                  "category": "apex-testing", "slug": "test-double",                         "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Testing%20Recipes/StubExample.cls",                 "category": "apex-testing", "slug": "stub-example",                        "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Testing%20Recipes/StubExampleConsumer.cls",         "category": "apex-testing", "slug": "stub-example-consumer",               "lang": "apex"},
            # Shared Code test data factory pattern
            {"url": f"{_APEX_RECIPES}/Shared%20Code/DataFactoryForPackageInstalls.cls",   "category": "apex-testing", "slug": "data-factory-for-package-installs",   "lang": "apex"},
            # LWC Jest test examples
            {"url": f"{_LWC_RECIPES}/apexWireMethodToProperty/__tests__/apexWireMethodToProperty.test.js", "category": "lwc-testing", "slug": "apex-wire-jest-test", "lang": "javascript"},
            {"url": f"{_LWC_RECIPES}/apexImperativeMethod/__tests__/apexImperativeMethod.test.js",         "category": "lwc-testing", "slug": "apex-imperative-jest-test", "lang": "javascript"},
        ],
    },
    "deployment": {
        "fetch": [
            # Shared Code utilities (service layer + trigger framework — deployment readiness patterns)
            {"url": f"{_APEX_RECIPES}/Shared%20Code/TriggerHandler.cls",                  "category": "deployment-patterns", "slug": "trigger-handler-framework",    "lang": "apex"},
            {"url": f"{_APEX_RECIPES}/Shared%20Code/AccountServiceLayer.cls",             "category": "deployment-patterns", "slug": "account-service-layer",        "lang": "apex"},
            # Platform Events (often deployed as part of integration) — recipes README as deployment context
            {"url": "https://raw.githubusercontent.com/trailheadapps/apex-recipes/main/README.md", "category": "deployment-patterns", "slug": "apex-recipes-readme", "lang": "markdown"},
            {"url": "https://raw.githubusercontent.com/trailheadapps/lwc-recipes/main/README.md",  "category": "deployment-patterns", "slug": "lwc-recipes-readme",  "lang": "markdown"},
        ],
    },
    "pre-sales": {
        "copy": [
            {"src": "wa-framework/overview.md",                                                "dst": "wa-framework/overview.md"},
            {"src": "wa-framework/trusted-overview.md",                                        "dst": "wa-framework/trusted-overview.md"},
            {"src": "wa-framework/easy-overview.md",                                           "dst": "wa-framework/easy-overview.md"},
            {"src": "wa-framework/adaptable-overview.md",                                      "dst": "wa-framework/adaptable-overview.md"},
            {"src": "decision-guides/get-started-platform-decision-guides.md",                 "dst": "decision-guides/get-started-platform-decision-guides.md"},
        ],
    },
    "retrofit": {
        "copy": [
            {"src": "wa-tools/patterns.md",                                                    "dst": "wa-tools/patterns.md"},
            {"src": "wa-tools/anti-patterns.md",                                               "dst": "wa-tools/anti-patterns.md"},
            {"src": "wa-tools/adaptable-overview.md",                                          "dst": "wa-tools/adaptable-overview.md"},
            {"src": "wa-tools/adaptable-application-lifecycle-management.md",                  "dst": "wa-tools/adaptable-application-lifecycle-management.md"},
            {"src": "wa-tools/adaptable-continuity-planning.md",                               "dst": "wa-tools/adaptable-continuity-planning.md"},
            {"src": "wa-tools/adaptable-incident-response.md",                                 "dst": "wa-tools/adaptable-incident-response.md"},
            {"src": "wa-tools/adaptable-interoperability.md",                                  "dst": "wa-tools/adaptable-interoperability.md"},
            {"src": "wa-tools/adaptable-packageability.md",                                    "dst": "wa-tools/adaptable-packageability.md"},
            {"src": "wa-tools/adaptable-separation-of-concerns.md",                            "dst": "wa-tools/adaptable-separation-of-concerns.md"},
        ],
    },
}


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


def build_frontmatter(url: str, phase: str, category: str, page_title: str) -> str:
    today = date.today().isoformat()
    return (
        f"---\n"
        f"source_url: {url}\n"
        f"date_fetched: {today}\n"
        f"phase: {phase}\n"
        f"category: {category}\n"
        f"page_title: {page_title}\n"
        f"---\n"
    )


def content_to_markdown(content: str, lang: str, url: str) -> str:
    """Wrap raw content in a fenced code block (or return as-is for markdown)."""
    if lang == "markdown":
        return content
    return f"```{lang}\n{content}\n```\n"


def process_fetch_entry(
    entry: dict,
    phase: str,
    session: requests.Session,
    force: bool,
    verbose: bool,
) -> str:
    dst = SKILLS_ROOT / phase / "references" / entry["category"] / f"{entry['slug']}.md"

    if dst.exists() and not force:
        return "SKIP"

    content = fetch_page(entry["url"], session, verbose)
    if content is None:
        return "ERROR"

    # Derive a readable title from the slug
    page_title = entry["slug"].replace("-", " ").title()

    body = content_to_markdown(content, entry.get("lang", "text"), entry["url"])
    frontmatter = build_frontmatter(entry["url"], phase, entry["category"], page_title)

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(frontmatter + "\n" + body + "\n", encoding="utf-8")
    return "FETCH"


def process_copy_entry(entry: dict, phase: str, force: bool, verbose: bool) -> str:
    src = DESIGN_REFS / entry["src"]
    dst = SKILLS_ROOT / phase / "references" / entry["dst"]

    if not src.exists():
        print(f"  ERROR: copy source missing: {src}")
        return "ERROR"

    if dst.exists() and not force:
        return "SKIP"

    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(src.read_bytes())
    return "COPY"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Populate Tier 1 references for all ADLC phases"
    )
    parser.add_argument(
        "--phase",
        choices=sorted(ALL_PHASES) + ["all"],
        default="all",
        help="Which phase to process (default: all)",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Re-fetch/re-copy even if files already exist",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Print actions without performing them",
    )
    parser.add_argument(
        "--list-urls",
        action="store_true",
        help="Print all operations and exit",
    )
    parser.add_argument(
        "--rate-limit",
        type=float,
        default=RATE_LIMIT_SECONDS,
        help="Seconds between fetch requests (default: 1.0)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print per-file status lines",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    selected = sorted(ALL_PHASES) if args.phase == "all" else [args.phase]
    fetch_selected = [p for p in selected if p in FETCH_PHASES]
    copy_selected = [p for p in selected if p in COPY_PHASES]

    if args.list_urls:
        for phase in selected:
            manifest = PHASE_MANIFEST.get(phase, {})
            for entry in manifest.get("fetch", []):
                print(f"FETCH  [{phase}/{entry['category']}]  {entry['url']}")
            for entry in manifest.get("copy", []):
                print(f"COPY   [{phase}]  {entry['src']}  →  {entry['dst']}")
        total_fetch = sum(len(PHASE_MANIFEST.get(p, {}).get("fetch", [])) for p in selected)
        total_copy = sum(len(PHASE_MANIFEST.get(p, {}).get("copy", [])) for p in selected)
        print(f"\n{total_fetch} fetches + {total_copy} copies = {total_fetch + total_copy} total operations")
        sys.exit(0)

    if args.dry_run:
        for phase in selected:
            manifest = PHASE_MANIFEST.get(phase, {})
            for entry in manifest.get("fetch", []):
                dst = SKILLS_ROOT / phase / "references" / entry["category"] / f"{entry['slug']}.md"
                status = "SKIP" if dst.exists() else "FETCH"
                print(f"[DRY] {status:5s}  [{phase}/{entry['category']}]  {entry['slug']}")
            for entry in manifest.get("copy", []):
                dst = SKILLS_ROOT / phase / "references" / entry["dst"]
                status = "SKIP" if dst.exists() else "COPY"
                print(f"[DRY] {status:5s}  [{phase}]  {entry['dst']}")
        sys.exit(0)

    session = None
    if fetch_selected:
        session = requests.Session()
        session.headers.update({"User-Agent": USER_AGENT})

    counts = {"FETCH": 0, "COPY": 0, "SKIP": 0, "ERROR": 0}
    total_ops = sum(
        len(PHASE_MANIFEST.get(p, {}).get("fetch", [])) +
        len(PHASE_MANIFEST.get(p, {}).get("copy", []))
        for p in selected
    )
    op_num = 0

    for phase in selected:
        manifest = PHASE_MANIFEST.get(phase, {})
        fetch_entries = manifest.get("fetch", [])
        copy_entries = manifest.get("copy", [])

        for entry in fetch_entries:
            op_num += 1
            result = process_fetch_entry(entry, phase, session, args.force, args.verbose)
            counts[result] += 1
            if args.verbose or result == "ERROR":
                print(f"[{op_num}/{total_ops}] {result:5s}  [{phase}/{entry['category']}]  {entry['url']}")
            elif result == "FETCH":
                print(f"[{op_num}/{total_ops}] FETCH  [{phase}/{entry['category']}]  {entry['slug']}")
            if result == "FETCH" and op_num < total_ops:
                time.sleep(args.rate_limit)

        for entry in copy_entries:
            op_num += 1
            result = process_copy_entry(entry, phase, args.force, args.verbose)
            counts[result] += 1
            if args.verbose or result == "ERROR":
                print(f"[{op_num}/{total_ops}] {result:5s}  [{phase}]  {entry['dst']}")
            elif result == "COPY":
                print(f"[{op_num}/{total_ops}] COPY   [{phase}]  {entry['dst']}")

    print(
        f"\nDone: {counts['FETCH']} fetched, {counts['COPY']} copied, "
        f"{counts['SKIP']} skipped, {counts['ERROR']} errors"
    )
    if counts["ERROR"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
