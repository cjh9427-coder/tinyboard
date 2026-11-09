#!/usr/bin/env bash
# Generic repo check for J H Cloud Agent repos. Exit 0 only if all checks pass.
# Safe on empty repos (README-only). Run from repo root: bash scripts/check.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
FAIL=0
pass(){ printf '  [PASS] %s\n' "$1"; }
fail(){ printf '  [FAIL] %s\n' "$1"; FAIL=$((FAIL+1)); }
warn(){ printf '  [WARN] %s\n' "$1"; }

echo "== cloud-kit check ($ROOT) =="

# --- 1. AGENTS.md line cap ≤ 40 ---
if [ -f AGENTS.md ]; then
  n=$(wc -l < AGENTS.md | tr -d ' ')
  if [ "$n" -le 40 ]; then
    pass "agents-size AGENTS.md ${n}줄 ≤ 40"
  else
    fail "agents-size AGENTS.md ${n}줄 > 40"
  fi
else
  warn "agents-size AGENTS.md 없음 (skip)"
fi

# --- 2. Python compile all .py (if any) ---
mapfile -t PYS < <(find . -type f -name '*.py' \
  ! -path './.git/*' ! -path './node_modules/*' ! -path './.venv/*' ! -path './venv/*' \
  ! -path './__pycache__/*' 2>/dev/null | sort)
if [ "${#PYS[@]}" -eq 0 ]; then
  pass "py-compile .py 없음 (skip)"
else
  if python3 -m py_compile "${PYS[@]}" 2>/tmp/cloudkit-py.err; then
    pass "py-compile ${#PYS[@]} files OK"
  else
    fail "py-compile failed: $(head -c 200 /tmp/cloudkit-py.err | tr '\n' ' ')"
  fi
fi

# --- 3. pytest if tests/ or test_*.py exist ---
if [ -d tests ] || [ -d test ] || find . -maxdepth 3 -type f \( -name 'test_*.py' -o -name '*_test.py' \) ! -path './.git/*' 2>/dev/null | grep -q .; then
  if command -v pytest >/dev/null 2>&1; then
    if pytest -q --tb=line 2>/tmp/cloudkit-pytest.err; then
      pass "pytest OK"
    else
      fail "pytest failed: $(tail -c 200 /tmp/cloudkit-pytest.err | tr '\n' ' ')"
    fi
  else
    # pytest not installed — try python -m pytest, else warn (not fail) so empty CI boxes still work
    if python3 -m pytest -q --tb=line 2>/tmp/cloudkit-pytest.err; then
      pass "pytest OK (python -m)"
    else
      if grep -qi 'No module named pytest' /tmp/cloudkit-pytest.err 2>/dev/null; then
        warn "pytest 미설치 — tests 있음, 설치 후 재실행"
      else
        fail "pytest failed: $(tail -c 200 /tmp/cloudkit-pytest.err | tr '\n' ' ')"
      fi
    fi
  fi
else
  pass "pytest 테스트 없음 (skip)"
fi

# --- 4. npm test / build if package.json exists ---
if [ -f package.json ]; then
  if command -v npm >/dev/null 2>&1; then
    if grep -q '"test"' package.json; then
      if npm test --silent 2>/tmp/cloudkit-npm.err; then
        pass "npm test OK"
      else
        fail "npm test failed: $(tail -c 200 /tmp/cloudkit-npm.err | tr '\n' ' ')"
      fi
    else
      pass "npm test 스크립트 없음 (skip)"
    fi
    if grep -q '"build"' package.json; then
      if npm run build --silent 2>/tmp/cloudkit-npm.err; then
        pass "npm run build OK"
      else
        fail "npm run build failed: $(tail -c 200 /tmp/cloudkit-npm.err | tr '\n' ' ')"
      fi
    else
      pass "npm build 스크립트 없음 (skip)"
    fi
  else
    warn "npm 미설치 — package.json 있음"
  fi
else
  pass "package.json 없음 (skip)"
fi

# --- 5. Forbidden content / data files (Falcon + secrets) ---
# Data files must not be committed (names). Source may mention labels.sqlite/kg.sqlite as tool paths.
BAD_FILES=$(find . -type f \( \
  -name 'labels.sqlite' -o -name 'kg.sqlite' -o -name '.env' -o -name '.env.*' \
  -o -name '*credentials*' -o -name '*.pem' -o -name 'id_rsa' \
  \) ! -path './.git/*' 2>/dev/null || true)
if [ -n "${BAD_FILES}" ]; then
  fail "forbidden-files: $(echo "$BAD_FILES" | tr '\n' ' ' | head -c 200)"
else
  pass "forbidden-files 없음"
fi

# Content: trading symbols + youtube watch/playlist links.
# token/secret: credential-like assignments only (avoid false positives on docs).
# Exclude this script, .git, node_modules, binary-ish extensions.
SCAN_PATHS=$(find . -type f \
  ! -path './.git/*' ! -path './node_modules/*' ! -path './.venv/*' ! -path './venv/*' \
  ! -path './__pycache__/*' ! -path './scripts/check.sh' \
  ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.gif' ! -name '*.webp' \
  ! -name '*.sqlite' ! -name '*.bin' ! -name '*.pyc' ! -name '*.woff*' \
  2>/dev/null | sort || true)

CONTENT_HITS=""
if [ -n "$SCAN_PATHS" ]; then
  # shellcheck disable=SC2086
  CONTENT_HITS=$(echo "$SCAN_PATHS" | xargs -r rg -n -I \
    -e 'ETHUSDT' \
    -e 'SUGARUSD' \
    -e 'youtube\.com/watch' \
    -e 'youtube\.com/playlist' \
    -e '(?i)(api[_-]?key|access[_-]?token|secret[_-]?key)\s*[:=]\s*['\''\"]?[A-Za-z0-9_\-]{8,}' \
    2>/dev/null || true)
fi
if [ -n "$CONTENT_HITS" ]; then
  fail "forbidden-content: $(echo "$CONTENT_HITS" | head -5 | tr '\n' ' ' | head -c 300)"
else
  pass "forbidden-content 없음 (symbols/youtube/cred-assign)"
fi

echo "== 결과: FAIL=$FAIL =="
if [ "$FAIL" -gt 0 ]; then
  exit 1
fi
exit 0
