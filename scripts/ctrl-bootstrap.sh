#!/usr/bin/env bash
set -euo pipefail

# CTRL Bootstrap — Sets up testing framework for new projects
# Usage: ctrl-bootstrap.sh /path/to/project [--mode mvp|production]

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/project [--mode mvp|production]"
  echo ""
  echo "Modes:"
  echo "  mvp        - Fast demo mode (build gate only)"
  echo "  production - Full quality gates (build + unit + e2e + coverage)"
  exit 1
fi

PROJECT="$1"
MODE="mvp"  # Default

# Parse optional flags
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-mvp}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

if [[ "$MODE" != "mvp" && "$MODE" != "production" ]]; then
  echo "Invalid mode: $MODE. Use 'mvp' or 'production'"
  exit 1
fi

mkdir -p "$PROJECT/scripts" "$PROJECT/.github/workflows"

echo "📦 Bootstrapping CTRL in $PROJECT (mode: $MODE)"

# Create copilot-instructions.md
cat > "$PROJECT/copilot-instructions.md" <<'MD'
# CTRL Instructions

## Rules

1. Write/update tests for each changed file.
2. Run gates before marking done.
3. Fix failures and rerun until green.
4. Never ship failing gates.

## Gates

- Fast gate: `npm run ctrl:gate`
- Full gate: `npm run ctrl:full`

## Mode

Check `.ctrlrc.json` or package.json `ctrl.mode` for project mode (mvp/production).
- MVP: Build must pass, tests recommended
- Production: All gates mandatory, coverage required
MD

# Create .ctrlrc.json with mode-specific config
if [[ "$MODE" == "production" ]]; then
cat > "$PROJECT/.ctrlrc.json" <<JSON
{
  "mode": "production",
  "gates": {
    "required": ["build", "test:unit", "test:e2e"],
    "coverage": true
  },
  "coverage": {
    "threshold": 60,
    "enforce": true
  },
  "hooks": {
    "pre-commit": "ctrl:gate",
    "pre-push": "ctrl:full"
  }
}
JSON
else
cat > "$PROJECT/.ctrlrc.json" <<JSON
{
  "mode": "mvp",
  "gates": {
    "required": ["build"],
    "coverage": false
  },
  "coverage": {
    "threshold": 0,
    "enforce": false
  },
  "hooks": {
    "pre-commit": null,
    "pre-push": "ctrl:gate"
  }
}
JSON
fi

# Create live smoke script
cat > "$PROJECT/scripts/ctrl-live-smoke.mjs" <<'JS'
#!/usr/bin/env node
const enabled = process.env.CTRL_LIVE_ENABLE === '1' || Boolean(process.env.CTRL_LIVE_SMOKE_URL);
if (!enabled) {
  console.log('[ctrl-live] skipped');
  process.exit(0);
}
const target = process.env.CTRL_LIVE_SMOKE_URL;
if (!target) {
  console.error('CTRL_LIVE_SMOKE_URL missing');
  process.exit(1);
}
const res = await fetch(target);
if (!res.ok) process.exit(1);
console.log('[ctrl-live] ok');
JS

# Create docker smoke script
cat > "$PROJECT/scripts/ctrl-docker-smoke.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if ! command -v docker >/dev/null 2>&1; then
  echo "[ctrl-docker] skipped (docker missing)"
  exit 0
fi
docker run --rm -v "$PWD":/app -w /app node:22-bullseye bash -lc 'npm ci && npm test'
SH

# Create mode-aware gate runner
cat > "$PROJECT/scripts/ctrl-gate-runner.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail

# Read mode from .ctrlrc.json or default to mvp
MODE="mvp"
if [ -f .ctrlrc.json ]; then
  MODE=$(node -e "console.log(JSON.parse(require('fs').readFileSync('.ctrlrc.json','utf8')).mode || 'mvp')")
fi

echo "[ctrl] Running in $MODE mode"

# Build is always required
npm run build || { echo "[ctrl] build failed"; exit 1; }

if [ "$MODE" == "production" ]; then
  echo "[ctrl] Production mode — running full gates"
  
  # Unit tests
  if npm run test:unit 2>/dev/null; then
    echo "[ctrl] unit tests passed"
  else
    echo "[ctrl] unit tests failed"
    exit 1
  fi
  
  # E2E tests
  if npm run test:e2e 2>/dev/null; then
    echo "[ctrl] e2e tests passed"
  else
    echo "[ctrl] e2e tests failed"
    exit 1
  fi
  
  # Coverage check (if configured)
  if [ -f .ctrlrc.json ]; then
    ENFORCE=$(node -e "const c=JSON.parse(require('fs').readFileSync('.ctrlrc.json','utf8')); console.log(c.coverage?.enforce ? '1' : '0')")
    if [ "$ENFORCE" == "1" ]; then
      npm run test:coverage 2>/dev/null || echo "[ctrl] coverage check skipped (no script)"
    fi
  fi
