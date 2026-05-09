import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {

    Kirigami.FormLayout {
        anchors.fill: parent

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: Qt.resolvedUrl("../../images/logo.png")
            fillMode: Image.PreserveAspectFit
            width: 96
            height: 96
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label {
            Kirigami.FormData.label: "Name:"
            text: "IDM Quota Monitor"
            font.bold: true
        }

        QQC2.Label {
            Kirigami.FormData.label: "Version:"
            text: "1.0"
        }

        QQC2.Label {
            Kirigami.FormData.label: "License:"
            text: "GPL-2.0-or-later"
        }

        Kirigami.Separator { Kirigami.FormData.isSection: true }

        QQC2.Label {
            Kirigami.FormData.label: "Authors:"
            text: "DarkXero / TechXero"
        }

        QQC2.Label {
            Kirigami.FormData.label: "Website:"
            text: "<a href='https://xerolinux.xyz'>xerolinux.xyz</a>"
            onLinkActivated: (url) => Qt.openUrlExternally(url)
            MouseArea {
                anchors.fill: parent
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.NoButton
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: "Get Help:"
            text: "<a href='https://discord.xerolinux.xyz'>discord.xerolinux.xyz</a>"
            onLinkActivated: (url) => Qt.openUrlExternally(url)
            MouseArea {
                anchors.fill: parent
                cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                acceptedButtons: Qt.NoButton
            }
        }
    }
}
