// IMPORT
// QtQuick
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml

// Plasma Modules
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.plasma.components as PlasmaComponents

// MAIN
PlasmoidItem {
    id: root
    
    // Loading Fonts
    FontLoader {
        id: defaultFont
        source: "../fonts/Hasteristico.ttf"
    }
    
    // Properties
    // Fonts
    property var fontFamily: defaultFont.name
    
    // Booleans
    property bool proportionalFont: Plasmoid.configuration.proportional_font
    property bool enableShadows: Plasmoid.configuration.enable_shadows
    property bool showDate: Plasmoid.configuration.show_date
    property bool showSysMon: Plasmoid.configuration.show_sys_mon
    property bool enableFillAnimation: Plasmoid.configuration.enable_fill_animation
    property bool enable24Hour: Plasmoid.configuration.enable_24_hour
    property bool useSystemColors: Plasmoid.configuration.use_system_colors 
    // Font Sizes
    property int globalFontSize: Plasmoid.configuration.global_font_size 
    property int monthFontSize: proportionalFont ? globalFontSize * 0.24 : Plasmoid.configuration.month_font_size
    property int dayFontSize: proportionalFont ? globalFontSize * 0.54 : Plasmoid.configuration.day_font_size
    property int yearFontSize: proportionalFont ? globalFontSize * 0.19 : Plasmoid.configuration.year_font_size
    property int timeFontSize: proportionalFont ? globalFontSize * 1.25 : Plasmoid.configuration.time_font_size
    property int timeAPFontSize: proportionalFont ? globalFontSize * 0.24 : Plasmoid.configuration.timeap_font_size
    property int sysMonTextFontSize: proportionalFont ? globalFontSize * 0.19 : Plasmoid.configuration.sys_mon_text_font_size
    property int sysMonUsageFontSize: proportionalFont ? globalFontSize * 0.1 : Plasmoid.configuration.sys_mon_usage_font_size
    property int audioTitleFontSize: proportionalFont ? globalFontSize * 0.1 : Plasmoid.configuration.audio_title_font_size
    property int audioArtistFontSize: proportionalFont ? globalFontSize * 0.07 : Plasmoid.configuration.audio_artist_font_size
    property int nowPlayingFontSize: proportionalFont ? globalFontSize * 0.08: Plasmoid.configuration.now_playing_font_size
    property int audioImageWidth: proportionalFont ? globalFontSize * 0.25 : Plasmoid.configuration.audio_image_width
    
    // subtracting some amount of spacing because this font has really big line height
    property int sysMonSpacing: -40 + Plasmoid.configuration.sys_mon_spacing
    property int audioSpacing: -20 + Plasmoid.configuration.audio_spacing
    property int dateSpacing: -15 + Plasmoid.configuration.date_spacing
    
    // Other
    property int sysMonInterval: Plasmoid.configuration.sys_mon_interval
    
    // Colors
    property string textBackgroundColor: useSystemColors ? PlasmaCore.Theme.backgroundColor : Plasmoid.configuration.text_background_color
    property string colorOne: useSystemColors ? PlasmaCore.Theme.negativeTextColor : Plasmoid.configuration.color_one
    property string colorTwo: useSystemColors ? PlasmaCore.Theme.positiveTextColor : Plasmoid.configuration.color_two
    property string colorThree: useSystemColors ? PlasmaCore.Theme.neutralTextColor : Plasmoid.configuration.color_three

    // Plasmoid
    fullRepresentation: Item {
        id: widget
        Plasmoid.backgroundHints: (enableShadows ? PlasmaCore.Types.ShadowBackground : PlasmaCore.Types.NoBackground) | PlasmaCore.Types.ConfigurableBackground
        Layout.minimumWidth: wrapper.implicitWidth + 50
        Layout.minimumHeight: wrapper.implicitHeight + 50
        
        
        // Time Data Source
        Plasma5Support.DataSource {
            id: timeSource
            engine: "time"
            connectedSources: ["Local"]
            interval: 1000
            signal fillDataChanged
            property bool use24Hour: root.enable24Hour
            
            onDataChanged: {
                var curDate = timeSource.data["Local"]["DateTime"]
                
                var DAY = parseInt(Qt.formatDate(curDate, "dd"))
                var HOUR = parseInt(Qt.formatTime(curDate, "hh"))
                var HOURAP = HOUR > 12 || HOUR == 0 ? Math.abs(HOUR - 12) : HOUR
                var MIN = parseInt(Qt.formatTime(curDate, "mm"))
                month.text = Qt.formatDate(curDate, "MMM")
                year.text = Qt.formatDate(curDate, "yyyy")
                timeAP.text = use24Hour ? ":" : Qt.formatTime(curDate, "AP")

                if (enable24Hour) {
                    hours.text = HOUR
                } else {
                    hours.text = HOURAP < 10 ? "0" + HOURAP.toString(): HOURAP
                }
                day.text = DAY < 10 ? "0" + DAY.toString() : DAY
                minutes.text = MIN < 10 ? "0" + MIN.toString() : MIN
                
                if (enableFillAnimation) fillDataChanged()
            } 
            onUse24HourChanged: {
                dataChanged()
            }
            onFillDataChanged: {
                var curDate = timeSource.data["Local"]["DateTime"]
                // updating minute fill value each second
                minutes.currentVal = parseInt(Qt.formatTime(curDate, "ss"))
                hours.currentVal = parseInt(minutes.text)
                day.currentVal = parseInt(Qt.formatTime(curDate,"hh"))+1
                month.to = daysInMonth(parseInt(Qt.formatDate(curDate, "MM")), parseInt(year.text))
                month.currentVal = parseInt(day.text)    
                year.currentVal = parseInt(Qt.formatDate(curDate, "MM"))
                if(!use24Hour) {
                    timeAP.currentVal = timeAP.text == "AM" ? 1 : 2
                }
            }
            
        }
        
        // Return days in a month to get fill data for the current month
        function daysInMonth (month, year) {
            return new Date(year, month, 0).getDate();
        }   

        // System Monitor Data Source
        Plasma5Support.DataSource {
            id: sysMonSource
            engine: "systemmonitor"
            connectedSources: ["mem/physical/available", "cpu/system/TotalLoad", "system/uptime"]
            interval: sysMonInterval
            onDataChanged: {
                cpuUsage.usage = Math.round(data["cpu/system/TotalLoad"]["value"])
                var ramUsageData = data["mem/physical/available"]
                ramUsage.usage = Math.round(((ramUsageData["max"]-ramUsageData["value"])/ramUsageData["max"])*100)
                
                // uptime
                var up = parseInt((data["system/uptime"]["value"]))
                if (up < 60) {
                    uptime.unit = "s"
                    uptime.from = 0
                    uptime.to = 60
                } else if (up < 3600) {
                    uptime.unit = "m"
                    uptime.from = 0
                    uptime.to = 60
                    up = up/60
                } else if (up < 86400) {
                    uptime.unit = "h"
                    uptime.from = 0
                    uptime.to = 24
                    up = up/3600
                } else {
                    uptime.unit = "d"
                    uptime.from = 0
                    uptime.to = 365
                    up = up/86400
                }
                uptime.usage = parseInt(up)
            }
        }
        
        // Music Data Source
        Plasma5Support.DataSource {
            id: musicSource
            engine: "mpris2"
            property bool showAudio: Plasmoid.configuration.show_audio
            
            onDataChanged: {
                connectedSources = ["@multiplex"]
                var audioData = data["@multiplex"]
                
                
                // show if and only if the audio source exists, the metadata exists, showAudio is enabled and the audio is currently playing
                if (audioData && showAudio && audioData["PlaybackStatus"] === "Playing") {
                    sectionAudio.visible = true
                    
                    var audioMetadata = audioData["Metadata"]
                    var title = audioMetadata["xesam:title"]
                    var artist = audioMetadata["xesam:artist"]
                    var thumb = audioMetadata["mpris:artUrl"]   
                    
                    audioTitle.text = title ? title : ""
                    audioThumb.source = thumb ? thumb : ""
                    
                    try {
                        audioArtist.text = artist.join(", ")
                    } catch(err) {
                        audioArtist.text = artist
                    }
                } else {
                    sectionAudio.visible = false
                }
            }
            onSourcesChanged: {
                dataChanged()
            }
            onSourceRemoved: {
                dataChanged()
            }
            onShowAudioChanged: {
                dataChanged()
            }
            Component.onCompleted: {
                dataChanged()
            }
        }
        
        
        // Layout
        ColumnLayout {
            id: wrapper
            anchors.centerIn: parent
            RowLayout {
                id: sectionAudio
                Layout.fillWidth: true
                Layout.bottomMargin: audioSpacing
                ColumnLayout {
                    id: nowPlaying
                    property var fontSize: nowPlayingFontSize;
                    FontLabel {
                        fill: false
                        color: colorOne
                        text: "Now"
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: nowPlaying.fontSize
                    }
                    FontLabel {
                        fill: false
                        color: colorOne
                        text: "Playing"
                        Layout.alignment: Qt.AlignRight
                        font.pixelSize: nowPlaying.fontSize
                    }
                }
                Image {
                    id: audioThumb 
                    fillMode: Image.PreserveAspectCrop
                    Layout.maximumHeight: audioImageWidth 
                    Layout.maximumWidth: audioImageWidth
                }
                ColumnLayout {
                    FontLabel {
                        id: audioTitle
                        color: colorTwo
                        fill: false
                        font.pixelSize: audioTitleFontSize
                        elide: Text.ElideRight
                        labelWidth: sectionTime.width
                        Layout.alignment: Qt.AlignLeft
                    }
                    FontLabel {
                        id: audioArtist
                        color: colorThree
                        fill: false
                        font.pixelSize: audioArtistFontSize
                        elide: Text.ElideRight
                        labelWidth: sectionTime.width
                        Layout.alignment: Qt.AlignLeft
                    }
                }
            }
            RowLayout {
                id: sectionDateTime
                Layout.fillWidth: true
                Layout.fillHeight: true
                ColumnLayout {
                    id: sectionDate
                    Layout.alignment: Qt.AlignHCenter 
                    Layout.fillWidth: true
                    spacing: dateSpacing
                    visible: showDate
                    FontLabel {
                        id: month
                        font.pixelSize: monthFontSize
                        color: colorOne
                        from: 0
                    }
                    FontLabel {
                        id: day 
                        font.pixelSize: dayFontSize
                        color: colorTwo
                        from: 0
                        to: 24
                    }
                    FontLabel {
                        id: year 
                        font.pixelSize: yearFontSize
                        color: colorThree
                        from: 1
                        to: 12
                    }
                }
                RowLayout {
                    id: sectionTime
                    Layout.alignment: Qt.AlignHCenter 
                    Layout.fillWidth: true
                    FontLabel {
                        id: hours
                        font.pixelSize: timeFontSize
                        color: colorOne
                        from: 0
                        to: 60
                    }
                    FontLabel {
                        id: timeAP
                        font.pixelSize: timeAPFontSize
                        color: colorThree
                        from: 1
                        to: 2
                    }
                    FontLabel {
                        id: minutes
                        font.pixelSize: timeFontSize
                        color: colorTwo
                        from: 0
                        to: 60
                    }
                }
            }
            RowLayout {
                id: sectionSysMon
                Layout.fillWidth: true
                Layout.topMargin: sysMonSpacing
                Layout.alignment: Qt.AlignRight
                visible: showSysMon
                
                SysMonLabel {
                    id: cpuUsage
                    text: "CPU"
                    color: colorOne
                    from: 0
                    to: 100
                    unit: "%"
                }
                SysMonLabel {
                    id: ramUsage
                    text: "RAM"
                    color: colorTwo
                    from: 0
                    to: 100
                    unit: "%"
                }
                SysMonLabel {
                    id: uptime
                    text: "UPTIME"
                    color: colorThree
                }
            }
            
        }
    }
}
