#!/usr/bin/env bash
# Temporarily allow passwordless sudo for the invoking user; revoke explicitly.
# Usage: bash sudo-nopasswd.sh enable|disable
set -euo pipefail

# Do not run privileged commands from a user-controlled PATH.
export PATH=/usr/sbin:/usr/bin:/sbin:/bin

die() { printf 'Ошибка: %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'EOF'
Использование: bash sudo-nopasswd.sh enable|disable

  enable   Разрешить текущему пользователю sudo без пароля для любых команд.
  disable  Удалить выданное этим скриптом правило и сбросить кеш пароля sudo.

Также поддерживаются install/revoke. При необходимости скрипт сам вызовет sudo.
При запуске через sudo используется исходный пользователь (SUDO_USER).
Права действуют до явного disable, в том числе после перезагрузки.
Другие настройки sudo скрипт не меняет.
EOF
}

if [[ $# -eq 1 && ( $1 == --help || $1 == -h ) ]]; then
  usage
  exit 0
fi
[[ $# -eq 1 ]] || { usage >&2; exit 2; }
case $1 in
  enable|install) action=enable ;;
  disable|revoke) action=disable ;;
  *) usage >&2; exit 2 ;;
esac

[[ $(uname -s) == Linux ]] || die 'Скрипт предназначен для Linux.'
command -v sudo >/dev/null || die 'Не найден sudo.'

if [[ $(id -u) -ne 0 ]]; then
  exec sudo -- /bin/bash -- "${BASH_SOURCE[0]}" "$action"
fi

target_user=${SUDO_USER:-}
[[ -n $target_user ]] || die 'Запустите скрипт из учетной записи sudo-пользователя, а не напрямую от root.'
target_uid=$(id -u -- "$target_user") || die "Не найден пользователь: $target_user"
[[ $target_uid =~ ^[0-9]+$ && $target_uid -ne 0 ]] || die 'Нельзя выбрать root.'
command -v visudo >/dev/null || die 'Не найден visudo (обычно входит в пакет sudo).'

sudoers_dir=/etc/sudoers.d
[[ -d $sudoers_dir && ! -L $sudoers_dir ]] || die "Не найден обычный каталог $sudoers_dir."
rule_file=$sudoers_dir/zz-agent-nopasswd-$target_uid
rule_text=$(printf '# Managed by sudo-nopasswd.sh\n#%s ALL=(ALL:ALL) NOPASSWD: ALL\n' "$target_uid")

# Refuse to overwrite or remove files that this script does not own.
[[ ! -L $rule_file ]] || die "Отказ работать с символической ссылкой: $rule_file"
if [[ -e $rule_file ]]; then
  [[ -f $rule_file ]] || die "Не обычный файл: $rule_file"
  [[ $(cat -- "$rule_file") == "$rule_text" ]] || die "Файл изменен вручную или создан другим инструментом: $rule_file"
fi

tmp=
new_rule=0
cleanup() {
  local status=$?
  [[ -z $tmp ]] || rm -f -- "$tmp"
  if [[ $status -ne 0 && $new_rule -eq 1 ]]; then
    rm -f -- "$rule_file"
  fi
  return "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

if [[ $action == enable ]]; then
  visudo -c >/dev/null || die 'Текущая конфигурация sudoers не прошла проверку.'
  if [[ ! -e $rule_file ]]; then
    # A dot in the temporary filename keeps sudoers.d from loading it early.
    tmp=$(mktemp "$sudoers_dir/.agent-nopasswd-$target_uid.XXXXXX")
    printf '%s\n' "$rule_text" >"$tmp"
    chown 0:0 "$tmp"
    chmod 0440 "$tmp"
    visudo -cf "$tmp" >/dev/null || die 'Новое правило sudoers не прошло проверку.'
    new_rule=1
    mv -T -- "$tmp" "$rule_file"
    tmp=
  fi
  visudo -c >/dev/null || die 'Конфигурация sudoers не прошла проверку; новое правило будет удалено.'
  # Ignore cached credentials: also detect a missing includedir or a later PASSWD rule.
  if ! sudo -u "$target_user" -- sudo -k -n -- /bin/true; then
    die 'sudo без пароля не работает. Проверьте подключение sudoers.d и порядок правил; новое правило будет удалено.'
  fi
  new_rule=0
  printf 'NOPASSWD включен для %s (UID %s). Для отзыва: bash %q disable\n' "$target_user" "$target_uid" "${BASH_SOURCE[0]}"
else
  rm -f -- "$rule_file"
  # Invalidate the user's timestamps, including those from other terminals.
  if ! sudo -u "$target_user" -- sudo -K; then
    printf 'Предупреждение: правило удалено, но не удалось сбросить кеш sudo. Выполните sudo -K от пользователя %s.\n' "$target_user" >&2
  fi
  visudo -c >/dev/null || die 'Правило удалено, но конфигурация sudoers не прошла проверку.'
  printf 'Выданное скриптом правило NOPASSWD для %s удалено.\n' "$target_user"
fi
