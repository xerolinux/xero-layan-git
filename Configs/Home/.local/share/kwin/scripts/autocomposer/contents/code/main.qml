import QtQuick 2.0;
import org.kde.plasma.core 2.0 as PlasmaCore;
import org.kde.plasma.components 2.0 as Plasma;
import org.kde.kwin 2.0;

Item {
	id: root

	PlasmaCore.DataSource {
		id: composition
		engine: 'executable'
		connectedSources: []
		property QtObject client

		function set(aClient) {
			client = aClient
			var windowId = client.windowId.toString(16)
			composition.connectSource("xprop -id 0x" + windowId + " _NET_WM_BYPASS_COMPOSITOR")
		}

		function preference(stdout) {
			if (clientIsException()) {
				return "on"
			} else {
				var splittedStdout = stdout.split(" ")
				var compositionPreference = splittedStdout[2]

				if (compositionPreference == "not") {
					return "none"
				} else if (compositionPreference == 1) {
					return "off"
				} else if (compositionPreference == 2) {
					return "on"
				} else {
					var error = ": Invalid composition preference: "
					console.error(client.resourceClass + error + compositionPreference)
					return false
				}
			}
		}

		function clientIsException() {
			var result = false;
			const exceptions = ['plasmashell', 'ksmserver-logout-greeter'];
			let index = 0;

			while (!result && index < exceptions.length) {
				result = (client.resourceClass == exceptions[index]);
				index++;
			}

			return result;
		}

		onNewData: {
			var exitCode = data["exit code"]
			var exitStatus = data["exit status"]
			var stdout = data["stdout"]
			var stderr = data["stderr"]

			if (exitCode != 0) {
				console.error(stderr)
				return false
			} else {
				let compositionPreference = composition.preference(stdout)

				if (client.fullScreen && compositionPreference != "on") {
					client.blocksCompositing = true
				} else if (!client.fullScreen && compositionPreference != "off") {
					client.blocksCompositing = false
				}
			}

			disconnectSource(sourceName)
		}
	}

	Connections {
		target: workspace

		function onClientAdded(client) {
			if (client.fullScreen) {
				composition.set(client)
			}
		}

		function onClientFullScreenSet(client) {
			composition.set(client)
		}
	}
}
