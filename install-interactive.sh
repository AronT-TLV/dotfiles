#!/bin/bash
# Based on https://github.com/Azure/azure-quickstart-templates/blob/e1b25fc3fd6545f90aaa536800d4aeb7bf61d1b5/demos/ubuntu-desktop-gnome/configure-ubuntu.sh
# (MIT License)
# NB: need to occassionaly update versions of software listed here
#TODO: for non-interactive version (e.g. as script on VM creation) need to modify the ask
# print commands and arguments as they are executed
set -x

echo "starting ubuntu devbox install on pid $$"
date
ps axjf

#############
# Parameters
#############
# read -p "enter VNC password: " mypass
VMNAME=$(hostname)
doit="n"
condain="n"
brewin="n"
echo "User: $USER"
echo "User home dir: $HOME"
echo "vmname: $VMNAME"
#echo "mypass: $mypass"
echo "doit: $doit"

###################################################
# Update Ubuntu
###################################################
updateUbuntu() {
    echo "Update ubuntu and if first time, make some directories & install some important packages"
    time sudo apt update -y
    time sudo apt upgrade -y
    if [ ! -d "$HOME/.local/bin" ]; then
        time sudo apt install apt-transport-https ca-certificates curl software-properties-common build-essential procps file git gnupg lsb-release fonts-firacode fonts-cascadia-code -y
        time mkdir -p $HOME/.local/bin
    fi
}
updateUbuntu

###################################################
# Setup gnome desktop
###################################################
setupGnome() {
    echo "install Gnome desktop"
    # kill the waagent and uninstall, otherwise, adding the desktop will do this and kill this script
    sudo pkill waagent
    time sudo apt remove walinuxagent -y
    time sudo apt install ubuntu-gnome-desktop firefox ntp terminator -y
    # don't automatically launch the desktop
    time sudo systemctl set-default multi-user.target
}

read -p "install Gnome desktop? (y or n): " doit
if [ $doit = "y" ]; then
    setupGnome
fi
doit="n"

#########################################
# Setup VNC
#########################################
setupVNC() {
    echo "set up vnc"
    time sudo apt install tigervnc-standalone-server -y
    touch $HOME/.local/bin/startvnc
    chmod 755 $HOME/.local/bin/startvnc
    touch $HOME/.local/bin/stopvnc
    chmod 755 $HOME/.local/bin/stopvnc
    echo "vncserver -geometry 1280x1024 -depth 16 -nolisten -localhost :1" | sudo tee $HOME/.local/bin/startvnc
    echo "vncserver -kill :1" | sudo tee $HOME/.local/bin/stopvnc
    echo "export PATH=\$PATH:~/.local/bin" | sudo tee -a $HOME/.bashrc

    #   prog=/usr/bin/vncpasswd

    # /usr/bin/expect <<EOF
    # spawn "$prog"
    # expect "Password:"
    # send "$mypass\r"
    # expect "Verify:"
    # send "$mypass\r"
    # expect eof
    # exit
    # EOF
    time vncpasswd
    time startvnc
    time stopvnc

    touch $HOME/.vnc/xstartup
    echo "#!/bin/bash" | tee $HOME/.vnc/xstartup
    echo "" | tee -a $HOME/.vnc/xstartup
    echo "" | tee -a $HOME/.vnc/xstartup
    echo "[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup" | tee -a $HOME/.vnc/xstartup
    echo "[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources" | tee -a $HOME/.vnc/xstartup
    echo "vncconfig -iconic &" | tee -a $HOME/.vnc/xstartup
    echo "" | tee -a $HOME/.vnc/xstartup
    echo "dbus-launch --exit-with-session gnome-session &" | tee -a $HOME/.vnc/xstartup

    $HOME/.local/bin/startvnc
}

read -p "setup vnc? (y or n): " doit
if [ $doit = "y" ]; then
    setupVNC
fi
doit="n"

###################################################
# Setup RDP
###################################################
setupRDP() {
    #install xrdp
    time sudo apt install xrdp -y
    # change access from root only to all users
    time sudo sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
    #start remote desktop session
    time sudo service xrdp restart
}

read -p "setup xrdp? (y or n): " doit
if [ $doit = "y" ]; then
    setupRDP
fi
doit="n"

#################################
# Setup the Azure CLI and AZcopy
#################################
setupAzure() {
    echo "setup Azure CLI"
    time curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

    echo "setup Azcopy"
    time curl -sL https://azcopyvnext.azureedge.net/release20210415/azcopy_linux_amd64_10.11.0.tar.gz | sudo tar xvzf - -C /usr/local/bin --strip-components=1
    sudo rm /usr/local/bin/NOTICE.txt
}

