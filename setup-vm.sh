#!/usr/bin/env bash
# Set up a Debian/Ubuntu VM: vim (default editor), tmux with vi keys, fzf, zoxide,
# bash history tuned for fzf. Edits ~/.bashrc and ~/.tmux.conf in place
# (inside marked blocks), so this repo can be deleted afterwards. Safe to re-run.
#
# fzf/zoxide come from apt when the repo version is recent enough; otherwise
# the outdated package is purged and the latest GitHub release binary is
# installed to /usr/local/bin (for all users).
#
# Usage: git clone <this repo> && ./dotfiles/setup-vm.sh && rm -rf dotfiles
set -euo pipefail

UPSTREAM_BIN=/usr/local/bin
FZF_MIN_VERSION=0.48.0    # first release with `fzf --bash`
ZOXIDE_MIN_VERSION=0.8.0  # Debian 12 / Ubuntu 22.04 ship 0.4.x

log()  { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mWARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

# version_ge A B: true if A >= B
version_ge() { [ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" = "$2" ]; }
# tool_version CMD: "1.2.3" from `CMD --version` (or `CMD -V` for tmux)
tool_version() {
  { "$1" --version 2>/dev/null || "$1" -V 2>/dev/null; } | grep -oE '[0-9]+(\.[0-9]+)+' | head -n1
}
# tool_ok CMD MIN: CMD is in PATH and its version is >= MIN
tool_ok() { local ver; ver=$(tool_version "$1") && [ -n "$ver" ] && version_ge "$ver" "$2"; }

BLOCK_BEGIN='# >>> setup-vm >>>'
BLOCK_END='# <<< setup-vm <<<'

# write_block FILE: replace this script's marked block in FILE with stdin
write_block() {
  local file=$1
  touch "$file"
  sed -i "/^$BLOCK_BEGIN\$/,/^$BLOCK_END\$/d" "$file"
  { echo "$BLOCK_BEGIN"; cat; echo "$BLOCK_END"; } >>"$file"
}

# grep_outside_block FILE REGEX: "LINENO: line" for matches outside our block
grep_outside_block() {
  awk -v b="$BLOCK_BEGIN" -v e="$BLOCK_END" -v re="$2" '
    $0 == b { inside = 1 }
    !inside && $0 ~ re { printf "      %d: %s\n", NR, $0 }
    $0 == e { inside = 0 }
  ' "$1"
}

has apt-get || die "only Debian/Ubuntu are supported"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=
elif has sudo; then
  SUDO=sudo
else
  die "run as root or install sudo"
fi

ARCH=$(dpkg --print-architecture)

# --- apt -----------------------------------------------------------------------

APT_UPDATED=
apt_update() {
  [ -n "$APT_UPDATED" ] && return
  $SUDO apt-get update -qq
  APT_UPDATED=1
}
apt_install() { $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@"; }
is_installed() { dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q '^install ok installed$'; }
# apt_candidate PKG: upstream part of the repo version ("1:0.44.1-1" -> "0.44.1"), empty if none
apt_candidate() {
  apt-cache policy "$1" 2>/dev/null \
    | sed -n 's/^ *Candidate: //p' | grep -v '(none)' | sed 's/^[0-9]*://; s/[-+~].*//' || true
}

# --- GitHub releases -------------------------------------------------------------

# latest_version OWNER/REPO: version of the latest release, without leading "v"
latest_version() {
  local url
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest")
  echo "${url##*/v}"
}

# install_release URL BIN: extract BIN from tarball URL into $UPSTREAM_BIN
install_release() {
  local url=$1 bin=$2 tmp
  tmp=$(mktemp -d)
  curl -fsSL "$url" | tar -xz -C "$tmp" "$bin"
  $SUDO install -m 755 "$tmp/$bin" "$UPSTREAM_BIN/$bin"
  rm -rf "$tmp"
}

install_fzf_upstream() {
  local ver arch
  case $ARCH in
    amd64|arm64) arch=$ARCH ;;
    armhf)       arch=armv7 ;;
    *)           die "no fzf release for $ARCH" ;;
  esac
  ver=$(latest_version junegunn/fzf)
  log "Installing fzf $ver from GitHub to $UPSTREAM_BIN"
  install_release "https://github.com/junegunn/fzf/releases/download/v$ver/fzf-$ver-linux_$arch.tar.gz" fzf
}

install_zoxide_upstream() {
  local ver target
  case $ARCH in
    amd64) target=x86_64-unknown-linux-musl ;;
    arm64) target=aarch64-unknown-linux-musl ;;
    armhf) target=armv7-unknown-linux-musleabihf ;;
    *)     die "no zoxide release for $ARCH" ;;
  esac
  ver=$(latest_version ajeetdsouza/zoxide)
  log "Installing zoxide $ver from GitHub to $UPSTREAM_BIN"
  install_release "https://github.com/ajeetdsouza/zoxide/releases/download/v$ver/zoxide-$ver-$target.tar.gz" zoxide
}

# --- steps -------------------------------------------------------------------

