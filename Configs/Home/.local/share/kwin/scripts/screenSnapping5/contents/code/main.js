/********************************************************************
 KWin - the KDE window manager
 This file is part of the KDE project.

 Copyright (C) 2014 Thomas Lübking <thomas.luebking@gmail.com>
 KDE5 revisions 2016 Bob Farmer <kde@bfarmer.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*********************************************************************/

var snapInnerX = readConfig("InnerX", 10);
var snapOuterX= readConfig("OuterX", 10);
var snapInnerY = readConfig("InnerY", 10);
var snapOuterY= readConfig("OuterY", 10);

// ---------------------------------------------------------

var clientStepUserMovedResized = function(client, rect) {
    if (rect == undefined)
        rect = client.geometry;
    else if (!client.move)
        return;
    var area = workspace.clientArea(KWin.WorkArea, workspace.activeScreen, workspace.currentDesktop);
    var adjust = false;
    var diff = rect.x - area.x;
    if (diff < snapInnerX && diff > -snapOuterX) {
        adjust = true;
        var width = rect.width;
        rect.x = area.x;
        rect.width = width;
    } else {
        diff = rect.x + rect.width - (area.x + area.width);
        if (diff > -snapInnerX && diff < snapOuterX) {
            adjust = true;
            var width = rect.width;
            rect.x = area.x + area.width - width;
            rect.width = width;
        }
    }
    diff = rect.y - area.y;
    if (diff < snapInnerY && diff > -snapOuterY) {
        adjust = true;
        var height = rect.height;
        rect.y = area.y;
        rect.height = height;
    } else {
        diff = rect.y + rect.height - (area.y + area.height);
        if (diff > -snapInnerY && diff < snapOuterY) {
            adjust = true;
            var height = rect.height;
            rect.y = area.y + area.height - height;
            rect.height = height;
        }
    }
    if (adjust)
        client.geometry = rect;
}

var addClient = function(client) {
    client.clientStepUserMovedResized.connect(clientStepUserMovedResized);
    client.clientFinishUserMovedResized.connect(clientStepUserMovedResized);
    clientStepUserMovedResized(client);
}

options.borderSnapZone = 0;
workspace.clientAdded.connect(addClient);
var clients = workspace.clientList();
for (var i = 0; i < clients.length; ++i) {
    addClient(clients[i])
}

