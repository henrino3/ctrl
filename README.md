<p align="center">
  <h1 align="center">🔁 CTRL — Close The Running Loop</h1>
  <p align="center"><strong>Make your AI coding agent test its own work. Automatically.</strong></p>
</p>

<p align="center">
  <a href="https://github.com/henrino3/ctrl/actions"><img src="https://img.shields.io/github/actions/workflow/status/henrino3/ctrl/ci.yml?branch=master&style=for-the-badge&label=CI" alt="CI Status"></a>
  <a href="https://www.npmjs.com/package/close-the-loop"><img src="https://img.shields.io/npm/v/close-the-loop?style=for-the-badge&logo=npm&color=CB3837" alt="npm version"></a>
  <a href="https://github.com/henrino3/ctrl/stargazers"><img src="https://img.shields.io/github/stars/henrino3/ctrl?style=for-the-badge&logo=github" alt="GitHub Stars"></a>
  <a href="https://github.com/henrino3/ctrl/blob/master/LICENSE"><img src="https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge" alt="MIT License"></a>
  <a href="https://superada.ai/blog/ctrl-testing-pyramid/"><img src="https://img.shields.io/badge/Blog-Read%20More-orange?style=for-the-badge" alt="Blog Post"></a>
</p>

<p align="center">
  <a href="#quick-start">Quick Start</a> · <a href="#the-problem">The Problem</a> · <a href="#the-4-layer-testing-pyramid">Testing Pyramid</a> · <a href="#installation">Installation</a> · <a href="#the-experiment">Experiment</a> · <a href="#supported-languages">Languages</a> · <a href="#the-prompt">Copy-Paste Prompt</a>
</p>

---

## Quick Start

Get CTRL running in any project in one command:

```bash
# Universal installer (auto-detects language)
curl -fsSL https://raw.githubusercontent.com/henrino3/ctrl/master/scripts/ctrl-bootstrap.sh | bash
```

```bash
# Or via npx (Node.js projects)
npx close-the-loop init
```

That's it. Your AI agent now knows how to test its own code. ✅

---

## The Problem

AI coding agents ship broken code because **they never check if it works.**

Traditional software testing assumes a human will run the tests. But when an AI agent writes code autonomously — in Cursor, Copilot, Claude Code, Codex, or OpenClaw — nobody is checking. The agent writes, commits, and moves on.

> *"Code works well with AI because it's verifiable. You can compile it, run it, test it. That's the loop. You have to close the loop."*
> — **Peter Steinberger**, creator of OpenClaw, who ships code he doesn't read and merged **600 commits in a single day**

**CTRL closes that loop.** It gives your agent the instructions, commands, and CI pipeline to verify its own work — without a human in the middle.

---

## The 4-Layer Testing Pyramid

```
                    ┌─────────────┐
                    │   🐳 Docker  │  Cold-start deployment
                    │    Tests     │  5-10 min · CI/CD
                    ├─────────────┤
                   │   🌐 Live     │  Real 3rd-party APIs
                   │    Tests      │  5-30 min · Pre-release
                   ├───────────────┤
                  │    🔗 E2E       │  Routes, auth, DB state
                  │     Tests       │  1-5 min · Before push
                  ├─────────────────┤
                 │     ⚡ Unit       │  Pure logic, validation
                 │      Tests        │  < 1 sec · Every commit
                 └───────────────────┘
```

| Layer | What it tests | Speed | Cost | Frequency |
|:------|:-------------|:------|:-----|:----------|
| ⚡ **Unit** | Pure functions, validation, parsing, security | < 1s | Free | Every commit |
| 🔗 **E2E** | API routes, auth flows, DB queries, webhooks | 1-5 min | Free | Before push |
| 🌐 **Live** | Real APIs (Stripe, OpenAI, etc.), rate limits | 5-30 min | $ | Pre-release |
| 🐳 **Docker** | Full cold-start in clean container | 5-10 min | Free | CI/CD |

> **Start with Unit.** It gives you 80% of the value at < 1% of the cost.

---

## Installation

### Option 1: Universal Installer (Recommended)

Works with **any language** — JS/TS, Python, Go, Rust, PHP, Ruby, Java, C#.

```bash
curl -fsSL https://raw.githubusercontent.com/henrino3/ctrl/master/scripts/ctrl-bootstrap.sh | bash
```

<details>
<summary>📦 What it creates</summary>

The installer auto-detects your project's language and generates:

