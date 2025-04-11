// Version 1

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami

// From the Widget ConfigOverlay:
// https://invent.kde.org/plasma/plasma-desktop/-/blame/master/containments/desktop/package/contents/ui/ConfigOverlay.qml
QQC2.CheckBox {
	Kirigami.FormData.label: i18n("Desktop Widget:")
	text: i18nd("plasma_applet_org.kde.desktopcontainment", "Show Background")
	visible: (plasmoid.backgroundHints & PlasmaCore.Types.ConfigurableBackground)
	checked: plasmoid.effectiveBackgroundHints & PlasmaCore.Types.StandardBackground || plasmoid.effectiveBackgroundHints & PlasmaCore.Types.TranslucentBackground
	onClicked: {
		if (checked) {
			if (plasmoid.backgroundHints & PlasmaCore.Types.StandardBackground || plasmoid.backgroundHints & PlasmaCore.Types.TranslucentBackground) {
				plasmoid.userBackgroundHints = plasmoid.backgroundHints
			} else {
				plasmoid.userBackgroundHints = PlasmaCore.Types.StandardBackground
			}
		} else {
			if (plasmoid.backgroundHints & PlasmaCore.Types.ShadowBackground || plasmoid.backgroundHints & PlasmaCore.Types.NoBackground) {
				plasmoid.userBackgroundHints = plasmoid.backgroundHints
			} else {
				plasmoid.userBackgroundHints = PlasmaCore.Types.ShadowBackground
			}
		}
	}
}
