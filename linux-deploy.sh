#!/bin/bash

###
# Variables
###
interactive="1"
originalPath=$(pwd)
DISTRO=""
PKG_CMD=""

###
# Functions
###

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

function usage()
{
    echo "usage: linux-deploy.sh [[-s] [-u]] | [-h]"
    echo " -h  - help"
    echo " -s  - silent/script mode"
    echo " -u  - upgrade OS"
    echo
    exit
}

function question()
{
    questionInput=""
    echo
    echo "$1"
    read questionInput
}

function detect_linux()
{
    if [ -f "/etc/os-release" ]; then
        . /etc/os-release
        case $ID in
            ubuntu|debian)
                DISTRO="debian"
                PKG_CMD="apt"
                ;;
            centos|rhel)
                DISTRO="centos"
                if command -v dnf &>/dev/null; then
                    PKG_CMD="dnf"
                else
                    PKG_CMD="yum"
                fi
                ;;
            *)
                printError "Unsupported Linux distribution: $ID"
                exit 1
                ;;
        esac
    else
        printError "Unable to detect Linux distribution!"
        exit 1
    fi
    echo "Detected distribution: $ID (family: $DISTRO, package manager: $PKG_CMD)"
}

function addHosts()
{
    if [ ! $(grep -c generic /etc/hosts) -eq "1" ]; then
        echo
        echo "Adding entries to hosts file..."
echo "

# generic
8.8.8.8     google

" >> /etc/hosts
        printLine
    fi
}

function pkg_install()
{
    if [ "$DISTRO" == "debian" ]; then
        if [ "${interactive}" == "1" ]; then
            sudo apt install "$@"
        else
            sudo apt -y install "$@"
        fi
    else
        if [ "${interactive}" == "1" ]; then
            sudo $PKG_CMD install "$@"
        else
            sudo $PKG_CMD -y install "$@"
        fi
    fi
}

function install_packages()
{
    if [ "$DISTRO" == "debian" ]; then
        echo
        echo "Installing useful software..."
        pkg_install nmap screen bzip2 psmisc htop mc grc iputils-ping zsh autojump jq \
            python3-pygments httpie molly-guard fzf bat curl make eza dnsutils \
            || (echo "Installation failed... Exiting." && exit 1)
        pkg_install ruby-albino

    else
        echo
        echo "Enabling EPEL repository..."
        sudo $PKG_CMD -y install epel-release

        echo
        echo "Installing useful software..."
        # molly-guard and ruby-albino not available on CentOS/RHEL
        # dnsutils -> bind-utils, iputils-ping -> iputils, eza installed separately
        pkg_install nmap screen bzip2 psmisc htop mc grc iputils zsh autojump jq \
            python3-pygments httpie fzf bat curl make bind-utils \
            || (echo "Installation failed... Exiting." && exit 1)

        install_eza_manual
    fi
}

function install_eza_manual()
{
    echo
    echo "Installing eza manually..."
    local eza_url
    eza_url=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
        | grep "browser_download_url" \
        | grep "eza_x86_64-unknown-linux-gnu.tar.gz\"" \
        | cut -d '"' -f 4)

    if [ -z "$eza_url" ]; then
        echo "Warning: Could not fetch eza release URL, skipping."
        return
    fi

    curl -Lo /tmp/eza.tar.gz "$eza_url"
    tar xzf /tmp/eza.tar.gz -C /tmp eza
    sudo mv /tmp/eza /usr/local/bin/eza
    rm -f /tmp/eza.tar.gz
    printLine
}

function install_vim()
{
    echo
    echo "vim..."
    if [ "$DISTRO" == "debian" ]; then
        sudo apt -y install vim
    else
        sudo $PKG_CMD -y install vim-enhanced
    fi
    mkdir -p $HOME/.vim/colors/
    cp configs/vim_colors_solarized.vim $HOME/.vim/colors/solarized.vim
    cp configs/vimrc $HOME/.vimrc
    chmod 644 $HOME/.vimrc
    echo "vim... installing plugins"
    curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim +PlugInstall +qall
    printLine
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
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/themes/powerlevel10k
    cp configs/p10kzsh $HOME/.p10k.zsh
    chmod 644 $HOME/.p10k.zsh

    echo
    echo "Installing plugins..."
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    git clone https://github.com/zsh-users/zsh-completions \
        ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions

    echo
    echo "Copy zshrc..."
    cp configs/zshrc $HOME/.zshrc
    cp configs/grc.zsh $HOME/.grc.zsh
    chmod 644 $HOME/.zshrc
    chmod 644 $HOME/.grc.zsh

    printLine
}

function setupRootScreen()
{
    echo
    echo "Setting up screen auto-start for root..."
    sudo cp configs/screenrc /root/.screenrc
    sudo cp configs/zprofile /root/.zprofile
    sudo chmod 644 /root/.screenrc /root/.zprofile
    printLine
}

function changeShell()
{
    local zsh_path
    zsh_path=$(command -v zsh)

    if [ "${interactive}" == "1" ]; then
        question "Do you want to change default shell to zsh? (y/N)"
        if [ "${questionInput}" == "y" ]; then
            echo "Changing the default shell to zsh..."
            sudo chsh $USER -s "$zsh_path"
        else
            echo "Please run zsh to test it..."
        fi
    else
        echo "Changing the default shell to zsh..."
        sudo chsh $USER -s "$zsh_path"
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
if [ "$DISTRO" == "debian" ]; then
    sudo apt update || (echo "Error: apt update failed... Exiting." && exit 1)
else
    sudo $PKG_CMD makecache || (echo "Error: $PKG_CMD makecache failed... Exiting." && exit 1)
fi

if [ "${interactive}" == "1" ]; then
    question "Do you want to upgrade the system? (y/N)"
    if [ "${questionInput}" == "y" ]; then
        echo "Upgrading OS..."
        if [ "$DISTRO" == "debian" ]; then
            sudo apt -y upgrade
        else
            sudo $PKG_CMD -y update
        fi
        printLine
    fi
else
    if [ "$os_upgrade" == "1" ]; then
        echo "Upgrading OS..."
        if [ "$DISTRO" == "debian" ]; then
            sudo apt -y upgrade
        else
            sudo $PKG_CMD -y update
        fi
        printLine
    fi
fi

install_packages
printLine

###
# vim
###

install_vim

###
# zsh & oh-my-zsh
###

if command -v zsh &>/dev/null; then
    # On CentOS, ensure zsh is listed in /etc/shells
    if [ "$DISTRO" == "centos" ] && [ "$EUID" -eq 0 ]; then
        zsh_path=$(command -v zsh)
        if ! grep -q "$zsh_path" /etc/shells; then
            echo "Adding $zsh_path to /etc/shells"
            echo "$zsh_path" >> /etc/shells
        fi
    fi

    tuneZsh
    changeShell
else
    echo "Error: No zsh installed..."
    printLine
fi

###
# root screen auto-start
###

setupRootScreen

printLine

###
# git variables
###
echo
echo "Setting the GIT variables..."
git config --global user.email "lubos@klokner.sk"
git config --global user.name "lubos klokner"

printLine

cd $originalPath