| File | Purpose |
|:-----|:--------|
| `AGENTS.md` | Build, test, and gate commands for your AI agent |
| `TESTING.md` | What to test, what NOT to test, testing conventions |
| `copilot-instructions.md` | Anti-redundancy rules, colocated test pattern |
| `.cursorrules` / `.clauderc` | Editor-specific agent instructions |
| `.github/workflows/ctrl.yml` | CI/CD pipeline that enforces the gates |

</details>

### Option 2: npx (Node.js / TypeScript)

```bash
npx close-the-loop init
```

### Option 3: Manual Bootstrap

```bash
git clone https://github.com/henrino3/ctrl.git
cd ctrl
./scripts/ctrl-bootstrap.sh /path/to/your/project --mode mvp
```

<details>
<summary>⚙️ Manual package.json setup</summary>

```json
{
  "scripts": {
    "test:unit": "vitest run",
    "test:e2e": "playwright test",
    "test:live": "vitest run --config vitest.live.config.ts",
    "test:docker": "./scripts/ctrl-docker-smoke.sh",
    "ctrl:gate": "npm run build && npm run test:unit && npm run test:e2e",
    "ctrl:full": "npm run ctrl:gate && npm run test:live && npm run test:docker"
  },
  "ctrl": {
    "mode": "production"
  }
}
```

</details>

---

## Gates

Two gates keep your agent honest:

```bash
# ⚡ Fast gate — run before every push
npm run ctrl:gate    # build + unit + e2e

# 🏭 Full gate — run before release
npm run ctrl:full    # gate + live + docker
```

For Python: `pytest`, `tox`, etc. are configured automatically by the installer.

---

## MVP vs Production Mode

Not every project needs the same rigor.

| | MVP Mode | Production Mode |
|:---|:---------|:---------------|
| **Use for** | Demos, prototypes, rapid validation | Customer-facing, revenue-generating |
| **Unit tests** | Recommended | **Mandatory** |
| **E2E tests** | Optional | **Mandatory** |
| **Coverage** | None required | 60%+ critical paths |
| **Gate** | Build must pass | All gates must pass |

> **Rule of thumb:** If failure would damage relationships, revenue, or reputation → **Production**. Otherwise → **MVP**.

Set the mode:
```json
{ "ctrl": { "mode": "mvp" } }
```

---

## The Experiment

We didn't just build this — we **proved it catches bugs**.

### Setup
- **Project:** Entity (Next.js + TypeScript monorepo)
- **Tests written:** 64 across 3 files
- **Execution time:** < 500ms

### Method
1. Wrote comprehensive tests for 2 modules (64 tests)
2. Verified all pass ✅
3. **Introduced 6 deliberate bugs** — logic inversions, missing cases, off-by-ones, and a critical security bypass
4. Ran tests to see what gets caught

### Results

| # | Bug Introduced | Type | Caught? |
|:--|:--------------|:-----|:--------|
| 1 | `blog` type returns `'prd'` | Logic inversion | ✅ |
| 2 | Henry agent detection removed | Missing case | ✅ |
| 3 | Tag filter `>2` → `>3` | Off-by-one | ❌ |
| 4 | **Path traversal bypass** | 🚨 Security critical | ✅ |
| 5 | `'secret'` removed from redaction list | Missing config | ✅ |
| 6 | `assertSourceEnabled` inverted | Logic inversion | ✅ |

### Verdict: **5/6 bugs caught (83%)** ✅

The test caught a **critical security vulnerability** (path traversal bypass) that would have shipped silently without CTRL.

The one miss: a subtle off-by-one where we didn't test the boundary value. Lesson: always test boundaries.

📄 [Full Experiment Report →](experiments/ctl-001-entity-close-loop.md)

---

## Supported Languages

The universal installer auto-detects and configures:

| Language | Test Runner | Gate Command |
|:---------|:-----------|:-------------|
| JavaScript / TypeScript | Vitest, Jest, Mocha | `npm run ctrl:gate` |
| Python | pytest, unittest, tox | `pytest && tox` |
| Go | `go test` | `go test ./...` |
| Rust | `cargo test` | `cargo test` |
| PHP | PHPUnit | `phpunit` |
| Ruby | RSpec, Minitest | `rspec` / `rails test` |
| Java | JUnit, Maven, Gradle | `mvn test` / `gradle test` |
| C# / .NET | xUnit, NUnit | `dotnet test` |

---

## The 4 Files That Make It Work

