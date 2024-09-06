# Blesh
#[[ $- == *i* ]] && source /usr/share/blesh/ble.sh --noattach

export PATH=$PATH:~/bin

alias DUSORT="du -ksh * | sort -rh"
alias DUSORTA="du -kah * | sort -rh"
alias rebash=". ~/.bashrc"
alias rehist="history -r"
alias i3-log='less $(ls -art ~/logs/i3* | tail -n 1)'
alias sway-log='less $(ls -art ~/logs/sway* | tail -n 1)'

# Commands
alias ls='ls --color=auto'
alias ll='ls -l'
alias cdn='cd $(\ls -1dt ./*/ | head -n 1)'
alias make='rederr make'
alias less='less -S -M -z-5 -W'
alias remake="rederr make $@ clean uninstall && rederr make $@"
alias gitk='gitk --all &'
alias RESET='clear && printf "\e[3J"'
alias ducks='du -cksh -- * | sort -rh | head'
alias lg="lazygit $@"
alias vimr="vim -R $@"
## Have to escape single quotes outside of quotes and concatenate seprate strings implicitly
alias mansearch='man $(apropos --long . | dmenu -i -l 30 | awk '\''{print $2, $1}'\'' | tr -d '\''()'\'')'
alias dotfiles="/usr/bin/git --git-dir=$HOME/dotfiles.git/ --work-tree=$HOME"

# Check for ssh connection
for f in ~/.ssh/*pc0118*user; do

  ## Check if the glob gets expanded to existing files.
  ## If not, f here will be exactly the pattern above
  ## and the exists test will evaluate to false.
  [ -e "$f" ] && echo "Found existing ssh socket: $f" && ssh pc0118

  ## This is all we needed to know, so we can break after the first iteration
  break
done

# Check pc0118 is reachable
alias waitpc0118="until nc -vzw 2 pc0118 22; do sleep 2; done; aplay /usr/share/sounds/alsa/Side_Right.wav"

function highlight() {
  grep --color -E "$1|$" "${@:1}"
}
function highlightp() {
  grep --color -E "$1|$"
}
# Override cd to allow swapping
function cds() {
  if [ $# -eq 2 ]; then builtin cd ${PWD/$1/$2}; else builtin cd $1; fi
}

function del_known_host() {
  sed -i.bak -e "$1d" ~/.ssh/known_hosts
}
function undel_known_host() {
  mv ~/.ssh/known_hosts.bak ~/.ssh/known_hosts
}
function repeat() {
  fc -$1 -1
}
function opacity() {
  xprop -format _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY 0x$1FFFFFFF
}
function whathaveidone() {
  ls -t --color=always -l | grep $(whoami) | tail -n +2 | head
}
function tldr {
  curl cht.sh/${1} | less -r
}

# Function for creating git aliases
GIT_ALIAS() {
  ALIAS=$1
  shift
  echo 'Executing: git config --global alias.'$ALIAS' "'$@'"'
  git config --global alias.$ALIAS "$@"
}
export GIT_ALIAS
# Show log of tags and their commits
GIT_TAG_LOG() { git tag | sort --reverse | xargs git show --quiet; }
export GIT_TAG_LOG
# Trace all commits touching the given file
GIT_TRACE() { git log --oneline --follow -- "$@"; }
export GIT_TRACE

function git_commit_diff() {
  #echo "Commit $1:"; \
  #git show "$1"; \
  #echo "Commit $2:"; \
  #git show "$2"; \
  #echo "Difference:"; \
  #diff -y <(git show "$1") <(git show "$2"); \
  vimdiff <(git show "$1") <(git show "$2")
}

# Man page colour
export LESS_TERMCAP_mb=$'\e[1;32m'
export LESS_TERMCAP_md=$'\e[1;32m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;33m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;4;31m'

# Save all history
export HISTCONTROL=ignoreboth:erasedups # Remove adjacent duplicate entries, ignorespace and ignoredups
export HISTSIZE=                        # Unlimited history
export HISTFILESIZE=                    # Unlimited history
export HISTFILE=~/.bash_eternal_history # Move bash history so it doesn't get manually trucated byt applications
shopt -s histappend                     # Append to history, don't overwrite it

# Append to history after each command finishes - Will be written to file on shell close
PROMPT_COMMAND="history -a"

# Apply solarized colours for Dracula theme
eval $(dircolors ~/.dircolors)

# Manually bind inputrc for some reason
bind -f ~/.config/readline/inputrc

# Keep pwd in new tab
if [[ -f /etc/profile.c/vte.sh ]]; then
  source /etc/profile.d/vte.sh
fi

# Starship
export STARSHIP_CONFIG=$HOME/.config/starship.toml
eval "$(starship init bash)"

# blesh
#[[ ${BLE_VERSION-} ]] && ble-attach

# Atuin
eval "$(atuin init bash)"

# zoxide
eval "$(zoxide init --cmd cd bash)"
