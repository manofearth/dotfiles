#!/usr/bin/env bash
# Isolated regression tests for config updates; no packages or home files touched.
# Run: bash tests/setup-vm.Tests.sh
set -euo pipefail
export PATH=/usr/bin:/bin:$PATH

repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
bash -n "$repo/setup-vm.sh"
# Load helpers without the package installation or configuration entry points.
source <(sed '/^has apt-get /,$d' "$repo/setup-vm.sh")
fixture=$(mktemp -d /tmp/setup-vm-tests.XXXXXX)
cleanup() {
  local path
  for path in "$fixture"/*; do rm -f -- "$path"; done
  rmdir -- "$fixture"
}
trap cleanup EXIT
config=$fixture/config
passed=0
pass() { passed=$((passed + 1)); printf 'PASS %s\n' "$*"; }
assert_no_temps() {
  local leftovers=("$fixture/"*.setup-vm.*)
  [[ ! -e ${leftovers[0]} ]]
}
update() { printf 'managed setting\n' | write_block "$config"; }

update
printf '%s\n' "$BLOCK_BEGIN" 'managed setting' "$BLOCK_END" >"$fixture/expected"
cmp "$config" "$fixture/expected"
# An unchanged update must not even attempt to rename the file.
(
  mv() { echo 'Unexpected replacement' >&2; return 99; }
  update
)
assert_no_temps
pass 'create a config and leave an identical config untouched'

printf 'user setting' >"$config"
printf '%s' 'managed setting' | write_block "$config"
printf '%s\n' 'user setting' "$BLOCK_BEGIN" 'managed setting' "$BLOCK_END" >"$fixture/expected"
cmp "$config" "$fixture/expected"
update
cmp "$config" "$fixture/expected"
pass 'missing trailing newlines do not merge markers or duplicate blocks'

printf '%s\n' 'before' "$BLOCK_BEGIN" 'old' "$BLOCK_END" 'between' \
  "$BLOCK_BEGIN" 'duplicate' "$BLOCK_END" 'after' >"$config"
chmod 640 "$config"
permissions=$(stat -c '%a:%u:%g' "$config")
update
printf '%s\n' before between after "$BLOCK_BEGIN" 'managed setting' "$BLOCK_END" >"$fixture/expected"
cmp "$config" "$fixture/expected"
[[ $(stat -c '%a:%u:%g' "$config") == "$permissions" ]]
pass 'replace complete blocks, retaining surrounding settings and permissions'

for malformed in unclosed orphan nested reversed; do
  case $malformed in
    unclosed) printf '%s\n' before "$BLOCK_BEGIN" partial 'valuable user setting' ;;
    orphan) printf '%s\n' before "$BLOCK_END" after ;;
    nested) printf '%s\n' "$BLOCK_BEGIN" "$BLOCK_BEGIN" "$BLOCK_END" "$BLOCK_END" ;;
    reversed) printf '%s\n' "$BLOCK_END" "$BLOCK_BEGIN" ;;
  esac >"$config"
  cp "$config" "$fixture/expected"
  if update >"$fixture/stdout" 2>"$fixture/stderr"; then
    echo "Expected failure for $malformed markers" >&2
    exit 1
  fi
  cmp "$config" "$fixture/expected"
  grep -Fq 'invalid setup-vm markers' "$fixture/stderr"
  assert_no_temps
done
pass 'reject malformed markers without losing any original content'

printf 'original\n' >"$config"
cp "$config" "$fixture/expected"
for failure in awk cp mv; do
  if (
    case $failure in
      awk) awk() { printf 'partial output\n'; return 1; } ;;
      cp) cp() { return 1; } ;;
      mv) mv() { return 1; } ;;
    esac
    update
  ) >"$fixture/stdout" 2>"$fixture/stderr"; then
    echo "Expected failure from $failure" >&2
    exit 1
  fi
  cmp "$config" "$fixture/expected"
  assert_no_temps
done
pass 'failed generation, metadata copy or rename leaves the original intact'

if (
  awk() { printf 'partial output\n'; kill -TERM "$BASHPID"; }
  update
) >"$fixture/stdout" 2>"$fixture/stderr"; then
  echo 'Expected interrupted write to fail' >&2
  exit 1
fi
cmp "$config" "$fixture/expected"
assert_no_temps
pass 'interruption before replacement preserves the original and cleans up'

# sys enables MSYS symlinks without Windows elevation; Linux ignores MSYS.
MSYS=winsymlinks:sys ln -s config "$fixture/link"
MSYS=winsymlinks:sys ln -s link "$fixture/chain"
[[ -L $fixture/link && -L $fixture/chain ]]
printf 'managed setting\n' | write_block "$fixture/chain"
[[ -L $fixture/link && -L $fixture/chain ]]
[[ $(readlink "$fixture/link") == config && $(readlink "$fixture/chain") == link ]]
printf '%s\n' original "$BLOCK_BEGIN" 'managed setting' "$BLOCK_END" >"$fixture/expected"
cmp "$config" "$fixture/expected"
pass 'relative chained symlinks stay intact while their target is updated'

MSYS=winsymlinks:sys ln -s new-target "$fixture/dangling"
printf 'managed setting\n' | write_block "$fixture/dangling"
[[ -L $fixture/dangling ]]
printf '%s\n' "$BLOCK_BEGIN" 'managed setting' "$BLOCK_END" >"$fixture/expected"
cmp "$fixture/new-target" "$fixture/expected"
assert_no_temps
pass 'create the target of a dangling symlink without replacing the link'

printf '%s checks passed\n' "$passed"
