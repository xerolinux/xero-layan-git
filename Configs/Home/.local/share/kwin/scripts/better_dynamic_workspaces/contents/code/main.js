// Better Dynamic Workspaces  

const MIN_DESKTOPS = 2;
const LOG_LEVEL = 2; // 0 verbose, 1 debug, 2 normal

function log(...args) { print("[better_dynamic_ws]", ...args); }
function debug(...args) { if (LOG_LEVEL <= 1) log(...args); }
function trace(...args) { if (LOG_LEVEL <= 0) log(...args); }

let animationGuard = false;

/******** Plasma 6 Compatibility Layer ********/

const compat = {
	addDesktop: () => {
		workspace.createDesktop(workspace.desktops.length, undefined);
	},

	windowAddedSignal: ws => ws.windowAdded,
	windowList: ws => ws.windowList(),

	desktopChangedSignal: client => client.desktopsChanged,

	toDesktop: d => d,

	workspaceDesktops: () => workspace.desktops,

	lastDesktop: () => workspace.desktops[workspace.desktops.length - 1],

	deleteLastDesktop: () => {
		try {
			animationGuard = true;

			const desktops = workspace.desktops;
			const last = desktops[desktops.length - 1];
			const current = workspace.currentDesktop;
			const idx = desktops.indexOf(current);

			const fallback =
			idx + 1 < desktops.length || idx === -1
			? desktops[idx + 1]
			: current;

			workspace.currentDesktop = fallback;
			workspace.removeDesktop(last);
			workspace.currentDesktop = current;
		} finally {
			animationGuard = false;
		}
	},

	findDesktop: (list, d) => list.indexOf(d),

	clientDesktops: c => c.desktops,

	setClientDesktops: (c, ds) => { c.desktops = ds; },

	clientOnDesktop: (c, d) => c.desktops.indexOf(d) !== -1,

	desktopAmount: () => workspace.desktops.length,
};

/******** Desktop Renumbering ********/

function renumberDesktops() {
	let count = compat.desktopAmount();

	for (let i = 0; i < count; i++) {
		const desktops = compat.workspaceDesktops();
		const current = desktops[i];

		if (desktops.indexOf(current) !== i) {
			compat.addDesktop();
			const newDesk = compat.lastDesktop();

			compat.windowList(workspace).forEach(client => {
				if (compat.clientOnDesktop(client, current)) {
					const newList = compat.clientDesktops(client)
					.map(d => (d === current ? newDesk : d));
					compat.setClientDesktops(client, newList);
				}
			});

			compat.deleteLastDesktop();
		}
	}
}

/******** GNOME‑Accurate Cleanup ********/

function desktopIsEmpty(idx) {
	const d = compat.workspaceDesktops()[idx];
	const clients = compat.windowList(workspace);

	for (const c of clients) {
		if (
			compat.clientOnDesktop(c, d) &&
			!c.skipPager &&
			!c.onAllDesktops
		) {
			return false;
		}
	}

	return true;
}

function removeDesktop(idx) {
	const count = compat.desktopAmount();
	if (count - 1 <= idx) return false;
	if (count <= MIN_DESKTOPS) return false;

	compat.windowList(workspace).forEach(c => {
		const cds = compat.clientDesktops(c);
		const all = compat.workspaceDesktops();
		const updated = cds.map(d => {
			const i = all.indexOf(d);
			return i > idx ? all[i - 1] : d;
		});
		compat.setClientDesktops(c, updated);
	});

	compat.deleteLastDesktop();
	renumberDesktops();
	return true;
}

/******** Unified GNOME Cleanup ********/

function enforceGnomeModel() {
	if (animationGuard) return;

	animationGuard = true;
	try {
		const all = compat.workspaceDesktops();
		const lastIdx = all.length - 1;

		// Remove all empty desktops except the last one
		for (let i = lastIdx - 1; i >= 0; i--) {
			if (desktopIsEmpty(i)) {
				removeDesktop(i);
			}
		}

		// Ensure last desktop is empty
		const newLastIdx = compat.desktopAmount() - 1;
		if (!desktopIsEmpty(newLastIdx)) {
			compat.addDesktop();
		}

		renumberDesktops();
	} finally {
		animationGuard = false;
	}
}

/******** Core Behavior ********/

function handleClientDesktopChange(client) {
	if (compat.clientOnDesktop(client, compat.lastDesktop())) {
		compat.addDesktop();
		renumberDesktops();
	}
	enforceGnomeModel();
}

function onClientAdded(client) {
	if (!client || client.skipPager) return;

	if (compat.clientOnDesktop(client, compat.lastDesktop())) {
		compat.addDesktop();
		renumberDesktops();
	}

	compat.desktopChangedSignal(client).connect(() => {
		handleClientDesktopChange(client);
	});

	enforceGnomeModel();
}

/******** Initialization ********/

function trimToMinimum() {
	while (compat.desktopAmount() > MIN_DESKTOPS) {
		try {
			compat.deleteLastDesktop();
		} catch (err) {
			break;
		}
	}
}

trimToMinimum();

(function setupInitialDesktops() {
	const ds = compat.workspaceDesktops();
	workspace.currentDesktop = ds[0];

	while (compat.desktopAmount() > MIN_DESKTOPS) {
		try {
			compat.deleteLastDesktop();
		} catch (err) {
			break;
		}
	}

	if (compat.desktopAmount() < MIN_DESKTOPS) {
		compat.addDesktop();
	}

	renumberDesktops();
})();

compat.windowList(workspace).forEach(onClientAdded);
compat.windowAddedSignal(workspace).connect(onClientAdded);
workspace.windowRemoved.connect(() => enforceGnomeModel());

workspace.currentDesktopChanged.connect(() => enforceGnomeModel());

// Startup redirect to enforce GNOME behavior.... might not be needed anymore tbh XD 
let initialRedirectDone = false;
workspace.currentDesktopChanged.connect(function () {
	if (initialRedirectDone) return;
	initialRedirectDone = true;

	const all = compat.workspaceDesktops();
	const currIdx = compat.findDesktop(all, workspace.currentDesktop);

	if (currIdx === 1) {
		animationGuard = true;
		try {
			workspace.currentDesktop = all[0];
		} finally {
			animationGuard = false;
		}
	}
});

