#!/bin/bash
set -euo pipefail

###
# Variables
###
interactive="1"
os_upgrade=""
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
    if ! grep -q "generic" /etc/hosts; then
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
            python3-pygments httpie molly-guard fzf bat curl make eza dnsutils
        pkg_install ruby-albino || true

        # Debian/Ubuntu installs bat as batcat due to a name collision
        if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
            sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
        fi

    else
        echo
        echo "Enabling EPEL repository..."
        sudo $PKG_CMD -y install epel-release

        echo
        echo "Installing useful software..."
        # molly-guard and ruby-albino not available on CentOS/RHEL
        # dnsutils -> bind-utils, iputils-ping -> iputils, eza installed separately
        pkg_install nmap screen bzip2 psmisc htop mc grc iputils zsh autojump jq \
            python3-pygments httpie fzf bat curl make bind-utils

        install_eza_manual
    fi
}

function install_eza_manual()
{
    echo
    echo "Installing eza manually..."

    local arch eza_arch eza_url
    arch=$(uname -m)
    case $arch in
        x86_64)  eza_arch="x86_64-unknown-linux-gnu" ;;
        aarch64) eza_arch="aarch64-unknown-linux-gnu" ;;
        armv7l)  eza_arch="arm-unknown-linux-gnueabihf" ;;
        *)
            echo "Warning: Unsupported architecture $arch for eza, skipping."
            return
            ;;
    esac

    eza_url=$(curl -s https://api.github.com/repos/eza-community/eza/releases/latest \
        | grep "browser_download_url" \
        | grep "eza_${eza_arch}.tar.gz\"" \
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

    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo
        echo "Installing Oh-my-zsh..."
        curl -o /tmp/omz-install.sh -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh
        chmod +x /tmp/omz-install.sh
        sh /tmp/omz-install.sh --unattended
        rm -f /tmp/omz-install.sh
    else
        echo "Oh-my-zsh already installed, skipping."
    fi

    echo
    echo "Installing powerlevel10k theme..."
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    else
        echo "powerlevel10k already installed, skipping."
    fi
    cp configs/p10kzsh $HOME/.p10k.zsh
    chmod 644 $HOME/.p10k.zsh

    echo
    echo "Installing plugins..."
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
    fi
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
    fi
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions" ]; then
        git clone https://github.com/zsh-users/zsh-completions \
            "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"
    fi

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

function install_docker()
{
    echo
    echo "Installing Docker..."

    if [ "$DISTRO" == "debian" ]; then
        local docker_id
        docker_id=$(. /etc/os-release && echo "$ID")  # "ubuntu" or "debian"
        sudo apt -y install ca-certificates curl
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo curl -fsSL "https://download.docker.com/linux/${docker_id}/gpg" \
            -o /etc/apt/keyrings/docker.asc
        sudo chmod a+r /etc/apt/keyrings/docker.asc
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/${docker_id} $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
            | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt -y install docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
    else
        sudo $PKG_CMD -y install yum-utils
        sudo yum-config-manager --add-repo \
            https://download.docker.com/linux/centos/docker-ce.repo
        sudo $PKG_CMD -y install docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin
    fi

    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "Docker installed. Log out and back in for group membership to take effect."
    printLine
}

function harden_ssh()
{
    local sshd_config="/etc/ssh/sshd_config"
    local backup="${sshd_config}.bak.$(date +%Y%m%d%H%M%S)"

    echo
    echo "WARNING: This will disable password authentication and root SSH login."
    echo "Make sure your SSH public key is already in ~/.ssh/authorized_keys"
    echo "before proceeding, or you will be locked out."
    question "Are you sure you want to harden SSH? (y/N)"
    if [ "${questionInput}" != "y" ]; then
        echo "SSH hardening skipped."
        return
    fi

    echo "Backing up $sshd_config to $backup..."
    sudo cp "$sshd_config" "$backup"

    echo "Applying SSH hardening..."
    # Each sed handles both commented-out and active versions of the setting
    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$sshd_config"
    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$sshd_config"
    sudo sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$sshd_config"

    echo "Validating config..."
    sudo sshd -t || (
        printError "sshd config validation failed — restoring backup"
        sudo cp "$backup" "$sshd_config"
        exit 1
    )

    sudo systemctl restart sshd
    echo "SSH hardened. Password authentication and root login are now disabled."
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

# Ensure we run from the script's own directory so configs/ is always reachable
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"
if [ ! -d "configs" ]; then
    printError "configs/ directory not found next to this script."
    exit 1
fi

trap 'printError "Script failed at line $LINENO"' ERR

while (( $# )); do
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

if [ "$EUID" -eq 0 ]; then
    addHosts
fi

###
# Software Management
###

echo
echo "System Package Management Update..."
if [ "$DISTRO" == "debian" ]; then
    sudo apt update
else
    sudo $PKG_CMD makecache
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
# Docker
###

if [ "${interactive}" == "1" ]; then
    question "Do you want to install Docker? (y/N)"
    if [ "${questionInput}" == "y" ]; then
        install_docker
    fi
fi

###
# SSH hardening
###

if [ "${interactive}" == "1" ]; then
    question "Do you want to harden SSH (disable password auth and root login)? (y/N)"
    if [ "${questionInput}" == "y" ]; then
        harden_ssh
    fi
fi

###
# git variables
###
echo
echo "Setting the GIT variables..."
if [ "${interactive}" == "1" ]; then
    question "Enter git email (leave blank for lubos@klokner.sk):"
    git_email="${questionInput:-lubos@klokner.sk}"
    question "Enter git name (leave blank for lubos klokner):"
    git_name="${questionInput:-lubos klokner}"
else
    git_email="lubos@klokner.sk"
    git_name="lubos klokner"
fi
git config --global user.email "$git_email"
git config --global user.name "$git_name"

printLine

cd "$originalPath"
