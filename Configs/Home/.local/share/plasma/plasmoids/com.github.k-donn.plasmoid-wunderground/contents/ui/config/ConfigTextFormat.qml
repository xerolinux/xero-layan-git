// Version 1

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: configTextFormat

    property alias boldConfigKey: configBold.configKey
    property alias italicConfigKey: configItalic.configKey
    property alias underlineConfigKey: configUnderline.configKey

    Button {
        id: configBold
        property string configKey: "compactWeight"
        visible: configKey
        icon.name: "format-text-bold-symbolic"
        checkable: true
        checked: configKey ? plasmoid.configuration[configKey] : false
        onClicked: plasmoid.configuration[configKey] = checked
    }

    Button {
        id: configItalic
        property string configKey: "compactItalic"
        visible: configKey
        icon.name: "format-text-italic-symbolic"
        checkable: true
        checked: configKey ? plasmoid.configuration[configKey] : false
        onClicked: plasmoid.configuration[configKey] = checked
    }

    Button {
        id: configUnderline
        property string configKey: "compactUnderline"
        visible: configKey
        icon.name: "format-text-underline-symbolic"
        checkable: true
        checked: configKey ? plasmoid.configuration[configKey] : false
        onClicked: plasmoid.configuration[configKey] = checked
    }

    Item {
        Layout.preferredWidth: units.smallSpacing
        visible: configBold.visible || configItalic.visible || configUnderline.visible
    }
}
