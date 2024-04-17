import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import org.kde.notification

PlasmaExtras.Representation {

  property var selectedEntry
  property bool busy: false
  property bool resetting: false

  implicitWidth: Kirigami.Units.gridUnit * 20
  implicitHeight: mainList.height + header.height + Kirigami.Units.largeSpacing

  Layout.preferredWidth: implicitWidth
  Layout.minimumWidth: implicitWidth
  Layout.preferredHeight: implicitHeight
  Layout.maximumHeight: implicitHeight
  Layout.minimumHeight: implicitHeight

  header: PlasmaExtras.PlasmoidHeading {
    contentItem: RowLayout {
      Kirigami.Heading {
        Layout.fillWidth: true
        padding: Kirigami.Units.smallSpacing
        text: i18n("Reboot to...")
      }
      PlasmaComponents.ToolButton {
        icon.name: "view-refresh"
        onClicked: {
          plasmoid.internalAction("reset").trigger()
          resetting = true
        }
        PlasmaComponents.ToolTip { text: i18n("Reset this applet") }
      }
      PlasmaComponents.ToolButton {
        icon.name: "configure"
        onClicked: plasmoid.internalAction("configure").trigger()
        PlasmaComponents.ToolTip { text: i18n("Configure this applet") }
      }
    }
  }

    ListView {
      id: mainList

      interactive: false
      spacing: Kirigami.Units.smallSpacing

      anchors.verticalCenter: parent.verticalCenter
      width: parent.width
      height: shownEntries.count > 0 ? contentHeight : 300

      model: shownEntries

      delegate: PlasmaComponents.ItemDelegate {
        required property string id
        required property string bIcon
        required property string title
        required property string version
        width: parent ? parent.width : 0
        contentItem: RowLayout {

          Layout.fillWidth: true

          Kirigami.Icon {
            source: Qt.resolvedUrl("../../assets/icons/" + bIcon + ".svg")
            color: Kirigami.Theme.colorSet
            smooth: true
            isMask: true
            scale: 0.8
          }
          ColumnLayout {
            spacing: 0
            Kirigami.Heading {
              level: 4
              Layout.fillWidth: true
              text: title
              elide: Text.ElideRight
            }
            PlasmaComponents.Label {
              color: Kirigami.Theme.disabledTextColor
              Layout.fillWidth: true
              visible: version
              text: version
            }
          }
        }
        onClicked: {
          root.expanded = !root.expanded
          selectedEntry = title
          myNotif.sendEvent()
          bootMgr.bootEntry(id)
        }
    }

    PlasmaComponents.BusyIndicator {
      implicitWidth: 150
      implicitHeight: 150
      anchors.centerIn: parent
      visible: bootMgr.step < BootManager.Ready || busy
    }

    ErrorMessage {
      id: noEntriesMsg
      anchors.centerIn: parent
      sIcon: "dialog-warning-symbolic"
      message: i18n("No boot entries could be listed.\nPlease check this applet settings.")
      show: bootMgr.step === BootManager.Ready && shownEntries.count == 0 && !busy
      action: Kirigami.Action {
        text: i18n("Configure")
        icon.name: "configure"
        onTriggered: plasmoid.internalAction("configure").trigger()
      }
    }

    ErrorMessage {
      id: notEligibleMsg
      anchors.centerIn: parent
      sIcon: "dialog-error-symbolic"
      message: i18n("This applet cannot work on this system.\nPlease check that the system is booted in UEFI mode and that systemd, systemd-boot are used and configured properly.")
      show: bootMgr.step === BootManager.Error
    }

    ErrorMessage {
      id: rootRequired
      anchors.centerIn: parent
      sIcon: "dialog-password-symbolic"
      message: i18n("Root access is required to get the full boot entries list.")
      show: bootMgr.step === BootManager.RootRequired
      action: Kirigami.Action {
        text: i18n("Retry as root")
        icon.name: "unlock-symbolic"
        onTriggered: bootMgr.getEntriesFull(true)
      }
      PlasmaComponents.Button {
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        text: i18n("Ignore")
        icon.name: "errornext"
        onClicked: bootMgr.finish(true)
        visible: bootMgr.step === BootManager.RootRequired
      }
    }

  }

  Notification {
    id: myNotif
    componentName: "plasma_workspace"
    eventId: "warning"
    title: i18n("Advanced reboot")
    text: i18n("The entry <b>") + selectedEntry + i18n("</b> has been set for the next reboot.")
    iconName: "refreshstructure"
  }

  function updateModel() {
    busy = true
    shownEntries.clear()
    try {
      for (let entry of JSON.parse(plasmoid.configuration.savedEntries)) {
        if (entry.show) shownEntries.append(entry)
      }
    }
    catch (err) {
      bootmgr.alog("Error parsing saved entries for the mainview: " + err)
    }
    busy = false
  }

  Component.onCompleted: {
    if (bootMgr.step === BootManager.Ready || bootMgr.step === BootManager.Error) updateModel()
  }

  Connections {
    target: plasmoid.configuration

    function onValueChanged(value) {
      if (bootMgr.step === BootManager.Ready && value == "savedEntries" && plasmoid.configuration.savedEntries) {
        updateModel()
      }
    }
   }

  // Workaround bug mainview not updating when ready
  Connections {
    target: bootMgr

    function onReady(step) {
      if (step === BootManager.Ready) {
        resetting ? resetting = false : updateModel() // Prevent double refresh upon reset...
      }
    }
  }

}
