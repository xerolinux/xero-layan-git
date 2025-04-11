import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami 2.4 as Kirigami
import org.kde.kquickcontrols 2.0 as KQControls

RowLayout {
    id: colorfield
    property alias text: label.text
    property alias color: colorbutton.color

    Label {
        id: label
    }
    KQControls.ColorButton {
        id: colorbutton
        color: root.color
        showAlphaChannel: false

        onAccepted: {
            colorfield.color = color
        }
    }
}
