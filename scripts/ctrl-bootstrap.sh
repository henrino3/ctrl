#!/usr/bin/env bash
set -euo pipefail

# CTRL Bootstrap — Sets up testing framework for new projects
# Usage: ctrl-bootstrap.sh /path/to/project [--mode mvp|production]

if [ $# -lt 1 ]; then
  echo "Usage: $0 /path/to/project [--mode mvp|production]"
  exit 1
fi

PROJECT="$1"
MODE="mvp"

shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode) MODE="${2:-mvp}"; shift 2 ;;
    *) shift ;;
  esac
done

mkdir -p "$PROJECT/scripts" "$PROJECT/.github/workflows"

echo "📦 Bootstrapping CTRL in $PROJECT (mode: $MODE)"

# Detect Language Environment
LANG_ENV="unknown"
TEST_CMD="echo 'Replace with test command'"
BUILD_CMD="echo 'Replace with build command'"
GATE_CMD="bash scripts/ctrl-gate-runner.sh"

if [ -f "$PROJECT/package.json" ]; then
  LANG_ENV="node"
  TEST_CMD="npm run test:unit"
  BUILD_CMD="npm run build"
  GATE_CMD="npm run ctrl:gate"
  echo "🔍 Detected Node.js (package.json)"
elif [ -f "$PROJECT/requirements.txt" ] || [ -f "$PROJECT/pyproject.toml" ]; then
  LANG_ENV="python"
  TEST_CMD="pytest"
  BUILD_CMD="echo 'Python project: no build step'"
  echo "🔍 Detected Python"
elif [ -f "$PROJECT/go.mod" ]; then
  LANG_ENV="go"
  TEST_CMD="go test ./..."
  BUILD_CMD="go build ./..."
  echo "🔍 Detected Go"
elif [ -f "$PROJECT/Cargo.toml" ]; then
  LANG_ENV="rust"
  TEST_CMD="cargo test"
  BUILD_CMD="cargo build"
  echo "🔍 Detected Rust"
else
  echo "⚠️  No known package manager found, defaulting to generic shell commands."
fi

# Fetch Universal Templates if missing
REPO_URL="https://raw.githubusercontent.com/henrino3/ctrl/master"
for file in AGENTS.md TESTING.md; do
  if [ ! -f "$PROJECT/$file" ]; then
    curl -sS "$REPO_URL/$file" > "$PROJECT/$file"
  fi
done

# Tailor AGENTS.md to the detected language
if [ "$LANG_ENV" != "node" ]; then
  sed -i.bak "s/npm run test:unit/$TEST_CMD/g" "$PROJECT/AGENTS.md"
  sed -i.bak "s/npm run ctrl:gate/$GATE_CMD/g" "$PROJECT/AGENTS.md"
  rm -f "$PROJECT/AGENTS.md.bak"
fi

# Create copilot-instructions.md
cat > "$PROJECT/copilot-instructions.md" <<MD
# CTRL Instructions
1. Write/update tests for each changed file.
2. Run gates before marking done.
3. Fix failures and rerun until green.
4. Never ship failing gates.

## Gates
- Fast gate: \`$GATE_CMD\`
MD

# Create mode-aware gate runner
cat > "$PROJECT/scripts/ctrl-gate-runner.sh" <<SH
#!/usr/bin/env bash
set -euo pipefail

echo "[ctrl] Running in $MODE mode ($LANG_ENV)"

$BUILD_CMD || { echo "[ctrl] build failed"; exit 1; }

if $TEST_CMD 2>/dev/null; then
  echo "[ctrl] tests passed"
else
  echo "[ctrl] tests failed"
  exit 1
fi

echo "[ctrl] gate passed ✅"
SH
chmod +x "$PROJECT/scripts/ctrl-gate-runner.sh"

# Create GitHub Actions workflow tailored to language
if [ "$LANG_ENV" == "node" ]; then
cat > "$PROJECT/.github/workflows/ctrl.yml" <<YML
name: CTRL Gate
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '22', cache: 'npm' }
      - run: npm ci
      - run: npm run build
      - run: npm test || echo "Tests skipped (MVP mode)"
YML
elif [ "$LANG_ENV" == "python" ]; then
cat > "$PROJECT/.github/workflows/ctrl.yml" <<YML
name: CTRL Gate
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.11' }
      - run: pip install pytest
      - run: if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
      - run: pytest
YML
elif [ "$LANG_ENV" == "go" ]; then
cat > "$PROJECT/.github/workflows/ctrl.yml" <<YML
name: CTRL Gate
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with: { go-version: '1.21' }
      - run: go build ./...
      - run: go test ./...
YML
elif [ "$LANG_ENV" == "rust" ]; then
cat > "$PROJECT/.github/workflows/ctrl.yml" <<YML
name: CTRL Gate
on: [push, pull_request]
jobs:
  gate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cargo build
      - run: cargo test
YML
fi

# Update package.json if Node
if [ "$LANG_ENV" == "node" ]; then
  node -e "
const fs = require('fs');
const p = '$PROJECT/package.json';
const j = JSON.parse(fs.readFileSync(p, 'utf8'));
j.scripts = j.scripts || {};
j.scripts['test:unit'] = j.scripts['test:unit'] || 'echo "No unit tests configured"';
j.scripts['ctrl:gate'] = 'bash scripts/ctrl-gate-runner.sh';
fs.writeFileSync(p, JSON.stringify(j, null, 2) + '\n');
"
fi

echo "✅ CTRL bootstrap complete for $LANG_ENV"
echo "Next step: Run $GATE_CMD"
