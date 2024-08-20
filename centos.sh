#!/bin/sh

dnf -y install zsh git wget vim unzip python38

sudo alternatives --set python /usr/bin/python3

git clone git://github.com/wting/autojump.git
cd autojump
./install.py
