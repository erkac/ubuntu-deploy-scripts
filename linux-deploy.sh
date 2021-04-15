#!/bin/bash

###
# Variables
###
interactive="1"
originalPath=`pwd`



###
# Functions
###

function detect_linux()
{
  if [ -f "/etc/os-release" ]; then
    . /etc/os-release

    case $ID in
      ubuntu )    interactive=0
                            ;;
      centos )    os_upgrade=1
                            ;;
      * )         usage
                  exit 1
    esac
  else
    printError "Unable to detect Linux distribution!"
    exit 1
  fi
}

function usage()
{
  echo "usage: ubuntu-deploy.sh [[-s] [-u] ] | [-h]]"
  echo " -h  - help"
  echo " -s  - silend/script mode"
  echo " -u  - upgrade OS"
  echo
  exit
}

function tuneZsh()
{
  echo
  echo "Tuning Shell..."

  echo
  echo "Installing Oh-my-zsh..."
  curl -o install.sh -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
  chmod +x install.sh
  sh ./install.sh --unattended

  echo
  echo "Installing powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
  cp configs/p10kzsh $HOME/.p10k.zsh
  chmod 644 $HOME/.p10k.zsh

  echo
  echo "Installing plugins..."
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

  echo
  echo "Copy zshrc..."
  cp configs/zshrc $HOME/.zshrc
  chmod 644 $HOME/.zshrc

  printLine
}

function question()
{
  questionInput=""
  echo
  echo "$1"
  read questionInput
}

function changeShell()
{
  if [ "${interactive}" == "1" ]; then
    question "Do you want to change default shell to zsh? (y/N)"
    
    if [ "${questionInput}" == "y" ]; then
      echo "Changing the default shell to zsh..."
      sudo chsh $USER -s /usr/bin/zsh
    else
      echo "Please run zsh to test it..."
    fi
  else
    echo "Changing the default shell to zsh..."
    sudo chsh $USER -s /usr/bin/zsh
  fi
}

function printLine()
{
	echo "======================================="
}

function printError()
{
	echo "======================================="
  echo "ERROR: $1"
	echo "======================================="
}



function addHosts()
{
  if [ ! $( grep -c generic /etc/hosts ) -eq "1" ]; then

    echo
    echo "Adding entries to hosts file..."

echo "

# generic
8.8.8.8     google

" >> /etc/hosts

    printLine
fi

}

###
# Main Script
###

while [ "$1" != "" ]; do
    case $1 in
        -s | --script-mode )    interactive=0
                                ;;
        -u | --upgrade )        os_upgrade=1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

printLine
echo "Linux Customization Script..."
printLine

detect_linux

###
# General system tuning
###

if [ "${EUID}" == "0" ]; then
  addHosts
fi

###
# Software Management
###

echo
echo "System Package Management Update..."
sudo apt update || ( echo "Error: apt update failed... Exiting." && exit 1 )

if [ "${interactive}" == "1" ]; then
  question "Do you want to upgrade the system? (y/N)"
  if [ "${questionInput}" == "y" ]; then
    echo "Upgrading OS..."
    sudo apt -y upgrade
    printLine
  fi
else
  if [ "$os_upgrade" == "1" ]; then
    echo "Upgrading OS..."
    sudo apt -y upgrade
    printLine
  fi
fi

echo
echo "Installing usefull software..."
if [ "${interactive}" == "1" ]; then
  sudo apt install nmap screen bzip2 psmisc htop mc grc iputils-ping zsh autojump jq python3-pygments httpie || ( echo "Installation failed... Exiting." && exit 1 )
else
  sudo apt -y install nmap screen bzip2 psmisc htop mc grc iputils-ping zsh autojump jq python3-pygments httpie || ( echo "Installation failed... Exiting." && exit 1 )
fi
printLine

###
# vim
###

echo
echo "vim..."
mkdir -p $HOME/.vim/colors/
cp configs/vim_colors_solarized.vim $HOME/.vim/colors/solarized.vim
cp configs/vimrc $HOME/.vimrc
chmod 644 $HOME/.vimrc
echo "vim... installing plugins"
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall
printLine


###
# zsh & oh-my-zsh
###
if [ -f /usr/bin/zsh ]; then

  tuneZsh
  
  changeShell

else
  echo "Error: No zsh installed..."
  printLine
fi

printLine

###
# git variables
###
echo
echo "Setting the GIT variables..."
git config --global user.email "lubos@klokner.sk"
git config --global user.name "lubos klokner"

###
# install exa
###
echo
echo "Installing exa to replace ls..."
wget https://github.com/ogham/exa/releases/download/v0.9.0/exa-linux-x86_64-0.9.0.zip
unzip exa-linux-x86_64-0.9.0.zip
sudo mv exa-linux-x86_64 /usr/local/bin/exa

printLine
echo

cd $originalPath
