# CTRL — Close The Running Loop

> **C**lose **T**he **R**unning **L**oop

A practical guide to **Peter Steinberger's "Close the Loop"** methodology for autonomous AI agent coding — with a real experiment proving it works.

![Peter explaining Close the Loop](peter-close-the-loop.gif)

## What is "Close the Loop"?

The idea is simple: **give your coding agent the ability to verify its own work.**

Peter Steinberger (creator of OpenClaw/Clawdbot, founder of PSPDFKit) ships code he doesn't read. He runs 3-8 AI coding agents in parallel and merged **600 commits in a single day**. The secret? Every agent writes tests, runs them, fixes failures, and only reports back when everything passes. No human in the loop for verification.

> *"Code works well with AI because it's verifiable. You can compile it, run it, test it. That's the loop. You have to close the loop."*
> — Peter Steinberger

## The Method

### 4 Files That Make It Work

| File | Purpose | Size in OpenClaw |
|------|---------|-----------------|
| **AGENTS.md** | Build, test, and dev commands | 21KB |
| **TESTING.md** | What to test, what NOT to test, how to test | 19KB |
| **copilot-instructions.md** | Anti-redundancy rules, colocated test pattern | 2KB |
| **package.json** | Scripts: `test`, `test:coverage`, `test:e2e` | - |

### 4-Layer Testing Pyramid

Start at the bottom. Each layer adds realism — and cost.

```
         ┌──────────┐
         │  Docker   │  Full app in container, cold-start
         │  Tests    │  Slowest, most realistic
         ├──────────┤
         │   Live    │  Real API calls (Stripe, Anthropic, etc.)
         │  Tests    │  Costs money, flaky (network/rate limits)
         ├──────────┤
         │   E2E     │  API routes, webhooks, request/response
         │  Tests    │  Minutes, catches integration bugs
         ├──────────┤
         │   Unit    │  Pure logic, validation, security
         │  Tests    │  Seconds, catches 80% of bugs
         └──────────┘
```

| Layer | What it tests | Speed | Cost | When to use |
|-------|--------------|-------|------|-------------|
| **Unit** | Pure functions, logic, validation, security | <1s | Free | Every commit |
| **E2E** | API routes, webhooks, auth flows, DB queries | 1-5 min | Free | Before push |
| **Live** | Real third-party APIs (Stripe, OpenAI, etc.) | 5-30 min | $ (API calls) | Before release |
| **Docker** | Full app cold-start in clean container | 5-10 min | Free | CI/CD pipeline |

**Where to start:** Unit tests. They give you 80% of the value at <1% of the cost. Peter's OpenClaw has 1,376 test files and unit tests are the foundation.

**When to add E2E:** When you have API routes that handle auth, data mutation, or external integrations. Tests like "does POST /api/tasks return 201?" catch a different class of bugs than unit tests.

**When to add Live:** Only when you integrate with third-party APIs and need to verify they haven't changed their format/behavior. These are expensive and flaky — run them manually or before releases, not on every commit.

**When to add Docker:** When you deploy to production and want to verify the entire app starts cleanly from scratch. Good for CI/CD pipelines.

### The Rules

1. **Colocated tests** — Every source file gets a `.test.ts` right next to it
2. **Close the loop** — After writing code, run tests. If they fail, fix. Don't ask the human.
3. **Full gate before push** — `build + lint + test` must all pass
4. **Anti-redundancy** — Search for existing helpers before creating new ones


### MVP vs Production Mode

Not all projects need the same rigor. CTRL defines two operational modes:

#### 1. MVP Mode (Fast Demo)
**Use for:** Demos, prototypes, proof of concepts, rapid validation
- Unit tests recommended but not mandatory
- E2E tests optional
- No coverage requirements
- Build must pass
- Deploy fast, iterate fast

#### 2. Production Mode (Factory)
**Use for:** Customer-facing deployments, revenue-generating products, contractual deliverables
- Unit tests **mandatory** for all new/changed code
- E2E tests **mandatory** for user flows
- Coverage target: 60%+ for critical paths
- All gates must pass before deploy

*Rule of thumb: If failure would damage relationships, revenue, or reputation → use **Production mode**. Otherwise, **MVP mode** is fine.*

### How to Set It Up

You can instantly install the CTRL framework into any project. The installer automatically detects your environment (Node.js, Python, Go, or Rust) and sets up `AGENTS.md`, `TESTING.md`, and your GitHub Actions CI pipeline.

#### Option 1: Universal Installer (Mac/Linux)
Best for Python, Go, Rust, and polyglot codebases.
```bash
curl -fsSL https://raw.githubusercontent.com/henrino3/ctrl/master/scripts/ctrl-bootstrap.sh | bash -s -- .
```

