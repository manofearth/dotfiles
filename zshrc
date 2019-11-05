bindkey -e # emacs-like controls

PS1="[%h] %B%F{blue}%~ %F{white}%#%f%b "

zstyle ':completion:*' completer _expand _complete _ignored
zstyle :compinstall filename '~/.zshrc'

autoload -Uz compinit
compinit

# History
HISTFILE=~/.histfile
HISTSIZE=5000
SAVEHIST=5000
setopt HIST_IGNORE_DUPS # Do not enter command lines into the history list if they are duplicates of the previous event
setopt HIST_IGNORE_SPACE # Remove command lines from the history list when the first character on the line (or in the alias) is a space
setopt HIST_REDUCE_BLANKS # Remove superfluous blanks from each command line being added to the history list
setopt APPEND_HISTORY # Append history to the history file (no overwriting)
setopt SHARE_HISTORY # Share history across terminals

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

# Ctrl+W to delete word until slash (instead space), taken from https://unix.stackexchange.com/questions/250690/how-to-configure-ctrlw-as-delete-word-in-zsh
my-backward-delete-word() {
    local WORDCHARS=${WORDCHARS/\//}
    zle backward-delete-word
}
zle -N my-backward-delete-word
bindkey '^w' my-backward-delete-word

# Aliases
alias grep='grep --color'
alias egrep='egrep --color'
alias ls='ls --color=auto'
alias ll='ls -alh'
alias tree='tree -L 2 -a'
if [[ -f ~/.aliases ]]; then
  source ~/.aliases
fi

# NVM
#export NVM_NO_USE=true
#source ~/.zsh-nvm/zsh-nvm.plugin.zsh

