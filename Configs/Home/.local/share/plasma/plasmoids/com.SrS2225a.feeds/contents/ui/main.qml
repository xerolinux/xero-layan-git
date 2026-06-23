import QtQuick 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.2

import "../utils/newsFetcher.js" as NewsFetcher

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.kquickcontrolsaddons 2.0

PlasmoidItem {
    id: mainWindow

    readonly property int implicitWidth: Kirigami.Units.gridUnit * 40
    readonly property int implicitHeight: Kirigami.Units.gridUnit * 18.5
    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
    
    Plasmoid.icon: "news"

    width: implicitWidth
    height: implicitHeight

    readonly property int minimumWidth: Kirigami.Units.gridUnit * 8
    readonly property int minimumHeight: Kirigami.Units.gridUnit * 8

    property var feedList: []
    property string errors: ""
    property var newsItems: [];
    property int currentIndex: 0;

    function fetchFeeds() {
        var feedUrls = plasmoid.configuration.feeds.split("\n"); // Read feed URLs from configuration
        NewsFetcher.fetchAllFeeds(feedUrls, function(allFeeds, errorMessage) {
            errors = errorMessage;
            feedList = allFeeds.sort(function(a, b) { // sort title alphabetically
                return a.title.localeCompare(b.title);
            });

            if(feedList.length > 0) {
                fetchCurrentFeed(currentIndex);
            }
        });
    }

    // Function to load a specific feed's news items
    function fetchCurrentFeed(index) {
        if (index < feedList.length) {
            // sort by date - oldest first
            newsItems = feedList[index].items.sort(function(a, b) {
                return new Date(a.pubDate) - new Date(b.pubDate);
            });
            currentIndex = newsItems.length - 1;
        }
    }

    Component.onCompleted: fetchFeeds();
    Plasmoid.onUserConfiguringChanged: fetchFeeds();

    Row {  // Tab Container
        id: tabContainer
        width: parent.width
        height: Math.max(feedTabs.implicitHeight, refreshButton.implicitHeight)
        anchors.top: parent.top
        spacing: 5

        Flickable {
            id: tabBarFlickable
            width: parent.width - refreshButton.width - 10 
            height: feedTabs.implicitHeight
            clip: true
            contentWidth: feedTabs.width
            interactive: feedTabs.width > width

            TabBar {
                id: feedTabs
                width: implicitWidth
                height: implicitHeight 

                Repeater {
                    model: feedList
                    TabButton {
                        text: feedList[model.index].title
                        onClicked: fetchCurrentFeed(model.index)
                    }
                }
            }
        }

        // Refresh Button
        PlasmaComponents.Button {
            id: refreshButton
            anchors.right: parent.right
            icon.name: "view-refresh"
            height: implicitHeight
            onClicked: fetchFeeds()
            z: 5
        }
    }

    Rectangle { // Error Display
        id: errorDisplay
        visible: errors !== ""
        width: parent.width
        height: parent.height
        // slgihtly red background
        color: "#FFCCCC"
        border.color: "#990000"
        border.width: 2
        radius: 8
        z: -1

        Column {
            anchors.centerIn: parent
            spacing: 10
            width: parent.width

            Kirigami.Icon {
                source: "data-error"
                width: 50
                height: 50
                anchors.horizontalCenter: parent.horizontalCenter
            }

            PlasmaComponents.Label {
                text: errors
                color: "#990000"
                font.bold: true
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                width: parent.width
            }
        }
    }

    Column {    // News Container
        anchors.fill: parent
        anchors.topMargin: feedTabs.height
        visible: errors === ""
        spacing: 10

        Row {
            anchors.fill: parent
            anchors.topMargin: feedTabs.height / 3
            spacing: 10

            // News Image
            Image {
                source: newsItems.length > 0 && newsItems[currentIndex].imageUrl !== "" 
                    ? newsItems[currentIndex].imageUrl : ""
                width: parent.width * 0.32
                fillMode: Image.PreserveAspectFit
                height: parent.height * 0.8
                visible: newsItems.length > 0 && newsItems[currentIndex].imageUrl !== ""
            }

            // News Text Content
            Column {
                id: newsContent
                width: newsItems.length > 0 && newsItems[currentIndex].imageUrl !== "" 
                    ? parent.width * 0.68 : parent.width + 10
                height: parent.height
                spacing: 5

                PlasmaComponents.Label {
                    id: newsTitle
                    text: newsItems.length > 0 ? newsItems[currentIndex].title : ""
                    font.bold: true
                    font.pointSize: 15.4
                    wrapMode: Text.Wrap
                    width: parent.width - 20
                }

                ScrollView {
                    id: newsScrollView
                    width: newsContent.width
                    // Set height to the smaller of content height or available space
                    height: Math.min(contentLabel.implicitHeight, parent.height - newsTitle.height - pubDateLabel.implicitHeight - navigationRow.height - 20)
                    visible: newsItems.length > 0 && newsItems[currentIndex].description !== ""

                    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    PlasmaComponents.Label {
                        id: contentLabel
                        text: newsItems.length > 0 ? newsItems[currentIndex].description : ""
                        wrapMode: Text.Wrap
                        font.pointSize: 12
                        width: newsScrollView.width - 20
                    }
                }

                PlasmaComponents.Label {
                    id: pubDateLabel
                    text: newsItems.length > 0 ? newsItems[currentIndex].pubDate : ""
                    font.italic: true
                    font.pointSize: 10
                    color: "gray"
                }
            }
        }

        Row {  // Navigation Buttons
            id: navigationRow
            width: parent.width
            spacing: 10
            height: parent.height * 0.1
            anchors.bottom: parent.bottom 
            visible: errors === ""

            PlasmaComponents.Button {
                text: "Read More"
                enabled: newsItems.length > 0
                onClicked: {
                    if (newsItems.length > 0) {
                        Qt.openUrlExternally(newsItems[currentIndex].link);
                    }
                }
                anchors.left: parent.left
            }

            Item {
                Layout.fillWidth: true // Fills space between buttons
            }

            Row {
                spacing: 10
                anchors.right: parent.right
                PlasmaComponents.Button {
                    icon.name: "arrow-left-double"
                    enabled: currentIndex > 0
                    onClicked: {
                        if (currentIndex > 0) {
                            currentIndex = 0;
                        }
                    }
                }

                PlasmaComponents.Button {
                    icon.name: "arrow-left"
                    enabled: currentIndex > 0
                    onClicked: {
                        if (currentIndex > 0) {
                            currentIndex--;
                        }
                    }
                }

                PlasmaComponents.Button {
                    icon.name: "arrow-right"
                    enabled: currentIndex < newsItems.length - 1
                    onClicked: {
                        if (currentIndex < newsItems.length - 1) {
                            currentIndex++;
                        }
                    }
                }

                PlasmaComponents.Button {
                    icon.name: "arrow-right-double"
                    enabled: currentIndex < newsItems.length - 1
                    onClicked: {
                        if (currentIndex < newsItems.length - 1) {
                            currentIndex = newsItems.length - 1;
                        }
                    }
                }
            }
        }
    }
}
