/********************************************************************
 This file is part of the KDE project.

 Copyright (C) 2012 Martin Gräßlin <mgraesslin@kde.org>
 Copyright (C) 2018 Alex Nemeth <alex.nemeth329@gmail.com

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

var rubberbandMaximizeEffect = {
    duration: animationTime(200),
    deviation: 0.05,
    loadConfig: function () {
        "use strict";
        rubberbandMaximizeEffect.duration = animationTime(200);
    },
    slotWindowMaximizedStateChanged: function (window) {
        "use strict";
        if (!window.oldGeometry) {
            return;
        }

        window.setData(Effect.WindowForceBackgroundContrastRole, true);
        window.setData(Effect.WindowForceBlurRole, true);

        var oldGeometry = window.oldGeometry;
        var newGeometry = window.geometry;
        if (oldGeometry.width == newGeometry.width &&
                oldGeometry.height == newGeometry.height) {
            oldGeometry = window.olderGeometry;
        }

        var scale = 0;

        if (oldGeometry.width < newGeometry.width) {
            scale = 1 - rubberbandMaximizeEffect.deviation;
        } else {
            scale = 1 + rubberbandMaximizeEffect.deviation;
        }

        window.olderGeometry = window.oldGeometry;
        window.oldGeometry = newGeometry;

        window.maximizeAnimation = animate({
            window: window,
            curve: QEasingCurve.OutSine,
            duration: rubberbandMaximizeEffect.duration,
            animations: [
                {
                    type: Effect.Size,
                    delay: animationTime(10),
                    from: {
                        value1: newGeometry.width * scale,
                        value2: newGeometry.height * scale
                    },
                    to: {
                        value1: newGeometry.width,
                        value2: newGeometry.height
                    }
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: (oldGeometry.x - newGeometry.x - (newGeometry.width - oldGeometry.width) / 2) * rubberbandMaximizeEffect.deviation,
                        value2: (oldGeometry.y - newGeometry.y - (newGeometry.height - oldGeometry.height) / 2) * rubberbandMaximizeEffect.deviation
                    },
                    to: {
                        value1: 0,
                        value2: 0
                    }
                }
            ]
        });
    },
    slotWindowGeometryShapeChanged: function (window, oldGeometry) {
        "use strict";
        if (window.maximizeAnimation) {
            if (window.geometry.width != window.oldGeometry.width ||
                    window.geometry.height != window.oldGeometry.height) {
                cancel(window.maximizeAnimation);
                delete window.maximizeAnimation;
            }
        }
        window.oldGeometry = window.geometry;
        window.olderGeometry = oldGeometry;
    },
    slotAnimationEnded: function (window) {
        window.setData(Effect.WindowForceBackgroundContrastRole, null);
        window.setData(Effect.WindowForceBlurRole, null);
    },
    init: function () {
        "use strict";
        effect.configChanged.connect(rubberbandMaximizeEffect.loadConfig);
        effect.animationEnded.connect(rubberbandMaximizeEffect.slotAnimationEnded);
        effects.windowGeometryShapeChanged.connect(rubberbandMaximizeEffect.slotWindowGeometryShapeChanged);
        effects.windowMaximizedStateChanged.connect(rubberbandMaximizeEffect.slotWindowMaximizedStateChanged);
    }
};

rubberbandMaximizeEffect.init();
