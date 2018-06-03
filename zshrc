# The following lines were added by compinstall

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall
# Lines configured by zsh-newuser-install
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=5000
bindkey -e
# End of lines configured by zsh-newuser-install
setopt appendhistory #Append history to the history file (no overwriting)
setopt sharehistory #Share history across terminals

autoload -U promptinit && promptinit

autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[[A" up-line-or-beginning-search # Up
bindkey "^[[B" down-line-or-beginning-search # Down

setopt COMPLETE_ALIASES

# Enable Ctrl-x-e to edit command line
autoload -U edit-command-line
# Emacs style
zle -N edit-command-line
bindkey '^xe' edit-command-line
bindkey '^x^e' edit-command-line

typeset -U path

alias grep='grep --color'
alias egrep='egrep --color'
alias ls='ls --color=auto'
alias ll='ls -al'
if [[ -f ~/.aliases ]]; then
  source ~/.aliases
fi

# Load random prompt theme
prompts=(adam1 adam2 bart bigfade clint elite2 elite fade fire elite2 elite fade fire elite2 elite fade fire)
prompt $prompts[$(($RANDOM % $#prompts))]
