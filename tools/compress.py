#!/usr/bin/env python3
"""
unga-bunga compress — shrink CLAUDE.md without losing behavioral rules.

Two modes:
  --fast    Rule-based compression (no API needed, ~30-40% reduction)
  --deep    AI-powered compression via Claude API (~50-60% reduction)

Usage:
  python3 tools/compress.py CLAUDE.md              # fast mode (default)
  python3 tools/compress.py CLAUDE.md --deep        # AI-powered
  python3 tools/compress.py CLAUDE.md --dry-run     # preview without writing
"""

import argparse
import os
import re
import shutil
import sys
from pathlib import Path


def count_tokens_estimate(text: str) -> int:
    """Rough token count: ~1 token per 4 chars for English."""
    return len(text) // 4


def compress_fast(content: str) -> str:
    """Rule-based compression. No API needed."""

    # --- Phase 1: Block-level transforms (before line processing) ---

    # Collapse markdown tables to compact key:value lines
    # Match full tables: header row, separator row, data rows
    def collapse_table(match):
        table_text = match.group(0)
        rows = [r.strip() for r in table_text.strip().split("\n")]
        if len(rows) < 3:
            return table_text

        # Parse header
        headers = [c.strip() for c in rows[0].split("|") if c.strip()]
        # Skip separator (row 1)
        result_lines = []
        for row in rows[2:]:
            cells = [c.strip() for c in row.split("|") if c.strip()]
            if len(cells) == len(headers):
                pairs = [f"{h}: {c}" for h, c in zip(headers, cells) if c and c != "---"]
                result_lines.append("- " + " | ".join(pairs))
            elif cells:
                result_lines.append("- " + " | ".join(cells))
        return "\n".join(result_lines)

    content = re.sub(
        r"(?:^|\n)\|[^\n]+\|\n\|[\s\-:|]+\|\n(?:\|[^\n]+\|\n?)+",
        collapse_table,
        content,
    )

    # Collapse CSS/code blocks with only variable definitions to compact form
    def collapse_css_vars(match):
        block = match.group(0)
        lines_in = block.split("\n")
        # Extract just the variable assignments
        vars_out = []
        for line in lines_in:
            # Match CSS custom properties: --name: value;
            m = re.match(r"\s*(--[\w-]+):\s*(.+?);?\s*(?:/\*.*\*/)?$", line)
            if m:
                vars_out.append(f"{m.group(1)}: {m.group(2)}")
        if vars_out:
            return "```\n" + "\n".join(vars_out) + "\n```"
        return block

    content = re.sub(r"```css\n.+?```", collapse_css_vars, content, flags=re.DOTALL)

    # --- Phase 2: Line-by-line processing ---

    lines = content.split("\n")
    result = []
    prev_blank = False
    in_code_block = False

    for line in lines:
        stripped = line.strip()

        # Track code blocks — don't compress inside them
        if stripped.startswith("```"):
            in_code_block = not in_code_block
            result.append(line)
            prev_blank = False
            continue

        if in_code_block:
            result.append(line)
            prev_blank = False
            continue

        # Collapse multiple blank lines
        if not stripped:
            if not prev_blank:
                result.append("")
                prev_blank = True
            continue
        prev_blank = False

        # Remove HTML comments
        if stripped.startswith("<!--") and stripped.endswith("-->"):
            continue

        # Remove pure decoration lines
        if re.match(r"^[-=*]{3,}$", stripped):
            continue

        # Remove trailing header markers
        line = re.sub(r"(#{1,6}\s+.+?)\s*#{1,6}\s*$", r"\1", line)

        # Strip bold/italic ONLY on purely decorative emphasis
        # Keep bold on: NEVER, ALWAYS, MUST, CRITICAL, DO NOT, WARNING — these change behavior
        # Keep bold at start of list items (structural labels)
        if not stripped.startswith("#") and not re.match(r"^[-*]\s+\*\*", stripped):
            # Only strip bold on words that aren't behavioral emphasis
            emphasis_words = r"(?:NEVER|ALWAYS|MUST|CRITICAL|DO NOT|WARNING|IMPORTANT|REQUIRED|NOTE)"
            line = re.sub(r"\*\*(" + emphasis_words + r"[^*]*?)\*\*", r"**\1**", line)  # keep these
            # Strip italic only (single *), not bold
            line = re.sub(r"(?<!\*)\*([^*]+?)\*(?!\*)", r"\1", line)

        # Remove trailing whitespace
        line = line.rstrip()

        # Remove parenthetical examples — but only pure examples, not constraints
        # "(e.g., foo)" is an example. "(must be BIGINT)" is a constraint.
        line = re.sub(r"\s*\(e\.g\.,?\s*[^)]+\)", "", line)
        line = re.sub(r"\s*\(for example,?\s*[^)]+\)", "", line)
        # Keep (i.e., ...) — these are definitions, not examples

        # Compress wordy phrases
        line = line.replace("in order to", "to")
        line = line.replace("as well as", "and")
        line = line.replace("make sure to", "")
        line = line.replace("Make sure to", "")
        line = line.replace("need to be", "must be")
        line = line.replace("should be", "must be")
        line = line.replace("is responsible for", "handles")

        result.append(line)

    compressed = "\n".join(result)

    # Collapse 3+ newlines to 2
    compressed = re.sub(r"\n{3,}", "\n\n", compressed)

    return compressed.strip() + "\n"


