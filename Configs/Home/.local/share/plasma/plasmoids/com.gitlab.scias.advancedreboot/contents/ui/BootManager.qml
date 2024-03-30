import QtQuick

import org.kde.plasma.private.sessions
import org.kde.plasma.plasma5support as Plasma5Support

Item {

    // TODO: 0.5 / sudo
    //property bool requiresRoot: false
    readonly property string cmdSudo: "pkexec "

    readonly property int minVersion: 251 // Minimum systemd version required
    readonly property string cmdDbusPre: "busctl"
    readonly property string cmdSdboot: "bootctl"
    readonly property string cmdDbusCheck: cmdDbusPre + " --version"
    readonly property string cmdSdbootCheck: cmdSdboot + " --version"
    readonly property string cmdDbusPath: "org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager"

    readonly property string cmdGetEntries: cmdSdboot + " list --json=short --no-pager"

    readonly property string cmdCheckEfi: cmdDbusPre + " call " + cmdDbusPath + " CanRebootToFirmwareSetup --json=short"
    readonly property string cmdCheckCustom: cmdDbusPre + " call " + cmdDbusPath + " CanRebootToBootLoaderEntry --json=short"
    readonly property string cmdCheckMenu: cmdDbusPre + " call " + cmdDbusPath + " CanRebootToBootLoaderMenu --json=short"

    readonly property string cmdSetEfi: cmdDbusPre + " call " + cmdDbusPath + " SetRebootToFirmwareSetup b true" 
    readonly property string cmdSetMenu: cmdDbusPre + " call " + cmdDbusPath + " SetRebootToBootLoaderMenu t 0"
    readonly property string cmdSetEntry: cmdDbusPre + " call " + cmdDbusPath + " SetRebootToBootLoaderEntry s "

    readonly property var ignoreEntries: ["auto-reboot-to-firmware-setup"]
    //TODO: sections
    //readonly property var systemEntries: ["auto-efi-shell", "bootloader-menu"]

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

    property var busctlOK: null
    property var bootctlOK: null
    property var canEntry: null
    property var canMenu: null
    property var canEfi: null
    property var gotEntries: null

    enum State {
        ReqPass,
        GotEntries,
        Ready,
        Error,
        RootRequired
    }
    property int step: -1

    // TODO: Optimisation: use a temporary model
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
            const stderr = data["stderr"]

            disconnectSource(cmd)

            if (cmd == cmdDbusCheck) {
                if (stdout && !stderr) {
                    const resp = stdout.split(" ")
                    busctlOK = parseInt(resp[1]) >= minVersion
                } else busctlOK = false
            }
            else if (cmd == cmdSdbootCheck) {
                // Assume bootctl version == busctl version
                bootctlOK = !stderr
            }
            else {
                let json
                try { json = JSON.parse(stdout) }
                catch (err) {
                    if (stderr.includes("Permission")) {
                        step = BootManager.RootRequired
                        return
                    }
                    else {
                        gotEntries = false
                        step = BootManager.GotEntries
                    }
                }
                if (cmd == cmdCheckCustom) {
                    canEntry = json.data == "yes"
                    if (canEntry) getEntries(false)
                    else step = BootManager.GotEntries
                }
                else if (cmd == cmdCheckMenu) {
                    canMenu = json.data == "yes"
                    if (canMenu) bootEntries.append(mapEntry("bootloader-menu", "Bootloader Menu", i18n("Bootloader Menu")))
                }
                else if (cmd == cmdCheckEfi) {
                    canEfi = json.data == "yes"
                    if (canEfi) bootEntries.append(mapEntry("firmware-setup", "Firmware Setup", i18n("Firmware Setup")))
                }
                else if (cmd.includes(cmdGetEntries)) {
                    if (step != BootManager.GotEntries) {
                        for (const entry of json) {
                            if (!ignoreEntries.includes(entry.id)) {
                                bootEntries.append(mapEntry(entry.id, entry.title, entry.showTitle))
                            }
                        }
                        step = BootManager.GotEntries
                        gotEntries = true
                    }
                }
            }

            if (step === -1) {
                if (busctlOK && bootctlOK) {
                    step = BootManager.ReqPass
                    getAbilities()
                }
                else if (busctlOK === false || bootctlOK === false) {
                    step = BootManager.Error
                }
            }

            if (step >= BootManager.GotEntries) finish(false)

        }

        function exec(cmd) {
            if (cmd) connectSource(cmd)
        }

    }

    function mapEntry(id, title, fullTitle) {
        let bIcon = defaultIcon
        //let system = systemEntries.includes(id)
        let cmd

        if (id == "bootloader-menu") cmd = cmdSetMenu
        else if (id == "firmware-setup") cmd = cmdSetEfi
        else cmd = cmdSetEntry + id

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
            //system: system,
            title: title,
            fullTitle: fullTitle,
            bIcon: Qt.resolvedUrl("../../assets/icons/" + bIcon + ".svg"),
            cmd: cmd,
            enabled: true,
        })

    }

    function initialize() {
        plasmoid.configuration.allEntries = []
        executable.exec(cmdDbusCheck)
        executable.exec(cmdSdbootCheck)
    }

    function getAbilities() {
        executable.exec(cmdCheckEfi)
        executable.exec(cmdCheckMenu)
        executable.exec(cmdCheckCustom)
    }

    function getEntries(root) {
        let cmd = cmdGetEntries
        if (root) cmd = cmdSudo + cmd
        executable.exec(cmd)
    }

    function bootEntry(cmd) {
        executable.exec(cmd)
        let mode = plasmoid.configuration.rebootMode
        if (mode === 0 || mode === 1) {
            session["requestReboot"](mode)
        }
    }

    function finish(skip) {

        if (skip) step = BootManager.GotEntries

        if (step === BootManager.GotEntries && canEntry !== null && canEfi !== null && canMenu !== null) {
            step = (canEntry || canEfi || canMenu) ? BootManager.Ready : BootManager.Error
            loaded(step)
        }

        if (step >= BootManager.Ready) {
                // TERRRIBLE WORKAROUND - GIVE INFO TO CONFIG PANEL
                plasmoid.configuration.sysdOK = busctlOK
                plasmoid.configuration.bctlOK = bootctlOK
                plasmoid.configuration.canEfi = canEfi
                plasmoid.configuration.canMenu = canMenu
                plasmoid.configuration.canEntry = canEntry
                plasmoid.configuration.gotEntries = gotEntries
                // TODO: Save all entries in configuration once ready
        }
    }

    signal loaded(int step)

}
