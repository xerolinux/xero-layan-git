#!/bin/bash
#set -e
echo "##########################################"
echo "Be Careful this will override your Rice!! "
echo "##########################################"
echo
echo "Installing Necessary Packages"
echo "#############################"
echo
echo "Native Packages..."
echo
sudo pacman -S --noconfirm --needed kvantum jq xmlstarlet fastfetch gtk-engine-murrine gtk-engines ttf-hack-nerd ttf-fira-code kdeconnect ttf-terminus-nerd noto-fonts-emoji ttf-meslo-nerd kde-wallpapers
echo
echo "AUR Packages..."
echo
# Check if yay is installed
if command -v yay &> /dev/null; then
    aur_helper="yay"
# Check if paru is installed
elif command -v paru &> /dev/null; then
    aur_helper="paru"
else
    echo "Neither yay nor paru is installed. Please install one of them."
    exit 1
fi
# Install packages using the detected AUR helper
$aur_helper -S --noconfirm --needed aur/ttf-meslo-nerd-font-powerlevel10k
sleep 2
echo
echo "Creating Backup & Applying new Rice, hold on..."
echo "###############################################"
cp -Rf ~/.config ~/.config-backup-$(date +%Y.%m.%d-%H.%M.%S) && cp -Rf Configs/Home/. ~
sudo cp -Rf Configs/System/. / && sudo cp -Rf Configs/Home/. /root/
sleep 2
echo
echo "Applying Grub Theme...."
echo "#######################"
chmod +x Grub.sh
sudo ./Grub.sh
sudo sed -i "s/GRUB_GFXMODE=*.*/GRUB_GFXMODE=1920x1080x32/g" /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
sleep 2
echo
echo "Installing Layan Theme"
echo "######################"
echo
cd ~ && git clone https://github.com/xerolinux/Layan-kde.git && cd Layan-kde/ && sh install.sh
cd ~ && rm -Rf Layan-kde/
sleep 2
echo
echo "Installing & Applying GTK4 Theme "
echo "#################################"
cd ~ && git clone https://github.com/vinceliuice/Layan-gtk-theme.git && cd Layan-gtk-theme/ && sh install.sh -l -c dark
cd ~ && rm -Rf Layan-gtk-theme/
echo
echo "Installing Icon Pack"
echo "####################"
cd ~ && git clone https://github.com/vinceliuice/Tela-circle-icon-theme.git && cd Tela-circle-icon-theme/
sudo chmod +x install.sh && sh install.sh -c purple
sleep 2
echo "clear && neofetch" >> ~/.bashrc
rm -rf ~/xero-layan-git/ ~/Tela-circle-icon-theme/
echo
if [ -f ~/.bashrc ]; then sed -i 's/neofetch/fastfetch/g' ~/.bashrc; fi
if [ -f ~/.zshrc ]; then sed -i 's/neofetch/fastfetch/g' ~/.zshrc; fi
echo "Plz Reboot To Apply Settings..."
echo "###############################"
