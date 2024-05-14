#!/bin/bash

set -x
set -e

function updated_system () {
	sudo apt update
	sudo apt full-upgrade -y
}

sudo dpkg --add-architecture i386

function install_packages () {
	sudo apt install -y \
	wget \
	curl \
	i3/noble \
	i3-wm/noble \
	i3blocks/noble \
	i3lock/noble \
	i3lock-fancy/noble \
	i3status/noble \
	vim \
	git \
	rsync \
	alacritty \
	pwgen \
	htop \
	chromium \
	vlc \
	gnome-system-monitor \
	udisks2 \
	remmina \
	zip \
	unzip \
	postfix \
	nodejs \
	npm \
	ruby{,-full} \
	zsh \
	picom \
	feh \
	rofi \
	lxappearance \
	thunar{,-volman,-archive-plugin} \
	xfce4-settings \
	polybar \
	dkms \
	arc-theme \
	gnome-screenshot \
	gnome-disk-utility \
	nautilus \
	fonts-font-awesome \
	thunderbird \
	mariadb-backup \
	mariadb-client \
	mariadb-common \
	mariadb-server \
	mariadb-server-core \
	virtualbox/noble \
	virtualbox-dkms/noble \
	virtualbox-ext-pack/noble \
	virtualbox-guest-additions-iso/noble \
	virtualbox-guest-utils/noble \
	virtualbox-guest-x11/noble \
	virtualbox-guest-x11/noble \
	virtualbox-source/noble \
	xmount/noble \
	policykit-1-gnome
}

function configure_mariadb () {
	if [ `systemctl is-enabled mariadb` = "disabled" ]; then
		sudo systemctl enable --now mariadb
	fi
}

function configure_zsh () {
	if [ ! -d ~/.oh-my-zsh ]; then
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" <<EOF
        exit
EOF
        chsh -s $(which zsh)
        sudo apt install -y keychain
        mkdir -p -m 700 ~/.ssh
        git clone https://github.com/sindresorhus/pure.git "$HOME/.zsh/pure"
        sed -i "s/ZSH_THEME=\"robbyrussell\"/#ZSH_THEME=\"robbyrussell\"/" ~/.zshrc
        cat >> ~/.zshrc <<EOF
fpath+=$HOME/.zsh/pure
autoload -U promptinit; promptinit
prompt pure
zmodload zsh/nearcolor
zstyle :prompt:pure:path color '#FFFFFF'
zstyle ':prompt:pure:prompt:*' color cyan
zstyle :prompt:pure:git:stash show yes
eval \$(keychain --eval --agents ssh --quick --quiet)
export TERM=xterm-256color
EOF
        fi
}

function configure_postfix() {
        if [ `systemctl is-enabled postfix` = "disabled" ]; then
                postfix_file=/etc/postfix/main.cf
                sudo chmod o+w $postfix_file
                sudo sed -i 's/#relayhost = \[an\.ip\.add\.ress\]/relayhost = 127\.0\.0\.1:1025/' $postfix_file
                sudo chmod o-w $postfix_file
                sudo systemctl enable --now postfix
        fi
}

function configure_docker () {
	        if [ ! -f /usr/bin/docker ]; then
			sudo apt-get update
			sudo apt-get install ca-certificates curl
			sudo install -m 0755 -d /etc/apt/keyrings
			sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
			sudo chmod a+r /etc/apt/keyrings/docker.asc
			echo \
				"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
				$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
			sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
			sudo apt-get update
			 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
                if [ `systemctl is-enabled docker.service` = "disabled" ] ; then
                        sudo systemctl enable --now docker.service
                fi
                if ! sudo docker ps | grep mail; then
                        sudo docker run -d --restart unless-stopped -p 1080:1080 -p 1025:1025 dominikserafin/maildev:latest
                fi
        fi
}

function install_snap () {
	sudo snap install opera
	sudo snap install discord
	sudo snap install spotify
}

function updated_config () {
	rsync -avPh ./config/ ~/.config/
	rsync -avPh ./Images/ ~/Images/
}

function disable_error_network () {
	sudo systemctl disable systemd-networkd-wait-online.service
	sudo systemctl mask systemd-networkd-wait-online.service
}

function configure_and_install_wine () {
	sudo apt install -y \
	wine \
	wine-stable \
	wine64 \
	wine64-preloader \
	wine64-tools
	sudo ln -s /usr/share/doc/wine/examples/wine.desktop /usr/share/applications/
}

function configure_software () {
	configure_mariadb
	configure_zsh
	configure_postfix
	configure_docker
}

function main () {
	updated_system
	install_packages
	configure_software
	install_snap
	disable_error_network
	configure_and_install_wine
	updated_config
}

main

