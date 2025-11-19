#!/bin/bash

set -eu

# Color variables
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# Centered header box
center_box() {
  local msg1="$1"
  local msg2="$2"
  local msg3="$3"
  echo -e "${RED}${BOLD}#############################################"
  printf "#%*s%*s#\n" $(( (43 + ${#msg1}) / 2 )) "$msg1" $(( (43 - ${#msg1}) / 2 )) ""
  printf "#%*s%*s#\n" $(( (43 + ${#msg2}) / 2 )) "$msg2" $(( (43 - ${#msg2}) / 2 )) ""
  printf "#%*s%*s#\n" $(( (43 + ${#msg3}) / 2 )) "$msg3" $(( (43 - ${#msg3}) / 2 )) ""
  echo -e "#############################################${RESET}\n"
}

# Centered section title
header() {
  local title="$1"
  local len=${#title}
  local border=$(printf '=%.0s' $(seq 1 $(( (45 - len) / 2 ))))
  echo -e "\n${CYAN}${BOLD}${border} $title ${border}${RESET}\n"
}

# Confirm execution
clear
center_box "Be Careful" "This will override your Rice!!" "Proceed at your own risk!"

read -p "Are you sure you want to continue? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

# Function to add XeroLinux repo
add_xerolinux_repo() {
  if grep -Pq '^\[xerolinux\]' /etc/pacman.conf; then
    echo "XeroLinux repo already present."
  else
    echo "Adding XeroLinux repository..."
    echo -e "\n[xerolinux]\nSigLevel = Optional TrustAll\nServer = https://repos.xerolinux.xyz/\$repo/\$arch" | sudo tee -a /etc/pacman.conf >/dev/null
  fi
}

# Function to add the Chaotic-AUR repository
add_chaotic_aur() {
  if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    header "Adding The Chaotic-AUR Repository"
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
    sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
    echo -e '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist' | sudo tee -a /etc/pacman.conf
    echo "Chaotic-AUR Repository added!"
  else
    echo "Chaotic-AUR Repository already added."
  fi
}

header "Adding Repositories"
add_xerolinux_repo
add_chaotic_aur

header "Installing Native Packages"
sudo pacman -Sy --noconfirm --needed \
  cava kwin-zones imagemagick kvantum unzip jq xmlstarlet fastfetch \
  ttf-hack-nerd ttf-fira-code kdeconnect ttf-terminus-nerd \
  noto-fonts-emoji ttf-meslo-nerd kde-wallpapers falkon

# Detect or install AUR helper
setup_aur_helper() {
  if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
  elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
  else
    header "AUR Helper Setup"
    echo "Choose AUR helper to install:"
    select choice in "paru" "yay"; do
      case "$choice" in
        paru|yay)
          sudo pacman -Syy "$choice"
          AUR_HELPER="$choice"
          break
          ;;
        *)
          echo "Invalid choice."
          ;;
      esac
    done
  fi
  echo "Using AUR helper: $AUR_HELPER"
}

setup_aur_helper

header "Installing AUR Packages"
$AUR_HELPER -S --noconfirm --needed \
  ttf-meslo-nerd-font-powerlevel10k tela-circle-icon-theme-purple oh-my-posh-bin pacseek

header "Backing Up & Applying Rice"
backup_dir="$HOME/.config-backup-$(date +%Y.%m.%d-%H.%M.%S)"
echo "Backing up current config to $backup_dir"
cp -Rf ~/.config "$backup_dir"
cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. /
sudo cp -Rf Configs/Home/. /root/

header "Setting up Fastfetch"
read -p "Enable fastfetch on terminal launch? (y/n): " response
if [[ $response =~ ^[Yy]$ ]]; then
  shell_rc="$HOME/.${SHELL##*/}rc"
  if ! grep -Fxq 'fastfetch' "$shell_rc"; then
    echo -e "\nfastfetch" >> "$shell_rc"
    echo "fastfetch added to $shell_rc"
  else
    echo "fastfetch already present in $shell_rc"
  fi
else
  echo "Skipped fastfetch setup."
fi

header "Injecting Oh-My-Posh into Bash"
bashrc_file="$HOME/.bashrc"
grep -qxF '# Oh-My-Posh Config' "$bashrc_file" || echo -e '\n# Oh-My-Posh Config' >> "$bashrc_file"
grep -qxF 'eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/distrous-xero-linux.omp.json)"' "$bashrc_file" || \
  echo 'eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/distrous-xero-linux.omp.json)"' >> "$bashrc_file"
echo "Oh-My-Posh injection complete."

header "Installing GRUB Theme"
if [ -d "/boot/grub" ]; then
  sudo ./Grub.sh
  sudo sed -i "s/^GRUB_GFXMODE=.*/GRUB_GFXMODE=1920x1080x32/" /etc/default/grub
else
  echo "GRUB not detected, skipping theme."
fi

header "Installing Layan KDE Theme"
if git clone https://github.com/vinceliuice/Layan-kde.git; then
  cd Layan-kde && sh install.sh && cd .. && rm -rf Layan-kde
else
  echo "Failed to install Layan-kde"
fi

header "Installing Layan GTK Theme"
mkdir -p ~/.themes
if git clone https://github.com/vinceliuice/Layan-gtk-theme.git; then
  cd Layan-gtk-theme && sh install.sh -l -c dark -d ~/.themes && cd .. && rm -rf Layan-gtk-theme
else
  echo "Failed to install Layan-gtk"
fi

center_box "All Done" "Setup Complete!" "Please reboot to apply settings."
