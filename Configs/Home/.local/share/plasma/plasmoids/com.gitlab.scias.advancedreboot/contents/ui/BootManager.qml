import QtQuick

import org.kde.plasma.private.sessions
import org.kde.plasma.plasma5support as Plasma5Support

Item {

    readonly property string cmdGetEntries: "bootctl list --json=short"

    // TODO: Use busctl instead of qdbus
    readonly property string cmdPre: "qdbus6 --system org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager."

    readonly property string cmdSetEfi: "SetRebootToFirmwareSetup"
    readonly property string cmdSetMenu: "SetRebootToBootLoaderMenu"
    readonly property string cmdSetEntry: "SetRebootToBootLoaderEntry"

    readonly property string cmdCheckEfi: "CanRebootToFirmwareSetup"
    readonly property string cmdCheckCustom: "CanRebootToBootLoaderEntry"
    readonly property string cmdCheckMenu: "CanRebootToBootLoaderMenu"

    readonly property var ignoreEntries: ["auto-reboot-to-firmware-setup"]
    readonly property var systemEntries: ["auto-efi-shell", "bootloader-menu"]

    readonly property string defaultIcon: "default"
    readonly property var iconMap: {
        "Firmware Setup" : "settings",
        "Bootloader Menu" : "menu",
        "Windows" : "windows",
        "Mac OS" : "apple",
        "Memtest" : "memtest",
        "Arch Linux" : "archlinux",
        "Endeavour" : "endeavour",
        "EFI Shell" : "shell",
        "Fedora" : "fedora",
        "Ubuntu" : "ubuntu",
        "SUSE" : "suse",
        "Debian" : "debian",
        "Mint" : "mint",
        "Gentoo" : "gentoo",
        "Manjaro" : "manjaro",
        "Linux" : "linux",
    }

    property bool canEntry: false
    property bool canMenu: false
    property bool canEfi: false

    property var bootEntries: ListModel { }
    
    SessionManagement {
        id: session
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: (cmd, data) => {
            const stdout = data["stdout"]

            if (cmd == cmdGetEntries) {
                const rawEntries = JSON.parse(stdout)
                for (const entry of rawEntries) {
                    if (!ignoreEntries.includes(entry.id)) {
                        bootEntries.append(mapEntry(entry.id, entry.title, entry.showTitle))
                    }
                }
            }
            else {
                if (cmd.includes(cmdCheckCustom)) {
                    canEntry = true
                }
                else if (stdout == "yes\n") {
                    if (cmd.includes(cmdCheckMenu)) {
                        bootEntries.append(mapEntry("bootloader-menu", "Bootloader Menu", "Bootloader Menu"))
                        canMenu = true
                    }
                    else if (cmd.includes(cmdCheckEfi)) {
                        bootEntries.append(mapEntry("firmware-setup", "Firmware Setup", "Firmware Setup"))
                        canEfi = true
                    }
                }
            }
            disconnectSource(cmd)

        }

        function exec(cmd) {
            if (cmd) connectSource(cmd)
        }

    }

    function mapEntry(id, title, fullTitle) {
        let bIcon = defaultIcon
        let system = systemEntries.includes(id)
        let cmd

        if (id == "bootloader-menu") cmd = cmdSetMenu + " true"
        else if (id == "firmware-setup") cmd = cmdSetEfi + " true"
        else cmd = cmdSetEntry + " " + id

        for (const key in iconMap) {
            if (title.includes(key)) {
                bIcon = iconMap[key]
                break
            }
        }

        // TODO: figure out why push method doesn't work on the plasmoid.configuration item
        let tmpList = plasmoid.configuration.allEntries
        tmpList.push(fullTitle)
        plasmoid.configuration.allEntries = tmpList

        return ({
            id: id,
            system: system,
            title: title,
            fullTitle: fullTitle,
            bIcon: Qt.resolvedUrl("../../assets/icons/" + bIcon + ".svg"),
            cmd: cmd,
            enabled: true,
        })

    }

    function doChecks() {
        // TODO: check busctl/bootctl better and abort if not good
        executable.exec(cmdPre + cmdCheckEfi)
        executable.exec(cmdPre + cmdCheckMenu)
        executable.exec(cmdPre + cmdCheckCustom)
    }

    function getEntries() {
        executable.exec(cmdGetEntries)
    }

    function bootEntry(cmdEnd) {
        executable.exec(cmdPre + cmdEnd)
        let mode = plasmoid.configuration.rebootMode
        if (mode === 0 || mode === 1) {
            session["requestReboot"](mode)
        }
    }


}
