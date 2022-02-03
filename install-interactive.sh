#!/bin/bash
# Based on https://github.com/Azure/azure-quickstart-templates/blob/e1b25fc3fd6545f90aaa536800d4aeb7bf61d1b5/demos/ubuntu-desktop-gnome/configure-ubuntu.sh
# (MIT License)
# NB: need to occassionaly update versions of software listed here
#TODO: for non-interactive version (e.g. as script on VM creation) need to modify the ask
# print commands and arguments as they are executed
set -x 

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
  sudo apt update -y
  sudo apt upgrade -y
  if [ ! -d "$HOME/.local/bin" ]; then
    sudo apt install apt-transport-https ca-certificates curl software-properties-common build-essential procps file git gnupg lsb-release fonts-firacode fonts-cascadia-code neovim direnv -y
    mkdir -p $HOME/.local/bin
  fi
}

read -p "is this the first time you are running this script? (y or n): " doit
if [ $doit = "y" ]; then
  updateUbuntu
fi
doit="n"


###################################################
# Setup gnome desktop
###################################################
setupGnome() {
  echo "install Gnome desktop"
  # kill the waagent and uninstall, otherwise, adding the desktop will do this and kill this script
  sudo pkill waagent
  sudo apt remove walinuxagent -y
  sudo apt install ubuntu-gnome-desktop firefox ntp terminator -y
  # don't automatically launch the desktop
  sudo systemctl set-default multi-user.target
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
  sudo apt install tigervnc-standalone-server -y
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
  vncpasswd
  startvnc
  stopvnc

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
  sudo apt install xrdp -y
  # change access from root only to all users
  sudo sed -i 's/allowed_users=console/allowed_users=anybody/' /etc/X11/Xwrapper.config
  #start remote desktop session
  sudo service xrdp restart
}

read -p "setup xrdp? (y or n): " doit
if [ $doit = "y" ]; then
  setupRDP
fi
doit="n"

#################################
# setup the Azure CLI and AZcopy
#################################
setupAzure() {
  echo "setup Azure CLI"
  curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

  echo "setup Azcopy"
  curl -sL https://aka.ms/downloadazcopy-v10-linux | sudo tar xvzf - -C /usr/local/bin --strip-components=1
  sudo rm /usr/local/bin/NOTICE.txt
}

read -p "setup Azure? (y or n): " doit
if [ $doit = "y" ]; then
  setupAzure
fi
doit="n"

#####################
# setup Anaconda
#####################
setupAnaconda() {
  echo "setup Anaconda"
  wget https://github.com/conda-forge/miniforge/releases/latest/download/Mambaforge-Linux-x86_64.sh
  chmod +x Mambaforge-Linux-x86_64.sh
  ./Mambaforge-Linux-x86_64.sh -b
  mambaforge/bin/conda init bash
  rm -f Mambaforge-Linux-x86_64.sh
}

read -p "setup Anaconda? (y or n): " doit
if [ $doit = "y" ]; then
  setupAnaconda
  condain="y"
fi
doit="n"

#####################
# setup brew
#####################
setupBrew() {
  echo "setup brew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >>$HOME/.profile
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  echo "install gh and yq"
  brew install gh yq
}

read -p "setup Brew? (y or n): " doit
if [ $doit = "y" ]; then
  setupBrew
  brewin="y"
fi
doit="n"

#####################
# setup Microsoft Edge
#####################
setupMSEdge() {
  echo "setup Microsoft edge"
  curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor >microsoft.gpg
  sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
  sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
  rm microsoft.gpg
  sudo apt update -y
  sudo apt install microsoft-edge-dev -y
}

read -p "setup MS Edge? (y or n): " doit
if [ $doit = "y" ]; then
  setupMSEdge
fi
doit="n"

#####################
# setup Spark
#####################
setupSpark() {
  echo "setup Java, Spark and Hadoop"
  # install java
  sudo apt install openjdk-11-jdk -y
  # install spark
  curl -sL https://apache.mivzakim.net/spark/spark-3.0.2/spark-3.0.2-bin-without-hadoop.tgz | sudo tar xvzf - -C /usr/local/
  sudo ln -s /usr/local/spark-3.0.2-bin-without-hadoop/ /usr/local/spark
  # make yourself the owner of the spark directory in /usr/local,
  # so substitute for "spark" whatever username you created for the WSL
  sudo chown -R $USER:$USER /usr/local/spark*
  # install hadoop
  curl -sL https://apache.mivzakim.net/hadoop/common/hadoop-3.2.2/hadoop-3.2.2.tar.gz | sudo tar xvzf - -C /usr/local/
  sudo ln -s /usr/local/hadoop-3.2.2/ /usr/local/hadoop
  # make yourself the owner of the hadoop directory in /usr/local,
  # so substitute for "spark" whatever username you created for the WSL
  sudo chown -R $USER:$USER /usr/local/hadoop*
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/apache-log4j-extras-1.2.17.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/aws-java-sdk-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/aws-java-sdk-core-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/aws-java-sdk-dynamodb-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/aws-java-sdk-kms-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/aws-java-sdk-s3-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/hadoop-aws-3.2.1.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/ion-java-1.0.2.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/jackson-dataformat-cbor-2.10.0.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/jmespath-java-1.11.820.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/joda-time-2.8.1.jar
  wget -P /usr/local/spark/jars/https://dmdevsa01.blob.core.windows.net/sparkjars/postgresql-42.2.19.jar
}

read -p "setup Spark? (y or n): " doit
if [ $doit = "y" ]; then
  setupSpark
fi
doit="n"

#################
# setup VS Code
#################

setupCode() {
  sudo snap install --classic code
}

read -p "setup VS Code? (y or n): " doit
if [ $doit = "y" ]; then
  setupCode
fi
doit="n"

#################
# setup MultiPass
#################

setupMultiPass() {
  sudo snap install multipass
}

read -p "setup MultiPass? (y or n): " doit
if [ $doit = "y" ]; then
  setupMultiPass
fi
doit="n"

##################
# setup kubectl
##################

setupKubectl() {
  sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
  echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
  sudo apt update
  sudo apt install -y kubectl
}

read -p "setup kubectl? (y or n): " doit
if [ $doit = "y" ]; then
  setupKubectl
fi
doit="n"

#################
# setup Flux
#################

setupFlux() {
  curl -s https://fluxcd.io/install.sh | sudo bash
}

read -p "setup Flux? (y or n): " doit
if [ $doit = "y" ]; then
  setupFlux
fi
doit="n"

#################
# setup Docker
#################

setupDocker() {
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io
  sudo groupadd docker
  sudo usermod -aG docker $USER
}

read -p "setup Docker? (y or n): " doit
if [ $doit = "y" ]; then
  setupDocker
fi
doit="n"

###############
# setup zsh
###############
setupZSH() {
  echo "setup zsh"
  sudo apt install zsh -y
  sudo chsh -s zsh
  sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  git clone https://github.com/agkozak/zsh-z $ZSH_CUSTOM/plugins/zsh-z
  git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/plugins/zsh-syntax-highlighting
  cp ./zshenv $HOME/.zshenv
  cp ./zshrc $HOME/.zshrc
  cp ./tmux.conf $HOME/.tmux.conf
  mkdir -p $HOME/conf/nvim
  cp ./init.vim $HOME/.config/nvim/

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