read -p "setup Azure? (y or n): " doit
if [ $doit = "y" ]; then
    setupAzure
fi
doit="n"

#####################
# Setup Anaconda
#####################
setupAnaconda() {
    echo "setup Anaconda"
    time wget https://github.com/conda-forge/miniforge/releases/download/4.10.3-5/Mambaforge-4.10.3-5-Linux-x86_64.sh
    chmod +x Mambaforge-4.10.3-5-Linux-x86_64.sh
    time ./Mambaforge-4.10.3-5-Linux-x86_64.sh -b
    time mambaforge/bin/conda init bash
}

read -p "setup Anaconda? (y or n): " doit
if [ $doit = "y" ]; then
    setupAnaconda
    condain="y"
fi
doit="n"

#####################
# Setup brew
#####################
setupBrew() {
    echo "setup brew"
    time /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    time echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>$HOME/.profile
    time eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    echo "install gh and yq"
    time brew install gh yq
}

read -p "setup Brew? (y or n): " doit
if [ $doit = "y" ]; then
    setupBrew
    brewin="y"
fi
doit="n"

#####################
# Setup Microsoft Edge
#####################
setupMSEdge() {
    echo "setup Microsoft edge"
    time curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
    time sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
    time sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
    time rm microsoft.gpg
    sudo apt update -y
    time sudo apt install microsoft-edge-dev -y
}

read -p "setup MS Edge? (y or n): " doit
if [ $doit = "y" ]; then
    setupMSEdge
fi
doit="n"

#####################
# Setup Spark
#####################
setupSpark() {
    echo "setup Java and Spark"
    # install java
    time sudo apt install openjdk-11-jdk -y
    # install spark
    time curl -sL https://archive.apache.org/dist/spark/spark-3.1.2/spark-3.1.2-bin-hadoop3.2.tgz | sudo tar xvzf - -C /usr/local/
    time sudo ln -s /usr/local/spark-3.1.2-bin-hadoop3.2.tgz/ /usr/local/spark
    # make yourself the owner of the spark directory in /usr/local,
    # so substitute for "spark" whatever username you created for the WSL
    time sudo chown -R $USER:$USER /usr/local/spark*
}

read -p "setup Spark? (y or n): " doit
if [ $doit = "y" ]; then
    setupSpark
fi
doit="n"

#################
# Setup VS Code
#################

setupCode() {
    time sudo snap install --classic code
}

read -p "setup VS Code? (y or n): " doit
if [ $doit = "y" ]; then
    setupCode
fi
doit="n"

#################
# Setup MultiPass
#################

setupMultiPass() {
    time sudo snap install multipass
}

read -p "setup MultiPass? (y or n): " doit
if [ $doit = "y" ]; then
    setupMultiPass
fi
doit="n"

##################
# Setup kubectl
##################

setupKubectl() {
    time sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    time echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
    time sudo apt update
    time sudo apt install -y kubectl
}

read -p "setup kubectl? (y or n): " doit
if [ $doit = "y" ]; then
    setupKubectl
fi
doit="n"

#################
# Setup Flux
#################

setupFlux() {
    time curl -s https://fluxcd.io/install.sh | sudo bash
}

read -p "setup Flux? (y or n): " doit
if [ $doit = "y" ]; then
    setupFlux
fi
doit="n"

#################
# Setup Docker
#################

setupDocker() {
    time curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    time echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    time sudo apt-get update
    time sudo apt-get install docker-ce docker-ce-cli containerd.io
    sudo groupadd docker
    sudo usermod -aG docker $USER
}

read -p "setup Docker? (y or n): " doit
if [ $doit = "y" ]; then
    setupDocker
fi
doit="n"

###############
# Setup zsh
###############
setupZSH() {
    echo "setup zsh"
    time sudo apt install zsh -y
    time sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    time git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/plugins/zsh-autosuggestions
    time git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
    time git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
    time cp ./zshenv $HOME/.zshenv
    time cp ./zshrc $HOME/.zshrc

    if [ $brewin = "y" ]; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>$HOME/.zshrc
    fi
    if [ $condain = "y" ]; then
        $HOME/mambaforge/bin/conda init zsh
    fi
}

read -p "setup ZSH? (y or n): " doit
if [ $doit = "y" ]; then
    setupZSH
fi
doit="n"

echo "completed ubuntu devbox install on pid $$"
