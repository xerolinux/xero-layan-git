/*
    This file is part of the KDE project.

    SPDX-FileCopyrightText: 2018 Vlad Zahorodnii <vlad.zahorodnii@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

"use strict";

function interpolateRect(src, tgt, t) {


    var itp = {
        x: (1 - t) * src.x + t * tgt.x,
        y: (1 - t) * src.y + t * tgt.y,
        width: (1 - t) * src.width + t * tgt.width,
        height: (1 - t) * src.height + t * tgt.height,
    };
    return itp;
}

var squashEffect = {
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
            cancel(window.unminimizeAnimation);
            delete window.unminimizeAnimation;
        }

        if (window.minimizeAnimation) {
            cancel(window.minimizeAnimation);
        }
        var sourceRect = window.geometry;
        var targetRect = interpolateRect(sourceRect, window.iconGeometry, 0.15);
        var sclx = targetRect.width / window.geometry.width;
        var scly = targetRect.height / window.geometry.height;
        var scl = (sclx < scly) ? sclx : scly;

        window.minimizeAnimation = animate({
            window: window,
            duration: animationTime(100),
            animations: [
                {
                    type: Effect.Scale,
                    from: 1,
                    to: scl,
                    curve: QEasingCurve.Linear
                },
                {
                    type: Effect.Opacity,
                    from: 10/10,
                    to: 0.2,
                    curve: QEasingCurve.Linear
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: 0,
                        value2: 0
                    },
                    to: {
                        value1: -(sourceRect.x + sourceRect.width / 2 - targetRect.x - targetRect.width / 2),
                        value2: -(sourceRect.y + sourceRect.height / 2 - targetRect.y - targetRect.height / 2)
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
            cancel(window.minimizeAnimation);
            delete window.minimizeAnimation;
        }

        if (window.unminimizeAnimation) {
            cancel(window.unminimizeAnimation);
        }

        var windowRect = window.geometry;
        var iconRect = window.iconGeometry;

        var sourceRect = window.geometry;
        var snappyness = 0.4;
        var targetRect = interpolateRect(sourceRect, window.iconGeometry, snappyness);
        var sclx = targetRect.width / window.geometry.width;
        var scly = targetRect.height / window.geometry.height;
        var scl = (sclx < scly) ? sclx : scly;

        window.unminimizeAnimation = animate({
            window: window,
            duration: animationTime(317),
            animations: [
                {
                    type: Effect.Scale,
                    from: scl,
                    to: 1,
                    curve: QEasingCurve.OutExpo
                },
                {
                    type: Effect.Translation,
                    from: {
                        value1: -(sourceRect.x + sourceRect.width / 2 - targetRect.x - targetRect.width / 2),
                        value2: -(sourceRect.y + sourceRect.height / 2 - targetRect.y - targetRect.height / 2)
                    },
                    to: {
                        value1: 0,
                        value2: 0
                    },
                    curve: QEasingCurve.OutExpo
                },
                {
                    type: Effect.Opacity,
                    from: 0.0,
                    to: 1.0,
                    curve: QEasingCurve.OutExpo
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
        effects.windowAdded.connect(squashEffect.slotWindowAdded);
        for (const window of effects.stackingOrder) {
            squashEffect.slotWindowAdded(window);
        }
    }
};

squashEffect.init();
