#!/usr/bin/env bash
# unga-bunga audit — shows where your Claude Code tokens actually go
# Usage: ./tools/audit.sh [project-dir]

set -euo pipefail

PROJECT_DIR="${1:-.}"
CLAUDE_HOME="${HOME}/.claude"

# Token estimation: ~1 token per 4 chars (cl100k_base average for English)
estimate_tokens() {
  local file="$1"
  if [[ -f "$file" ]]; then
    local chars
    chars=$(wc -c < "$file" | tr -d ' ')
    echo $(( chars / 4 ))
  else
    echo 0
  fi
}

format_cost() {
  # Claude Sonnet: $3/M input tokens. Opus: $15/M input tokens.
  # Using $3/M as baseline (most common)
  local tokens=$1
  local cost_per_1k
  cost_per_1k=$(echo "scale=6; $tokens * 3 / 1000000" | bc 2>/dev/null || echo "0")
  echo "\$${cost_per_1k}"
}

echo ""
echo "=== UNGA BUNGA TOKEN AUDIT ==="
echo "Project: $(cd "$PROJECT_DIR" && pwd)"
echo ""

total_per_message=0

# --- CLAUDE.md files (loaded every message) ---
echo "--- CLAUDE.md files (loaded EVERY message) ---"
echo ""

# Check project CLAUDE.md
if [[ -f "${PROJECT_DIR}/CLAUDE.md" ]]; then
  tokens=$(estimate_tokens "${PROJECT_DIR}/CLAUDE.md")
  total_per_message=$((total_per_message + tokens))
  lines=$(wc -l < "${PROJECT_DIR}/CLAUDE.md" | tr -d ' ')
  echo "  ${PROJECT_DIR}/CLAUDE.md"
  echo "    ${lines} lines | ~${tokens} tokens per message"
else
  echo "  No CLAUDE.md found in project root"
fi

# Check parent CLAUDE.md files
dir="$PROJECT_DIR"
while [[ "$dir" != "/" ]]; do
  dir=$(dirname "$dir")
  if [[ -f "${dir}/CLAUDE.md" ]]; then
    tokens=$(estimate_tokens "${dir}/CLAUDE.md")
    total_per_message=$((total_per_message + tokens))
    lines=$(wc -l < "${dir}/CLAUDE.md" | tr -d ' ')
    echo "  ${dir}/CLAUDE.md"
    echo "    ${lines} lines | ~${tokens} tokens per message"
  fi
done

# Check user-level CLAUDE.md
if [[ -f "${CLAUDE_HOME}/CLAUDE.md" ]]; then
  tokens=$(estimate_tokens "${CLAUDE_HOME}/CLAUDE.md")
  total_per_message=$((total_per_message + tokens))
  lines=$(wc -l < "${CLAUDE_HOME}/CLAUDE.md" | tr -d ' ')
  echo "  ${CLAUDE_HOME}/CLAUDE.md"
  echo "    ${lines} lines | ~${tokens} tokens per message"
fi

echo ""

# --- Memory files ---
echo "--- Memory files (loaded on relevance) ---"
echo ""

memory_total=0
memory_count=0

# Project-level memory
project_slug=$(cd "$PROJECT_DIR" && pwd | sed 's|/|-|g')
project_memory="${CLAUDE_HOME}/projects/${project_slug}/memory"

if [[ -d "$project_memory" ]]; then
  for f in "$project_memory"/*.md; do
    if [[ -f "$f" ]]; then
      tokens=$(estimate_tokens "$f")
      memory_total=$((memory_total + tokens))
      memory_count=$((memory_count + 1))
    fi
  done
fi

# MEMORY.md index
if [[ -f "$project_memory/MEMORY.md" ]]; then
  idx_tokens=$(estimate_tokens "$project_memory/MEMORY.md")
  total_per_message=$((total_per_message + idx_tokens))
  echo "  MEMORY.md index: ~${idx_tokens} tokens (loaded every message)"
fi

echo "  ${memory_count} memory files | ~${memory_total} tokens total"
echo "  (loaded selectively, not all at once)"
echo ""

# --- Skills ---
echo "--- Skills (loaded when matched) ---"
echo ""

skill_total=0
skill_count=0

if [[ -d "${CLAUDE_HOME}/skills" ]]; then
  for f in "${CLAUDE_HOME}/skills"/*.md; do
    if [[ -f "$f" ]]; then
      tokens=$(estimate_tokens "$f")
      skill_total=$((skill_total + tokens))
      skill_count=$((skill_count + 1))
      name=$(basename "$f")
      echo "  ${name}: ~${tokens} tokens"
    fi
  done
fi

# Project-level skills
if [[ -d "${PROJECT_DIR}/.claude/skills" ]]; then
  for f in "${PROJECT_DIR}/.claude/skills"/*.md; do
    if [[ -f "$f" ]]; then
      tokens=$(estimate_tokens "$f")
      skill_total=$((skill_total + tokens))
      skill_count=$((skill_count + 1))
      name=$(basename "$f")
      echo "  ${name} (project): ~${tokens} tokens"
    fi
  done
fi

if [[ $skill_count -eq 0 ]]; then
  echo "  No skills installed"
fi
echo "  ${skill_count} skills | ~${skill_total} tokens total"
echo ""

# --- Summary ---
echo "=== PER-MESSAGE OVERHEAD ==="
echo ""
echo "  Fixed cost (every message): ~${total_per_message} tokens"

# Estimate messages per session
avg_messages=25
session_input=$((total_per_message * avg_messages))
echo "  Avg session (${avg_messages} msgs):    ~${session_input} tokens"
echo ""

# Cost estimate
echo "=== COST ESTIMATE (input tokens only) ==="
echo ""
echo "  Per message:  $(format_cost $total_per_message)"
echo "  Per session:  $(format_cost $session_input)"

daily_sessions=5
daily=$((session_input * daily_sessions))
monthly=$((daily * 22))
echo "  Per day (${daily_sessions} sessions): $(format_cost $daily)"
echo "  Per month (22 days):  $(format_cost $monthly)"
echo ""

# --- Recommendations ---
echo "=== TOP OPTIMIZATIONS ==="
echo ""

if [[ $total_per_message -gt 2000 ]]; then
  echo "  [!] CLAUDE.md is ${total_per_message}+ tokens — compress it"
  echo "      Run: python3 tools/compress.py ${PROJECT_DIR}/CLAUDE.md"
fi

if [[ $memory_count -gt 10 ]]; then
  echo "  [!] ${memory_count} memory files — prune stale entries"
fi

if [[ $skill_total -gt 500 ]]; then
  echo "  [!] Skills add ${skill_total} tokens — review if all are needed"
fi

echo "  [*] Use /clear between unrelated tasks"
echo "  [*] Start fresh sessions for new work"
echo "  [*] Read files with offset+limit, not full reads"
echo ""