# Install only what is missing: `apt-get install` would also upgrade
# packages that are already there.
install_packages() {
  local present=() missing=() p
  for p in curl ca-certificates vim tmux bash-completion; do
    if is_installed "$p"; then present+=("$p"); else missing+=("$p"); fi
  done
  [ ${#present[@]} -gt 0 ] && log "Already installed: ${present[*]}"
  [ ${#missing[@]} -eq 0 ] && return
  log "Not installed, installing from apt: ${missing[*]}"
  apt_update
  apt_install "${missing[@]}"
}

# ensure_tool CMD MIN UPSTREAM_INSTALLER: get CMD >= MIN from apt if the repo
# has it, else purge the outdated package and install from upstream
ensure_tool() {
  local cmd=$1 min=$2 installer=$3 cur cand
  cur=$(tool_version "$cmd" || true)
  if tool_ok "$cmd" "$min"; then
    log "$cmd $cur is already installed ($(command -v "$cmd")), >= $min"
    return
  fi
  if [ -n "$cur" ]; then
    warn "$cmd $cur ($(command -v "$cmd")) is older than $min"
  else
    log "$cmd is not installed"
  fi
  apt_update
  cand=$(apt_candidate "$cmd")
  if [ -n "$cand" ] && version_ge "$cand" "$min"; then
    log "apt has $cmd $cand (>= $min), installing from apt"
    apt_install "$cmd"
  else
    if [ -n "$cand" ]; then
      log "apt has $cmd $cand (< $min), using GitHub release"
    else
      log "apt has no $cmd package, using GitHub release"
    fi
    if is_installed "$cmd"; then
      warn "removing outdated $cmd package"
      $SUDO apt-get purge -y -qq "$cmd"
    fi
    "$installer"
  fi
  hash -r
  tool_ok "$cmd" "$min" \
    || die "$cmd >= $min not found in PATH: $(command -v "$cmd" || echo none) is $(tool_version "$cmd" || echo '?')"
}

set_default_editor() {
  # System-wide `editor` alternative (sudoedit, crontab -e, git, ...)
  local vim=/usr/bin/vim.basic
  if [ "$(readlink -f /etc/alternatives/editor)" = "$vim" ]; then
    log "vim is already the default editor"
    return
  fi
  log "Making vim the default editor"
  # Output only on failure: minimized images lack man pages, which makes
  # update-alternatives print harmless "skip creation of ...man..." warnings.
  local out
  if ! out=$($SUDO update-alternatives --set editor "$vim" 2>&1); then
    printf '%s\n' "$out" >&2
    die "update-alternatives failed"
  fi
}

configure_bash() {
  log "Updating ~/.bashrc"
  write_block "$HOME/.bashrc" <<'EOF'
export VISUAL=vim EDITOR=vim

# History: big, no duplicates, written after every command so all
# shells/tmux panes share it with fzf's Ctrl-R in new shells
HISTCONTROL=ignoreboth:erasedups
HISTSIZE=100000
HISTFILESIZE=200000
shopt -s histappend
case "$PROMPT_COMMAND" in
  *"history -a"*) ;;
  *) PROMPT_COMMAND="history -a${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

# fzf: Ctrl-R history, Ctrl-T files, Alt-C cd, **<Tab> completion
command -v fzf >/dev/null && eval "$(fzf --bash)"

# zoxide: z <dir>, zi (interactive via fzf); keep last
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
EOF
}

configure_tmux() {
  log "Updating ~/.tmux.conf"
  write_block "$HOME/.tmux.conf" <<'EOF'
# vi keys in copy mode and the command prompt
set -g mode-keys vi
set -g status-keys vi
bind -T copy-mode-vi v send-keys -X begin-selection
bind -T copy-mode-vi C-v send-keys -X rectangle-toggle
bind -T copy-mode-vi y send-keys -X copy-selection-and-cancel

# hjkl to move between panes, HJKL to resize
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# no delay after Esc (vim inside tmux)
set -sg escape-time 10
EOF
}

# Older setups (distro docs, tool installers, hand edits) may also load fzf/zoxide;
# that duplicates our block, and breaks once the package is removed. Only report it.
check_shell_rc() {
  local f found
  for f in "$HOME/.bashrc" "$HOME/.bash_aliases" "$HOME/.bash_profile" "$HOME/.profile"; do
    [ -f "$f" ] || continue
    found=$(grep_outside_block "$f" 'fzf|zoxide')
    if [ -n "$found" ]; then
      warn "$f mentions fzf/zoxide outside the setup-vm block; review and remove if redundant:"
      printf '%s\n' "$found" >&2
    fi
  done
}

summary() {
  log "Done:"
  local t
  for t in vim tmux fzf zoxide; do
    printf '    %-7s %-8s %s\n' "$t" "$(tool_version "$t" || echo 'MISSING')" "$(command -v "$t" || true)"
  done
  echo "    Open a new shell (or run: exec bash) to apply changes."
}

install_packages
ensure_tool fzf    "$FZF_MIN_VERSION"    install_fzf_upstream
ensure_tool zoxide "$ZOXIDE_MIN_VERSION" install_zoxide_upstream
set_default_editor
configure_bash
configure_tmux
check_shell_rc
summary
