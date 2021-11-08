#!/bin/bash
# Based on https://github.com/Azure/azure-quickstart-templates/blob/e1b25fc3fd6545f90aaa536800d4aeb7bf61d1b5/demos/ubuntu-desktop-gnome/configure-ubuntu.sh
# (MIT License)
# NB: need to occassionaly update versions of software listed here
# print commands and arguments as they are executed
# this is the non-interactive version so no need to install desktop. Mainly used for codespaces

set -x

echo "starting Github container setup"
date


#############
# Parameters
#############
# read -p "enter VNC password: " mypass
VMNAME=$(hostname)
echo "User: $USER"
echo "User home dir: $HOME"
echo "vmname: $VMNAME"


###################################################
# Update Ubuntu
###################################################
updateUbuntu() {
    echo "Update ubuntu and if first time, make some directories & install some important packages"
    time sudo apt update -y
    time sudo apt upgrade -y
    if [ ! -d "$HOME/.local/bin" ]; then
        time sudo apt install apt-transport-https ca-certificates curl software-properties-common build-essential procps file git gnupg lsb-release fonts-firacode fonts-cascadia-code neovim direnv -y
        time mkdir -p $HOME/.local/bin
    fi
}
updateUbuntu


#################################
# Setup the Azure CLI and AZcopy
#################################
setupAzure() {
    echo "setup Azure CLI"
    time curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    echo "setup Azcopy"
    time curl -sL https://aka.ms/downloadazcopy-v10-linux | sudo tar xvzf - -C /usr/local/bin --strip-components=1
    sudo rm /usr/local/bin/NOTICE.txt
}

setupAzure


#####################
# Setup Anaconda
#####################
setupAnaconda() {
    echo "setup Anaconda"
    time wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
    time chmod +x Mambaforge-Linux-x86_64.sh
    time ./Mambaforge-Linux-x86_64.sh -b
    time mambaforge/bin/conda init bash
    time rm -f Mambaforge-Linux-x86_64.sh}

setupAnaconda


###############
# Setup zsh
###############
setupOHMYZSH() {
    # we use containers that already have zsh installed
    time sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    time git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/plugins/zsh-autosuggestions
    time git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    time git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
    time cp ./zshenv $HOME/.zshenv
    time cp ./zshrc $HOME/.zshrc
    time cp ./tmux.conf $HOME/.tmux.conf
    time mkdir -p $HOME/conf/nvim
    time cp ./init.vim $HOME/.config/nvim/

    $HOME/mambaforge/bin/conda init zsh

}

setupOHMYZSH

echo "completed Github Code Space setup on"
