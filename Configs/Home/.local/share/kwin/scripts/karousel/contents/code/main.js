"use strict";
function initWorkspaceSignalHandlers(world, focusPasser) {
    const manager = new SignalManager();
    manager.connect(Workspace.windowAdded, (kwinClient) => {
        world.do((clientManager, desktopManager) => {
            clientManager.addClient(kwinClient);
        });
    });
    manager.connect(Workspace.windowRemoved, (kwinClient) => {
        world.do((clientManager, desktopManager) => {
            clientManager.removeClient(kwinClient, 1 /* FocusPassing.Type.Immediate */);
        });
    });
    manager.connect(Workspace.windowActivated, (kwinClient) => {
        if (kwinClient === null) {
            focusPasser.activate();
        }
        else {
            focusPasser.clearIfDifferent(kwinClient);
            world.do((clientManager, desktopManager) => {
                clientManager.onClientFocused(kwinClient);
            });
        }
    });
    manager.connect(Workspace.currentDesktopChanged, () => {
        world.do(() => { }); // re-arrange desktop
    });
    manager.connect(Workspace.currentActivityChanged, () => {
        world.do(() => { }); // re-arrange desktop
    });
    manager.connect(Workspace.screensChanged, () => {
        world.do((clientManager, desktopManager) => {
            desktopManager.selectScreen(Workspace.activeScreen);
        });
    });
    manager.connect(Workspace.activitiesChanged, () => {
        world.do((clientManager, desktopManager) => {
            desktopManager.updateActivities();
        });
    });
    manager.connect(Workspace.desktopsChanged, () => {
        world.do((clientManager, desktopManager) => {
            desktopManager.updateDesktops();
        });
    });
    manager.connect(Workspace.virtualScreenSizeChanged, () => {
        world.onScreenResized();
    });
    return manager;
}
class PresetWidths {
    constructor(presetWidths, spacing) {
        this.presets = PresetWidths.parsePresetWidths(presetWidths, spacing);
    }
    next(currentWidth, minWidth, maxWidth) {
        const widths = this.getWidths(minWidth, maxWidth);
        const nextIndex = widths.findIndex(width => width > currentWidth);
        return nextIndex >= 0 ? widths[nextIndex] : widths[0];
    }
    prev(currentWidth, minWidth, maxWidth) {
        const widths = this.getWidths(minWidth, maxWidth).reverse();
        const nextIndex = widths.findIndex(width => width < currentWidth);
        return nextIndex >= 0 ? widths[nextIndex] : widths[0];
    }
    getWidths(minWidth, maxWidth) {
        const widths = this.presets.map(f => clamp(f(maxWidth), minWidth, maxWidth));
        widths.sort((a, b) => a - b);
        return uniq(widths);
    }
    static parsePresetWidths(presetWidths, spacing) {
        function getRatioFunction(ratio) {
            return (maxWidth) => Math.floor((maxWidth + spacing) * ratio - spacing);
        }
        return presetWidths.split(",").map((widthStr) => {
            widthStr = widthStr.trim();
            const widthPx = PresetWidths.parseNumberWithSuffix(widthStr, "px");
            if (widthPx !== undefined) {
                return () => widthPx;
            }
            const widthPct = PresetWidths.parseNumberWithSuffix(widthStr, "%");
            if (widthPct !== undefined) {
                return getRatioFunction(widthPct / 100.0);
            }
            return getRatioFunction(PresetWidths.parseNumberSafe(widthStr));
        });
    }
    static parseNumberSafe(str) {
        const num = Number(str);
        if (isNaN(num) || num <= 0) {
            throw new Error("Invalid number: " + str);
        }
        return num;
    }
    static parseNumberWithSuffix(str, suffix) {
        if (!str.endsWith(suffix)) {
            return undefined;
        }
        return PresetWidths.parseNumberSafe(str.substring(0, str.length - suffix.length).trim());
    }
}
class ContextualResizer {
    constructor(presetWidths) {
        this.presetWidths = presetWidths;
    }
    increaseWidth(column) {
        const grid = column.grid;
        const desktop = grid.desktop;
        const visibleRange = desktop.getCurrentVisibleRange();
        const minWidth = column.getMinWidth();
        const maxWidth = column.getMaxWidth();
        if (!Range.contains(visibleRange, column) || column.getWidth() >= maxWidth) {
            return;
        }
        const leftVisibleColumn = grid.getLeftmostVisibleColumn(visibleRange, true);
        const rightVisibleColumn = grid.getRightmostVisibleColumn(visibleRange, true);
        if (leftVisibleColumn === null || rightVisibleColumn === null) {
            console.assert(false); // should at least see self
            return;
        }
        const leftSpace = leftVisibleColumn.getLeft() - visibleRange.getLeft();
        const rightSpace = visibleRange.getRight() - rightVisibleColumn.getRight();
        const newWidth = findMinPositive([
            column.getWidth() + leftSpace + rightSpace,
            column.getWidth() + leftSpace + rightSpace + leftVisibleColumn.getWidth() + grid.config.gapsInnerHorizontal,
            column.getWidth() + leftSpace + rightSpace + rightVisibleColumn.getWidth() + grid.config.gapsInnerHorizontal,
            ...this.presetWidths.getWidths(minWidth, maxWidth),
        ], width => width - column.getWidth());
        if (newWidth === undefined) {
            return;
        }
        column.setWidth(newWidth, true);
        desktop.scrollCenterVisible(column);
    }
    decreaseWidth(column) {
        const grid = column.grid;
        const desktop = grid.desktop;
        const visibleRange = desktop.getCurrentVisibleRange();
        const minWidth = column.getMinWidth();
        const maxWidth = column.getMaxWidth();
        if (!Range.contains(visibleRange, column) || column.getWidth() <= minWidth) {
            return;
        }
        const leftVisibleColumn = grid.getLeftmostVisibleColumn(visibleRange, true);
        const rightVisibleColumn = grid.getRightmostVisibleColumn(visibleRange, true);
        if (leftVisibleColumn === null || rightVisibleColumn === null) {
            console.assert(false); // should at least see self
            return;
        }
        let leftOffScreenColumn = grid.getLeftColumn(leftVisibleColumn);
        if (leftOffScreenColumn === column) {
            leftOffScreenColumn = null;
        }
        let rightOffScreenColumn = grid.getRightColumn(rightVisibleColumn);
        if (rightOffScreenColumn === column) {
            rightOffScreenColumn = null;
        }
        const visibleColumnsWidth = rightVisibleColumn.getRight() - leftVisibleColumn.getLeft();
        const unusedWidth = visibleRange.getWidth() - visibleColumnsWidth;
        const leftOffScreen = leftOffScreenColumn === null ? 0 : leftOffScreenColumn.getWidth() + grid.config.gapsInnerHorizontal - unusedWidth;
        const rightOffScreen = rightOffScreenColumn === null ? 0 : rightOffScreenColumn.getWidth() + grid.config.gapsInnerHorizontal - unusedWidth;
        const newWidth = findMinPositive([
            column.getWidth() - leftOffScreen,
            column.getWidth() - rightOffScreen,
            ...this.presetWidths.getWidths(minWidth, maxWidth),
        ], width => column.getWidth() - width);
        if (newWidth === undefined) {
            return;
        }
        column.setWidth(newWidth, true);
        desktop.scrollCenterVisible(column);
    }
}
class RawResizer {
    constructor(presetWidths) {
        this.presetWidths = presetWidths;
    }
    increaseWidth(column) {
        const newWidth = findMinPositive([
            ...this.presetWidths.getWidths(column.getMinWidth(), column.getMaxWidth()),
        ], width => width - column.getWidth());
        if (newWidth === undefined) {
            return;
        }
        column.setWidth(newWidth, true);
    }
    decreaseWidth(column) {
        const newWidth = findMinPositive([
            ...this.presetWidths.getWidths(column.getMinWidth(), column.getMaxWidth()),
        ], width => column.getWidth() - width);
        if (newWidth === undefined) {
            return;
        }
        column.setWidth(newWidth, true);
    }
}
class CenterClamper {
    clampScrollX(desktop, x) {
        const firstColumn = desktop.grid.getFirstColumn();
        if (firstColumn === null) {
            return 0;
        }
        const lastColumn = desktop.grid.getLastColumn();
        const minScroll = Math.round((firstColumn.getWidth() - desktop.tilingArea.width) / 2);
        const maxScroll = Math.round(desktop.grid.getWidth() - (desktop.tilingArea.width + lastColumn.getWidth()) / 2);
        return clamp(x, minScroll, maxScroll);
    }
}
class EdgeClamper {
    clampScrollX(desktop, x) {
        const minScroll = 0;
        const maxScroll = desktop.grid.getWidth() - desktop.tilingArea.width;
        if (maxScroll < 0) {
            return Math.round(maxScroll / 2);
        }
        return clamp(x, minScroll, maxScroll);
    }
}
class CenteredScroller {
    scrollToColumn(desktop, column) {
        desktop.scrollCenterRange(column);
    }
}
class GroupedScroller {
    scrollToColumn(desktop, column) {
        desktop.scrollCenterVisible(column);
    }
}
class LazyScroller {
    scrollToColumn(desktop, column) {
        desktop.scrollIntoView(column);
    }
}
const defaultWindowRules = `[
    {
        "class": "(org\\\\.kde\\\\.)?plasmashell",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?polkit-kde-authentication-agent-1",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?kded6",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?kcalc",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?kfind",
        "tile": true
    },
    {
        "class": "(org\\\\.kde\\\\.)?kruler",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?krunner",
        "tile": false
    },
    {
        "class": "(org\\\\.kde\\\\.)?yakuake",
        "tile": false
    },
    {
        "class": "steam",
        "caption": "Steam Big Picture Mode",
        "tile": false
    },
    {
        "class": "zoom",
        "caption": "Zoom Cloud Meetings|zoom|zoom <2>",
        "tile": false
    },
    {
        "class": "jetbrains-.*",
        "caption": "splash",
        "tile": false
    },
    {
        "class": "jetbrains-.*",
        "caption": "Unstash Changes|Paths Affected by stash@.*",
        "tile": true
    }
]`;
const configDef = [
    {
        name: "gapsOuterTop",
        type: "UInt",
        default: 16,
    },
    {
        name: "gapsOuterBottom",
        type: "UInt",
        default: 16,
    },
    {
        name: "gapsOuterLeft",
        type: "UInt",
        default: 16,
    },
    {
        name: "gapsOuterRight",
        type: "UInt",
        default: 16,
    },
    {
        name: "gapsInnerHorizontal",
        type: "UInt",
        default: 8,
    },
    {
        name: "gapsInnerVertical",
        type: "UInt",
        default: 8,
    },
    {
        name: "stackOffsetX",
        type: "UInt",
        default: 8,
    },
    {
        name: "stackOffsetY",
        type: "UInt",
        default: 32,
    },
    {
        name: "manualScrollStep",
        type: "UInt",
        default: 200,
    },
    {
        name: "presetWidths",
        type: "String",
        default: "50%, 100%",
    },
    {
        name: "offScreenOpacity",
        type: "UInt",
        default: 100,
    },
    {
        name: "untileOnDrag",
        type: "Bool",
        default: true,
    },
    {
        name: "cursorFollowsFocus",
        type: "Bool",
        default: false,
    },
    {
        name: "stackColumnsByDefault",
        type: "Bool",
        default: false,
    },
    {
        name: "resizeNeighborColumn",
        type: "Bool",
        default: false,
    },
    {
        name: "reMaximize",
        type: "Bool",
        default: false,
    },
    {
        name: "skipSwitcher",
        type: "Bool",
        default: false,
    },
    {
        name: "scrollingLazy",
        type: "Bool",
        default: true,
    },
    {
        name: "scrollingCentered",
        type: "Bool",
        default: false,
    },
    {
        name: "scrollingGrouped",
        type: "Bool",
        default: false,
    },
    {
        name: "gestureScroll",
        type: "Bool",
        default: false,
    },
    {
        name: "gestureScrollInvert",
        type: "Bool",
        default: false,
    },
    {
        name: "gestureScrollStep",
        type: "UInt",
        default: 1920,
    },
    {
        name: "tiledKeepBelow",
        type: "Bool",
        default: true,
    },
    {
        name: "floatingKeepAbove",
        type: "Bool",
        default: false,
    },
    {
        name: "noLayering",
        type: "Bool",
        default: false,
    },
    {
        name: "windowRules",
        type: "String",
        default: defaultWindowRules,
    },
    {
        name: "tiledDesktops",
        type: "String",
        default: ".*",
    },
];
class Actions {
    constructor(config) {
        this.config = config;
        this.focusLeft = (cm, dm, window, column, grid) => {
            const leftColumn = grid.getLeftColumn(column);
            if (leftColumn === null) {
                return;
            }
            leftColumn.getWindowToFocus().focus();
        };
        this.focusRight = (cm, dm, window, column, grid) => {
            const rightColumn = grid.getRightColumn(column);
            if (rightColumn === null) {
                return;
            }
            rightColumn.getWindowToFocus().focus();
        };
        this.focusUp = (cm, dm, window, column, grid) => {
            const aboveWindow = column.getAboveWindow(window);
            if (aboveWindow === null) {
                return;
            }
            aboveWindow.focus();
        };
        this.focusDown = (cm, dm, window, column, grid) => {
            const belowWindow = column.getBelowWindow(window);
            if (belowWindow === null) {
                return;
            }
            belowWindow.focus();
        };
        this.focusNext = (cm, dm, window, column, grid) => {
            const belowWindow = column.getBelowWindow(window);
            if (belowWindow !== null) {
                belowWindow.focus();
            }
            else {
                const rightColumn = grid.getRightColumn(column);
                if (rightColumn === null) {
                    return;
                }
                rightColumn.getFirstWindow().focus();
            }
        };
        this.focusPrevious = (cm, dm, window, column, grid) => {
            const aboveWindow = column.getAboveWindow(window);
            if (aboveWindow !== null) {
                aboveWindow.focus();
            }
            else {
                const leftColumn = grid.getLeftColumn(column);
                if (leftColumn === null) {
                    return;
                }
                leftColumn.getLastWindow().focus();
            }
        };
        this.focusStart = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const firstColumn = grid.getFirstColumn();
            if (firstColumn === null) {
                return;
            }
            firstColumn.getWindowToFocus().focus();
        };
        this.focusEnd = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const lastColumn = grid.getLastColumn();
            if (lastColumn === null) {
                return;
            }
            lastColumn.getWindowToFocus().focus();
        };
        this.windowMoveLeft = (cm, dm, window, column, grid) => {
            if (column.getWindowCount() === 1) {
                // move from own column into existing column
                const leftColumn = grid.getLeftColumn(column);
                if (leftColumn === null) {
                    return;
                }
                window.moveToColumn(leftColumn, true, 0 /* FocusPassing.Type.None */);
                grid.desktop.autoAdjustScroll();
            }
            else {
                // move from shared column into own column
                const newColumn = new Column(grid, grid.getLeftColumn(column));
                window.moveToColumn(newColumn, true, 0 /* FocusPassing.Type.None */);
            }
        };
        this.windowMoveRight = (cm, dm, window, column, grid, bottom = true) => {
            if (column.getWindowCount() === 1) {
                // move from own column into existing column
                const rightColumn = grid.getRightColumn(column);
                if (rightColumn === null) {
                    return;
                }
                window.moveToColumn(rightColumn, bottom, 0 /* FocusPassing.Type.None */);
                grid.desktop.autoAdjustScroll();
            }
            else {
                // move from shared column into own column
                const newColumn = new Column(grid, column);
                window.moveToColumn(newColumn, true, 0 /* FocusPassing.Type.None */);
            }
        };
        // TODO (optimization): only arrange moved windows
        this.windowMoveUp = (cm, dm, window, column, grid) => {
            column.moveWindowUp(window);
        };
        // TODO (optimization): only arrange moved windows
        this.windowMoveDown = (cm, dm, window, column, grid) => {
            column.moveWindowDown(window);
        };
        this.windowMoveNext = (cm, dm, window, column, grid) => {
            const canMoveDown = window !== column.getLastWindow();
            if (canMoveDown) {
                column.moveWindowDown(window);
            }
            else {
                this.windowMoveRight(cm, dm, window, column, grid, false);
            }
        };
        this.windowMovePrevious = (cm, dm, window, column, grid) => {
            const canMoveUp = window !== column.getFirstWindow();
            if (canMoveUp) {
                column.moveWindowUp(window);
            }
            else {
                this.windowMoveLeft(cm, dm, window, column, grid);
            }
        };
        this.windowMoveStart = (cm, dm, window, column, grid) => {
            const newColumn = new Column(grid, null);
            window.moveToColumn(newColumn, true, 0 /* FocusPassing.Type.None */);
        };
        this.windowMoveEnd = (cm, dm, window, column, grid) => {
            const newColumn = new Column(grid, grid.getLastColumn());
            window.moveToColumn(newColumn, true, 0 /* FocusPassing.Type.None */);
        };
        this.windowToggleFloating = (cm, dm) => {
            if (Workspace.activeWindow === null) {
                return;
            }
            cm.toggleFloatingClient(Workspace.activeWindow);
        };
        this.columnMoveLeft = (cm, dm, window, column, grid) => {
            grid.moveColumnLeft(column);
        };
        this.columnMoveRight = (cm, dm, window, column, grid) => {
            grid.moveColumnRight(column);
        };
        this.columnMoveStart = (cm, dm, window, column, grid) => {
            grid.moveColumn(column, null);
        };
        this.columnMoveEnd = (cm, dm, window, column, grid) => {
            grid.moveColumn(column, grid.getLastColumn());
        };
        this.columnToggleStacked = (cm, dm, window, column, grid) => {
            column.toggleStacked();
        };
        this.columnWidthIncrease = (cm, dm, window, column, grid) => {
            this.config.columnResizer.increaseWidth(column);
        };
        this.columnWidthDecrease = (cm, dm, window, column, grid) => {
            this.config.columnResizer.decreaseWidth(column);
        };
        this.cyclePresetWidths = (cm, dm, window, column, grid) => {
            const nextWidth = this.config.presetWidths.next(column.getWidth(), column.getMinWidth(), column.getMaxWidth());
            column.setWidth(nextWidth, true);
        };
        this.cyclePresetWidthsReverse = (cm, dm, window, column, grid) => {
            const nextWidth = this.config.presetWidths.prev(column.getWidth(), column.getMinWidth(), column.getMaxWidth());
            column.setWidth(nextWidth, true);
        };
        this.columnsWidthEqualize = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const visibleRange = desktop.getCurrentVisibleRange();
            const visibleColumns = Array.from(desktop.grid.getVisibleColumns(visibleRange, true));
            const availableSpace = desktop.tilingArea.width;
            const gapsWidth = desktop.grid.config.gapsInnerHorizontal * (visibleColumns.length - 1);
            const widths = fillSpace(availableSpace - gapsWidth, visibleColumns.map(column => ({ min: column.getMinWidth(), max: column.getMaxWidth() })));
            visibleColumns.forEach((column, index) => column.setWidth(widths[index], true));
            desktop.scrollCenterRange(Range.fromRanges(visibleColumns[0], visibleColumns[visibleColumns.length - 1]));
        };
        this.columnsSqueezeLeft = (cm, dm, window, focusedColumn, grid) => {
            const visibleRange = grid.desktop.getCurrentVisibleRange();
            if (!Range.contains(visibleRange, focusedColumn)) {
                return;
            }
            const currentVisibleColumns = Array.from(grid.getVisibleColumns(visibleRange, true));
            console.assert(currentVisibleColumns.includes(focusedColumn), "should at least contain the focused column");
            const targetColumn = grid.getLeftColumn(currentVisibleColumns[0]);
            if (targetColumn === null) {
                return;
            }
            const wantedVisibleColumns = [targetColumn, ...currentVisibleColumns];
            while (true) {
                const success = this.squeezeColumns(wantedVisibleColumns);
                if (success) {
                    break;
                }
                const removedColumn = wantedVisibleColumns.pop();
                if (removedColumn === focusedColumn) {
                    break; // don't scroll past the currently focused column
                }
            }
        };
        this.columnsSqueezeRight = (cm, dm, window, focusedColumn, grid) => {
            const visibleRange = grid.desktop.getCurrentVisibleRange();
            if (!Range.contains(visibleRange, focusedColumn)) {
                return;
            }
            const currentVisibleColumns = Array.from(grid.getVisibleColumns(visibleRange, true));
            console.assert(currentVisibleColumns.includes(focusedColumn), "should at least contain the focused column");
            const targetColumn = grid.getRightColumn(currentVisibleColumns[currentVisibleColumns.length - 1]);
            if (targetColumn === null) {
                return;
            }
            const wantedVisibleColumns = [...currentVisibleColumns, targetColumn];
            while (true) {
                const success = this.squeezeColumns(wantedVisibleColumns);
                if (success) {
                    break;
                }
                const removedColumn = wantedVisibleColumns.shift();
                if (removedColumn === focusedColumn) {
                    break; // don't scroll past the currently focused column
                }
            }
        };
        this.squeezeColumns = (columns) => {
            const firstColumn = columns[0];
            const lastColumn = columns[columns.length - 1];
            const grid = firstColumn.grid;
            const desktop = grid.desktop;
            const availableSpace = desktop.tilingArea.width;
            const gapsWidth = grid.config.gapsInnerHorizontal * (columns.length - 1);
            const columnConstraints = columns.map(column => ({ min: column.getMinWidth(), max: column.getWidth() }));
            const minTotalWidth = gapsWidth + columnConstraints.reduce((acc, constraint) => acc + constraint.min, 0);
            if (minTotalWidth > availableSpace) {
                // there's nothing we can do
                return false;
            }
            const widths = fillSpace(availableSpace - gapsWidth, columnConstraints);
            columns.forEach((column, index) => column.setWidth(widths[index], true));
            desktop.scrollCenterRange(Range.fromRanges(firstColumn, lastColumn));
            return true;
        };
        this.gridScrollLeft = (cm, dm) => {
            this.gridScroll(dm, -this.config.manualScrollStep);
        };
        this.gridScrollRight = (cm, dm) => {
            this.gridScroll(dm, this.config.manualScrollStep);
        };
        this.gridScroll = (desktopManager, amount) => {
            const desktop = desktopManager.getCurrentDesktop();
            if (desktop !== undefined) {
                desktop.adjustScroll(amount, false);
            }
        };
        this.gridScrollStart = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const firstColumn = grid.getFirstColumn();
            if (firstColumn === null) {
                return;
            }
            grid.desktop.scrollToColumn(firstColumn, false);
        };
        this.gridScrollEnd = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const lastColumn = grid.getLastColumn();
            if (lastColumn === null) {
                return;
            }
            grid.desktop.scrollToColumn(lastColumn, false);
        };
        this.gridScrollFocused = (cm, dm, window, column, grid) => {
            const scrollAmount = Range.minus(column, grid.desktop.getCurrentVisibleRange());
            if (scrollAmount !== 0) {
                grid.desktop.adjustScroll(scrollAmount, true);
            }
            else {
                grid.desktop.scrollToColumn(column, true);
            }
        };
        this.gridScrollLeftColumn = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const column = grid.getLeftmostVisibleColumn(grid.desktop.getCurrentVisibleRange(), true);
            if (column === null) {
                return;
            }
            const leftColumn = grid.getLeftColumn(column);
            if (leftColumn === null) {
                return;
            }
            grid.desktop.scrollToColumn(leftColumn, false);
        };
        this.gridScrollRightColumn = (cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const column = grid.getRightmostVisibleColumn(grid.desktop.getCurrentVisibleRange(), true);
            if (column === null) {
                return;
            }
            const rightColumn = grid.getRightColumn(column);
            if (rightColumn === null) {
                return;
            }
            grid.desktop.scrollToColumn(rightColumn, false);
        };
        this.screenSwitch = (cm, dm) => {
            dm.selectScreen(Workspace.activeScreen);
        };
        this.focus = (columnIndex, cm, dm) => {
            const desktop = dm.getCurrentDesktop();
            if (desktop === undefined) {
                return;
            }
            const grid = desktop.grid;
            const targetColumn = grid.getColumnAtIndex(columnIndex);
            if (targetColumn === null) {
                return;
            }
            targetColumn.getWindowToFocus().focus();
        };
        this.windowMoveToColumn = (columnIndex, cm, dm, window, column, grid) => {
            const targetColumn = grid.getColumnAtIndex(columnIndex);
            if (targetColumn === null) {
                return;
            }
            window.moveToColumn(targetColumn, true, 0 /* FocusPassing.Type.None */);
            grid.desktop.autoAdjustScroll();
        };
        this.columnMoveToColumn = (columnIndex, cm, dm, window, column, grid) => {
            const targetColumn = grid.getColumnAtIndex(columnIndex);
            if (targetColumn === null || targetColumn === column) {
                return;
            }
            if (targetColumn.isToTheRightOf(column)) {
                grid.moveColumn(column, targetColumn);
            }
            else {
                grid.moveColumn(column, grid.getLeftColumn(targetColumn));
            }
        };
        this.columnMoveToDesktop = (desktopIndex, cm, dm, window, column, oldGrid) => {
            const kwinDesktop = Workspace.desktops[desktopIndex];
            if (kwinDesktop === undefined) {
                return;
            }
            const newDesktop = dm.getDesktopInCurrentActivity(kwinDesktop);
            if (newDesktop === undefined) {
                return;
            }
            const newGrid = newDesktop.grid;
            if (newGrid === null || newGrid === oldGrid) {
                return;
            }
            column.moveToGrid(newGrid, newGrid.getLastColumn());
        };
        this.tailMoveToDesktop = (desktopIndex, cm, dm, window, column, oldGrid) => {
            const kwinDesktop = Workspace.desktops[desktopIndex];
            if (kwinDesktop === undefined) {
                return;
            }
            const newDesktop = dm.getDesktopInCurrentActivity(kwinDesktop);
            if (newDesktop === undefined) {
                return;
            }
            const newGrid = newDesktop.grid;
            if (newGrid === null || newGrid === oldGrid) {
                return;
            }
            oldGrid.evacuateTail(newGrid, column);
        };
    }
}
function getKeyBindings(world, actions) {
    return [
        {
            name: "window-toggle-floating",
            description: "Toggle floating",
            defaultKeySequence: "Meta+Space",
            action: () => world.do(actions.windowToggleFloating),
        },
        {
            name: "focus-left",
            description: "Move focus left",
            defaultKeySequence: "Meta+A",
            action: () => world.doIfTiledFocused(actions.focusLeft),
        },
        {
            name: "focus-right",
            description: "Move focus right",
            comment: "Clashes with default KDE shortcuts, may require manual remapping",
            defaultKeySequence: "Meta+D",
            action: () => world.doIfTiledFocused(actions.focusRight),
        },
        {
            name: "focus-up",
            description: "Move focus up",
            comment: "Clashes with default KDE shortcuts, may require manual remapping",
            defaultKeySequence: "Meta+W",
            action: () => world.doIfTiledFocused(actions.focusUp),
        },
        {
            name: "focus-down",
            description: "Move focus down",
            comment: "Clashes with default KDE shortcuts, may require manual remapping",
            defaultKeySequence: "Meta+S",
            action: () => world.doIfTiledFocused(actions.focusDown),
        },
        {
            name: "focus-next",
            description: "Move focus to the next window in grid",
            action: () => world.doIfTiledFocused(actions.focusNext),
        },
        {
            name: "focus-previous",
            description: "Move focus to the previous window in grid",
            action: () => world.doIfTiledFocused(actions.focusPrevious),
        },
        {
            name: "focus-start",
            description: "Move focus to start",
            defaultKeySequence: "Meta+Home",
            action: () => world.do(actions.focusStart),
        },
        {
            name: "focus-end",
            description: "Move focus to end",
            defaultKeySequence: "Meta+End",
            action: () => world.do(actions.focusEnd),
        },
        {
            name: "window-move-left",
            description: "Move window left",
            comment: "Moves window out of and into columns",
            defaultKeySequence: "Meta+Shift+A",
            action: () => world.doIfTiledFocused(actions.windowMoveLeft),
        },
        {
            name: "window-move-right",
            description: "Move window right",
            comment: "Moves window out of and into columns",
            defaultKeySequence: "Meta+Shift+D",
            action: () => world.doIfTiledFocused(actions.windowMoveRight),
        },
        {
            name: "window-move-up",
            description: "Move window up",
            defaultKeySequence: "Meta+Shift+W",
            action: () => world.doIfTiledFocused(actions.windowMoveUp),
        },
        {
            name: "window-move-down",
            description: "Move window down",
            defaultKeySequence: "Meta+Shift+S",
            action: () => world.doIfTiledFocused(actions.windowMoveDown),
        },
        {
            name: "window-move-next",
            description: "Move window to the next position in grid",
            action: () => world.doIfTiledFocused(actions.windowMoveNext),
        },
        {
            name: "window-move-previous",
            description: "Move window to the previous position in grid",
            action: () => world.doIfTiledFocused(actions.windowMovePrevious),
        },
        {
            name: "window-move-start",
            description: "Move window to start",
            defaultKeySequence: "Meta+Shift+Home",
            action: () => world.doIfTiledFocused(actions.windowMoveStart),
        },
        {
            name: "window-move-end",
            description: "Move window to end",
            defaultKeySequence: "Meta+Shift+End",
            action: () => world.doIfTiledFocused(actions.windowMoveEnd),
        },
        {
            name: "column-toggle-stacked",
            description: "Toggle stacked layout for focused column",
            comment: "Only the active window visible",
            defaultKeySequence: "Meta+X",
            action: () => world.doIfTiledFocused(actions.columnToggleStacked),
        },
        {
            name: "column-move-left",
            description: "Move column left",
            defaultKeySequence: "Meta+Ctrl+Shift+A",
            action: () => world.doIfTiledFocused(actions.columnMoveLeft),
        },
        {
            name: "column-move-right",
            description: "Move column right",
            defaultKeySequence: "Meta+Ctrl+Shift+D",
            action: () => world.doIfTiledFocused(actions.columnMoveRight),
        },
        {
            name: "column-move-start",
            description: "Move column to start",
            defaultKeySequence: "Meta+Ctrl+Shift+Home",
            action: () => world.doIfTiledFocused(actions.columnMoveStart),
        },
        {
            name: "column-move-end",
            description: "Move column to end",
            defaultKeySequence: "Meta+Ctrl+Shift+End",
            action: () => world.doIfTiledFocused(actions.columnMoveEnd),
        },
        {
            name: "column-width-increase",
            description: "Increase column width",
            defaultKeySequence: "Meta+Ctrl++",
            action: () => world.doIfTiledFocused(actions.columnWidthIncrease),
        },
        {
            name: "column-width-decrease",
            description: "Decrease column width",
            defaultKeySequence: "Meta+Ctrl+-",
            action: () => world.doIfTiledFocused(actions.columnWidthDecrease),
        },
        {
            name: "cycle-preset-widths",
            description: "Cycle through preset column widths",
            defaultKeySequence: "Meta+R",
            action: () => world.doIfTiledFocused(actions.cyclePresetWidths),
        },
        {
            name: "cycle-preset-widths-reverse",
            description: "Cycle through preset column widths in reverse",
            defaultKeySequence: "Meta+Shift+R",
            action: () => world.doIfTiledFocused(actions.cyclePresetWidthsReverse),
        },
        {
            name: "columns-width-equalize",
            description: "Equalize widths of visible columns",
            defaultKeySequence: "Meta+Ctrl+X",
            action: () => world.do(actions.columnsWidthEqualize),
        },
        {
            name: "columns-squeeze-left",
            description: "Squeeze left column onto the screen",
            comment: "Clashes with default KDE shortcuts, may require manual remapping",
            defaultKeySequence: "Meta+Ctrl+A",
            action: () => world.doIfTiledFocused(actions.columnsSqueezeLeft),
        },
        {
            name: "columns-squeeze-right",
            description: "Squeeze right column onto the screen",
            defaultKeySequence: "Meta+Ctrl+D",
            action: () => world.doIfTiledFocused(actions.columnsSqueezeRight),
        },
        {
            name: "grid-scroll-focused",
            description: "Center focused window",
            comment: "Scrolls so that the focused window is centered in the screen",
            defaultKeySequence: "Meta+Alt+Return",
            action: () => world.doIfTiledFocused(actions.gridScrollFocused),
        },
        {
            name: "grid-scroll-left-column",
            description: "Scroll one column to the left",
            defaultKeySequence: "Meta+Alt+A",
            action: () => world.do(actions.gridScrollLeftColumn),
        },
        {
            name: "grid-scroll-right-column",
            description: "Scroll one column to the right",
            defaultKeySequence: "Meta+Alt+D",
            action: () => world.do(actions.gridScrollRightColumn),
        },
        {
            name: "grid-scroll-left",
            description: "Scroll left",
            defaultKeySequence: "Meta+Alt+PgUp",
            action: () => world.do(actions.gridScrollLeft),
        },
        {
            name: "grid-scroll-right",
            description: "Scroll right",
            defaultKeySequence: "Meta+Alt+PgDown",
            action: () => world.do(actions.gridScrollRight),
        },
        {
            name: "grid-scroll-start",
            description: "Scroll to start",
            defaultKeySequence: "Meta+Alt+Home",
            action: () => world.do(actions.gridScrollStart),
        },
        {
            name: "grid-scroll-end",
            description: "Scroll to end",
            defaultKeySequence: "Meta+Alt+End",
            action: () => world.do(actions.gridScrollEnd),
        },
        {
            name: "screen-switch",
            description: "Move Karousel grid to the current screen",
            defaultKeySequence: "Meta+Ctrl+Return",
            action: () => world.do(actions.screenSwitch),
        },
    ];
}
function getNumKeyBindings(world, actions) {
    return [
        {
            name: "focus-{}",
            description: "Move focus to column {}",
            comment: "Clashes with default KDE shortcuts, may require manual remapping",
            defaultModifiers: "Meta",
            fKeys: false,
            action: (i) => world.do(actions.focus.partial(i)),
        },
        {
            name: "window-move-to-column-{}",
            description: "Move window to column {}",
            comment: "Requires manual remapping according to your keyboard layout, e.g. Meta+Shift+1 -> Meta+!",
            defaultModifiers: "Meta+Shift",
            fKeys: false,
            action: (i) => world.doIfTiledFocused(actions.windowMoveToColumn.partial(i)),
        },
        {
            name: "column-move-to-column-{}",
            description: "Move column to position {}",
            comment: "Requires manual remapping according to your keyboard layout, e.g. Meta+Ctrl+Shift+1 -> Meta+Ctrl+!",
            defaultModifiers: "Meta+Ctrl+Shift",
            fKeys: false,
            action: (i) => world.doIfTiledFocused(actions.columnMoveToColumn.partial(i)),
        },
        {
            name: "column-move-to-desktop-{}",
            description: "Move column to desktop {}",
            defaultModifiers: "Meta+Ctrl+Shift",
            fKeys: true,
            action: (i) => world.doIfTiledFocused(actions.columnMoveToDesktop.partial(i)),
        },
        {
            name: "tail-move-to-desktop-{}",
            description: "Move this and all following columns to desktop {}",
            defaultModifiers: "Meta+Ctrl+Shift+Alt",
            fKeys: true,
            action: (i) => world.doIfTiledFocused(actions.tailMoveToDesktop.partial(i)),
        },
    ];
}
function catchWrap(f) {
    return () => {
        try {
            f();
        }
        catch (error) {
            log(error);
            log(error.stack);
        }
    };
}
function registerKeyBinding(shortcutActions, keyBinding) {
    shortcutActions.push(new ShortcutAction(keyBinding, catchWrap(keyBinding.action)));
}
function registerNumKeyBindings(shortcutActions, numKeyBinding) {
    const numPrefix = numKeyBinding.fKeys ? "F" : "";
    const n = numKeyBinding.fKeys ? 12 : 9;
    for (let i = 0; i < 12; i++) {
        const numKey = String(i + 1);
        const keySequence = i < n ?
            numKeyBinding.defaultModifiers + "+" + numPrefix + numKey :
            "";
        shortcutActions.push(new ShortcutAction({
            name: applyMacro(numKeyBinding.name, numKey),
            description: applyMacro(numKeyBinding.description, numKey),
            defaultKeySequence: keySequence,
        }, catchWrap(() => numKeyBinding.action(i))));
    }
}
function registerKeyBindings(world, config) {
    const actions = new Actions(config);
    const shortcutActions = [];
    for (const keyBinding of getKeyBindings(world, actions)) {
        registerKeyBinding(shortcutActions, keyBinding);
    }
    for (const numKeyBinding of getNumKeyBindings(world, actions)) {
        registerNumKeyBindings(shortcutActions, numKeyBinding);
    }
    return shortcutActions;
}
class Column {
    constructor(grid, leftColumn) {
        this.gridX = 0;
        this.width = 0;
        this.windows = new LinkedList();
        this.stacked = grid.config.stackColumnsByDefault;
        this.focusTaker = null;
        this.grid = grid;
        this.grid.onColumnAdded(this, leftColumn);
    }
    moveToGrid(targetGrid, leftColumn) {
        if (targetGrid === this.grid) {
            this.grid.moveColumn(this, leftColumn);
        }
        else {
            this.grid.onColumnRemoved(this, this.isFocused() ? 1 /* FocusPassing.Type.Immediate */ : 0 /* FocusPassing.Type.None */);
            this.grid = targetGrid;
            targetGrid.onColumnAdded(this, leftColumn);
            for (const window of this.windows.iterator()) {
                window.client.kwinClient.desktops = [targetGrid.desktop.kwinDesktop];
            }
        }
    }
    isToTheLeftOf(other) {
        return this.gridX < other.gridX;
    }
    isToTheRightOf(other) {
        return this.gridX > other.gridX;
    }
    moveWindowUp(window) {
        this.windows.moveBack(window);
        this.grid.desktop.onLayoutChanged();
    }
    moveWindowDown(window) {
        this.windows.moveForward(window);
        this.grid.desktop.onLayoutChanged();
    }
    getWindowCount() {
        return this.windows.length();
    }
    isEmpty() {
        return this.getWindowCount() === 0;
    }
    getFirstWindow() {
        return this.windows.getFirst();
    }
    getLastWindow() {
        return this.windows.getLast();
    }
    getAboveWindow(window) {
        return this.windows.getPrev(window);
    }
    getBelowWindow(window) {
        return this.windows.getNext(window);
    }
    getWidth() {
        return this.width;
    }
    getMinWidth() {
        let maxMinWidth = Column.minWidth;
        for (const window of this.windows.iterator()) {
            const minWidth = window.client.kwinClient.minSize.width;
            if (minWidth > maxMinWidth) {
                maxMinWidth = minWidth;
            }
        }
        return maxMinWidth;
    }
    getMaxWidth() {
        return this.grid.desktop.tilingArea.width;
    }
    setWidth(width, setPreferred) {
        width = clamp(width, this.getMinWidth(), this.getMaxWidth());
        if (width === this.width) {
            return;
        }
        this.width = width;
        if (setPreferred) {
            for (const window of this.windows.iterator()) {
                window.client.preferredWidth = width;
            }
        }
        this.grid.onColumnWidthChanged(this);
    }
    adjustWidth(widthDelta, setPreferred) {
        this.setWidth(this.width + widthDelta, setPreferred);
    }
    updateWidth() {
        let minErr = Infinity;
        let closestPreferredWidth = this.width;
        for (const window of this.windows.iterator()) {
            const err = Math.abs(window.client.preferredWidth - this.width);
            if (err < minErr) {
                minErr = err;
                closestPreferredWidth = window.client.preferredWidth;
            }
        }
        this.setWidth(closestPreferredWidth, false);
    }
    // returns x position of left edge in grid space
    getLeft() {
        return this.gridX;
    }
    // returns x position of right edge in grid space
    getRight() {
        return this.gridX + this.width;
    }
    onUserResizeWidth(startWidth, currentDelta, resizingLeftSide, neighbor) {
        const oldColumnWidth = this.getWidth();
        this.setWidth(startWidth + currentDelta, true);
        const actualDelta = this.getWidth() - startWidth;
        let leftEdgeDeltaStep = resizingLeftSide ? oldColumnWidth - this.getWidth() : 0;
        if (neighbor !== undefined) {
            const oldNeighborWidth = neighbor.column.getWidth();
            neighbor.column.setWidth(neighbor.startWidth - actualDelta, true);
            if (resizingLeftSide) {
                leftEdgeDeltaStep -= neighbor.column.getWidth() - oldNeighborWidth;
            }
        }
        this.grid.desktop.adjustScroll(-leftEdgeDeltaStep, true);
    }
    adjustWindowHeight(window, heightDelta, top) {
        const otherWindow = top ? this.windows.getPrev(window) : this.windows.getNext(window);
        if (otherWindow === null) {
            return;
        }
        window.height += heightDelta;
        otherWindow.height -= heightDelta;
        this.grid.desktop.onLayoutChanged();
    }
    resizeWindows() {
        const nWindows = this.windows.length();
        if (nWindows === 0) {
            return;
        }
        if (nWindows === 1) {
            this.stacked = this.grid.config.stackColumnsByDefault;
        }
        let remainingPixels = this.grid.desktop.tilingArea.height - (nWindows - 1) * this.grid.config.gapsInnerVertical;
        let remainingWindows = nWindows;
        for (const window of this.windows.iterator()) {
            const windowHeight = Math.round(remainingPixels / remainingWindows);
            window.height = windowHeight;
            remainingPixels -= windowHeight;
            remainingWindows--;
        }
        // TODO: respect min height
        this.grid.desktop.onLayoutChanged();
    }
    getFocusTaker() {
        if (this.focusTaker === null || !this.windows.contains(this.focusTaker)) {
            return null;
        }
        return this.focusTaker;
    }
    getWindowToFocus() {
        return this.getFocusTaker() ?? this.windows.getFirst();
    }
    isFocused() {
        const lastFocusedWindow = this.grid.getLastFocusedWindow();
        if (lastFocusedWindow === null) {
            return false;
        }
        return lastFocusedWindow.column === this && lastFocusedWindow.isFocused();
    }
    arrange(x, visibleRange, forceOpaque) {
        if (this.grid.config.offScreenOpacity < 1.0 && !forceOpaque) {
            const opacity = Range.contains(visibleRange, this) ? 100 : this.grid.config.offScreenOpacity;
            for (const window of this.windows.iterator()) {
                window.client.kwinClient.opacity = opacity;
            }
        }
        if (this.stacked && this.windows.length() >= 2) {
            this.arrangeStacked(x);
            return;
        }
        let y = this.grid.desktop.tilingArea.y;
        for (const window of this.windows.iterator()) {
            window.arrange(x, y, this.width, window.height);
            y += window.height + this.grid.config.gapsInnerVertical;
        }
    }
    arrangeStacked(x) {
        const nWindows = this.windows.length();
        const windowWidth = this.width - (nWindows - 1) * this.grid.config.stackOffsetX;
        const windowHeight = this.grid.desktop.tilingArea.height - (nWindows - 1) * this.grid.config.stackOffsetY;
        let windowX = x;
        let windowY = this.grid.desktop.tilingArea.y;
        for (const window of this.windows.iterator()) {
            window.arrange(windowX, windowY, windowWidth, windowHeight);
            windowX += this.grid.config.stackOffsetX;
            windowY += this.grid.config.stackOffsetY;
        }
    }
    toggleStacked() {
        if (this.windows.length() < 2) {
            return;
        }
        this.stacked = !this.stacked;
        this.grid.desktop.onLayoutChanged();
    }
    onWindowAdded(window, bottom) {
        if (bottom) {
            this.windows.insertEnd(window);
        }
        else {
            this.windows.insertStart(window);
        }
        if (this.width === 0) {
            this.setWidth(window.client.preferredWidth, false);
        }
        // TODO: also change column width if the new window requires it
        this.resizeWindows();
        if (window.isFocused()) {
            this.onWindowFocused(window);
        }
        this.grid.desktop.onLayoutChanged();
    }
    onWindowRemoved(window, passFocus) {
        const lastWindow = this.windows.length() === 1;
        const windowToFocus = this.getAboveWindow(window) ?? this.getBelowWindow(window);
        this.windows.remove(window);
        if (window === this.focusTaker) {
            this.focusTaker = windowToFocus;
        }
        if (lastWindow) {
            console.assert(this.isEmpty());
            this.destroy(passFocus);
        }
        else {
            this.resizeWindows();
            if (windowToFocus !== null) {
                switch (passFocus) {
                    case 1 /* FocusPassing.Type.Immediate */:
                        windowToFocus.focus();
                        break;
                    case 2 /* FocusPassing.Type.OnUnfocus */:
                        this.grid.focusPasser.request(windowToFocus.client.kwinClient);
                        break;
                }
            }
        }
        this.grid.desktop.onLayoutChanged();
    }
    onWindowFocused(window) {
        this.grid.onColumnFocused(this, window);
        this.focusTaker = window;
    }
    restoreToTiled(focusedWindow) {
        const lastFocusedWindow = this.getFocusTaker();
        if (lastFocusedWindow !== null && lastFocusedWindow !== focusedWindow) {
            lastFocusedWindow.restoreToTiled();
        }
    }
    destroy(passFocus) {
        this.grid.onColumnRemoved(this, passFocus);
    }
}
Column.minWidth = 40;
class Desktop {
    constructor(kwinDesktop, pinManager, config, getScreen, layoutConfig, focusPasser) {
        this.kwinDesktop = kwinDesktop;
        this.pinManager = pinManager;
        this.config = config;
        this.getScreen = getScreen;
        this.scrollX = 0;
        this.gestureScrollXInitial = null;
        this.dirty = true;
        this.dirtyScroll = true;
        this.dirtyPins = true;
        this.grid = new Grid(this, layoutConfig, focusPasser);
        this.clientArea = Desktop.getClientArea(this.getScreen(), kwinDesktop);
        this.tilingArea = Desktop.getTilingArea(this.clientArea, kwinDesktop, pinManager, config);
    }
    updateArea() {
        const newClientArea = Desktop.getClientArea(this.getScreen(), this.kwinDesktop);
        if (rectEquals(newClientArea, this.clientArea) && !this.dirtyPins) {
            return;
        }
        this.clientArea = newClientArea;
        this.tilingArea = Desktop.getTilingArea(newClientArea, this.kwinDesktop, this.pinManager, this.config);
        this.dirty = true;
        this.dirtyScroll = true;
        this.dirtyPins = false;
        this.grid.onScreenSizeChanged();
        this.autoAdjustScroll();
    }
    static getClientArea(screen, kwinDesktop) {
        return Workspace.clientArea(0 /* ClientAreaOption.PlacementArea */, screen, kwinDesktop);
    }
    static getTilingArea(clientArea, kwinDesktop, pinManager, config) {
        const availableSpace = pinManager.getAvailableSpace(kwinDesktop, clientArea);
        const top = availableSpace.top + config.marginTop;
        const bottom = availableSpace.bottom - config.marginBottom;
        const left = availableSpace.left + config.marginLeft;
        const right = availableSpace.right - config.marginRight;
        return Qt.rect(left, top, right - left, bottom - top);
    }
    scrollIntoView(range) {
        const left = range.getLeft();
        const right = range.getRight();
        const initialVisibleRange = this.getCurrentVisibleRange();
        let targetScrollX;
        if (left < initialVisibleRange.getLeft()) {
            targetScrollX = left;
        }
        else if (right > initialVisibleRange.getRight()) {
            targetScrollX = right - this.tilingArea.width;
        }
        else {
            targetScrollX = initialVisibleRange.getLeft();
        }
        this.setScroll(targetScrollX, false);
    }
    scrollCenterRange(range) {
        const scrollAmount = Range.minus(range, this.getCurrentVisibleRange());
        this.adjustScroll(scrollAmount, true);
    }
    scrollCenterVisible(focusedColumn) {
        const columnRange = new Desktop.ColumnRange(focusedColumn);
        const visibleRange = this.getCurrentVisibleRange();
        columnRange.addNeighbors(visibleRange, this.grid.config.gapsInnerHorizontal);
        this.scrollCenterRange(columnRange);
    }
    autoAdjustScroll() {
        const focusedColumn = this.grid.getLastFocusedColumn();
        if (focusedColumn === null || focusedColumn.grid !== this.grid) {
            return;
        }
        this.scrollToColumn(focusedColumn, false);
    }
    scrollToColumn(column, force) {
        if (force || this.dirtyScroll || !Range.contains(this.getCurrentVisibleRange(), column)) {
            this.config.scroller.scrollToColumn(this, column);
        }
    }
    getVisibleRange(scrollX) {
        return Range.create(scrollX, this.tilingArea.width);
    }
    getCurrentVisibleRange() {
        return this.getVisibleRange(this.scrollX);
    }
    clampScrollX(x) {
        return this.config.clamper.clampScrollX(this, x);
    }
    setScroll(x, force) {
        const oldScrollX = this.scrollX;
        this.scrollX = force ? x : this.clampScrollX(x);
        if (this.scrollX !== oldScrollX) {
            this.onLayoutChanged();
        }
        this.dirtyScroll = false;
    }
    adjustScroll(dx, force) {
        this.setScroll(this.scrollX + dx, force);
    }
    gestureScroll(amount) {
        if (!this.config.gestureScroll) {
            return;
        }
        if (this.gestureScrollXInitial === null) {
            this.gestureScrollXInitial = this.scrollX;
        }
        if (this.config.gestureScrollInvert) {
            amount = -amount;
        }
        this.setScroll(this.gestureScrollXInitial + this.config.gestureScrollStep * amount, false);
    }
    gestureScrollFinish() {
        this.gestureScrollXInitial = null;
    }
    arrange() {
        // TODO (optimization): only arrange visible windows
        this.updateArea();
        if (!this.dirty) {
            return;
        }
        this.grid.arrange(this.tilingArea.x - this.scrollX, this.getCurrentVisibleRange());
        this.dirty = false;
    }
    forceArrange() {
        this.dirty = true;
    }
    onLayoutChanged() {
        this.dirty = true;
        this.dirtyScroll = true;
    }
    onPinsChanged() {
        this.dirty = true;
        this.dirtyScroll = true;
        this.dirtyPins = true;
    }
    destroy() {
        this.grid.destroy();
    }
}
(function (Desktop) {
    class ColumnRange {
        constructor(initialColumn) {
            this.left = initialColumn;
            this.right = initialColumn;
            this.width = initialColumn.getWidth();
        }
        addNeighbors(visibleRange, gap) {
            const grid = this.left.grid;
            const columnRange = this;
            function canFit(column) {
                return columnRange.width + gap + column.getWidth() <= visibleRange.getWidth();
            }
            function isUsable(column) {
                return column !== null && canFit(column);
            }
            let leftColumn = grid.getLeftColumn(this.left);
            let rightColumn = grid.getRightColumn(this.right);
            function checkColumns() {
                if (!isUsable(leftColumn)) {
                    leftColumn = null;
                }
                if (!isUsable(rightColumn)) {
                    rightColumn = null;
                }
            }
            checkColumns();
            const visibleCenter = visibleRange.getLeft() + visibleRange.getWidth() / 2;
            while (leftColumn !== null || rightColumn !== null) {
                const leftToCenter = leftColumn === null ? Infinity : Math.abs(leftColumn.getLeft() - visibleCenter);
                const rightToCenter = rightColumn === null ? Infinity : Math.abs(rightColumn.getRight() - visibleCenter);
                if (leftToCenter < rightToCenter) {
                    this.addLeft(leftColumn, gap);
                    leftColumn = grid.getLeftColumn(leftColumn);
                }
                else {
                    this.addRight(rightColumn, gap);
                    rightColumn = grid.getRightColumn(rightColumn);
                }
                checkColumns();
            }
        }
        addLeft(column, gap) {
            this.left = column;
            this.width += column.getWidth() + gap;
        }
        addRight(column, gap) {
            this.right = column;
            this.width += column.getWidth() + gap;
        }
        getLeft() {
            return this.left.getLeft();
        }
        getRight() {
            return this.right.getRight();
        }
        getWidth() {
            return this.width;
        }
    }
    Desktop.ColumnRange = ColumnRange;
})(Desktop || (Desktop = {}));
class Grid {
    constructor(desktop, config, focusPasser) {
        this.desktop = desktop;
        this.config = config;
        this.focusPasser = focusPasser;
        this.columns = new LinkedList();
        this.lastFocusedColumn = null;
        this.width = 0;
        this.userResize = false;
        this.userResizeFinishedDelayer = new Delayer(50, () => {
            // this delay prevents windows' contents from freezing after resizing
            this.desktop.onLayoutChanged();
            this.desktop.autoAdjustScroll();
            this.desktop.arrange();
        });
    }
    moveColumn(column, leftColumn) {
        if (column === leftColumn) {
            return;
        }
        const movedLeft = leftColumn === null ? true : column.isToTheRightOf(leftColumn);
        const firstMovedColumn = movedLeft ? column : this.getRightColumn(column);
        this.columns.move(column, leftColumn);
        this.columnsSetX(firstMovedColumn);
        this.desktop.onLayoutChanged();
        this.desktop.autoAdjustScroll();
    }
    moveColumnLeft(column) {
        this.columns.moveBack(column);
        this.columnsSetX(column);
        this.desktop.onLayoutChanged();
        this.desktop.autoAdjustScroll();
    }
    moveColumnRight(column) {
        const rightColumn = this.columns.getNext(column);
        if (rightColumn === null) {
            return;
        }
        this.moveColumnLeft(rightColumn);
    }
    getWidth() {
        return this.width;
    }
    isUserResizing() {
        return this.userResize;
    }
    getLeftColumn(column) {
        return this.columns.getPrev(column);
    }
    getRightColumn(column) {
        return this.columns.getNext(column);
    }
    getFirstColumn() {
        return this.columns.getFirst();
    }
    getLastColumn() {
        return this.columns.getLast();
    }
    getColumnAtIndex(i) {
        return this.columns.getItemAtIndex(i);
    }
    getLastFocusedColumn() {
        if (this.lastFocusedColumn === null || this.lastFocusedColumn.grid !== this) {
            return null;
        }
        return this.lastFocusedColumn;
    }
    getLastFocusedWindow() {
        const lastFocusedColumn = this.getLastFocusedColumn();
        if (lastFocusedColumn === null) {
            return null;
        }
        return lastFocusedColumn.getFocusTaker();
    }
    columnsSetX(firstMovedColumn) {
        const lastUnmovedColumn = firstMovedColumn === null ? this.columns.getLast() : this.columns.getPrev(firstMovedColumn);
        let x = lastUnmovedColumn === null ? 0 : lastUnmovedColumn.getRight() + this.config.gapsInnerHorizontal;
        if (firstMovedColumn !== null) {
            for (const column of this.columns.iteratorFrom(firstMovedColumn)) {
                column.gridX = x;
                x += column.getWidth() + this.config.gapsInnerHorizontal;
            }
        }
        this.width = x - this.config.gapsInnerHorizontal;
    }
    getLeftmostVisibleColumn(visibleRange, fullyVisible) {
        for (const column of this.columns.iterator()) {
            if (Range.contains(visibleRange, column)) {
                return column;
            }
        }
        return null;
    }
    getRightmostVisibleColumn(visibleRange, fullyVisible) {
        let last = null;
        for (const column of this.columns.iterator()) {
            if (Range.contains(visibleRange, column)) {
                last = column;
            }
            else if (last !== null) {
                break;
            }
        }
        return last;
    }
    *getVisibleColumns(visibleRange, fullyVisible) {
        for (const column of this.columns.iterator()) {
            if (Range.contains(visibleRange, column)) {
                yield column;
            }
        }
    }
    arrange(x, visibleRange) {
        for (const column of this.columns.iterator()) {
            column.arrange(x, visibleRange, this.userResize);
            x += column.getWidth() + this.config.gapsInnerHorizontal;
        }
        const focusedWindow = this.getLastFocusedWindow();
        if (focusedWindow !== null) {
            focusedWindow.client.ensureTransientsVisible(this.desktop.clientArea);
        }
    }
    onColumnAdded(column, leftColumn) {
        if (leftColumn === null) {
            this.columns.insertStart(column);
        }
        else {
            this.columns.insertAfter(column, leftColumn);
        }
        this.columnsSetX(column);
        this.desktop.onLayoutChanged();
        this.desktop.autoAdjustScroll();
    }
    onColumnRemoved(column, passFocus) {
        const isLastColumn = this.columns.length() === 1;
        const rightColumn = this.getRightColumn(column);
        const columnToFocus = isLastColumn ? null : this.getLeftColumn(column) ?? rightColumn;
        if (column === this.lastFocusedColumn) {
            this.lastFocusedColumn = columnToFocus;
        }
        this.columns.remove(column);
        this.columnsSetX(rightColumn);
        this.desktop.onLayoutChanged();
        if (columnToFocus !== null) {
            switch (passFocus) {
                case 1 /* FocusPassing.Type.Immediate */:
                    columnToFocus.getWindowToFocus().focus();
                    return;
                case 2 /* FocusPassing.Type.OnUnfocus */:
                    this.focusPasser.request(columnToFocus.getWindowToFocus().client.kwinClient);
                    return;
            }
        }
        this.desktop.autoAdjustScroll();
    }
    onColumnWidthChanged(column) {
        const rightColumn = this.columns.getNext(column);
        this.columnsSetX(rightColumn);
        this.desktop.onLayoutChanged();
        if (!this.userResize) {
            this.desktop.autoAdjustScroll();
        }
    }
    onColumnFocused(column, window) {
        const lastFocusedColumn = this.getLastFocusedColumn();
        if (lastFocusedColumn !== null) {
            lastFocusedColumn.restoreToTiled(window);
        }
        this.lastFocusedColumn = column;
        this.desktop.scrollToColumn(column, false);
    }
    onScreenSizeChanged() {
        for (const column of this.columns.iterator()) {
            column.updateWidth();
            column.resizeWindows();
        }
    }
    onUserResizeStarted() {
        this.userResize = true;
    }
    onUserResizeFinished() {
        this.userResize = false;
        this.userResizeFinishedDelayer.run();
    }
    evacuateTail(targetGrid, startColumn) {
        for (const column of this.columns.iteratorFrom(startColumn)) {
            column.moveToGrid(targetGrid, targetGrid.getLastColumn());
        }
    }
    evacuate(targetGrid) {
        for (const column of this.columns.iterator()) {
            column.moveToGrid(targetGrid, targetGrid.getLastColumn());
        }
    }
    destroy() {
        this.userResizeFinishedDelayer.destroy();
    }
}
var Range;
(function (Range) {
    function create(x, width) {
        return new Basic(x, width);
    }
    Range.create = create;
    function fromRanges(leftRange, rightRange) {
        const left = leftRange.getLeft();
        const right = rightRange.getRight();
        return new Basic(left, right - left);
    }
    Range.fromRanges = fromRanges;
    function contains(parent, child) {
        return child.getLeft() >= parent.getLeft() &&
            child.getRight() <= parent.getRight();
    }
    Range.contains = contains;
    function minus(a, b) {
        const aCenter = a.getLeft() + a.getWidth() / 2;
        const bCenter = b.getLeft() + b.getWidth() / 2;
        return Math.round(aCenter - bCenter);
    }
    Range.minus = minus;
    class Basic {
        constructor(x, width) {
            this.x = x;
            this.width = width;
        }
        getLeft() {
            return this.x;
        }
        getRight() {
            return this.x + this.width;
        }
        getWidth() {
            return this.width;
        }
    }
})(Range || (Range = {}));
class Window {
    constructor(client, column) {
        this.client = client;
        this.height = client.kwinClient.frameGeometry.height;
        let maximizedMode = this.client.getMaximizedMode();
        if (maximizedMode === undefined) {
            maximizedMode = 0 /* MaximizedMode.Unmaximized */; // defaulting to unmaximized, as this is set in Tiled.prepareClientForTiling
        }
        this.focusedState = {
            fullScreen: this.client.kwinClient.fullScreen,
            maximizedMode: maximizedMode,
        };
        this.skipArrange = this.client.kwinClient.fullScreen || maximizedMode !== 0 /* MaximizedMode.Unmaximized */;
        this.column = column;
        column.onWindowAdded(this, true);
    }
    moveToColumn(targetColumn, bottom, passFocus) {
        if (targetColumn === this.column) {
            return;
        }
        this.column.onWindowRemoved(this, passFocus);
        this.column = targetColumn;
        targetColumn.onWindowAdded(this, bottom);
    }
    arrange(x, y, width, height) {
        if (this.skipArrange) {
            // window is maximized, fullscreen, or being manually resized, prevent fighting with the user
            return;
        }
        let maximized = false;
        if (this.column.grid.config.reMaximize && this.isFocused()) {
            // do this here rather than in `onFocused` to ensure it happens after placement
            // (otherwise placement may not happen at all)
            if (this.focusedState.maximizedMode !== 0 /* MaximizedMode.Unmaximized */) {
                this.client.setMaximize(this.focusedState.maximizedMode === 2 /* MaximizedMode.Horizontally */ || this.focusedState.maximizedMode === 3 /* MaximizedMode.Maximized */, this.focusedState.maximizedMode === 1 /* MaximizedMode.Vertically */ || this.focusedState.maximizedMode === 3 /* MaximizedMode.Maximized */);
                maximized = true;
            }
            if (this.focusedState.fullScreen) {
                this.client.setFullScreen(true);
                maximized = true;
            }
        }
        if (!maximized) {
            this.client.place(x, y, width, height);
        }
    }
    focus() {
        this.client.focus();
        const kwinClient = this.client.kwinClient;
        if (!this.isFocused()) {
            // in some situations focus assignment just doesn't work, let's do it later
            this.column.grid.focusPasser.request(kwinClient);
        }
    }
    isFocused() {
        return this.client.isFocused();
    }
    onFocused() {
        if (this.column.grid.config.reMaximize && (this.focusedState.maximizedMode !== 0 /* MaximizedMode.Unmaximized */ ||
            this.focusedState.fullScreen)) {
            // We need to maximize/fullscreen this window, but we can't do it here.
            // We need to do it in `arrange` to ensure it happens after placement.
            this.column.grid.desktop.forceArrange();
        }
        this.column.onWindowFocused(this);
    }
    restoreToTiled() {
        if (this.isFocused()) {
            return;
        }
        this.client.setFullScreen(false);
        this.client.setMaximize(false, false);
    }
    onMaximizedChanged(maximizedMode) {
        const maximized = maximizedMode !== 0 /* MaximizedMode.Unmaximized */;
        this.skipArrange = maximized;
        if (this.column.grid.config.tiledKeepBelow) {
            this.client.kwinClient.keepBelow = !maximized;
        }
        if (this.column.grid.config.maximizedKeepAbove) {
            this.client.kwinClient.keepAbove = maximized;
        }
        if (this.isFocused()) {
            this.focusedState.maximizedMode = maximizedMode;
        }
        this.column.grid.desktop.onLayoutChanged();
    }
    onFullScreenChanged(fullScreen) {
        this.skipArrange = fullScreen;
        if (this.column.grid.config.tiledKeepBelow) {
            this.client.kwinClient.keepBelow = !fullScreen;
        }
        if (this.column.grid.config.maximizedKeepAbove) {
            this.client.kwinClient.keepAbove = fullScreen;
        }
        if (this.isFocused()) {
            this.focusedState.fullScreen = fullScreen;
        }
        this.column.grid.desktop.onLayoutChanged();
    }
    onFrameGeometryChanged() {
        const newGeometry = this.client.kwinClient.frameGeometry;
        this.column.setWidth(newGeometry.width, true);
        this.column.grid.desktop.onLayoutChanged();
    }
    destroy(passFocus) {
        this.column.onWindowRemoved(this, passFocus);
    }
}
class ClientMatcher {
    constructor(regex) {
        this.regex = regex;
    }
    matches(kwinClient) {
        return this.regex.test(ClientMatcher.getClientString(kwinClient));
    }
    static getClientString(kwinClient) {
        return ClientMatcher.getRuleString(kwinClient.resourceClass, kwinClient.caption);
    }
    static getRuleString(ruleClass, ruleCaption) {
        return ruleClass + "\0" + ruleCaption;
    }
}
class DesktopFilter {
    constructor(desktopsConfig) {
        this.desktopRegex = DesktopFilter.parseDesktopConfig(desktopsConfig);
    }
    shouldWorkOnDesktop(kwinDesktop) {
        if (this.desktopRegex === null) {
            return true; // Work on all desktops
        }
        return this.desktopRegex.test(kwinDesktop.name);
    }
    static parseDesktopConfig(config) {
        const trimmed = config.trim();
        if (trimmed.length === 0) {
            return null; // Empty config means work on all desktops
        }
        try {
            return new RegExp(`^${trimmed}$`);
        }
        catch (e) {
            notificationInvalidTiledDesktops.sendEvent();
            log(`Invalid regex pattern in tiledDesktops config: ${trimmed}. Working on all desktops.`);
            return null; // Invalid regex means work on all desktops as fallback
        }
    }
}
class WindowRuleEnforcer {
    constructor(windowRules) {
        const [floatRegex, tileRegex, followCaptionRegex] = WindowRuleEnforcer.createWindowRuleRegexes(windowRules);
        this.preferFloating = new ClientMatcher(floatRegex);
        this.preferTiling = new ClientMatcher(tileRegex);
        this.followCaption = followCaptionRegex;
    }
    shouldTile(kwinClient) {
        return this.preferTiling.matches(kwinClient) || (kwinClient.normalWindow &&
            !kwinClient.transient &&
            kwinClient.managed &&
            kwinClient.pid > -1 &&
            !kwinClient.fullScreen &&
            !Clients.isFullScreenGeometry(kwinClient) &&
            !this.preferFloating.matches(kwinClient));
    }
    initClientSignalManager(world, kwinClient) {
        if (!this.followCaption.test(kwinClient.resourceClass)) {
            return null;
        }
        const enforcer = this;
        const manager = new SignalManager();
        manager.connect(kwinClient.captionChanged, () => {
            const shouldTile = Clients.canTileNow(kwinClient) && enforcer.shouldTile(kwinClient);
            world.do((clientManager, desktopManager) => {
                const desktop = desktopManager.getDesktopForClient(kwinClient);
                if (shouldTile && desktop !== undefined) {
                    clientManager.tileKwinClient(kwinClient, desktop.grid);
                }
                else {
                    clientManager.floatKwinClient(kwinClient);
                }
            });
        });
        return manager;
    }
    static createWindowRuleRegexes(windowRules) {
        const floatRegexes = [];
        const tileRegexes = [];
        const followCaptionRegexes = [];
        for (const windowRule of windowRules) {
            const ruleClass = WindowRuleEnforcer.parseRegex(windowRule.class);
            const ruleCaption = WindowRuleEnforcer.parseRegex(windowRule.caption);
            const ruleString = ClientMatcher.getRuleString(WindowRuleEnforcer.wrapParens(ruleClass), WindowRuleEnforcer.wrapParens(ruleCaption));
            (windowRule.tile ? tileRegexes : floatRegexes).push(ruleString);
            if (ruleCaption !== ".*") {
                followCaptionRegexes.push(ruleClass);
            }
        }
        return [
            WindowRuleEnforcer.joinRegexes(floatRegexes),
            WindowRuleEnforcer.joinRegexes(tileRegexes),
            WindowRuleEnforcer.joinRegexes(followCaptionRegexes),
        ];
    }
    static parseRegex(rawRule) {
        if (rawRule === undefined || rawRule === "" || rawRule === ".*") {
            return ".*";
        }
        else {
            return rawRule;
        }
    }
    static joinRegexes(regexes) {
        if (regexes.length === 0) {
            return new RegExp("a^"); // match nothing
        }
        if (regexes.length === 1) {
            return new RegExp("^(" + regexes[0] + ")$");
        }
        const joinedRegexes = regexes.map(WindowRuleEnforcer.wrapParens).join("|");
        return new RegExp("^(" + joinedRegexes + ")$");
    }
    static wrapParens(str) {
        return "(" + str + ")";
    }
}
class Delayer {
    constructor(delay, f) {
        this.timer = initQmlTimer();
        this.timer.interval = delay;
        this.timer.triggered.connect(f);
    }
    run() {
        this.timer.restart();
    }
    destroy() {
        this.timer.destroy();
    }
}
function initQmlTimer() {
    return Qt.createQmlObject(`import QtQuick 6.0
        Timer {}`, qmlBase);
}
class Doer {
    constructor() {
        this.nCalls = 0;
    }
    do(f) {
        this.nCalls++;
        f();
        this.nCalls--;
    }
    isDoing() {
        return this.nCalls > 0;
    }
}
class LinkedList {
    constructor() {
        this.firstNode = null;
        this.lastNode = null;
        this.itemMap = new Map();
    }
    getNode(item) {
        const node = this.itemMap.get(item);
        if (node === undefined) {
            throw new Error("item not in list");
        }
        return node;
    }
    insertBefore(item, nextItem) {
        const nextNode = this.getNode(nextItem);
        this.insert(item, nextNode.prev, nextNode);
    }
    insertAfter(item, prevItem) {
        const prevNode = this.getNode(prevItem);
        this.insert(item, prevNode, prevNode.next);
    }
    insertStart(item) {
        this.insert(item, null, this.firstNode);
    }
    insertEnd(item) {
        this.insert(item, this.lastNode, null);
    }
    insert(item, prevNode, nextNode) {
        const node = new LinkedList.Node(item);
        this.itemMap.set(item, node);
        this.insertNode(node, prevNode, nextNode);
    }
    insertNode(node, prevNode, nextNode) {
        node.prev = prevNode;
        node.next = nextNode;
        if (nextNode !== null) {
            console.assert(nextNode.prev === prevNode);
            nextNode.prev = node;
        }
        if (prevNode !== null) {
            console.assert(prevNode.next === nextNode);
            prevNode.next = node;
        }
        if (this.firstNode === nextNode) {
            this.firstNode = node;
        }
        if (this.lastNode === prevNode) {
            this.lastNode = node;
        }
    }
    getPrev(item) {
        const prevNode = this.getNode(item).prev;
        return prevNode === null ? null : prevNode.item;
    }
    getNext(item) {
        const nextNode = this.getNode(item).next;
        return nextNode === null ? null : nextNode.item;
    }
    getFirst() {
        if (this.firstNode === null) {
            return null;
        }
        return this.firstNode.item;
    }
    getLast() {
        if (this.lastNode === null) {
            return null;
        }
        return this.lastNode.item;
    }
    getItemAtIndex(index) {
        let node = this.firstNode;
        if (node === null) {
            return null;
        }
        for (let i = 0; i < index; i++) {
            node = node.next;
            if (node === null) {
                return null;
            }
        }
        return node.item;
    }
    remove(item) {
        const node = this.getNode(item);
        this.itemMap.delete(item);
        this.removeNode(node);
    }
    removeNode(node) {
        const prevNode = node.prev;
        const nextNode = node.next;
        if (prevNode !== null) {
            prevNode.next = nextNode;
        }
        if (nextNode !== null) {
            nextNode.prev = prevNode;
        }
        if (this.firstNode === node) {
            this.firstNode = nextNode;
        }
        if (this.lastNode === node) {
            this.lastNode = prevNode;
        }
    }
    contains(item) {
        return this.itemMap.has(item);
    }
    swap(node0, node1) {
        console.assert(node0.next === node1 && node1.prev === node0);
        const prevNode = node0.prev;
        const nextNode = node1.next;
        if (prevNode !== null) {
            prevNode.next = node1;
        }
        node1.next = node0;
        node0.next = nextNode;
        if (nextNode !== null) {
            nextNode.prev = node0;
        }
        node0.prev = node1;
        node1.prev = prevNode;
        if (this.firstNode === node0) {
            this.firstNode = node1;
        }
        if (this.lastNode === node1) {
            this.lastNode = node0;
        }
    }
    move(item, prevItem) {
        const node = this.getNode(item);
        this.removeNode(node);
        if (prevItem === null) {
            this.insertNode(node, null, this.firstNode);
        }
        else {
            const prevNode = this.getNode(prevItem);
            this.insertNode(node, prevNode, prevNode.next);
        }
    }
    moveBack(item) {
        const node = this.getNode(item);
        if (node.prev !== null) {
            console.assert(node !== this.firstNode);
            this.swap(node.prev, node);
        }
    }
    moveForward(item) {
        const node = this.getNode(item);
        if (node.next !== null) {
            console.assert(node !== this.lastNode);
            this.swap(node, node.next);
        }
    }
    length() {
        return this.itemMap.size;
    }
    *iterator() {
        for (let node = this.firstNode; node !== null; node = node.next) {
            yield node.item;
        }
    }
    *iteratorFrom(startItem) {
        for (let node = this.getNode(startItem); node !== null; node = node.next) {
            yield node.item;
        }
    }
}
(function (LinkedList) {
    // TODO (optimization): reuse nodes
    class Node {
        constructor(item) {
            this.item = item;
            this.prev = null;
            this.next = null;
        }
    }
    LinkedList.Node = Node;
})(LinkedList || (LinkedList = {}));
class RateLimiter {
    constructor(n, intervalMs) {
        this.n = n;
        this.intervalMs = intervalMs;
        this.i = 0;
        this.intervalStart = 0;
    }
    acquire() {
        const now = Date.now();
        if (now - this.intervalStart >= this.intervalMs) {
            this.i = 0;
            this.intervalStart = now;
        }
        if (this.i < this.n) {
            this.i++;
            return true;
        }
        else {
            return false;
        }
    }
}
class ShortcutAction {
    constructor(keyBinding, f) {
        this.shortcutHandler = ShortcutAction.initShortcutHandler(keyBinding);
        this.shortcutHandler.activated.connect(f);
    }
    destroy() {
        this.shortcutHandler.destroy();
    }
    static initShortcutHandler(keyBinding) {
        const sequenceLine = keyBinding.defaultKeySequence !== undefined ?
            `    sequence: "${keyBinding.defaultKeySequence}";
` :
            "";
        return Qt.createQmlObject(`import QtQuick 6.0
import org.kde.kwin 3.0
ShortcutHandler {
    name: "karousel-${keyBinding.name}";
    text: "Karousel: ${keyBinding.description}";
${sequenceLine}}`, qmlBase);
    }
}
class SignalManager {
    constructor() {
        this.connections = [];
    }
    connect(signal, handler) {
        signal.connect(handler);
        this.connections.push({ signal: signal, handler: handler });
    }
    destroy() {
        for (const connection of this.connections) {
            connection.signal.disconnect(connection.handler);
        }
        this.connections = [];
    }
}
function union(array0, array1) {
    const set = new Set([...array0, ...array1]);
    return [...set];
}
function uniq(sortedArray) {
    const filtered = [];
    let lastItem;
    for (const item of sortedArray) {
        if (item !== lastItem) {
            filtered.push(item);
            lastItem = item;
        }
    }
    return filtered;
}
function mapGetOrInit(map, key, defaultItem) {
    const item = map.get(key);
    if (item !== undefined) {
        return item;
    }
    else {
        map.set(key, defaultItem);
        return defaultItem;
    }
}
function findMinPositive(items, evaluate) {
    let bestScore = Infinity;
    let bestItem = undefined;
    for (const item of items) {
        const score = evaluate(item);
        if (score > 0 && score < bestScore) {
            bestScore = score;
            bestItem = item;
        }
    }
    return bestItem;
}
function fillSpace(availableSpace, items) {
    if (items.length === 0) {
        return [];
    }
    const middleSize = findMiddleSize(availableSpace, items);
    const sizes = items.map(item => clamp(middleSize, item.min, item.max));
    if (middleSize !== Math.floor(availableSpace / items.length)) {
        distributeRemainder(availableSpace, middleSize, sizes, items);
    }
    return sizes;
    function findMiddleSize(availableSpace, items) {
        const ranges = buildRanges(items);
        let requiredSpace = items.reduce((acc, item) => acc + item.min, 0);
        for (const range of ranges) {
            const rangeSize = range.end - range.start;
            const maxRequiredSpaceDelta = rangeSize * range.n;
            if (requiredSpace + maxRequiredSpaceDelta >= availableSpace) {
                const positionInRange = (availableSpace - requiredSpace) / maxRequiredSpaceDelta;
                return Math.floor(range.start + rangeSize * positionInRange);
            }
            requiredSpace += maxRequiredSpaceDelta;
        }
        return ranges[ranges.length - 1].end;
    }
    function buildRanges(items) {
        const fenceposts = extractFenceposts(items);
        if (fenceposts.length === 1) {
            return [{
                    start: fenceposts[0].value,
                    end: fenceposts[0].value,
                    n: items.length,
                }];
        }
        const ranges = [];
        let n = 0;
        for (let i = 1; i < fenceposts.length; i++) {
            const startFencepost = fenceposts[i - 1];
            const endFencepost = fenceposts[i];
            n = n - startFencepost.nMax + startFencepost.nMin;
            ranges.push({
                start: startFencepost.value,
                end: endFencepost.value,
                n: n,
            });
        }
        return ranges;
    }
    function extractFenceposts(items) {
        const fenceposts = new Map();
        for (const item of items) {
            mapGetOrInit(fenceposts, item.min, { value: item.min, nMin: 0, nMax: 0 }).nMin++;
            mapGetOrInit(fenceposts, item.max, { value: item.max, nMin: 0, nMax: 0 }).nMax++;
        }
        const array = Array.from(fenceposts.values());
        array.sort((a, b) => a.value - b.value);
        return array;
    }
    function distributeRemainder(availableSpace, middleSize, sizes, constraints) {
        const indexes = Array.from(sizes.keys())
            .filter(i => sizes[i] === middleSize);
        indexes.sort((a, b) => constraints[a].max - constraints[b].max);
        const requiredSpace = sum(...sizes);
        let remainder = availableSpace - requiredSpace;
        let n = indexes.length;
        for (const i of indexes) {
            if (remainder <= 0) {
                break;
            }
            const enlargable = constraints[i].max - sizes[i];
            if (enlargable > 0) {
                const enlarge = Math.min(enlargable, Math.ceil(remainder / n));
                sizes[i] += enlarge;
                remainder -= enlarge;
            }
            n--;
        }
    }
}
Function.prototype.partial = function (...head) {
    return (...tail) => this(...head, ...tail);
};
function log(...args) {
    console.log("Karousel:", ...args);
}
function clamp(value, min, max) {
    if (value < min) {
        return min;
    }
    if (value > max) {
        return max;
    }
    return value;
}
function sum(...list) {
    return list.reduce((acc, val) => acc + val);
}
function rectEquals(a, b) {
    return a.x === b.x &&
        a.y === b.y &&
        a.width === b.width &&
        a.height === b.height;
}
function pointEquals(a, b) {
    return a.x === b.x &&
        a.y === b.y;
}
function rectContainsPoint(rect, point) {
    return rect.left <= point.x &&
        rect.right >= point.x &&
        rect.top <= point.y &&
        rect.bottom >= point.y;
}
function applyMacro(base, value) {
    return base.replace("{}", String(value));
}
class ClientManager {
    constructor(config, world, desktopManager, pinManager) {
        this.world = world;
        this.desktopManager = desktopManager;
        this.pinManager = pinManager;
        this.world = world;
        this.config = config;
        this.desktopManager = desktopManager;
        this.pinManager = pinManager;
        this.clientMap = new Map();
        this.lastFocusedClient = null;
        let parsedWindowRules = [];
        try {
            parsedWindowRules = JSON.parse(config.windowRules);
        }
        catch (error) {
            notificationInvalidWindowRules.sendEvent();
            log("failed to parse windowRules:", error);
        }
        this.windowRuleEnforcer = new WindowRuleEnforcer(parsedWindowRules);
    }
    addClient(kwinClient) {
        console.assert(!this.hasClient(kwinClient));
        let constructState;
        let desktop;
        if (kwinClient.dock) {
            constructState = () => new ClientState.Docked(this.world, kwinClient);
        }
        else if (Clients.canTileEver(kwinClient) &&
            this.windowRuleEnforcer.shouldTile(kwinClient) &&
            (desktop = this.desktopManager.getDesktopForClient(kwinClient)) !== undefined) {
            Clients.makeTileable(kwinClient);
            console.assert(Clients.canTileNow(kwinClient));
            constructState = (client) => new ClientState.Tiled(this.world, client, desktop.grid);
        }
        else {
            constructState = (client) => new ClientState.Floating(this.world, client, this.config, false);
        }
        const client = new ClientWrapper(kwinClient, constructState, this.findTransientFor(kwinClient), this.windowRuleEnforcer.initClientSignalManager(this.world, kwinClient));
        this.clientMap.set(kwinClient, client);
    }
    removeClient(kwinClient, passFocus) {
        console.assert(this.hasClient(kwinClient));
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        if (kwinClient !== this.lastFocusedClient) {
            passFocus = 0 /* FocusPassing.Type.None */;
        }
        client.destroy(passFocus);
        this.clientMap.delete(kwinClient);
    }
    findTransientFor(kwinClient) {
        if (!kwinClient.transient || kwinClient.transientFor === null) {
            return null;
        }
        const transientFor = this.clientMap.get(kwinClient.transientFor);
        if (transientFor === undefined) {
            return null;
        }
        return transientFor;
    }
    minimizeClient(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        if (client.stateManager.getState() instanceof ClientState.Tiled) {
            const passFocus = kwinClient === this.lastFocusedClient ? 1 /* FocusPassing.Type.Immediate */ : 0 /* FocusPassing.Type.None */;
            client.stateManager.setState(() => new ClientState.TiledMinimized(this.world, client), passFocus);
        }
    }
    tileClient(client, grid) {
        if (client.stateManager.getState() instanceof ClientState.Tiled) {
            return;
        }
        client.stateManager.setState(() => new ClientState.Tiled(this.world, client, grid), 0 /* FocusPassing.Type.None */);
    }
    floatClient(client) {
        if (client.stateManager.getState() instanceof ClientState.Floating) {
            return;
        }
        client.stateManager.setState(() => new ClientState.Floating(this.world, client, this.config, true), 0 /* FocusPassing.Type.None */);
    }
    tileKwinClient(kwinClient, grid) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        this.tileClient(client, grid);
    }
    floatKwinClient(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        this.floatClient(client);
    }
    pinClient(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        if (client.getMaximizedMode() !== 0 /* MaximizedMode.Unmaximized */) {
            // the client is not really kwin-tiled, just maximized
            kwinClient.tile = null;
            return;
        }
        client.stateManager.setState(() => new ClientState.Pinned(this.world, this.pinManager, this.desktopManager, kwinClient, this.config), 0 /* FocusPassing.Type.None */);
        this.pinManager.addClient(kwinClient);
        for (const desktop of this.desktopManager.getDesktopsForClient(kwinClient)) {
            desktop.onPinsChanged();
        }
    }
    unpinClient(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        console.assert(client.stateManager.getState() instanceof ClientState.Pinned);
        client.stateManager.setState(() => new ClientState.Floating(this.world, client, this.config, false), 0 /* FocusPassing.Type.None */);
        this.pinManager.removeClient(kwinClient);
        for (const desktop of this.desktopManager.getDesktopsForClient(kwinClient)) {
            desktop.onPinsChanged();
        }
    }
    toggleFloatingClient(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return;
        }
        const clientState = client.stateManager.getState();
        if ((clientState instanceof ClientState.Floating || clientState instanceof ClientState.Pinned) && Clients.canTileEver(kwinClient)) {
            Clients.makeTileable(kwinClient);
            const desktop = this.desktopManager.getDesktopForClient(kwinClient);
            if (desktop === undefined) {
                return;
            }
            client.stateManager.setState(() => new ClientState.Tiled(this.world, client, desktop.grid), 0 /* FocusPassing.Type.None */);
        }
        else if (clientState instanceof ClientState.Tiled) {
            client.stateManager.setState(() => new ClientState.Floating(this.world, client, this.config, true), 0 /* FocusPassing.Type.None */);
        }
    }
    hasClient(kwinClient) {
        return this.clientMap.has(kwinClient);
    }
    onClientFocused(kwinClient) {
        this.lastFocusedClient = kwinClient;
        const window = this.findTiledWindow(kwinClient);
        if (window !== null) {
            window.onFocused();
        }
    }
    findTiledWindow(kwinClient) {
        const client = this.clientMap.get(kwinClient);
        if (client === undefined) {
            return null;
        }
        return this.findTiledWindowOfClient(client);
    }
    findTiledWindowOfClient(client) {
        const clientState = client.stateManager.getState();
        if (clientState instanceof ClientState.Tiled) {
            return clientState.window;
        }
        else if (client.transientFor !== null) {
            return this.findTiledWindowOfClient(client.transientFor);
        }
        else {
            return null;
        }
    }
    removeAllClients() {
        for (const kwinClient of Array.from(this.clientMap.keys())) {
            this.removeClient(kwinClient, 0 /* FocusPassing.Type.None */);
        }
    }
    destroy() {
        this.removeAllClients();
    }
}
class ClientWrapper {
    constructor(kwinClient, constructInitialState, transientFor, rulesSignalManager) {
        this.kwinClient = kwinClient;
        this.transientFor = transientFor;
        this.rulesSignalManager = rulesSignalManager;
        this.kwinClient = kwinClient;
        this.transientFor = transientFor;
        this.transients = [];
        if (transientFor !== null) {
            transientFor.addTransient(this);
        }
        this.signalManager = ClientWrapper.initSignalManager(this);
        this.rulesSignalManager = rulesSignalManager;
        this.preferredWidth = kwinClient.frameGeometry.width;
        this.manipulatingGeometry = new Doer();
        this.lastPlacement = null;
        this.stateManager = new ClientState.Manager(constructInitialState(this));
    }
    place(x, y, width, height) {
        this.manipulatingGeometry.do(() => {
            if (this.kwinClient.resize) {
                // window is being manually resized, prevent fighting with the user
                return;
            }
            this.lastPlacement = Qt.rect(x, y, width, height);
            this.kwinClient.frameGeometry = this.lastPlacement;
            if (this.kwinClient.frameGeometry !== this.lastPlacement) {
                // frameGeometry assignment failed. This sometimes happens on Wayland
                // when a window is off-screen, effectively making it stuck there.
                this.kwinClient.frameGeometry.x = x; // This makes it unstuck.
                this.kwinClient.frameGeometry = this.lastPlacement;
            }
        });
    }
    moveTransient(dx, dy, kwinDesktops) {
        if (this.stateManager.getState() instanceof ClientState.Floating) {
            if (Clients.isOnOneOfVirtualDesktops(this.kwinClient, kwinDesktops)) {
                const frame = this.kwinClient.frameGeometry;
                this.kwinClient.frameGeometry = Qt.rect(frame.x + dx, frame.y + dy, frame.width, frame.height);
            }
            for (const transient of this.transients) {
                transient.moveTransient(dx, dy, kwinDesktops);
            }
        }
    }
    moveTransients(dx, dy) {
        for (const transient of this.transients) {
            transient.moveTransient(dx, dy, this.kwinClient.desktops);
        }
    }
    focus() {
        Workspace.activeWindow = this.kwinClient;
    }
    isFocused() {
        return Workspace.activeWindow === this.kwinClient;
    }
    setMaximize(horizontally, vertically) {
        if (!this.kwinClient.maximizable) {
            this.maximizedMode = 0 /* MaximizedMode.Unmaximized */;
            return;
        }
        if (this.maximizedMode === undefined) {
            if (horizontally && vertically) {
                this.maximizedMode = 3 /* MaximizedMode.Maximized */;
            }
            else if (horizontally) {
                this.maximizedMode = 2 /* MaximizedMode.Horizontally */;
            }
            else if (vertically) {
                this.maximizedMode = 1 /* MaximizedMode.Vertically */;
            }
            else {
                this.maximizedMode = 0 /* MaximizedMode.Unmaximized */;
            }
        }
        this.manipulatingGeometry.do(() => {
            this.kwinClient.setMaximize(vertically, horizontally);
        });
    }
    setFullScreen(fullScreen) {
        if (!this.kwinClient.fullScreenable) {
            return;
        }
        this.manipulatingGeometry.do(() => {
            this.kwinClient.fullScreen = fullScreen;
        });
    }
    getMaximizedMode() {
        return this.maximizedMode;
    }
    isManipulatingGeometry(newGeometry) {
        if (newGeometry !== null && newGeometry === this.lastPlacement) {
            return true;
        }
        return this.manipulatingGeometry.isDoing();
    }
    addTransient(transient) {
        this.transients.push(transient);
    }
    removeTransient(transient) {
        const i = this.transients.indexOf(transient);
        this.transients.splice(i, 1);
    }
    ensureTransientsVisible(screenSize) {
        for (const transient of this.transients) {
            if (transient.stateManager.getState() instanceof ClientState.Floating) {
                transient.ensureVisible(screenSize);
                transient.ensureTransientsVisible(screenSize);
            }
        }
    }
    ensureVisible(screenSize) {
        if (!Clients.isOnVirtualDesktop(this.kwinClient, Workspace.currentDesktop)) {
            return;
        }
        const frame = this.kwinClient.frameGeometry;
        if (frame.left < screenSize.left) {
            frame.x = screenSize.left;
        }
        else if (frame.right > screenSize.right) {
            frame.x = screenSize.right - frame.width;
        }
    }
    destroy(passFocus) {
        this.stateManager.destroy(passFocus);
        this.signalManager.destroy();
        if (this.rulesSignalManager !== null) {
            this.rulesSignalManager.destroy();
        }
        if (this.transientFor !== null) {
            this.transientFor.removeTransient(this);
        }
        for (const transient of this.transients) {
            transient.transientFor = null;
        }
    }
    static initSignalManager(client) {
        const manager = new SignalManager();
        manager.connect(client.kwinClient.maximizedAboutToChange, (maximizedMode) => {
            if (maximizedMode !== 0 /* MaximizedMode.Unmaximized */ && client.kwinClient.tile !== null) {
                client.kwinClient.tile = null;
            }
            client.maximizedMode = maximizedMode;
        });
        return manager;
    }
}
var Clients;
(function (Clients) {
    const prohibitedClasses = [
        "ksmserver-logout-greeter",
        "xwaylandvideobridge",
    ];
    function canTileEver(kwinClient) {
        const shapeable = (kwinClient.moveable && kwinClient.resizeable) || kwinClient.fullScreen; // full-screen windows may become shapeable after exiting full-screen mode
        return shapeable &&
            !kwinClient.popupWindow &&
            !prohibitedClasses.includes(kwinClient.resourceClass);
    }
    Clients.canTileEver = canTileEver;
    function canTileNow(kwinClient) {
        return canTileEver(kwinClient) &&
            !kwinClient.minimized &&
            kwinClient.desktops.length === 1 &&
            kwinClient.activities.length === 1;
    }
    Clients.canTileNow = canTileNow;
    function makeTileable(kwinClient) {
        if (kwinClient.minimized) {
            kwinClient.minimized = false;
        }
        if (kwinClient.desktops.length !== 1) {
            kwinClient.desktops = [Workspace.currentDesktop];
        }
        if (kwinClient.activities.length !== 1) {
            kwinClient.activities = [Workspace.currentActivity];
        }
    }
    Clients.makeTileable = makeTileable;
    function getKwinDesktopApprox(kwinClient) {
        switch (kwinClient.desktops.length) {
            case 0:
                return Workspace.currentDesktop;
            case 1:
                return kwinClient.desktops[0];
            default:
                if (kwinClient.desktops.includes(Workspace.currentDesktop)) {
                    return Workspace.currentDesktop;
                }
                else {
                    return kwinClient.desktops[0];
                }
        }
    }
    Clients.getKwinDesktopApprox = getKwinDesktopApprox;
    function isFullScreenGeometry(kwinClient) {
        const fullScreenArea = Workspace.clientArea(4 /* ClientAreaOption.FullScreenArea */, kwinClient.output, getKwinDesktopApprox(kwinClient));
        return kwinClient.clientGeometry.width >= fullScreenArea.width &&
            kwinClient.clientGeometry.height >= fullScreenArea.height;
    }
    Clients.isFullScreenGeometry = isFullScreenGeometry;
    function isOnVirtualDesktop(kwinClient, kwinDesktop) {
        return kwinClient.desktops.length === 0 || kwinClient.desktops.includes(kwinDesktop);
    }
    Clients.isOnVirtualDesktop = isOnVirtualDesktop;
    function isOnOneOfVirtualDesktops(kwinClient, kwinDesktops) {
        return kwinClient.desktops.length === 0 || kwinClient.desktops.some(d => kwinDesktops.includes(d));
    }
    Clients.isOnOneOfVirtualDesktops = isOnOneOfVirtualDesktops;
})(Clients || (Clients = {}));
class DesktopManager {
    constructor(pinManager, config, layoutConfig, focusPasser, desktopFilter) {
        this.pinManager = pinManager;
        this.config = config;
        this.layoutConfig = layoutConfig;
        this.focusPasser = focusPasser;
        this.desktopFilter = desktopFilter;
        this.pinManager = pinManager;
        this.config = config;
        this.layoutConfig = layoutConfig;
        this.desktops = new Map();
        this.selectedScreen = Workspace.activeScreen;
        this.kwinActivities = new Set(Workspace.activities);
        this.kwinDesktops = new Set(Workspace.desktops);
    }
    getDesktop(activity, kwinDesktop) {
        if (!this.desktopFilter.shouldWorkOnDesktop(kwinDesktop)) {
            return undefined;
        }
        const desktopKey = DesktopManager.getDesktopKey(activity, kwinDesktop);
        const desktop = this.desktops.get(desktopKey);
        if (desktop !== undefined) {
            return desktop;
        }
        else {
            return this.addDesktop(activity, kwinDesktop);
        }
    }
    getCurrentDesktop() {
        return this.getDesktop(Workspace.currentActivity, Workspace.currentDesktop);
    }
    getDesktopInCurrentActivity(kwinDesktop) {
        return this.getDesktop(Workspace.currentActivity, kwinDesktop);
    }
    getDesktopForClient(kwinClient) {
        if (kwinClient.activities.length !== 1 || kwinClient.desktops.length !== 1) {
            return undefined;
        }
        return this.getDesktop(kwinClient.activities[0], kwinClient.desktops[0]);
    }
    addDesktop(activity, kwinDesktop) {
        const desktopKey = DesktopManager.getDesktopKey(activity, kwinDesktop);
        const desktop = new Desktop(kwinDesktop, this.pinManager, this.config, () => this.selectedScreen, this.layoutConfig, this.focusPasser);
        this.desktops.set(desktopKey, desktop);
        return desktop;
    }
    static getDesktopKey(activity, kwinDesktop) {
        return activity + "|" + kwinDesktop.id;
    }
    updateActivities() {
        const newActivities = new Set(Workspace.activities);
        for (const activity of this.kwinActivities) {
            if (!newActivities.has(activity)) {
                this.removeActivity(activity);
            }
        }
        this.kwinActivities = newActivities;
    }
    updateDesktops() {
        const newDesktops = new Set(Workspace.desktops);
        for (const desktop of this.kwinDesktops) {
            if (!newDesktops.has(desktop)) {
                this.removeKwinDesktop(desktop);
            }
        }
        this.kwinDesktops = newDesktops;
    }
    selectScreen(screen) {
        this.selectedScreen = screen;
    }
    removeActivity(activity) {
        for (const kwinDesktop of this.kwinDesktops) {
            this.destroyDesktop(activity, kwinDesktop);
        }
    }
    removeKwinDesktop(kwinDesktop) {
        for (const activity of this.kwinActivities) {
            this.destroyDesktop(activity, kwinDesktop);
        }
    }
    destroyDesktop(activity, kwinDesktop) {
        const desktopKey = DesktopManager.getDesktopKey(activity, kwinDesktop);
        const desktop = this.desktops.get(desktopKey);
        if (desktop !== undefined) {
            desktop.destroy();
            this.desktops.delete(desktopKey);
        }
    }
    destroy() {
        for (const desktop of this.desktops.values()) {
            desktop.destroy();
        }
    }
    *getAllDesktops() {
        for (const desktop of this.desktops.values()) {
            yield desktop;
        }
    }
    getDesktopsForClient(kwinClient) {
        const desktops = this.getDesktops(kwinClient.activities, kwinClient.desktops); // workaround for QTBUG-109880
        return desktops;
    }
    // empty array means all
    *getDesktops(activities, kwinDesktops) {
        const matchedActivities = activities.length > 0 ? activities : this.kwinActivities.keys();
        const matchedDesktops = kwinDesktops.length > 0 ? kwinDesktops : this.kwinDesktops.keys();
        for (const matchedActivity of matchedActivities) {
            for (const matchedDesktop of matchedDesktops) {
                const desktopKey = DesktopManager.getDesktopKey(matchedActivity, matchedDesktop);
                const desktop = this.desktops.get(desktopKey);
                if (desktop !== undefined) {
                    yield desktop;
                }
            }
        }
    }
}
var FocusPassing;
(function (FocusPassing) {
    class Passer {
        constructor() {
            this.currentRequest = null;
        }
        request(target) {
            this.currentRequest = new Request(target, Date.now());
        }
        clear() {
            this.currentRequest = null;
        }
        clearIfDifferent(kwinClient) {
            if (this.currentRequest !== null && this.currentRequest.target !== kwinClient) {
                this.clear();
            }
        }
        activate() {
            if (this.currentRequest === null) {
                return;
            }
            if (this.currentRequest.isExpired()) {
                this.clear();
                return;
            }
            Workspace.activeWindow = this.currentRequest.target;
        }
    }
    FocusPassing.Passer = Passer;
    class Request {
        constructor(target, time) {
            this.target = target;
            this.time = time;
        }
        isExpired() {
            return Date.now() - this.time > Request.validMs;
        }
    }
    Request.validMs = 200;
})(FocusPassing || (FocusPassing = {}));
class PinManager {
    constructor() {
        this.pinnedClients = new Set();
    }
    addClient(kwinClient) {
        this.pinnedClients.add(kwinClient);
    }
    removeClient(kwinClient) {
        this.pinnedClients.delete(kwinClient);
    }
    getAvailableSpace(kwinDesktop, screen) {
        const baseLot = new PinManager.Lot(screen.top, screen.bottom, screen.left, screen.right);
        let lots = [baseLot];
        for (const client of this.pinnedClients) {
            if (!Clients.isOnVirtualDesktop(client, kwinDesktop) || client.minimized) {
                continue;
            }
            const newLots = [];
            for (const lot of lots) {
                lot.split(newLots, client.frameGeometry);
            }
            lots = newLots;
        }
        let largestLot = baseLot;
        let largestArea = 0;
        for (const lot of lots) {
            const area = lot.area();
            if (area > largestArea) {
                largestArea = area;
                largestLot = lot;
            }
        }
        return largestLot;
    }
}
(function (PinManager) {
    class Lot {
        constructor(top, bottom, left, right) {
            this.top = top;
            this.bottom = bottom;
            this.left = left;
            this.right = right;
        }
        split(destLots, obstacle) {
            if (!this.contains(obstacle)) {
                // don't split
                destLots.push(this);
                return;
            }
            if (obstacle.top - this.top >= Lot.minHeight) {
                destLots.push(new Lot(this.top, obstacle.top, this.left, this.right));
            }
            if (this.bottom - obstacle.bottom >= Lot.minHeight) {
                destLots.push(new Lot(obstacle.bottom, this.bottom, this.left, this.right));
            }
            if (obstacle.left - this.left >= Lot.minWidth) {
                destLots.push(new Lot(this.top, this.bottom, this.left, obstacle.left));
            }
            if (this.right - obstacle.right >= Lot.minWidth) {
                destLots.push(new Lot(this.top, this.bottom, obstacle.right, this.right));
            }
        }
        contains(obstacle) {
            return obstacle.right > this.left && obstacle.left < this.right &&
                obstacle.bottom > this.top && obstacle.top < this.bottom;
        }
        area() {
            return (this.bottom - this.top) * (this.right - this.left);
        }
    }
    Lot.minWidth = 200;
    Lot.minHeight = 200;
    PinManager.Lot = Lot;
})(PinManager || (PinManager = {}));
class World {
    constructor(config) {
        const focusPasser = new FocusPassing.Passer();
        this.workspaceSignalManager = initWorkspaceSignalHandlers(this, focusPasser);
        this.cursorFollowsFocus = config.cursorFollowsFocus;
        let presetWidths = {
            next: (currentWidth, minWidth, maxWidth) => currentWidth,
            prev: (currentWidth, minWidth, maxWidth) => currentWidth,
            getWidths: (minWidth, maxWidth) => [],
        };
        try {
            presetWidths = new PresetWidths(config.presetWidths, config.gapsInnerHorizontal);
        }
        catch (error) {
            notificationInvalidPresetWidths.sendEvent();
            log("failed to parse presetWidths:", error);
        }
        this.shortcutActions = registerKeyBindings(this, {
            manualScrollStep: config.manualScrollStep,
            presetWidths: presetWidths,
            columnResizer: config.scrollingCentered ? new RawResizer(presetWidths) : new ContextualResizer(presetWidths),
        });
        this.screenResizedDelayer = new Delayer(1000, () => {
            // this delay ensures that docks are taken into account by `Workspace.clientArea`
            for (const desktop of this.desktopManager.getAllDesktops()) {
                desktop.onLayoutChanged();
            }
            this.update();
        });
        this.pinManager = new PinManager();
        const layoutConfig = {
            gapsInnerHorizontal: config.gapsInnerHorizontal,
            gapsInnerVertical: config.gapsInnerVertical,
            stackOffsetX: config.stackOffsetX,
            stackOffsetY: config.stackOffsetY,
            offScreenOpacity: config.offScreenOpacity / 100.0,
            stackColumnsByDefault: config.stackColumnsByDefault,
            resizeNeighborColumn: config.resizeNeighborColumn,
            reMaximize: config.reMaximize,
            skipSwitcher: config.skipSwitcher,
            tiledKeepBelow: config.tiledKeepBelow,
            maximizedKeepAbove: config.floatingKeepAbove,
            untileOnDrag: config.untileOnDrag,
        };
        this.desktopManager = new DesktopManager(this.pinManager, {
            marginTop: config.gapsOuterTop,
            marginBottom: config.gapsOuterBottom,
            marginLeft: config.gapsOuterLeft,
            marginRight: config.gapsOuterRight,
            scroller: World.createScroller(config),
            clamper: config.scrollingLazy ? new EdgeClamper() : new CenterClamper(),
            gestureScroll: config.gestureScroll,
            gestureScrollInvert: config.gestureScrollInvert,
            gestureScrollStep: config.gestureScrollStep,
        }, layoutConfig, focusPasser, new DesktopFilter(config.tiledDesktops));
        this.clientManager = new ClientManager(config, this, this.desktopManager, this.pinManager);
        this.addExistingClients();
        this.update();
    }
    static createScroller(config) {
        if (config.scrollingLazy) {
            return new LazyScroller();
        }
        else if (config.scrollingCentered) {
            return new CenteredScroller();
        }
        else if (config.scrollingGrouped) {
            return new GroupedScroller();
        }
        else {
            log("No scrolling mode selected, using default");
            return new LazyScroller();
        }
    }
    addExistingClients() {
        for (const kwinClient of Workspace.windows) {
            this.clientManager.addClient(kwinClient);
        }
    }
    update() {
        const currentDesktop = this.desktopManager.getCurrentDesktop();
        if (currentDesktop !== undefined) {
            currentDesktop.arrange();
            this.moveCursorToFocus();
        }
    }
    moveCursorToFocus() {
        if (this.cursorFollowsFocus && Workspace.activeWindow !== null) {
            // Only move cursor for tiled windows
            const tiledWindow = this.clientManager.findTiledWindow(Workspace.activeWindow);
            if (tiledWindow === null) {
                return;
            }
            const cursorAlreadyInFocus = rectContainsPoint(Workspace.activeWindow.frameGeometry, Workspace.cursorPos);
            if (cursorAlreadyInFocus) {
                return;
            }
            moveCursorToFocus.call();
        }
    }
    do(f) {
        f(this.clientManager, this.desktopManager);
        this.update();
    }
    doIfTiled(kwinClient, f) {
        const window = this.clientManager.findTiledWindow(kwinClient);
        if (window === null) {
            return;
        }
        const column = window.column;
        const grid = column.grid;
        f(this.clientManager, this.desktopManager, window, column, grid);
        this.update();
    }
    doIfTiledFocused(f) {
        if (Workspace.activeWindow === null) {
            return;
        }
        this.doIfTiled(Workspace.activeWindow, f);
    }
    gestureScroll(amount) {
        this.do((clientManager, desktopManager) => {
            const currentDesktop = desktopManager.getCurrentDesktop();
            if (currentDesktop !== undefined) {
                currentDesktop.gestureScroll(amount);
            }
        });
    }
    gestureScrollFinish() {
        this.do((clientManager, desktopManager) => {
            const currentDesktop = desktopManager.getCurrentDesktop();
            if (currentDesktop !== undefined) {
                currentDesktop.gestureScrollFinish();
            }
        });
    }
    destroy() {
        this.workspaceSignalManager.destroy();
        for (const shortcutAction of this.shortcutActions) {
            shortcutAction.destroy();
        }
        this.clientManager.destroy();
        this.desktopManager.destroy();
    }
    onScreenResized() {
        this.screenResizedDelayer.run();
    }
}
var ClientState;
(function (ClientState) {
    class Docked {
        constructor(world, kwinClient) {
            this.world = world;
            this.signalManager = Docked.initSignalManager(world, kwinClient);
            world.onScreenResized();
        }
        destroy(passFocus) {
            this.signalManager.destroy();
            this.world.onScreenResized();
        }
        static initSignalManager(world, kwinClient) {
            const manager = new SignalManager();
            manager.connect(kwinClient.frameGeometryChanged, () => {
                world.onScreenResized();
            });
            return manager;
        }
    }
    ClientState.Docked = Docked;
})(ClientState || (ClientState = {}));
var ClientState;
(function (ClientState) {
    class Floating {
        constructor(world, client, config, limitHeight) {
            this.client = client;
            this.config = config;
            if (config.floatingKeepAbove) {
                client.kwinClient.keepAbove = true;
            }
            if (limitHeight && client.kwinClient.tile === null) {
                Floating.limitHeight(client);
            }
            this.signalManager = Floating.initSignalManager(world, client.kwinClient);
        }
        destroy(passFocus) {
            this.signalManager.destroy();
        }
        // TODO: move to `Tiled.restoreClientAfterTiling`
        static limitHeight(client) {
            const placementArea = Workspace.clientArea(0 /* ClientAreaOption.PlacementArea */, client.kwinClient.output, Clients.getKwinDesktopApprox(client.kwinClient));
            const clientRect = client.kwinClient.frameGeometry;
            const width = client.preferredWidth;
            client.place(clientRect.x, clientRect.y, width, Math.min(clientRect.height, Math.round(placementArea.height / 2)));
        }
        static initSignalManager(world, kwinClient) {
            const manager = new SignalManager();
            manager.connect(kwinClient.tileChanged, () => {
                // on X11, this fires after `frameGeometryChanged`
                if (kwinClient.tile !== null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.pinClient(kwinClient);
                    });
                }
            });
            manager.connect(kwinClient.frameGeometryChanged, () => {
                // on Wayland, this fires after `tileChanged`
                if (kwinClient.tile !== null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.pinClient(kwinClient);
                    });
                }
            });
            return manager;
        }
    }
    ClientState.Floating = Floating;
})(ClientState || (ClientState = {}));
var ClientState;
(function (ClientState) {
    class Manager {
        constructor(initialState) {
            this.state = initialState;
        }
        setState(constructNewState, passFocus) {
            this.state.destroy(passFocus);
            this.state = constructNewState();
        }
        getState() {
            return this.state;
        }
        destroy(passFocus) {
            this.state.destroy(passFocus);
        }
    }
    ClientState.Manager = Manager;
})(ClientState || (ClientState = {}));
var ClientState;
(function (ClientState) {
    class Pinned {
        constructor(world, pinManager, desktopManager, kwinClient, config) {
            this.kwinClient = kwinClient;
            this.pinManager = pinManager;
            this.desktopManager = desktopManager;
            this.config = config;
            if (config.floatingKeepAbove) {
                kwinClient.keepAbove = true;
            }
            this.signalManager = Pinned.initSignalManager(world, pinManager, kwinClient);
        }
        destroy(passFocus) {
            this.signalManager.destroy();
            this.pinManager.removeClient(this.kwinClient);
            for (const desktop of this.desktopManager.getDesktopsForClient(this.kwinClient)) {
                desktop.onPinsChanged();
            }
        }
        static initSignalManager(world, pinManager, kwinClient) {
            const manager = new SignalManager();
            let oldActivities = kwinClient.activities;
            let oldDesktops = kwinClient.desktops;
            manager.connect(kwinClient.tileChanged, () => {
                if (kwinClient.tile === null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.unpinClient(kwinClient);
                    });
                }
            });
            manager.connect(kwinClient.frameGeometryChanged, () => {
                if (kwinClient.tile === null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.unpinClient(kwinClient);
                    });
                    return;
                }
                world.do((clientManager, desktopManager) => {
                    for (const desktop of desktopManager.getDesktopsForClient(kwinClient)) {
                        desktop.onPinsChanged();
                    }
                });
            });
            manager.connect(kwinClient.minimizedChanged, () => {
                world.do((clientManager, desktopManager) => {
                    for (const desktop of desktopManager.getDesktopsForClient(kwinClient)) {
                        desktop.onPinsChanged();
                    }
                });
            });
            manager.connect(kwinClient.desktopsChanged, () => {
                const changedDesktops = oldDesktops.length === 0 || kwinClient.desktops.length === 0 ?
                    [] :
                    union(oldDesktops, kwinClient.desktops);
                world.do((clientManager, desktopManager) => {
                    for (const desktop of desktopManager.getDesktops(kwinClient.activities, changedDesktops)) {
                        desktop.onPinsChanged();
                    }
                });
                oldDesktops = kwinClient.desktops;
            });
            manager.connect(kwinClient.activitiesChanged, () => {
                const changedActivities = oldActivities.length === 0 || kwinClient.activities.length === 0 ?
                    [] :
                    union(oldActivities, kwinClient.activities);
                world.do((clientManager, desktopManager) => {
                    for (const desktop of desktopManager.getDesktops(changedActivities, kwinClient.desktops)) {
                        desktop.onPinsChanged();
                    }
                });
                oldActivities = kwinClient.activities;
            });
            return manager;
        }
    }
    ClientState.Pinned = Pinned;
})(ClientState || (ClientState = {}));
var ClientState;
(function (ClientState) {
    class Tiled {
        constructor(world, client, grid) {
            this.defaultState = { skipSwitcher: client.kwinClient.skipSwitcher };
            Tiled.prepareClientForTiling(client, grid.config);
            const column = new Column(grid, grid.getLastFocusedColumn() ?? grid.getLastColumn());
            const window = new Window(client, column);
            this.window = window;
            this.signalManager = Tiled.initSignalManager(world, window, grid.config);
        }
        destroy(passFocus) {
            this.signalManager.destroy();
            const window = this.window;
            const grid = window.column.grid;
            const client = window.client;
            window.destroy(passFocus);
            Tiled.restoreClientAfterTiling(client, grid.config, this.defaultState, grid.desktop.clientArea);
        }
        static initSignalManager(world, window, config) {
            const client = window.client;
            const kwinClient = client.kwinClient;
            const manager = new SignalManager();
            manager.connect(kwinClient.desktopsChanged, () => {
                world.do((clientManager, desktopManager) => {
                    const desktop = desktopManager.getDesktopForClient(kwinClient);
                    if (desktop === undefined) {
                        // windows on multiple desktops are not supported
                        clientManager.floatClient(client);
                        return;
                    }
                    Tiled.moveWindowToGrid(window, desktop.grid);
                });
            });
            manager.connect(kwinClient.activitiesChanged, () => {
                world.do((clientManager, desktopManager) => {
                    const desktop = desktopManager.getDesktopForClient(kwinClient);
                    if (desktop === undefined) {
                        // windows on multiple activities are not supported
                        clientManager.floatClient(client);
                        return;
                    }
                    Tiled.moveWindowToGrid(window, desktop.grid);
                });
            });
            manager.connect(kwinClient.minimizedChanged, () => {
                console.assert(kwinClient.minimized);
                world.do((clientManager, desktopManager) => {
                    clientManager.minimizeClient(kwinClient);
                });
            });
            manager.connect(kwinClient.maximizedAboutToChange, (maximizedMode) => {
                world.do(() => {
                    window.onMaximizedChanged(maximizedMode);
                });
            });
            let moving = false;
            let resizing = false;
            let resizeStartWidth = 0;
            let resizeNeighbor;
            manager.connect(kwinClient.interactiveMoveResizeStarted, () => {
                if (kwinClient.move) {
                    if (config.untileOnDrag) {
                        world.do((clientManager, desktopManager) => {
                            clientManager.floatClient(client);
                        });
                    }
                    else {
                        moving = true;
                    }
                    return;
                }
                if (kwinClient.resize) {
                    resizing = true;
                    resizeStartWidth = window.column.getWidth();
                    if (config.resizeNeighborColumn) {
                        const resizeNeighborColumn = Tiled.getResizeNeighborColumn(window);
                        if (resizeNeighborColumn !== null) {
                            resizeNeighbor = {
                                column: resizeNeighborColumn,
                                startWidth: resizeNeighborColumn.getWidth(),
                            };
                        }
                    }
                    window.column.grid.onUserResizeStarted();
                }
            });
            manager.connect(kwinClient.interactiveMoveResizeFinished, () => {
                if (moving) {
                    moving = false;
                    world.do(() => window.column.grid.desktop.onLayoutChanged()); // move the dragged window back to its position
                }
                if (resizing) {
                    resizing = false;
                    resizeNeighbor = undefined;
                    window.column.grid.onUserResizeFinished();
                }
            });
            const externalFrameGeometryChangedRateLimiter = new RateLimiter(4, Tiled.maxExternalFrameGeometryChangedIntervalMs);
            manager.connect(kwinClient.frameGeometryChanged, (oldGeometry) => {
                // on Wayland, this fires after `tileChanged`
                if (kwinClient.tile !== null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.pinClient(kwinClient);
                    });
                    return;
                }
                const newGeometry = client.kwinClient.frameGeometry;
                const oldCenterX = oldGeometry.x + oldGeometry.width / 2;
                const oldCenterY = oldGeometry.y + oldGeometry.height / 2;
                const newCenterX = newGeometry.x + newGeometry.width / 2;
                const newCenterY = newGeometry.y + newGeometry.height / 2;
                const dx = Math.round(newCenterX - oldCenterX);
                const dy = Math.round(newCenterY - oldCenterY);
                if (dx !== 0 || dy !== 0) {
                    // TODO: instead of passing dx and dy, remember relative (to the parent) x and y for each
                    // transient window and use them for `moveTransients` and `ensureTransientsVisible`
                    client.moveTransients(dx, dy);
                }
                if (kwinClient.resize) {
                    world.do(() => {
                        if (newGeometry.width !== oldGeometry.width) {
                            window.column.onUserResizeWidth(resizeStartWidth, newGeometry.width - resizeStartWidth, newGeometry.left !== oldGeometry.left, resizeNeighbor);
                        }
                        if (newGeometry.height !== oldGeometry.height) {
                            window.column.adjustWindowHeight(window, newGeometry.height - oldGeometry.height, newGeometry.y !== oldGeometry.y);
                        }
                    });
                }
                else if (!window.column.grid.isUserResizing() &&
                    !client.isManipulatingGeometry(newGeometry) &&
                    client.getMaximizedMode() === 0 /* MaximizedMode.Unmaximized */ &&
                    !Clients.isFullScreenGeometry(kwinClient) // not using `kwinClient.fullScreen` because it may not be set yet at this point
                ) {
                    if (externalFrameGeometryChangedRateLimiter.acquire()) {
                        world.do(() => window.onFrameGeometryChanged());
                    }
                }
            });
            manager.connect(kwinClient.fullScreenChanged, () => {
                world.do((clientManager, desktopManager) => {
                    // some clients only turn out to be untileable after exiting full-screen mode
                    if (!Clients.canTileEver(kwinClient)) {
                        clientManager.floatClient(client);
                        return;
                    }
                    window.onFullScreenChanged(kwinClient.fullScreen);
                });
            });
            manager.connect(kwinClient.tileChanged, () => {
                // on X11, this fires after `frameGeometryChanged`
                if (kwinClient.tile !== null) {
                    world.do((clientManager, desktopManager) => {
                        clientManager.pinClient(kwinClient);
                    });
                }
            });
            return manager;
        }
        static getResizeNeighborColumn(window) {
            const kwinClient = window.client.kwinClient;
            const column = window.column;
            if (Workspace.cursorPos.x > kwinClient.clientGeometry.right) {
                return column.grid.getRightColumn(column);
            }
            else if (Workspace.cursorPos.x < kwinClient.clientGeometry.left) {
                return column.grid.getLeftColumn(column);
            }
            else {
                return null;
            }
        }
        static moveWindowToGrid(window, grid) {
            if (grid === window.column.grid) {
                // window already on the given grid
                return;
            }
            const newColumn = new Column(grid, grid.getLastFocusedColumn() ?? grid.getLastColumn());
            const passFocus = window.isFocused() ? 2 /* FocusPassing.Type.OnUnfocus */ : 0 /* FocusPassing.Type.None */;
            window.moveToColumn(newColumn, true, passFocus);
        }
        static prepareClientForTiling(client, config) {
            if (config.skipSwitcher) {
                client.kwinClient.skipSwitcher = true;
            }
            if (client.kwinClient.fullScreen) {
                if (config.maximizedKeepAbove) {
                    client.kwinClient.keepAbove = true;
                }
            }
            else {
                if (config.tiledKeepBelow) {
                    client.kwinClient.keepBelow = true;
                }
                client.kwinClient.keepAbove = false;
            }
            if (client.kwinClient.tile !== null) {
                client.setMaximize(false, true); // disable quick tile mode
            }
            client.setMaximize(false, false);
        }
        static restoreClientAfterTiling(client, config, defaultState, screenSize) {
            if (config.skipSwitcher) {
                client.kwinClient.skipSwitcher = defaultState.skipSwitcher;
            }
            if (config.tiledKeepBelow) {
                client.kwinClient.keepBelow = false;
            }
            if (config.offScreenOpacity < 1.0) {
                client.kwinClient.opacity = 1.0;
            }
            client.setFullScreen(false);
            if (client.kwinClient.tile === null) {
                client.setMaximize(false, false);
            }
            client.ensureVisible(screenSize);
        }
    }
    Tiled.maxExternalFrameGeometryChangedIntervalMs = 1000;
    ClientState.Tiled = Tiled;
})(ClientState || (ClientState = {}));
var ClientState;
(function (ClientState) {
    class TiledMinimized {
        constructor(world, client) {
            this.signalManager = TiledMinimized.initSignalManager(world, client);
        }
        destroy(passFocus) {
            this.signalManager.destroy();
        }
        static initSignalManager(world, client) {
            const manager = new SignalManager();
            manager.connect(client.kwinClient.minimizedChanged, () => {
                console.assert(!client.kwinClient.minimized);
                world.do((clientManager, desktopManager) => {
                    const desktop = desktopManager.getDesktopForClient(client.kwinClient);
                    if (desktop !== undefined) {
                        clientManager.tileClient(client, desktop.grid);
                    }
                    else {
                        clientManager.floatClient(client);
                    }
                });
            });
            return manager;
        }
    }
    ClientState.TiledMinimized = TiledMinimized;
})(ClientState || (ClientState = {}));
function init() {
    return new World(loadConfig());
}
function loadConfig() {
    const config = {};
    for (const entry of configDef) {
        config[entry.name] = KWin.readConfig(entry.name, entry.default);
    }
    return config;
}
