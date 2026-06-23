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

# Detect distribution / package manager
detect_distro() {
  if command -v pacman >/dev/null 2>&1; then
    DISTRO="arch"
  elif command -v dnf >/dev/null 2>&1; then
    DISTRO="fedora"
  else
    echo -e "${RED}Unsupported distro: need pacman (Arch) or dnf (Fedora).${RESET}"
    exit 1
  fi
  echo "Detected package manager for: $DISTRO"
}

# Confirm execution
clear
center_box "Be Careful" "This will override your Rice!!" "Proceed at your own risk!"

read -p "Are you sure you want to continue? (y/n): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

detect_distro

#############################################
# Arch Linux package setup
#############################################

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

install_arch_packages() {
  header "Adding Repositories"
  add_xerolinux_repo
  add_chaotic_aur

  header "Installing Native Packages"
  # kwin-zones = KDE-automotive ext-zones plugin, from the XeroLinux repo added above.
  sudo pacman -Sy --noconfirm --needed \
    cava kwin-zones btop imagemagick kvantum unzip jq xmlstarlet fastfetch \
    ttf-hack-nerd ttf-fira-code kdeconnect ttf-terminus-nerd python-websockets \
    noto-fonts-emoji ttf-meslo-nerd qt6-websockets adw-gtk-theme

  setup_aur_helper

  header "Installing AUR Packages"
  # Tela-circle is installed from source (shared step) for cross-distro parity.
  $AUR_HELPER -S --noconfirm --needed \
    ttf-meslo-nerd-font-powerlevel10k oh-my-posh-bin pacseek
}

#############################################
# Fedora package setup
#############################################

# Nerd Fonts are not packaged in Fedora repos -> fetch from upstream releases
install_nerd_fonts() {
  header "Installing Nerd Fonts"
  local ver="v3.2.1"
  local dir="$HOME/.local/share/fonts"
  local fonts=(Hack FiraCode Terminus Meslo)
  mkdir -p "$dir"
  for f in "${fonts[@]}"; do
    if find "$dir" -iname "*${f}*Nerd*" 2>/dev/null | grep -q .; then
      echo "$f Nerd Font already present."
      continue
    fi
    echo "Downloading $f Nerd Font..."
    if curl -fLo "/tmp/${f}.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/download/${ver}/${f}.zip"; then
      unzip -oq "/tmp/${f}.zip" -d "$dir/${f}-NF" && rm -f "/tmp/${f}.zip"
    else
      echo "Warning: failed to download $f Nerd Font, skipping."
    fi
  done
  fc-cache -f >/dev/null 2>&1 || true
}

# dnfseek: Fedora replacement for Arch's pacseek (fzf-based dnf TUI browser)
install_dnfseek() {
  header "Installing dnfseek (pacseek replacement)"
  if command -v dnfseek >/dev/null 2>&1; then
    echo "dnfseek already present."
    return
  fi
  rm -rf /tmp/dnfseek
  if git clone --depth=1 https://github.com/OmarHesham2356/dnfseek.git /tmp/dnfseek; then
    sudo install -m755 /tmp/dnfseek/dnfseek.sh /usr/local/bin/dnfseek \
      || echo "Warning: dnfseek install failed."
    rm -rf /tmp/dnfseek
  else
    echo "Warning: failed to clone dnfseek, skipping."
  fi
}

# Kurve CAVA visualizer plasmoid needs a compiled QML plugin
# (com.github.luisbocanegra.audiovisualizer.process) for its Primary backend.
# Build + install it from source; on failure the widget uses the QtWebSockets
# fallback (qt6-qtwebsockets-devel + python3-websockets, both installed above).
# install.sh puts the plugin in /usr (survives the later Configs copy) and a
# plasmoid copy in ~/.local (harmless: the rice's Configs copy overwrites it).
install_kurve_cava_plugin() {
  header "Building Kurve CAVA Visualizer Plugin"
  rm -rf /tmp/kurve
  if git clone --depth=1 --branch v3.5.1 https://github.com/luisbocanegra/kurve.git /tmp/kurve \
     || git clone --depth=1 https://github.com/luisbocanegra/kurve.git /tmp/kurve; then
    ( cd /tmp/kurve && ./install.sh ) \
      || echo "Warning: Kurve plugin build failed; widget falls back to QtWebSockets."
    rm -rf /tmp/kurve
  else
    echo "Warning: failed to clone Kurve; widget falls back to QtWebSockets."
  fi
}

# oh-my-posh (oh-my-posh-bin on Arch) -> official installer to /usr/local/bin
install_oh_my_posh_bin() {
  if command -v oh-my-posh >/dev/null 2>&1; then
    echo "oh-my-posh already present."
    return
  fi
  header "Installing Oh-My-Posh"
  curl -s https://ohmyposh.dev/install.sh | sudo bash -s -- -d /usr/local/bin \
    || echo "Warning: oh-my-posh install failed."
}

