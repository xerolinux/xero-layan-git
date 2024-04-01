import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("Entry management")
        icon: "media-track-show-active"
        source: "configEntries.qml"
    }
    ConfigCategory {
        name: i18n("Debug information")
        icon: "debug-step-instruction"
        source: "configInfo.qml"
    }
}
