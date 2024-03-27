function isCSD(client) {
    return client.resourceClass == "gedit" || client.resourceClass == "nautilus" || client.resourceClass == "lollypop" || client.resourceClass == "gtg" || client.resourceClass == "totem" || client.resourceClass == "corebird" || client.resourceClass == "gnome-music" || client.resourceClass == "gnome-boxes" || client.resourceClass == "evince" || client.resourceClass == "baobab" || client.resourceClass == "epiphany" || client.resourceClass == "dconf-editor" || client.resourceClass == "file-roller" || client.resourceClass == "five-or-more" || client.resourceClass == "four-in-a-row" || client.resourceClass == "gnome-calculator" || client.resourceClass == "gnome-chess" || client.resourceClass == "gnome-clocks" || client.resourceClass == "gnome-contacts" || client.resourceClass == "gnome-control-center" || client.resourceClass == "gnome-dictionary" || client.resourceClass == "gnome-disks" || client.resourceClass == "gnome-builder" || client.resourceClass == "gnome-font-viewer" || client.resourceClass == "gnome-klotski" || client.resourceClass == "gnome-logs" || client.resourceClass == "gnome-mahjongg" || client.resourceClass == "gnome-mines" || client.resourceClass == "gnome-multi-writer" || client.resourceClass == "gnome-robots" || client.resourceClass == "gnome-sudoku" || client.resourceClass == "gnome-taquin" || client.resourceClass == "gnome-tetravex" || client.resourceClass == "gnome-usage" || client.resourceClass == "hitori" || client.resourceClass == "iagno" || client.resourceClass == "simple-scan" || client.resourceClass == "sysprof" || client.resourceClass == "notes-up" || client.resourceClass == "gnome-mpv" || client.resourceClass == "glade" || client.resourceClass == "eolie" || client.resourceClass == "gnome-calendar" || client.resourceClass == "gnome-todo" || client.resourceClass == "marker" || client.resourceClass == "pitivi" || client.resourceClass == "pamac-manager";
}



function onClientAdded(client) {
    if (isCSD(client)) {
        client.noBorder = false;
    }
}


workspace.clientAdded.connect(onClientAdded);
