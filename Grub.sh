#!/bin/bash

# Grub2 Theme

ROOT_UID=0

# Fedora/openSUSE keep grub2 assets under /boot/grub2; Arch uses /usr/share/grub/themes.
if command -v dnf > /dev/null 2>&1 || command -v zypper > /dev/null 2>&1; then
  THEME_DIR="/boot/grub2/themes"
else
  THEME_DIR="/usr/share/grub/themes"
fi
THEME_NAME=XeroLayan

#COLORS
CDEF=" \033[0m"
CCIN=" \033[0;36m"
CGSC=" \033[0;32m"
CRER=" \033[0;31m"
CWAR=" \033[0;33m"
b_CDEF=" \033[1;37m"
b_CCIN=" \033[1;36m"
b_CGSC=" \033[1;32m"
b_CRER=" \033[1;31m"
b_CWAR=" \033[1;33m"

prompt () {
  case ${1} in
    "-s"|"--success") echo -e "${b_CGSC}${@/-s/}${CDEF}";;
    "-e"|"--error")   echo -e "${b_CRER}${@/-e/}${CDEF}";;
    "-w"|"--warning") echo -e "${b_CWAR}${@/-w/}${CDEF}";;
    "-i"|"--info")    echo -e "${b_CCIN}${@/-i/}${CDEF}";;
    *)                echo -e "$@";;
  esac
}

function has_command() {
  command -v "$1" > /dev/null 2>&1
}

# Set or replace a key=value line in /etc/default/grub
set_grub_opt() {
  local key="$1" val="$2"
  if grep -q "^${key}=" /etc/default/grub 2>/dev/null; then
    sed -i "s|^${key}=.*|${key}=${val}|" /etc/default/grub
  else
    echo "${key}=${val}" >> /etc/default/grub
  fi
}

prompt -s "\n\t************************\n\t*  ${THEME_NAME} - Grub2 Theme  *\n\t************************"

if [ "$UID" -eq "$ROOT_UID" ]; then

  prompt -i "\nChecking directory..."
  [[ -d "${THEME_DIR}/${THEME_NAME}" ]] && rm -rf "${THEME_DIR}/${THEME_NAME}"
  mkdir -p "${THEME_DIR}/${THEME_NAME}"

  prompt -i "\nInstalling theme..."
  cp -a "${THEME_NAME}/"* "${THEME_DIR}/${THEME_NAME}/"

  prompt -i "\nSetting theme in /etc/default/grub..."
  cp -an /etc/default/grub /etc/default/grub.bak

  # Remove any stale GRUB_THEME line (wrong path from a previous run) then set correct one
  sed -i '/^GRUB_THEME=/d' /etc/default/grub
  echo "GRUB_THEME=\"${THEME_DIR}/${THEME_NAME}/theme.txt\"" >> /etc/default/grub

  # Fedora hides the boot menu by default - make it visible so the theme shows
  if command -v dnf > /dev/null 2>&1; then
    prompt -i "\nConfiguring Fedora GRUB timeout (5s, menu visible)..."
    set_grub_opt GRUB_TIMEOUT 5
    set_grub_opt GRUB_TIMEOUT_STYLE menu
    set_grub_opt GRUB_GFXMODE 1920x1080x32
  fi

  prompt -i "\nUpdating grub config..."
  if has_command update-grub; then
    update-grub
  elif has_command grub-mkconfig; then
    grub-mkconfig -o /boot/grub/grub.cfg
  elif has_command grub2-mkconfig; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
  fi

  prompt -s "\n\t          ***************\n\t          *  installed!  *\n\t          ***************\n"

else
  prompt -e "\n [ Error! ] -> Run as root: sudo bash Grub.sh"
  exit 1
fi
