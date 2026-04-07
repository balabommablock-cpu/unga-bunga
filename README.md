# unga bunga

**Save up to 72% of your Claude Code token spend. Not by making Claude talk like a caveman. By fixing the 85% of waste nobody tells you about.**

Your `CLAUDE.md` is a gym membership you forgot to cancel. Except it charges you every message.

You wrote a beautiful, 300-line `CLAUDE.md`. Design tokens. Architecture decisions. Personality instructions. A manifesto, really. You're proud of it.

Claude reads the whole thing. Every. Single. Message.

"Fix this typo" — that'll be 3,500 tokens of context first, please.
"Add a comma" — let me just load your entire database schema real quick.
"What's 2+2?" — hold on, I need to read your design philosophy first.

You're not paying for intelligence. You're paying for Claude to re-read your diary 40 times a session.

## Run this. I dare you.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/balabommablock-cpu/unga-bunga/main/install.sh)
```

It audits your setup and shows you a number you've never seen before:

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

$30/month. In overhead. Before Claude has done a single useful thing for you. That's a Netflix subscription for the privilege of Claude knowing you prefer Cormorant Garamond.

And that's one project. You have seven.

## The math

| Layer | What's wasted | Savings | How |
|-------|--------------|---------|-----|
| CLAUDE.md bloat | ~3,500 tokens/msg | **40-60%** | Compressor strips prose, collapses tables |
| Output verbosity | ~200 tokens/response | **50-70%** | 50-token skill kills preambles & summaries |
| Tool call waste | ~800 tokens/call | **60-80%** | Read ranges, grep smart, skip re-reads |
| Stale memory | ~500 tokens/msg | **100%** | Audit finds it, you delete it |
| **Combined** | | **up to 72%** | All three tools working together |

That's not a made-up number. Run the audit. Run the benchmarks. Check the receipts.

## What's in the box

Three tools. No philosophy. No 47-page prompt engineering thesis. Just tools.

### The Audit — "oh no"

```bash
./tools/audit.sh /path/to/your/project
```

Finds every `CLAUDE.md` in your project hierarchy (yes, they stack), counts your memory files, measures your skills, and shows you the per-message tax. It's like checking your screen time — you'll feel attacked, but you needed to know.

### The Compressor — "oh thank god"

```bash
python3 tools/compress.py ./CLAUDE.md               # fast, no API
python3 tools/compress.py ./CLAUDE.md --deep         # AI-powered
python3 tools/compress.py ./CLAUDE.md --dry-run      # just looking
```

Your `CLAUDE.md` has opinions about typography. It has example conversations. It has a table explaining what "contextual copy" means. Claude already knows what contextual copy means. It's a language model. That's literally its whole thing.

The compressor strips the prose, collapses the tables, kills the filler — keeps every rule that actually changes Claude's behavior. Backs up your original because we're not monsters.

Fast mode: 15-30% smaller. Deep mode: 40-60%. On a heavy CLAUDE.md, that's **1,400-2,100 tokens you stop paying for. Every message. Forever.** Multiply that by 40 messages a session. Multiply that by 5 sessions a day. Now multiply that by the fact that you feel nothing because nothing changed except your bill.

### The Skill — 50 tokens that mass replace 300

```
Direct answers only. No preambles, no transitions, no post-action summaries.
Never restate the question. One sentence when one works. After file edits,
say nothing unless there's an error. Read files with offset+limit.
Grep with files_with_matches before content mode.
```

Stops Claude from doing the thing where it reads a file and then writes you a paragraph about how it read the file. We know, Claude. We asked you to read it. We were there.

Also teaches Claude to stop reading 2,000-line files when it needs line 47. Which — and I cannot stress this enough — is something it does constantly.

### Honest Benchmarks

```bash
pip install anthropic
python3 benchmarks/run.py
```

Measures real `usage.input_tokens` and `usage.output_tokens` from the API. Not word counts. Not vibes. Tokens. The things you actually pay for.

## The actual priority list

Everyone optimizes #7. The money is in #1.

| # | Do this | Because |
|---|---------|---------|
| 1 | **Compress your CLAUDE.md** | It's loaded every message. It's the cover charge at the world's most expensive club. |
| 2 | **`/clear` between tasks** | By message 20, conversation history is the main character. |
| 3 | **Prune stale memory files** | That memory about a bug you fixed in February? Still riding along. Every message. |
| 4 | **Read files with ranges** | `offset: 50, limit: 100` — not the full 2,000 lines, Claude, please. |
| 5 | **Grep before you read** | `files_with_matches` first. Don't dump 500 lines to find one function name. |
| 6 | **Start fresh sessions** | Message 30+ means 50K+ tokens of "remember when we tried that thing that didn't work?" |
| 7 | **Terse output** | The skill handles this. 50 tokens of instruction. Done. |

## The "I'm not installing anything" version

Fine. Add this one line to your `CLAUDE.md`:

```
No preambles, summaries, or filler. After edits, say nothing unless there's an error.
```

20 tokens. Kills the "Let me read that file for you..." and "Here's a summary of the changes I made..." monologues. Claude talks less, you pay less, everyone's happier.

It's like telling your coworker they don't need to narrate their screen share.

## Install

**One command:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/balabommablock-cpu/unga-bunga/main/install.sh)
```

**Or the manual way, for the trust-issue crowd:**

```bash
git clone https://github.com/balabommablock-cpu/unga-bunga.git
cd unga-bunga
bash tools/audit.sh /path/to/your/project
python3 tools/compress.py /path/to/your/CLAUDE.md
cp SKILL.md ~/.claude/skills/unga-bunga.md
```

No dependencies. The benchmark script needs `pip install anthropic`. That's it. We didn't build a framework. We built a wrench.

## Why "unga bunga"

Because the smartest optimization in the world is the stupidest one: stop making Claude read things it doesn't need to read.

No prompt engineering PhD required. No grammar hacks. No making Claude talk like a telegram from 1943. Just: measure the waste, cut the waste, go write code.

The future of AI cost optimization is a shell script and common sense.

You're overthinking it. We're underthinking it. Guess who's saving money.

## License

MIT — do whatever you want with it. It's a shell script and a Python file, not the crown jewels.