def compress_deep(content: str) -> str:
    """AI-powered compression using Claude API."""
    try:
        import anthropic
    except ImportError:
        print("Error: 'anthropic' package required for --deep mode")
        print("Install: pip install anthropic")
        sys.exit(1)

    client = anthropic.Anthropic()

    prompt = f"""Compress this CLAUDE.md file to minimize token count while preserving ALL behavioral rules, constraints, and technical specifications.

Rules:
- Keep every imperative rule ("do X", "never Y", "always Z")
- Keep all technical specs (schemas, tokens, design values)
- Remove explanatory prose, examples that restate rules, and filler
- Collapse tables into compact key:value format where possible
- Remove markdown formatting that doesn't affect meaning
- Keep code blocks that define values (CSS vars, configs)
- Remove code blocks that are just examples
- Use sentence fragments over full sentences
- Output valid markdown

Input CLAUDE.md:

{content}

Output the compressed version only. No commentary."""

    response = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=4096,
        messages=[{"role": "user", "content": prompt}],
    )

    return response.content[0].text.strip() + "\n"


def main():
    parser = argparse.ArgumentParser(
        description="Compress CLAUDE.md to reduce per-message token overhead"
    )
    parser.add_argument("file", help="Path to CLAUDE.md")
    parser.add_argument(
        "--deep", action="store_true", help="Use Claude API for deeper compression"
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview compression without writing",
    )
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="Skip creating .original.md backup",
    )
    args = parser.parse_args()

    filepath = Path(args.file).resolve()
    if not filepath.exists():
        print(f"Error: {filepath} not found")
        sys.exit(1)

    original = filepath.read_text(encoding="utf-8")
    original_tokens = count_tokens_estimate(original)

    print(f"\nInput:  {filepath}")
    print(f"Before: {len(original)} chars | ~{original_tokens} tokens")
    print(f"Mode:   {'deep (Claude API)' if args.deep else 'fast (rule-based)'}")
    print()

    if args.deep:
        compressed = compress_deep(original)
    else:
        compressed = compress_fast(original)

    compressed_tokens = count_tokens_estimate(compressed)
    saved = original_tokens - compressed_tokens
    pct = (saved / original_tokens * 100) if original_tokens > 0 else 0

    print(f"After:  {len(compressed)} chars | ~{compressed_tokens} tokens")
    print(f"Saved:  ~{saved} tokens ({pct:.0f}% reduction)")
    print()

    if args.dry_run:
        print("--- Preview (first 50 lines) ---")
        preview_lines = compressed.split("\n")[:50]
        print("\n".join(preview_lines))
        if len(compressed.split("\n")) > 50:
            print(f"\n... ({len(compressed.split(chr(10)))} total lines)")
        return

    # Backup original
    if not args.no_backup:
        backup = filepath.with_suffix(".original.md")
        shutil.copy2(filepath, backup)
        print(f"Backup: {backup}")

    # Write compressed
    filepath.write_text(compressed, encoding="utf-8")
    print(f"Written: {filepath}")

    # Per-message savings context
    print()
    print(f"You save ~{saved} input tokens PER MESSAGE.")
    print(f"Over 25 messages: ~{saved * 25:,} tokens saved.")
    print(f"Over a full day (5 sessions): ~{saved * 125:,} tokens saved.")


if __name__ == "__main__":
    main()
