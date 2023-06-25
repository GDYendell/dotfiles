#!/bin/bash

# Linux
ln -s ~/dotfiles/xinitrc ~/.xinitrc
ln -s  ~/dotfiles/xprofile ~/.xprofile
mkdir -p ~/.ssh && ln -s ~/dotfiles/ssh/config ~/.ssh/config && echo "Add credentials to ~/.ssh/config"

# Applications
mkdir -p ~/.config/alacritty && ln -s ~/dotfiles/config/alacritty.yml ~/.config/alacritty/alacritty.yml
mkdir -p ~/.config/readline &&  ln -s ~/dotfiles/inputrc ~/.config/readline/inputrc
mkdir -p ~/.config/i3 && ln -s ~/dotfiles/config/i3 ~/.config/i3/config
mkdir -p ~/.icons/default/ &&  ln -s ~/dotfiles/gtk/icon.theme ~/.icons/default/index.theme
mkdir -p ~/.config/git && ln -s ~/dotfiles/git/config ~/.config/git/gitconfig
mkdir -p ~/.config/polybar && ln -s ~/dotfiles/config/polybar ~/.config/polybar/config
mkdir -p ~/.config/rofi && ln -s ~/dotfiles/config/rofi ~/.config/rofi/config.rasi
mkdir -p ~/.config/vim && ln -s ~/dotfiles/vimrc ~/.config/vim/vimrc && mkdir -p ~/.vim/pack/themes/start && ln -s ~/dotfiles/dracula/vim ~/.vim/pack/themes/start/dracula

# Launchers
mkdir -p  ~/.local/share/applications && ln -s ~/dotfiles/applications/obsidian.desktop ~/.local/share/applications/obsidian.desktop

# Fonts
mkdir -p ~/.config/fontconfig && ln -s ~/dotfiles/config/fonts/fonts.conf ~/.config/fontconfig/fonts.conf
mkdir ~/.local/share/fonts && tar -xzf ~/dotfiles/fonts/Garosevka.tar.gz -C ~/.local/share/fonts

# Useful Directories
mkdir -p ~/logs
mkdir -p ~/development

# Clone submodules
git submodule update --init --recursive

# Insert into default configs - Uncomment and run once
# echo "source ~/dotfiles/bashrc" >> ~/.bashrc
# sudo echo ". ~/dotfiles/profile" >> /etc/profile
