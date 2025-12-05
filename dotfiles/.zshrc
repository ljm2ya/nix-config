# If not running interactively, don't do anything
[[ $- != *i* ]] && return
#xmodmap ~/.Xmodmap

alias ls='ls --color=auto'

#S1='[\u@\h \W]\$ '
# vterm in Emacs
if [ "$INSIDE_EMACS" = "vterm" ]; then
    # Communicating with vterm in Emacs
    vterm_printf() {
        if [ -n "$TMUX" ] && ([ "${TERM%%-*}" = "tmux" ] || [ "${TERM%%-*}" = "screen" ]); then
            # Tell tmux to pass the escape sequences through
            printf "\ePtmux;\e\e]%s\007\e\\" "$1"
        elif [ "${TERM%%-*}" = "screen" ]; then
            # GNU screen (screen, screen-256color, screen-256color-bce)
            printf "\eP\e]%s\007\e\\" "$1"
        else
            printf "\e]%s\e\\" "$1"
        fi
    }

    # directory tracking
    vterm_prompt_end() {
        vterm_printf "51;A$(whoami)@$(hostname):$(pwd)"
    }
    PROMPT=$PROMPT'%{$(vterm_prompt_end)%}'

    # call emacs functions
    vterm_cmd() {
        local vterm_elisp
        vterm_elisp=""
        while [ $# -gt 0 ]; do
            vterm_elisp="$vterm_elisp""$(printf '"%s" ' "$(printf "%s" "$1" | sed -e 's|\\|\\\\|g' -e 's|"|\\"|g')")"
            shift
        done
        vterm_printf "51;E$vterm_elisp"
    }

    find_file() {
        vterm_cmd find-file "$(realpath "${@:-.}")"
    }
fi

#if [[ $UID -eq 0 ]]; then
  #PROMPT_COLOR="1;31m"
#else
  #PROMPT_COLOR="1;32m"
#fi

#PROMPT='%F{#c0c0c0}%n%f@%F{#A3BE8C}%m%f %F{#B48EAD}%B%~%b%f %# '
#RPROMPT='[%F{#EBCB8B}%?%f]'

export EDITOR="vim"
export ZVM_SYSTEM_CLIPBOARD_ENABLED=true

alias dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles.git/ --work-tree=$HOME"
eval "$(direnv hook zsh)"

function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# no new line on tmux 
if [[ ! -z "$TMUX" ]] && [[ ! -v $PURE_FIX ]]; then
    tmux send-keys -t $(tmux display-message -p '#P') '^L'
    PURE_FIX=0
fi

# zinit
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
[ ! -d $ZINIT_HOME ] && mkdir -p "$(dirname $ZINIT_HOME)"
[ ! -d $ZINIT_HOME/.git ] && git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light chisui/zsh-nix-shell
zinit ice depth = 1
#zinit light jeffreytse/zsh-vi-mode

# zsh-vi-mode setting 
#bindkey -r '^R' # conflict with fzf search

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt sharehistory

# pure load
fpath+=($HOME/.zsh/pure)
autoload -U promptinit; promptinit
prompt pure
zstyle :prompt:pure:git:stash show yes

eval "$(zoxide init zsh)"
