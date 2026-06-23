import QtQuick 2.0
import QtQuick.Controls 2.5 as QQC2
import org.kde.kirigami 2.4 as Kirigami
import QtQuick.Layouts 1.1 as QtLayouts

Kirigami.FormLayout {
    id: configPage

    // use string list
    property alias cfg_feeds: feeds.text

    QQC2.Label {
        QtLayouts.Layout.fillWidth: true
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignBottom
        text: i18n("List of feeds")
    }

    QQC2.TextArea {
        id: feeds
        placeholderText: i18n("Enter a list of feeds, separated by new lines")
        text: cfg_feeds // Load stored feeds as newline-separated text
    }
}