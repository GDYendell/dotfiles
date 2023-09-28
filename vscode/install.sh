#!/usr/bin/env bash

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

# Don't pollute workspace with downloaded files
cd /tmp

# Tools
if [[ "$DISTRO" =~ Debian ]]; then
    sudo apt-get update
    sudo apt-get install -y vim
fi

# Lazygit
if [[ "$DISTRO" =~ Debian ]]; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
elif [[ "$DISTRO" =~ CentOS ]]; then
    dnf copr enable atim/lazygit -y
    dnf install lazygit
fi

# Starship Prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
ln -s ~/dotfiles/config/starship.toml ~/.config/starship.toml

echo -e '\n. ~/dotfiles/bashrc' >> ~/.bashrc
