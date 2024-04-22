#!/usr/bin/env bash

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

# Run commands with sudo if container user is not root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    SUDO="sudo"
fi

# Don't pollute workspace with downloaded files
cd /tmp

# Tools
if [[ "$DISTRO" =~ Debian|Ubuntu ]]; then
    ${SUDO} apt-get update
    ${SUDO} apt-get install -y vim
fi

# Lazygit
if [[ "$DISTRO" =~ Debian|Ubuntu ]]; then
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    ${SUDO} install lazygit /usr/local/bin
elif [[ "$DISTRO" =~ CentOS ]]; then
    ${SUDO} dnf copr enable atim/lazygit -y
    ${SUDO} dnf install lazygit
fi

# Starship Prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
mkdir -p ~/.config
ln -s ~/dotfiles/.config/starship.toml ~/.config/starship.toml

echo -e '\n. ~/dotfiles/.bashrc' >> ~/.bashrc