| File | Purpose | Why It Matters |
|:-----|:--------|:---------------|
| **AGENTS.md** | Build, test, and dev commands | Agent knows *exactly* what commands to run |
| **TESTING.md** | What to test, conventions, anti-patterns | Agent knows *how* to write good tests |
| **copilot-instructions.md** | Colocated tests, anti-redundancy | Agent doesn't duplicate or skip |
| **package.json** / config | Gate scripts + mode setting | CI enforces the rules automatically |

> Peter Steinberger's OpenClaw has **1,376 test files** and a 21KB `AGENTS.md`. The pattern works at scale.

---

## The Rules

```
1. Colocated tests     → source.test.ts sits next to source.ts
2. Close the loop      → Write code → run tests → fix failures → don't ask the human
3. Full gate on push   → build + lint + test must all pass
4. Anti-redundancy     → Search for existing helpers before creating new ones
```

---

## The Prompt

Copy-paste this into any AI coding agent's system prompt:

<details>
<summary>📋 Click to expand the full prompt</summary>

```
You are working on my project which has a [YOUR STACK].

I want to implement the "Close the Loop" methodology, where you (the agent)
test and verify your own work autonomously via CLI commands, without needing
a human to check every change.

TESTING STRUCTURE
- Write a test file for every file you create or modify
- Colocate tests next to the source file they test
- Name them: source.test.ts next to source.ts
- Start with unit tests only

CLOSE THE LOOP
- After writing any code, run the tests via CLI before considering the task done
- If tests fail, fix the code and run again — do not ask me to check
- Only report back when tests are passing

COMMANDS TO RUN
- After writing code: run tests, linter, type checker
- Before any PR: run full gate (build + lint + test)
- Never push failing code

ANTI-REDUNDANCY
- Before creating any helper or utility, search for existing ones first
- If a function already exists, import it — do not duplicate it
- Extract shared test fixtures into test-helpers files when used in 3+ tests
```

</details>

---

## Integration with AI Agents

CTRL works with any agent that reads instruction files:

| Agent / Editor | How It Works |
|:--------------|:-------------|
| **OpenClaw / Pi** | Reads `AGENTS.md` automatically. Geordi adapter runs `ctrl:gate` after every task. |
| **Cursor** | Reads `.cursorrules` for project-level instructions. |
| **Claude Code** | Reads `AGENTS.md` and `.clauderc` in the project root. |
| **GitHub Copilot** | Reads `copilot-instructions.md` for workspace rules. |
| **Codex CLI** | Reads `AGENTS.md` for build/test commands. |

---

## Key Insights

1. **Speed matters.** If tests take > 1 minute, the loop is too slow. Ours run in < 500ms.
2. **Quality > Quantity.** 64 tests missed one bug because we didn't test boundaries. Edge cases are the differentiator.
3. **Colocated = discovered.** When tests sit next to source files, agents naturally find and run them.
4. **Security bugs get caught.** The most important bug in our experiment (path traversal) was caught instantly.
5. **It's not magic.** It works because code is *verifiable*. The agent can objectively check if its work is correct.

---

## Origin

This methodology was researched after **Henry Mascot** and **[Kinan Zayat](https://github.com/kinanzayat)** reverse-engineered **Peter Steinberger's** approach by studying the [OpenClaw codebase](https://github.com/openclaw/openclaw). Peter runs 3-8 AI agents in parallel and merged 600 commits in a single day — every agent writes tests, runs them, and only reports back when everything passes.

### References

- 📝 [Peter Steinberger — "Just Talk To It"](https://steipete.me/posts/just-talk-to-it)
- 🎙️ [The Pragmatic Engineer Podcast](https://newsletter.pragmaticengineer.com/p/the-creator-of-clawd-i-ship-code)
- 📖 [Blog Post — CTRL Testing Pyramid](https://superada.ai/blog/ctrl-testing-pyramid/)
- 🦞 [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- 📋 [Peter's AGENTS.md gist](https://gist.github.com/steipete/d3b9db3fa8eb1d1a692b7656217d8655)

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=henrino3/ctrl&type=Date)](https://star-history.com/#henrino3/ctrl&Date)

---

<p align="center">
  Built by the <strong>Enterprise Crew</strong> 🚀<br/>
  <sub>Ada 🔮 · Spock 🖖 · Scotty 🔧</sub>
</p>

<p align="center">
  <sub>MIT License · <a href="https://superada.ai">superada.ai</a></sub>
</p>