install_fedora_packages() {
  header "Installing Native Packages"
  # fzf: dnfseek dep (pacseek replacement).
  # Nerd fonts, oh-my-posh, Tela-circle handled by manual installers below.
  # Dropped vs Arch: kwin-zones (KDE-automotive ext-zones C++ plugin, no Fedora
  # package; kwinrc has kzonesEnabled=false so snapping isn't relied on) and
  # pacseek (pacman-only; replaced by dnfseek).
  # qt6-qtwebsockets-devel: ships the 'import QtWebSockets' QML module that the
  # Kurve (CAVA) visualizer plasmoid needs for its ProcessMonitor fallback;
  # the base qt6-qtwebsockets lib alone lacks the QML import on Fedora. Pulls
  # the base lib as a dependency.
  # gcc-c++/cmake/extra-cmake-modules/libplasma-devel: build Kurve's C++ plugin.
  sudo dnf install -y \
    git curl unzip fzf jq xmlstarlet ImageMagick fastfetch btop cava \
    kvantum kde-connect python3-websockets qt6-qtwebsockets-devel \
    fira-code-fonts google-noto-emoji-fonts adw-gtk3-theme \
    gcc-c++ cmake extra-cmake-modules libplasma-devel

  install_kurve_cava_plugin

  install_nerd_fonts
  install_oh_my_posh_bin
  install_dnfseek
}

#############################################
# Shared / cross-distro steps
#############################################

# Tela-circle purple icon theme installed from source on every distro
# (https://github.com/vinceliuice/Tela-circle-icon-theme) for parity.
install_tela_icons() {
  header "Installing Tela-circle Icon Theme"
  if [ -d "$HOME/.local/share/icons/Tela-circle-purple-dark" ] \
     || [ -d /usr/share/icons/Tela-circle-purple-dark ]; then
    echo "Tela-circle already present."
    return
  fi
  rm -rf /tmp/Tela-circle
  if git clone --depth=1 https://github.com/vinceliuice/Tela-circle-icon-theme.git /tmp/Tela-circle; then
    ( cd /tmp/Tela-circle && ./install.sh -c purple ) || echo "Warning: Tela-circle install failed."
    rm -rf /tmp/Tela-circle
  else
    echo "Warning: failed to clone Tela-circle, skipping."
  fi
}

# XeroLinux KDE wallpaper set (kde-wallpapers pkg from the XeroLinux Arch repo).
# Installed from source on every distro: the repo mirrors the system tree under
# usr/, matching the PKGBUILD which copies the repo root to / (minus docs).
install_xero_wallpapers() {
  header "Installing XeroLinux KDE Wallpapers"
  rm -rf /tmp/kde-wallpapers
  if git clone --depth=1 https://github.com/xerolinux/kde-wallpapers.git /tmp/kde-wallpapers; then
    sudo cp -rf /tmp/kde-wallpapers/usr/. /usr/
    rm -rf /tmp/kde-wallpapers
  else
    echo "Warning: failed to clone kde-wallpapers, skipping."
  fi
}

# Remove plasmoids/configs that only work on Arch (pacman backend) so they
# don't ship a broken updater widget on Fedora. $1 = home dir to clean.
strip_arch_plasmoids() {
  local home="$1"
  rm -rf "$home/.local/share/plasma/plasmoids/com.github.exequtic.apdatifier" \
         "$home/.config/apdatifier" \
         "$home/.config/pacseek"
}

# Swap the Arch png logo for fastfetch's built-in Fedora logo and size it to
# look right (builtin ascii is narrower than the 30-wide kitty png). $1 = home.
swap_fastfetch_logo_fedora() {
  local cfg="$1/.config/fastfetch/config.jsonc"
  [ -f "$cfg" ] || return 0
  sed -i \
    -e 's#"source": "~/.config/fastfetch/ArchP.png",#"source": "fedora",#' \
    -e 's#"type": "kitty",#"type": "builtin",#' \
    -e 's#"width": 30,#"width": 13,#' \
    -e 's#"top": 8,#"top": 6,#' \
    "$cfg"
}

# Swap the Kicker/Kickoff app-menu button icon from the Arch logo to Fedora's.
# $1 = home dir.
swap_appmenu_logo_fedora() {
  local cfg="$1/.config/plasma-org.kde.plasma.desktop-appletsrc"
  [ -f "$cfg" ] || return 0
  sed -i 's/^customButtonImage=distributor-logo-archlinux/customButtonImage=goa-account-fedora/' "$cfg"
}

