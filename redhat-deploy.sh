#!/bin/bash

CURL_BIN="curl -s -o"

function printLine()
{
	echo "======================================="
}

function addHosts()
{
  if [ ! $( grep -c generic /etc/hosts ) -eq "1" ]; then
echo "

# generic
8.8.8.8     google

" >> /etc/hosts
fi

}

originalPath=`pwd`

amIRoot=`whoami`
if [ "${amIRoot}" == "root" ]; then

    QUESTION=""
    echo "Do you want to upgrade the system? (y/N)"
    read QUESTION
    if [ "${QUESTION}" == "y" ]; then
        echo "Upgrade..."
        yum -y update
        printLine
    fi

    echo "Installing usefull software..."
    yum -y install nmap screen bzip2 psmisc mc zsh
    printLine
fi

echo "vim..."
mkdir -p $HOME/.vim/colors/
cp configs/vim_colors_solarized.vim $HOME/.vim/colors/solarized.vim
cp configs/vimrc $HOME/.vimrc
chmod 644 $HOME/.vimrc
echo "vim... installing plugins"
curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || ( mkdir -p $HOME/.vim/autoload/ && cp -a configs/plug.vim $HOME/.vim/autoload/plug.vim )
vim +PluginInstall +qall
printLine

if [ "$EUID" -eq 0 ]; then
  echo "Add entries to hosts file..."
  addHosts
fi

if [ ! -f /usr/bin/zsh ]; then
  echo "Error: No zsh installed... exiting..."
  exit 1
  printLine
fi

echo
echo "Shell..."

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
git clone git://github.com/wting/autojump.git && cd autojump && ./install.py

echo
echo "Copy zshrc..."
cp configs/zshrc $HOME/.zshrc
chmod 644 $HOME/.zshrc

printLine

if [ "$EUID" -eq 0 ]; then
  echo "Adding /usr/bin/zsh to /etc/shells"
  echo "/usr/bin/zsh" >> /etc/shells
fi

QUESTION=""
echo "Do you want to change default shell to zsh? (y/N)"
read QUESTION
if [ "${QUESTION}" == "y" ]; then
  if [ -f /usr/bin/zsh ]; then
    echo "Changing the default shell to zsh..."
    chsh $USER -s /bin/zsh
  fi
fi

printLine

echo "Set the variables git..."
git config --global user.email "lubos@klokner.sk"
git config --global user.name "lubos klokner"

printLine

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

# TODO/Issues
# - for some reason the instalation of the oh-my-zsh fails because it is instaled into \~ subfolder instead of ~ for non-root users
