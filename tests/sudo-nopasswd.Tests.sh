#!/usr/bin/env bash
# Isolated behavior tests; no real sudo or system configuration is accessed.
# Run: bash tests/sudo-nopasswd.Tests.sh
set -euo pipefail
export PATH=/usr/bin:/bin:$PATH

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bash -n "$repo/sudo-nopasswd.sh"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
export TEST_BIN=$fixture/bin TEST_RULES=$fixture/sudoers.d TEST_LOG=$fixture/log
mkdir -p "$TEST_BIN" "$TEST_RULES"
script=$fixture/script.sh

# Substitute only the protected paths in a disposable copy, never the source.
sed -e 's|^export PATH=.*|export PATH="$TEST_BIN:$PATH"|' \
    -e 's|^sudoers_dir=/etc/sudoers.d$|sudoers_dir=$TEST_RULES|' \
    "$repo/sudo-nopasswd.sh" >"$script"
grep -q '^sudoers_dir=\$TEST_RULES$' "$script"

cat >"$fixture/mock" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s %s\n' "${0##*/}" "$*" >>"$TEST_LOG"
case ${0##*/} in
  uname) printf '%s\n' "${TEST_OS:-Linux}" ;;
  id)
    if [[ $# -eq 1 && $1 == -u ]]; then
      printf '%s\n' "${TEST_EUID:-0}"
    elif [[ $# -eq 3 && $1 == -u && $2 == -- ]]; then
      [[ $3 != root ]] || { echo 0; exit 0; }
      printf '%s\n' 1001
    else
      exit 99
    fi
    ;;
  chown|chmod) exit 0 ;;
  visudo)
    case ${TEST_VISUDO_FAIL:-} in
      preflight) exit 1 ;;
      rule) [[ $1 != -cf ]] ;;
      full) [[ $1 != -c || ! -e $TEST_RULES/zz-agent-nopasswd-1001 ]] ;;
      *) exit 0 ;;
    esac
    ;;
  sudo)
    case "$*" in
      '-u alice -- sudo -k -n -- /bin/true') exit "${TEST_PROBE_FAIL:-0}" ;;
      '-u alice -- sudo -K') exit "${TEST_CACHE_FAIL:-0}" ;;
      "-- /bin/bash -- "*) exit 0 ;;
      *) exit 99 ;;
    esac
    ;;
  *) exit 99 ;;
esac
EOF
for command in uname id chown chmod visudo sudo; do
  cp "$fixture/mock" "$TEST_BIN/$command"
  chmod +x "$TEST_BIN/$command"
done

rule=$TEST_RULES/zz-agent-nopasswd-1001
passed=0
reset_case() {
  rm -f -- "$TEST_RULES/"* "$TEST_RULES/".agent-*
  : >"$TEST_LOG"
  export SUDO_USER=alice TEST_EUID=0
  unset TEST_VISUDO_FAIL TEST_PROBE_FAIL TEST_CACHE_FAIL TEST_OS
}
run() {
  status=0
  bash "$script" "$@" >"$fixture/stdout" 2>"$fixture/stderr" || status=$?
}
assert_ok() { [[ $status -eq 0 ]] || { cat "$fixture/stderr" >&2; exit 1; }; }
assert_fail() { [[ $status -ne 0 ]] || { echo 'Expected failure' >&2; exit 1; }; }
pass() { passed=$((passed + 1)); printf 'PASS %s\n' "$*"; }

reset_case
run --help
assert_ok
[[ ! -s $TEST_LOG ]]
run
[[ $status -eq 2 ]]
run invalid
[[ $status -eq 2 ]]
run enable extra
[[ $status -eq 2 ]]
pass 'help and argument validation require no privileges'

reset_case
TEST_OS=Darwin run enable
assert_fail
[[ ! -e $rule ]]
pass 'reject non-Linux systems'

reset_case
unset SUDO_USER
run enable
assert_fail
SUDO_USER=root run enable
assert_fail
[[ ! -e $rule ]]
pass 'reject direct root and a root target'

reset_case
TEST_EUID=1001 run install
assert_ok
grep -Fxq "sudo -- /bin/bash -- $script enable" "$TEST_LOG"
[[ ! -e $rule ]]
pass 'ordinary user escalates with the normalized action'

reset_case
run enable
assert_ok
[[ $(cat "$rule") == $'# Managed by sudo-nopasswd.sh\n#1001 ALL=(ALL:ALL) NOPASSWD: ALL' ]]
grep -Fq 'chown 0:0 ' "$TEST_LOG"
grep -Fq 'chmod 0440 ' "$TEST_LOG"
grep -Fq 'visudo -cf ' "$TEST_LOG"
grep -Fxq 'sudo -u alice -- sudo -k -n -- /bin/true' "$TEST_LOG"
[[ $(find "$TEST_RULES" -type f | wc -l) -eq 1 ]]
pass 'enable uses the original user UID, validates and probes without cached credentials'

: >"$TEST_LOG"
run enable
assert_ok
! grep -q '^chown ' "$TEST_LOG"
run disable
assert_ok
[[ ! -e $rule ]]
grep -Fxq 'sudo -u alice -- sudo -K' "$TEST_LOG"
run revoke
assert_ok
pass 'repeated enable and disable are idempotent; disable clears user timestamps'

for failure in preflight rule full; do
  reset_case
  TEST_VISUDO_FAIL=$failure run enable
  assert_fail
  [[ ! -e $rule ]]
  [[ -z $(find "$TEST_RULES" -type f -print) ]]
  pass "visudo failure ($failure) leaves no new rule or temporary files"
done

reset_case
TEST_PROBE_FAIL=1 run enable
assert_fail
[[ ! -e $rule ]]
[[ -z $(find "$TEST_RULES" -type f -print) ]]
pass 'failed passwordless probe rolls back the new rule'

reset_case
printf '# administrator rule\n' >"$rule"
run enable
assert_fail
run disable
assert_fail
[[ $(cat "$rule") == '# administrator rule' ]]
pass 'preserve rules belonging to another tool or administrator'

reset_case
printf '# untouched\n' >"$fixture/foreign"
if ln -s "$fixture/foreign" "$rule" 2>/dev/null && [[ -L $rule ]]; then
  run enable
  assert_fail
  run disable
  assert_fail
  [[ $(cat "$fixture/foreign") == '# untouched' ]]
  pass 'refuse symbolic links'
else
  printf 'SKIP symlink check (not supported by this filesystem)\n'
fi

reset_case
run install
assert_ok
TEST_CACHE_FAIL=1 run disable
assert_ok
[[ ! -e $rule ]]
[[ -s $fixture/stderr ]]
pass 'remove the rule even if timestamp invalidation fails, and report the failure'

printf '%s test cases passed.\n' "$passed"
