import QtQml
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as Plasma5Support

import "../lib" as Lib


Lib.CardButton {
    property alias cfg_isDarkTheme: isDarkTheme.checked
    
    id: colorSchemeSwitcher
    
    visible: root.showColorSwitcher
    Layout.fillHeight: true
    Layout.fillWidth: true
    title: i18n(Plasmoid.configuration.isDarkTheme ? "Dark Theme" : "Light Theme")
    Kirigami.Icon {
        id: brightnessIcon
        anchors.fill: parent
        source: Plasmoid.configuration.isDarkTheme ? "brightness-high" : "brightness-low"
    }
    Component.onCompleted: {
        executable1.checkColorScheme();
    }

    onClicked: {
        executable.swapColorScheme();
        Plasmoid.configuration.isDarkTheme = !Plasmoid.configuration.isDarkTheme
    }


    Plasma5Support.DataSource {
        id: executable1
        engine: "executable"
        connectedSources: []

        onNewData: { 
            console.log("IsDarkCommand: ", sourceName)
            var isDark = data["stdout"]
            console.log("IsDarkResponse: ", isDark)
            isDarkTheme.checked = isDark.indexOf("Dark") > 0
            console.log("IsDark: " + isDarkTheme.checked)

            disconnectSource(sourceName)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }

        function checkColorScheme() {
            exec("cat ~/.config/kdeglobals | grep 'ColorScheme='")
        }
    }

    CheckBox {
        id: isDarkTheme
        visible: false
        onCheckedChanged: {
            colorSchemeSwitcher.title = i18n(checked ? "Dark Theme" : "Light Theme")
            brightnessIcon.source = checked ? "brightness-high" : "brightness-low"
        }
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (source) => { 
            disconnectSource(source)
        }
        
        function exec(cmd) {
            connectSource(cmd)
        }

        function swapColorScheme() {
            isDarkTheme.checked = !isDarkTheme.checked
            var colorSchemeName = isDarkTheme.checked ? Plasmoid.configuration.darkTheme : Plasmoid.configuration.lightTheme
            exec("plasma-apply-colorscheme " + colorSchemeName)
        }
    }
}