# fastfetch's "kernel" module prints the full Fedora kernel string with the
# distro suffix (e.g. 6.x.x-300.fc41.x86_64). Replace that module with a command
# that strips the ".fcNN.*" suffix for a clean "Linux 6.x.x-300". Fedora only;
# the Arch config keeps the plain "kernel" module. $1 = home dir.
swap_fastfetch_kernel_fedora() {
  local cfg="$1/.config/fastfetch/config.jsonc"
  [ -f "$cfg" ] || return 0
  python3 - "$cfg" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
pat = re.compile(r'"type": "kernel",(\s*\n\s*"key": "[^"]*",\s*\n\s*"keyColor": "yellow")')
def repl(m):
    return ('"type": "command",' + m.group(1) + ',\n'
            '            "text": "echo Linux $(uname -r | sed \'s/\\\\.fc[0-9]*\\\\..*//\')"')
s, n = pat.subn(repl, s, count=1)
if n:
    open(p, 'w', encoding='utf-8').write(s)
PY
}

# Widen the Konsole profile from 105 to 120 columns on Fedora. $1 = home dir.
swap_konsole_columns_fedora() {
  local cfg="$1/.local/share/konsole/XeroLinux.profile"
  [ -f "$cfg" ] || return 0
  sed -i 's/^TerminalColumns=105$/TerminalColumns=120/' "$cfg"
}

#############################################
# Run package setup for detected distro
#############################################
if [ "$DISTRO" = "arch" ]; then
  install_arch_packages
else
  install_fedora_packages
fi

install_tela_icons
install_xero_wallpapers

header "Backing Up & Applying Rice"
backup_dir="$HOME/.config-backup-$(date +%Y.%m.%d-%H.%M.%S)"
echo "Backing up current config to $backup_dir"
cp -Rf ~/.config "$backup_dir"
cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. /
sudo cp -Rf Configs/Home/. /root/

if [ "$DISTRO" = "fedora" ]; then
  header "Adapting Configs For Fedora"
  echo "Removing Arch-only plasmoids (apdatifier, pacseek)..."
  strip_arch_plasmoids "$HOME"
  sudo bash -c "$(declare -f strip_arch_plasmoids); strip_arch_plasmoids /root"
  echo "Swapping fastfetch logo to Fedora..."
  swap_fastfetch_logo_fedora "$HOME"
  sudo bash -c "$(declare -f swap_fastfetch_logo_fedora); swap_fastfetch_logo_fedora /root"
  echo "Swapping app-menu button icon to Fedora..."
  swap_appmenu_logo_fedora "$HOME"
  sudo bash -c "$(declare -f swap_appmenu_logo_fedora); swap_appmenu_logo_fedora /root"
  echo "Fixing fastfetch kernel line for Fedora..."
  swap_fastfetch_kernel_fedora "$HOME"
  sudo bash -c "$(declare -f swap_fastfetch_kernel_fedora); swap_fastfetch_kernel_fedora /root"
  echo "Widening Konsole columns to 120 for Fedora..."
  swap_konsole_columns_fedora "$HOME"
  sudo bash -c "$(declare -f swap_konsole_columns_fedora); swap_konsole_columns_fedora /root"
fi

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
grep -qxF 'eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/xero.omp.json)"' "$bashrc_file" || \
  echo 'eval "$(oh-my-posh init bash --config $HOME/.config/ohmyposh/xero.omp.json)"' >> "$bashrc_file"
echo "Oh-My-Posh injection complete."

# Set or append a KEY=VALUE option in /etc/default/grub.
set_grub_option() {
  local key="$1" val="$2"
  if grep -q "^${key}=" /etc/default/grub; then
    sudo sed -i "s/^${key}=.*/${key}=${val}/" /etc/default/grub
  else
    echo "${key}=${val}" | sudo tee -a /etc/default/grub >/dev/null
  fi
}

header "Installing GRUB Theme"
if [ -d "/boot/grub" ] || [ -d "/boot/grub2" ]; then
  # Apply /etc/default/grub tweaks BEFORE Grub.sh regenerates grub.cfg.
  set_grub_option GRUB_GFXMODE 1920x1080x32
  if [ "$DISTRO" = "fedora" ]; then
    # Fedora hides the boot menu by default; show it for 5s so the theme shows.
    set_grub_option GRUB_TIMEOUT 5
    set_grub_option GRUB_TIMEOUT_STYLE menu
  fi
  sudo ./Grub.sh
else
  echo "GRUB not detected, skipping theme."
fi

header "Installing Layan KDE Theme"
if git clone https://github.com/vinceliuice/Layan-kde.git; then
  cd Layan-kde && sh install.sh && cd .. && rm -rf Layan-kde
else
  echo "Failed to install Layan-kde"
fi

center_box "All Done" "Setup Complete!" "Please reboot to apply settings."
