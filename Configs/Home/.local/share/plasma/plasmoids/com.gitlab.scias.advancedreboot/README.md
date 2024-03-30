# Advanced Reboot Plasmoid for Plasma 6

Simple Plasmoid for KDE Plasma 6 that lists the bootloader entries from systemd-boot/bootctl.
This allows you to quickly reboot into Windows, the EFI or bootloader menu, other distributions and EFI programs...

## Requirements

- UEFI system only
- systemd >= 251
- systemd-boot (bootctl) bootloader

**Other bootloaders (GRUB/rEFInd...) and non-systemd systems are NOT supported!**

## Troubleshooting

In addition to the requirements above, some other criterias must be met in order for this applet to fully work :

- The EFI partition (esp) must be user accessible

By default, most Linux distributions hide it completely to the user for security reasons. This makes bootctl listing impossible without root.
You can work around this by making the esp readable to users by editing your /etc/fstab file and setting the esp fmask and dmask values to 0022.
```
UUID=xxxxx  /efi   vfat    ...,fmask=0022,dmask=0022,...
```
From version 0.5 this applet will work without the need of such workaround.

- The required DBus methods must be usable without root

A few distributions (like OpenSUSE) make the user unable to interact with bootctl (via DBus) without root. For now there's no solution to this issue yet.

## Tested on

- ✅ **Archlinux** - Should work out of the box
- 🟨 **Endeavour OS** - See Troubleshooting
- 🟨 **Fedora KDE (Rawhide)** - See Troubleshooting
- 🚫 **KDE Neon (based on Ubuntu 22.04)** - systemd/bootctl version is too old
- 🚫 **OpenSUSE Tumbleweed** - busctl requires root for setting bootnext

## Roadmap / TODO

- [ ] Improve look and feel
- [X] Translation support
- [X] Custom icons
- [X] Detect if requirements are really met and warn the user/disable the feature if not
- [X] Dynamically get and list all the bootloader entries
- [X] Ability to tweak visibility of every entry
- [X] Ability to just set the flag without rebooting immediately
- [X] Better error detection and reporting (0.45)
- [ ] Ask for root to get the initial entry list for the distros that hide the ESP by default (0.5)
- [ ] Show detailed entry info/metadata (0.6)
- [ ] Show which entry is currently the active one (0.6x)
- [ ] Show which entry has been set for next boot (0.6x)
- [ ] Allow customisation of entry names, logos and order (0.7)

## Translations

- [X] French
- [X] Dutch (by Heimen Stoffels)

If you wish to contribute your own translation, a template.pot file is available in the translate folder.

## License

Mozilla Public License 2.0
