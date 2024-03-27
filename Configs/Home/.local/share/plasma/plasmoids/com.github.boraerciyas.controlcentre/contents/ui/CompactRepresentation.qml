import QtQml
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

Item {
    id: compactRep
    
    RowLayout {
        anchors.fill: parent
        
        Kirigami.Icon {
            Layout.fillWidth: true
            Layout.fillHeight: true
            source: root.mainIconName
            smooth: true
            
            MouseArea {
                anchors.fill: parent
                onPressed: mouse => {
                    if (mouse.button != Qt.LeftButton)
                        return;

                    root.expanded = !root.expanded
                }
            }
        }
    }
}