#### Option 2: NPM (JS/TS Projects)
Best for Node.js, Next.js, and frontend codebases.
```bash
npx close-the-loop
```

If you prefer to scaffold it manually:
```bash
# Clone this repo and run the bootstrap script against your project
./scripts/ctrl-bootstrap.sh /path/to/your/project --mode mvp
```

This will automatically create:
1. `AGENTS.md` (Build/test/gate commands for the agent)
2. `TESTING.md` (Testing conventions)
3. `copilot-instructions.md` (Agent behavioral rules)

Alternatively, you can configure CTRL manually in your project's `package.json`:

```json
{
  "scripts": {
    "test:unit": "vitest run",
    "test:e2e": "playwright test",
    "ctrl:gate": "npm run build && npm run test:unit",
    "ctrl:full": "npm run ctrl:gate && npm run test:e2e"
  },
  "ctrl": {
    "mode": "production"
  }
}
```

**Integration with AI Agents (e.g., OpenClaw/Geordi):**
Instruct your agent (via `AGENTS.md` or system prompt) to automatically run `npm run ctrl:gate` after writing code. If the gate fails, the agent must read the error output and fix the code before marking the task complete.

## Evidence From OpenClaw's Codebase

We analyzed the [OpenClaw GitHub repo](https://github.com/openclaw/openclaw):

- **1,376 test files** across the codebase
- **563 source files** with colocated `.test.ts` files
- Largest test files are **45-65KB** — real tests, not stubs
- Recent commits consistently pair source changes with test changes

## The Prompt

Here's a ready-to-use prompt for your coding agent (adapt the stack):

```
You are working on my project which has a [YOUR STACK].
We currently have zero tests.

I want to implement Peter Steinberger's "Close the Loop" methodology, where the agent
(you) can test and verify your own work autonomously via CLI commands, without needing
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
- Extract shared test fixtures into test-helpers files when used in multiple tests
```

## Experiment 1: Does It Actually Work?

We didn't just implement this — we **tested whether the tests actually catch bugs**.

📄 **[Full Experiment Report →](experiments/ctl-001-entity-close-loop.md)**

### Setup

- **Project:** Entity (Next.js + TypeScript monorepo)
- **Test runner:** Vitest
- **Modules tested:** `classify.ts` (file classification) and `security.ts` (path security)
- **Total tests written:** 64 across 3 files
- **Test execution time:** <500ms

### Method

1. Wrote comprehensive tests for 2 modules (64 tests total)
2. Verified all tests pass (baseline)
3. **Introduced 6 deliberate bugs** — mix of logic inversions, missing cases, off-by-ones, and a critical security bypass
4. Ran tests to see how many bugs get caught

### Results

| # | Bug | Type | Caught? |
|---|-----|------|---------|
| 1 | `blog` type returns `'prd'` | Logic inversion | ✅ |
| 2 | Henry agent detection removed | Missing case | ✅ |
| 3 | Tag filter `>2` → `>3` | Off-by-one | ❌ |
| 4 | **Path traversal bypass** | Security critical | ✅ |
| 5 | 'secret' removed from redaction list | Missing config | ✅ |
| 6 | `assertSourceEnabled` inverted | Logic inversion | ✅ |

### Verdict: **5/6 bugs caught (83%) — STRONG PASS** ✅

The tests caught:
- Both logic inversions
- A missing code path
- A **critical security vulnerability** (path traversal bypass)
- A missing configuration entry

The one it missed: a subtle off-by-one where the test wasn't testing the boundary value. **Lesson: test boundary values, not just happy paths.**

## Key Insights

1. **Speed matters.** If tests take >1 minute, the loop is too slow. Our tests run in <500ms.
2. **Quality > Quantity.** 64 tests missed one bug because we didn't test the boundary value. Edge cases are the critical differentiator.
3. **Colocated = discovered.** When tests sit next to source files, agents naturally find and run them.
4. **Security bugs get caught.** The most important bug in our experiment (path traversal bypass) was caught immediately.
5. **It's not magic.** Close the loop works because code is *verifiable*. The agent can objectively check if its work is correct.

## Origin

This methodology was researched after a conversation between Henry Mascot and [Kinan Zayat](https://github.com/kinanzayat), who reverse-engineered Peter Steinberger's approach by studying the OpenClaw codebase. Kinan identified the 4-file pattern and adapted it for his own Next.js stack.

### References

- [Peter Steinberger's blog: "Just Talk To It"](https://steipete.me/posts/just-talk-to-it)
- [The Pragmatic Engineer Podcast interview](https://newsletter.pragmaticengineer.com/p/the-creator-of-clawd-i-ship-code)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [Peter's AGENTS.md gist](https://gist.github.com/steipete/d3b9db3fa8eb1d1a692b7656217d8655)

## License

MIT — use this however you want.
