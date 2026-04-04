# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME=""

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.

alias ls="eza -la --group-directories-first --icons=auto"
alias lsn="ls --sort newest"
alias lt="eza --tree"
alias fd="fd --hidden $@"
alias lg="lazygit $@"
alias mansearch='man $(apropos --long . | dmenu -i -l 30 | awk '\''{print $2, $1}'\'' | tr -d '\''()'\'')'
alias kc="kubectl"
alias kc-ns='kubectl config set-context --current --namespace $1'
alias x="startx"
alias h="uwsm start -g -1 -D Hyprland hyprland.desktop"
alias tmks="tmux kill-server"
alias grep="echo 'Use rg!'; grep $@"
alias find="echo 'Use fd!'; find $@"

function repeat() {
  fc -$1 -1
}
function tldr {
  curl cht.sh/${1} | less -r
}

# Dracula fzf
export FZF_DEFAULT_OPTS='--color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

# Startup commands

eval "$(zoxide init --cmd cd zsh)"

eval "$(atuin init zsh)"

eval "$(starship init zsh)"
source "$HOME/.local/share/zsh/transient-prompt.plugin.zsh"
TRANSIENT_PROMPT_TRANSIENT_PROMPT='$(starship module character)'