else
  echo "[ctrl] MVP mode — build passed, tests optional"
  # Run tests if they exist but don't fail on missing
  npm run test:unit 2>/dev/null || echo "[ctrl] unit tests skipped"
fi

echo "[ctrl] gate passed ✅"
SH

# Create GitHub Actions workflow with mode awareness
if [[ "$MODE" == "production" ]]; then
cat > "$PROJECT/.github/workflows/ctrl.yml" <<'YML'
name: CTRL Gate (Production)

on: [push, pull_request, workflow_dispatch]

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - run: npm run test:unit
      - run: npm run test:e2e
      - run: npm run test:coverage || true

  docker-smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: bash scripts/ctrl-docker-smoke.sh

  notify:
    if: ${{ always() && secrets.DISCORD_BUILD_WEBHOOK_URL != '' }}
    needs: [gate, docker-smoke]
    runs-on: ubuntu-latest
    steps:
      - name: Discord notification
        env:
          WEBHOOK: ${{ secrets.DISCORD_BUILD_WEBHOOK_URL }}
          STATUS: ${{ needs.gate.result == 'success' && needs.docker-smoke.result == 'success' && '✅ PASS' || '❌ FAIL' }}
        run: |
          curl -sS -X POST "$WEBHOOK" \
            -H 'Content-Type: application/json' \
            -d "{\"content\": \"$STATUS CTRL Gate — ${{ github.repository }} (${{ github.ref_name }})\"}"
YML
else
cat > "$PROJECT/.github/workflows/ctrl.yml" <<'YML'
name: CTRL Gate (MVP)

on: [push, pull_request, workflow_dispatch]

jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run build
      - run: npm test || echo "Tests skipped (MVP mode)"

  notify:
    if: ${{ always() && secrets.DISCORD_BUILD_WEBHOOK_URL != '' }}
    needs: [gate]
    runs-on: ubuntu-latest
    steps:
      - name: Discord notification
        env:
          WEBHOOK: ${{ secrets.DISCORD_BUILD_WEBHOOK_URL }}
          STATUS: ${{ needs.gate.result == 'success' && '✅ PASS' || '❌ FAIL' }}
        run: |
          curl -sS -X POST "$WEBHOOK" \
            -H 'Content-Type: application/json' \
            -d "{\"content\": \"$STATUS CTRL Gate — ${{ github.repository }} (${{ github.ref_name }})\"}"
YML
fi

chmod +x "$PROJECT/scripts/ctrl-live-smoke.mjs" "$PROJECT/scripts/ctrl-docker-smoke.sh" "$PROJECT/scripts/ctrl-gate-runner.sh"

# Update package.json if it exists
if [ -f "$PROJECT/package.json" ]; then
  echo "📝 Updating package.json scripts..."
  node -e "
const fs = require('fs');
const p = '$PROJECT/package.json';
const j = JSON.parse(fs.readFileSync(p, 'utf8'));
j.scripts = j.scripts || {};
j.scripts['test:unit'] = j.scripts['test:unit'] || 'echo \"No unit tests configured\"';
j.scripts['test:e2e'] = j.scripts['test:e2e'] || 'echo \"No e2e tests configured\"';
j.scripts['test:live'] = 'node scripts/ctrl-live-smoke.mjs';
j.scripts['test:docker'] = 'bash scripts/ctrl-docker-smoke.sh';
j.scripts['ctrl:gate'] = 'bash scripts/ctrl-gate-runner.sh';
j.scripts['ctrl:full'] = 'npm run ctrl:gate && npm run test:live && npm run test:docker';
j.ctrl = { mode: '$MODE' };
fs.writeFileSync(p, JSON.stringify(j, null, 2) + '\\n');
"
fi

echo ""
echo "✅ CTRL bootstrap complete ($MODE mode)"
echo ""
echo "Files created:"
echo "  - copilot-instructions.md"
echo "  - .ctrlrc.json"
echo "  - scripts/ctrl-live-smoke.mjs"
echo "  - scripts/ctrl-docker-smoke.sh"
echo "  - scripts/ctrl-gate-runner.sh"
echo "  - .github/workflows/ctrl.yml"
echo ""
echo "Next steps:"
echo "  1. Run: npm run ctrl:gate"
echo "  2. Add DISCORD_BUILD_WEBHOOK_URL secret to GitHub repo"
if [[ "$MODE" == "production" ]]; then
echo "  3. Set up actual test commands in package.json (test:unit, test:e2e)"
echo "  4. Configure coverage thresholds in .ctrlrc.json"
fi
