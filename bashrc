alias DUSORT="du -ksh * | sort -rh"
alias DUSORTA="du -kah * | sort -rh"
alias rebash=". ~/.bashrc_local"
alias rehist="history -r"

# Commands
alias ls='ls --color=auto'
alias cdn='cd $(\ls -1dt ./*/ | head -n 1)'
alias make='rederr make'
alias less='less -S -M -z-5 -W'
alias remake="rederr make $@ clean uninstall && rederr make $@"
alias gitk='gitk --all &'
alias RESET='clear && printf "\e[3J"'
alias ducks='du -cksh -- * | sort -rh | head'

# Override cd to allow swapping
function cds()
{
    if [ $# -eq 2 ]; then builtin cd ${PWD/$1/$2}; else builtin cd $1; fi
}

function del_known_host()
{
    sed -i.bak -e "$1d" /home/mef65357/.ssh/known_hosts
}
function undel_known_host()
{
    mv /home/mef65357/.ssh/known_hosts.bak /home/mef65357/.ssh/known_hosts
}
function repeat()
{
    fc -$1 -1
}
function opacity()
{
    xprop -format _NET_WM_WINDOW_OPACITY 32c -set _NET_WM_WINDOW_OPACITY 0x$1FFFFFFF
}

# Git Formatting
# source /home/mef65357/bin/oh-my-git/prompt.sh
source ~/bin/git-completion-2-11.bash
source ~/bin/git-prompt-2-11.sh
export GIT_PS1_SHOWDIRTYSTATE=1 # '*' -> Unstaged Changes, '+' -> Staged Changes
export GIT_PS1_SHOWSTASHSTATE=1 # '$' -> Something Stashed
export GIT_PS1_SHOWUNTRACKEDFILES=1 # '%' -> Untracked Files
export GIT_PS1_SHOWUPSTREAM="auto verbose name" # 'u' plus '+N'-> Ahead by N commits, '-N' -> Behind by N commits, '=' -> Equal
export GIT_PS1_DESCRIBE_STYLE="branch"
export GIT_PS1_HIDE_IF_PWD_IGNORED=
export GIT_PS1_STATESEPARATOR=": "

# Function for creating git aliases
GIT_ALIAS () { ALIAS=$1; \
               shift; \
               echo 'Executing: git config --global alias.'$ALIAS' "'$@'"'; \
               git config --global alias.$ALIAS "$@";
             }
export GIT_ALIAS
# Show log of tags and their commits
GIT_TAG_LOG () { git tag | sort --reverse | xargs git show --quiet; }
export GIT_TAG_LOG
# Trace all commits touching the given file
GIT_TRACE () { git log --oneline --follow -- "$@"; }
export GIT_TRACE

function git_commit_diff()
{
    #echo "Commit $1:"; \
    #git show "$1"; \
    #echo "Commit $2:"; \
    #git show "$2"; \
    #echo "Difference:"; \
    #diff -y <(git show "$1") <(git show "$2"); \
    vimdiff <(git show "$1") <(git show "$2");
}

# Save all history
export HISTCONTROL=ignoreboth:erasedups  # Remove adjacent duplicate entries, ignorespace and ignoredups
export HISTSIZE=                         # Unlimited history
export HISTFILESIZE=                     # Unlimited history
export HISTFILE=~/.bash_eternal_history  # Move bash history so it doesn't get manually trucated byt applications
shopt -s histappend                      # Append to history, don't overwrite it

# Append to history after each command finishes - Will be written to file on shell close
PROMPT_COMMAND="history -a"

# Override VENV display
function virtualenv_info(){
    # Get Virtual Env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi
    [[ -n "$venv" ]] && echo "($venv)"
}
VENV="\$(virtualenv_info)"
# Disable the default virtualenv prompt to manually put it in a nice place
export VIRTUAL_ENV_DISABLE_PROMPT=1

# PS1
DEFAULT="\[\e[39m\]"
GIT_STATE="\$(__git_ps1)"
RED="\[\e[0;31m\]"
GREEN="\[\e[0;32m\]"
YELLOW="\[\e[0;33m\]"
BLUE="\[\e[0;34m\]"
PURPLE="\[\e[0;35m\]"
CYAN="\[\e[0;36m\]"
GREY="\[\e[0;37m\]"
_COLOUR="\[\e[m\]"
BOLD="\[\e[1m\]"
_BOLD="\[\e[21m\]"
ITALIC="\[\e[3m\]"
DIM="\[\e[2m\]"
_DIM="\[\e[22m\]"
BLINK="\[\e[5m\]"
_BLINK="\[\e[25m\]"
RESET="\[\e[0m\]"

PS1="${CYAN}╔${VENV}═${RESET}[\u@\h | \w | \A]${CYAN}═${GREEN}${GIT_STATE}${CYAN}═■\n╚═▶ ${RESET}"

export PS1

# Apply solarized colours for Dracula theme
eval `dircolors ~/.dir_colors/dircolors`

# Keep pwd in new tab
. /etc/profile.d/vte.sh
