#!/usr/bin/env bash
# unga-bunga installer
# bash <(curl -fsSL https://raw.githubusercontent.com/balabommablock-cpu/unga-bunga/main/install.sh)

set -euo pipefail

REPO="https://github.com/balabommablock-cpu/unga-bunga"
CLAUDE_HOME="${HOME}/.claude"
SKILL_DIR="${CLAUDE_HOME}/skills"
TOOL_DIR="${CLAUDE_HOME}/unga-bunga"

echo ""
echo "  UNGA BUNGA"
echo "  Token optimizer for Claude Code"
echo ""

# Create directories
mkdir -p "$SKILL_DIR" "$TOOL_DIR"

# Download skill
echo "  Installing skill..."
if command -v curl &>/dev/null; then
  curl -fsSL "${REPO}/raw/main/SKILL.md" -o "${SKILL_DIR}/unga-bunga.md"
elif command -v wget &>/dev/null; then
  wget -q "${REPO}/raw/main/SKILL.md" -O "${SKILL_DIR}/unga-bunga.md"
else
  echo "Error: curl or wget required"
  exit 1
fi

# Download tools
echo "  Installing tools..."
for tool in compress.py audit.sh; do
  if command -v curl &>/dev/null; then
    curl -fsSL "${REPO}/raw/main/tools/${tool}" -o "${TOOL_DIR}/${tool}"
  else
    wget -q "${REPO}/raw/main/tools/${tool}" -O "${TOOL_DIR}/${tool}"
  fi
done

chmod +x "${TOOL_DIR}/audit.sh"

echo ""
echo "  Installed:"
echo "    Skill  → ${SKILL_DIR}/unga-bunga.md"
echo "    Tools  → ${TOOL_DIR}/"
echo ""
echo "  Usage:"
echo "    Audit your setup:      ${TOOL_DIR}/audit.sh"
echo "    Compress CLAUDE.md:    python3 ${TOOL_DIR}/compress.py ./CLAUDE.md"
echo ""

# Run audit if in a project
if [[ -f "CLAUDE.md" ]] || [[ -f "${CLAUDE_HOME}/CLAUDE.md" ]]; then
  echo "  Running audit on current setup..."
  echo ""
  bash "${TOOL_DIR}/audit.sh" "$(pwd)"
fi
