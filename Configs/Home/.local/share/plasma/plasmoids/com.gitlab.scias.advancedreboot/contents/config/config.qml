import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: i18n("General")
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: i18n("Debug information")
        icon: "debug-step-instruction"
        source: "configInfo.qml"
    }
}
