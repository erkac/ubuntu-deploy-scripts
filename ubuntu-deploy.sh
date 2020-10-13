#!/bin/bash

###
# Variables
###
interactive="1"
originalPath=`pwd`

###
# Functions
###

function usage()
{
  echo "usage: ubuntu-deploy.sh [[-s] | [-h]]"
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
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

printLine
echo "Ubuntu Customization Script..."
printLine

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

if [ "${EUID}" == "0" ]; then
    question "Do you want to upgrade the system? (y/N)"
    
    if [ "${questionInput}" == "y" ]; then
        echo "Upgrading..."    
        apt -y upgrade
        printLine
    fi
fi

echo
echo "Installing usefull software..."
if [ "${interactive}" == "1" ]; then
    sudo apt install nmap screen bzip2 psmisc htop mc grc iputils-ping zsh autojump jq python3-pygments || ( echo "Installation failed... Exiting." && exit 1 )
else
    sudo apt -y install nmap screen bzip2 psmisc htop mc grc iputils-ping zsh autojump jq python3-pygments || ( echo "Installation failed... Exiting." && exit 1 )
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

printLine
echo

#echo "iptables..."
#${CURL_BIN} /etc/iptables.rules ${DOWNLOAD_HOST}/iptables.rules
#echo "
##!/bin/sh
#iptables-restore < /etc/iptables.rules
#exit 0
#" > /etc/network/if-pre-up.d/iptablesload
#chmod 755 /etc/network/if-pre-up.d/iptablesload
#/etc/network/if-pre-up.d/iptablesload
#printLine

# QUESTION=""
# echo "Deploy H4X0r t00lZ? (y/N)"
# read QUESTION
# if [ "${QUESTION}" == "y" ]; then
#     mkdir -p $HOME/ddos
#     apt-get install slowhttptest
   
#     ${CURL_BIN} $HOME/ddos/httpflooder.pl https://raw.githubusercontent.com/ddusnoki/httpflooder/master/httpflooder/httpflooder.pl
#     chmod 755 $HOME/ddos/httpflooder.pl

#     cp ./tools/hulk.py $HOME/ddos/hulk.py
#     chmod 755 $HOME/ddos/hulk.py

#     ${CURL_BIN} $HOME/ddos/phantomjs-2.1.1-linux-x86_64.tar.bz2 https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2
#     cp ./tools/L7DDOS.js $HOME/ddos/L7DDOS.js
#     cd $HOME/ddos/
#     tar xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2

#     echo 'export QT_QPA_PLATFORM="offscreen"' >> $HOME/.bashrc
#     echo 'alias phantomjs="$HOME/ddos/phantomjs-2.1.1-linux-x86_64/bin/phantomjs"' >> $HOME/.aliases
#     echo 'export QT_QPA_PLATFORM=offscreen' >> $HOME/.bash_profile
# #    echo "
# ## L7 DoS Demo
# #52.16.253.235   www.trnava-live.sk
# #    " >> /etc/hosts
# fi
# printLine

cd $originalPath
