import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasma5support as P5Support

KCM.SimpleKCM {
    id: root

    property alias cfg_username:          usernameField.text
    property alias cfg_password:          passwordField.text
    property string cfg_connectionChoice: "adsl"
    property alias cfg_autoRefresh:       autoRefreshSwitch.checked

    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => disconnectSource(sourceName)
        function exec(cmd) { connectSource(cmd) }
    }

    Kirigami.FormLayout {
        anchors.fill: parent

        QQC2.TextField {
            id: usernameField
            Kirigami.FormData.label: "Username:"
            placeholderText: "IDM account username"
        }

        QQC2.TextField {
            id: passwordField
            Kirigami.FormData.label: "Password:"
            echoMode: TextInput.Password
            placeholderText: "IDM account password"
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Connection"
        }

        QQC2.ComboBox {
            id: connectionCombo
            Kirigami.FormData.label: "Show:"
            model: [
                { text: "ADSL", value: "adsl" },
                { text: "LTE",  value: "lte"  }
            ]
            textRole: "text"
            valueRole: "value"
            Component.onCompleted: currentIndex = (cfg_connectionChoice === "lte" ? 1 : 0)
            onActivated: cfg_connectionChoice = currentValue
        }

        Kirigami.Separator {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Auto Refresh"
        }

        QQC2.Switch {
            id: autoRefreshSwitch
            Kirigami.FormData.label: "Enable timer:"
            text: checked ? "On — fetches every 15 min" : "Off"
            onToggled: {
                if (checked) {
                    executable.exec("systemctl --user enable --now idm-quota.timer")
                } else {
                    executable.exec(
                        "systemctl --user disable --now idm-quota.timer 2>/dev/null; " +
                        "systemctl --user disable idm-quota.service 2>/dev/null; " +
                        "rm -f ~/.config/systemd/user/idm-quota.timer " +
                             "~/.config/systemd/user/idm-quota.service " +
                             "~/.config/systemd/user/timers.target.wants/idm-quota.timer; " +
                        "systemctl --user daemon-reload"
                    )
                }
            }
        }
    }
}
