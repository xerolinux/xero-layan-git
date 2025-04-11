import QtQuick 2.5
import org.kde.plasma.private.quicklaunch 1.0

Item {
    Logic {
        id: kRun
    }

    function launch(url) {
        kRun.openUrl(url)
    }
}
