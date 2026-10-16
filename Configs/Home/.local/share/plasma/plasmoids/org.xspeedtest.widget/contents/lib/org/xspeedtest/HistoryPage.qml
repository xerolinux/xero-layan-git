import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: root

    required property SpeedSettings settings
    required property HistoryModel history
    property bool compact: false
    property real minWidth: Kirigami.Units.gridUnit * 17

    readonly property real rowHeight: Kirigami.Units.gridUnit * (compact ? 1.6 : 1.9)
    readonly property int visibleRows: Math.max(2, Math.min(history.count, 6))

    implicitWidth: compact ? minWidth : Kirigami.Units.gridUnit * 22
    implicitHeight: compact ? column.implicitHeight : Kirigami.Units.gridUnit * 20

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: root.compact ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: root.compact ? 0 : Kirigami.Units.largeSpacing
            Layout.rightMargin: root.compact ? 0 : Kirigami.Units.largeSpacing

            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 3
                elide: Text.ElideRight
                text: qsTr("Date / Time")
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: root.compact ? qsTr("Download") : qsTr("Download (%1)").arg(root.settings.unitLabel)
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
            }
            QQC2.Label {
                Layout.fillWidth: true
                Layout.preferredWidth: 2
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: root.compact ? qsTr("Upload") : qsTr("Upload (%1)").arg(root.settings.unitLabel)
                color: Kirigami.Theme.disabledTextColor
                font.weight: Font.DemiBold
            }
        }

        Kirigami.Separator {
            Layout.fillWidth: true
        }

        ListView {
            id: list
            Layout.fillWidth: true
            Layout.fillHeight: !root.compact
            Layout.preferredHeight: root.compact ? root.visibleRows * root.rowHeight : -1
            clip: true
            model: root.history
            boundsBehavior: Flickable.StopAtBounds
            QQC2.ScrollBar.vertical: QQC2.ScrollBar {}

            delegate: Rectangle {
                required property int index
                required property string timestamp
                required property double download
                required property double upload

                width: ListView.view.width
                height: root.rowHeight
                color: index % 2 === 0 ? Qt.alpha(Kirigami.Theme.textColor, 0.05) : "transparent"
                radius: Kirigami.Units.smallSpacing

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing

                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 3
                        elide: Text.ElideRight
                        text: Qt.formatDateTime(new Date(timestamp), "d MMM yyyy, hh:mm")
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        horizontalAlignment: Text.AlignRight
                        font.features: {"tnum": 1}
                        text: Stream.speed(download, root.settings)
                    }
                    QQC2.Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        horizontalAlignment: Text.AlignRight
                        font.features: {"tnum": 1}
                        text: Stream.speed(upload, root.settings)
                    }
                }
            }

            QQC2.Label {
                anchors.centerIn: parent
                visible: list.count === 0
                text: qsTr("No results yet")
                color: Kirigami.Theme.disabledTextColor
            }
        }

        QQC2.Button {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8
            text: qsTr("Clear history")
            enabled: root.history.count > 0
            onClicked: root.history.clear()
        }
    }
}
