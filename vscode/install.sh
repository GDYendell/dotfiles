#!/usr/bin/env bash

DISTRO=$(awk -F= '/^NAME/{print $2}' /etc/os-release)

# Run commands with sudo if container user is not root
if [[ $(/usr/bin/id -u) -ne 0 ]]; then
    SUDO="sudo"
fi

# Init repo
git -C ~/dotfiles submodule init && git -C ~/dotfiles submodule update --recursive

# Don't pollute workspace with downloaded files
cd /tmp

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

# Neovim
curl -Lo nvim-linux64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
tar xf nvim-linux64.tar.gz
${SUDO} install nvim-linux64/bin/nvim /usr/local/bin
${SUDO} cp -r nvim-linux64/lib/nvim /usr/local/lib/nvim
${SUDO} cp -r nvim-linux64/share/nvim /usr/local/share/nvim
ln -s ~/dotfiles/.config/nvim ~/.config/nvim
ln -s ~/dotfiles/.vimrc ~/.vimrc

# Nerd Fonts
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -Lo NerdFontsSymbolsOnly.tar.xz https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/NerdFontsSymbolsOnly.tar.xz
tar xf NerdFontsSymbolsOnly.tar.xz
rm NerdFontsSymbolsOnly.tar.xz
fc-cache -fv
cd /tmp

# Starship Prompt
curl -sS https://starship.rs/install.sh | sh -s -- -y
mkdir -p ~/.config
ln -s ~/dotfiles/.config/starship.toml ~/.config/starship.toml

echo -e '\n. ~/dotfiles/.bashrc' >> ~/.bashrc
