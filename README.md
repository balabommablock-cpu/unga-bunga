# unga bunga

**Every message you send to Claude Code has a hidden tax. You've just never seen the bill.**

Your `CLAUDE.md` is silently loaded on every single message — all of it, every time. Your memory files. Your skills. Your growing conversation history. Before Claude even reads your question, it's already consumed thousands of tokens you didn't ask for and can't see.

Most people have no idea how much this costs. We built a tool that shows you.

Then we built tools that fix it.

## See it for yourself

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/balabommablock-cpu/unga-bunga/main/install.sh)
```

The first thing it does is audit your current setup:

```
=== UNGA BUNGA TOKEN AUDIT ===

--- CLAUDE.md files (loaded EVERY message) ---
  ./CLAUDE.md
    287 lines | ~3,530 tokens per message

--- Memory files ---
  MEMORY.md index: ~186 tokens (loaded every message)
  8 memory files | ~2,602 tokens total

=== PER-MESSAGE OVERHEAD ===
  Fixed cost (every message): ~3,716 tokens

=== COST ESTIMATE ===
  Per message:   $0.01
  Per session:   $0.28
  Per month:     $30.66
```

That's $30/month in context overhead alone. Before you've written a single line of code. Before Claude has answered a single question.

And that's just one project.

## What this actually is

Three tools, one insight: **the biggest token cost isn't what Claude says — it's what Claude reads.**

### 1. The Audit

```bash
./tools/audit.sh /path/to/your/project
```

X-ray vision for your Claude Code token spend. Finds every `CLAUDE.md` in your project hierarchy, counts your memory files, measures your skills, and tells you exactly what you're paying per message, per session, per month. Most people run this once and immediately start pruning.

### 2. The Compressor

```bash
# Rule-based, no API needed
python3 tools/compress.py ./CLAUDE.md

# AI-powered for deeper compression
python3 tools/compress.py ./CLAUDE.md --deep

# Preview before touching anything
python3 tools/compress.py ./CLAUDE.md --dry-run
```

Shrinks your `CLAUDE.md` while preserving every behavioral rule, every constraint, every technical spec. Strips the prose, collapses the tables, kills the filler. Backs up your original automatically.

Fast mode gets 15-30% reduction. Deep mode (uses Claude API) gets 40-60%.

That 30% on a 3,500-token file? That's 1,000 tokens saved on **every single message** for the rest of the project's life.

### 3. The Skill

A 50-token instruction that makes Claude stop wasting your output tokens:

```
Direct answers only. No preambles, no transitions, no post-action summaries.
Never restate the question. One sentence when one works. After file edits,
say nothing unless there's an error. Read files with offset+limit.
Grep with files_with_matches before content mode.
```

No broken grammar. No weird caveman syntax. Just a Claude that gets to the point and uses its tools efficiently.

### 4. Honest Benchmarks

```bash
pip install anthropic
python3 benchmarks/run.py
```

Measures **actual API token counts** across 5 prompt types. Not word counts. Not estimates. Real `usage.input_tokens` and `usage.output_tokens` from the API response.

## The optimization stack, ranked by real impact

| Rank | What | Why |
|------|------|-----|
| 1 | **Compress CLAUDE.md** | Loaded every message. Biggest fixed cost. |
| 2 | **`/clear` between tasks** | Conversation history is the #1 token consumer by message 20. |
| 3 | **Prune memory files** | Delete stale entries. Keep index under 20 lines. |
| 4 | **Read with ranges** | `offset: 50, limit: 100` instead of reading 2,000 lines. |
| 5 | **Grep smart** | `files_with_matches` first, then targeted content reads. |
| 6 | **Fresh sessions** | By message 30, you're carrying 50K+ tokens of dead context. |
| 7 | **Terse output** | The skill handles this — 50 tokens of instruction, not 300. |

Most optimization advice focuses on #7. The actual money is in #1 through #4.

## The free version

Not ready to install anything? Add this single line to your `CLAUDE.md`:

```
No preambles, summaries, or filler. After edits, say nothing unless there's an error.
```

20 tokens of instruction. Eliminates the "Let me read that file for you..." and "Here's a summary of what I changed..." fluff that burns hundreds of output tokens per session.

You'll feel the difference immediately.

## Install

**One command:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/balabommablock-cpu/unga-bunga/main/install.sh)
```

**Or clone and use directly:**

```bash
git clone https://github.com/balabommablock-cpu/unga-bunga.git
cd unga-bunga
bash tools/audit.sh /path/to/your/project
python3 tools/compress.py /path/to/your/CLAUDE.md
cp SKILL.md ~/.claude/skills/unga-bunga.md
```

No dependencies for the audit and compressor. The benchmark script needs `pip install anthropic`. That's it.

## Why "unga bunga"

Because the smartest optimization is the dumbest one: stop feeding Claude things it doesn't need to read. No fancy prompt engineering. No grammar hacks. Just measure what goes in, cut what doesn't earn its tokens, and move on.

Sometimes the right move is the obvious one.

## License

MIT
