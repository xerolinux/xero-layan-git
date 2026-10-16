import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property SpeedSettings settings
    property PlasmoidInstaller installer: null
    property bool showOpacity: true
    property bool compact: false
    property real minWidth: Kirigami.Units.gridUnit * 14

    property bool justInstalled: false

    property string pendingStyle: settings.style
    property int pendingUnit: settings.speedUnit
    property string pendingBackend: settings.backend
    property bool pendingAutoStart: settings.autoStart
    property bool pendingAnimate: settings.animate

    readonly property bool dirty: pendingStyle !== settings.style
        || pendingUnit !== settings.speedUnit
        || pendingBackend !== settings.backend
        || pendingAutoStart !== settings.autoStart
        || pendingAnimate !== settings.animate

    implicitWidth: compact ? Math.max(layout.implicitWidth, minWidth) : Kirigami.Units.gridUnit * 22
    implicitHeight: compact ? layout.implicitHeight : Kirigami.Units.gridUnit * 20

    component Gap: Item {
        Layout.fillHeight: !root.compact
        Layout.preferredHeight: root.compact ? Kirigami.Units.smallSpacing : -1
        Layout.minimumHeight: Kirigami.Units.smallSpacing
    }

    function apply() {
        settings.style = pendingStyle;
        settings.speedUnit = pendingUnit;
        settings.backend = pendingBackend;
        settings.autoStart = pendingAutoStart;
        settings.animate = pendingAnimate;
    }

    function installPlasmoid() {
        installer.install();
        justInstalled = installer.errorString.length === 0;
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        Gap {}

        SettingsRow {
            label: qsTr("Style")

            QQC2.ComboBox {
                id: styleBox
                Layout.fillWidth: true
                textRole: "name"
                valueRole: "id"
                model: Styles.list
                onActivated: root.pendingStyle = currentValue
                Binding on currentIndex {
                    value: (styleBox.count, styleBox.indexOfValue(root.pendingStyle))
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        Gap {}

        SettingsRow {
            label: qsTr("Speed unit")

            QQC2.ComboBox {
                id: unit
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    {text: qsTr("Megabits per second (Mbps)"), value: SpeedSettings.Mbps},
                    {text: qsTr("Kilobits per second (kbps)"), value: SpeedSettings.Kbps},
                    {text: qsTr("Megabytes per second (MBps)"), value: SpeedSettings.MBps},
                    {text: qsTr("Kilobytes per second (KBps)"), value: SpeedSettings.KBps}
                ]
                onActivated: root.pendingUnit = currentValue
                Binding on currentIndex {
                    value: (unit.count, unit.indexOfValue(root.pendingUnit))
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        Gap {}

        SettingsRow {
            label: qsTr("Test server")

            QQC2.ComboBox {
                id: backend
                Layout.fillWidth: true
                textRole: "text"
                valueRole: "value"
                model: [
                    {text: qsTr("Automatic (closest and fastest)"), value: "auto"},
                    {text: qsTr("speedtest-cli servers only"), value: "speedtest"},
                    {text: qsTr("Cloudflare only"), value: "cloudflare"}
                ]
                onActivated: root.pendingBackend = currentValue
                Binding on currentIndex {
                    value: (backend.count, backend.indexOfValue(root.pendingBackend))
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        Gap {}

        SettingsRow {
            label: qsTr("Test on launch")

            QQC2.Switch {
                onToggled: root.pendingAutoStart = checked
                Binding on checked {
                    value: root.pendingAutoStart
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        Gap {}

        SettingsRow {
            label: qsTr("Animation")

            QQC2.Switch {
                onToggled: root.pendingAnimate = checked
                Binding on checked {
                    value: root.pendingAnimate
                    restoreMode: Binding.RestoreNone
                }
            }
        }

        Gap { visible: root.showOpacity }

        SettingsRow {
            visible: root.showOpacity
            label: qsTr("Window opacity")

            QQC2.Slider {
                Layout.fillWidth: true
                from: 0.1
                to: 1
                stepSize: 0.01
                onMoved: root.settings.glassOpacity = value
                Binding on value {
                    value: root.settings.glassOpacity
                    restoreMode: Binding.RestoreNone
                }
            }
            QQC2.Label {
                Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5
                text: Math.round(root.settings.glassOpacity * 100) + "%"
            }
        }

        Gap { visible: root.installer !== null }

        SettingsRow {
            visible: root.installer !== null
            label: qsTr("Plasma widget")

            QQC2.Label {
                text: !root.installer ? "" : root.installer.outdated ? qsTr("Update available") : root.installer.userInstalled ? qsTr("Installed") : root.installer.installed ? qsTr("Installed by the system") : qsTr("Not installed")
                color: root.installer && root.installer.outdated ? Kirigami.Theme.textColor : Kirigami.Theme.disabledTextColor
            }
            QQC2.Button {
                visible: root.installer && !root.installer.installed
                text: qsTr("Install Plasmoid")
                onClicked: root.installPlasmoid()
            }
            QQC2.Button {
                visible: root.installer && root.installer.outdated
                text: qsTr("Update Plasmoid")
                onClicked: root.installer.update()
            }
            Item {
                Layout.fillWidth: true
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            Layout.topMargin: Kirigami.Units.smallSpacing
            visible: root.installer && root.installer.outdated
            wrapMode: Text.Wrap
            text: qsTr("Updating installs the new widget and restarts the Plasma shell. Your panels and desktop reload for a few seconds.")
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            visible: root.installer && root.installer.errorString.length > 0
            wrapMode: Text.Wrap
            color: Kirigami.Theme.negativeTextColor
            text: root.installer ? root.installer.errorString : ""
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.preferredWidth: 1
            visible: root.justInstalled && root.installer && root.installer.userInstalled
            wrapMode: Text.Wrap
            text: qsTr("Plasmoid installed. Add xSpeedTest from Add Widgets on your desktop or panel.")
        }

        Gap {}

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            highlighted: root.dirty
            enabled: root.dirty
            text: qsTr("Apply")
            onClicked: root.apply()
        }

        Gap {}
    }
}
