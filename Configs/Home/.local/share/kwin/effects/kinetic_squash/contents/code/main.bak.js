/*
    This file is part of the KDE project.

    SPDX-FileCopyrightText: 2018 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

"use strict";

function interpolate(from, to, t) {
    return from * (1 - t) + to * t;
}

function morphRect(fromRect, toRect, t) {
    var targetScale = (toRect.width > toRect.height)
        ? toRect.width / fromRect.width
        : toRect.height / fromRect.height;
    var toCenter = {
        x: toRect.x + toRect.width / 2,
        y: toRect.y + toRect.height / 2
    };

    var targetRect = {
        x: toCenter.x - targetScale * fromRect.width / 2,
        y: toCenter.y - targetScale * fromRect.height / 2,
        width: targetScale * fromRect.width,
        height: targetScale * fromRect.height
    };

    var morphedRect = {
        x: interpolate(fromRect.x, targetRect.x, t),
        y: interpolate(fromRect.y, targetRect.y, t),
        width: interpolate(fromRect.width, targetRect.width, t),
        height: interpolate(fromRect.height, targetRect.height, t)
    };

    return morphedRect;
}

var squashEffect = {
    duration: animationTime(630),
    loadConfig: function () {
        // squashEffect.duration = animationTime(1000);
    },
    slotWindowMinimized: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }

        // If the window doesn't have an icon in the task manager,
        // don't animate it.
        var iconRect = window.iconGeometry;
        if (iconRect.width == 0 || iconRect.height == 0) {
            return;
        }

        if (window.unminimizeAnimation) {
            if (redirect(window.unminimizeAnimation, Effect.Backward)) {
                return;
            }
            cancel(window.unminimizeAnimation);
            delete window.unminimizeAnimation;
        }

        if (window.minimizeAnimation) {
            if (redirect(window.minimizeAnimation, Effect.Forward)) {
                return;
            }
            cancel(window.minimizeAnimation);
        }

        var windowRect = window.geometry;
        var iconRect = window.iconGeometry;
        var targetRect = iconRect;//morphRect(windowRect, iconRect, 1.0);
        var dx = targetRect.x - windowRect.x - (windowRect.width - targetRect.width) / 2;
        var dy = targetRect.y - windowRect.y - (windowRect.height - targetRect.height) / 2;
        var dmax = 100;
        var dabs = (dx * dx + dy * dy) ** 0.5;
        if (dabs > dmax) {
            dx = dx * dmax / dabs;
            dy = dy * dmax / dabs;
        }


        window.minimizeAnimation = animate({
            window: window,
            // duration: squashEffect.duration,
            duration: animationTime(150),
            animations: [
                {
                    type: Effect.Scale,
                    from: 1,
                    to: 0.925,
                    curve: QEasingCurve.Linear
                },
                {
                    type: Effect.Opacity,
                    from: 9/10,
                    to: 0.0,
                    curve: QEasingCurve.Linear
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: 0,
                        value2: 0
                    },
                    to: {
                        value1: dx,
                        value2: dy
                    },
                    curve: QEasingCurve.Linear
                },
            ]
        });
    },
    slotWindowUnminimized: function (window) {
        if (effects.hasActiveFullScreenEffect) {
            return;
        }

        // If the window doesn't have an icon in the task manager,
        // don't animate it.
        var iconRect = window.iconGeometry;
        if (iconRect.width == 0 || iconRect.height == 0) {
            return;
        }

        if (window.minimizeAnimation) {
            // if (redirect(window.minimizeAnimation, Effect.Backward)) {
            //     return;
            // }
            cancel(window.minimizeAnimation);
            delete window.minimizeAnimation;
        }

        if (window.unminimizeAnimation) {
            // if (redirect(window.unminimizeAnimation, Effect.Forward)) {
            //     return;
            // }
            cancel(window.unminimizeAnimation);
        }

        var windowRect = window.geometry;

        window.unminimizeAnimation = animate({
            window: window,
            duration: squashEffect.duration/2,
            animations: [
                {
                    type: Effect.Size,
                    from: {
                        value1: iconRect.width,
                        value2: iconRect.height
                    },
                    to: {
                        value1: windowRect.width,
                        value2: windowRect.height
                    },
                    curve: QEasingCurve.OutExpo
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: iconRect.x - windowRect.x -
                            (windowRect.width - iconRect.width) / 2,
                        value2: iconRect.y - windowRect.y -
                            (windowRect.height - iconRect.height) / 2,
                    },
                    to: {
                        value1: 0.0,
                        value2: 0.0
                    },
                    curve: QEasingCurve.OutExpo
                },
                {
                    type: Effect.Opacity,
                    from: 0.0,
                    to: 1.0,
                    curve: QEasingCurve.OutQuad
                }
            ]
        });
    },
    slotWindowAdded: function (window) {
        window.minimizedChanged.connect(() => {
            if (window.minimized) {
                squashEffect.slotWindowMinimized(window);
            } else {
                squashEffect.slotWindowUnminimized(window);
            }
        });
    },
    init: function () {
        effect.configChanged.connect(squashEffect.loadConfig);

        effects.windowAdded.connect(squashEffect.slotWindowAdded);
        for (const window of effects.stackingOrder) {
            squashEffect.slotWindowAdded(window);
        }
    }
};

squashEffect.init();
