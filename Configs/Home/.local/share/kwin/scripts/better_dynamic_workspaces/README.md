# Better Dynamic Workspaces #
---

# Purpose of This Fork

The original script was created for Plasma 5, which used different APIs and session handling rules. Plasma 6 introduced new desktop management behavior, new virtual desktop APIs, and a different approach to session restoration. These changes made the original design harder to maintain and led to issues such as inconsistent numbering, restored clutter from previous sessions, and unpredictable startup desktops.

This fork focuses exclusively on Plasma 6 and rebuilds the concept around its modern architecture. The goal is to deliver a stable, predictable, GNOME style dynamic workspace system that behaves consistently across sessions and window events.

# Key Features

## Plasma 6 Native Codebase
The script uses Plasma 6’s virtual desktop API directly. This removes the need for compatibility layers and allows the logic to be simpler, more reliable, and easier to maintain. Window events, desktop creation, and desktop removal all use Plasma 6’s native structures.

## GNOME Style Dynamic Workspace Model
The workspace lifecycle follows the GNOME approach. The session always begins with two desktops. The user always starts on Desktop 1. A new desktop is created only when the last one becomes occupied. Empty desktops are removed automatically, and the final desktop is always kept empty. This creates a self maintaining layout that grows and shrinks naturally based on activity.

## Unified Cleanup System
The original project used direction based cleanup and shifted windows to earlier desktops to maintain order. Plasma 6 made this approach less reliable. This fork replaces it with a single cleanup pass that runs after any structural change. It removes empty desktops, ensures the last desktop remains empty, and keeps the layout free of gaps. The cleanup is direction agnostic and does not shift windows, which makes the behavior consistent and predictable.

## Consistent Desktop Renumbering
Desktops are always kept in sequential order. Renumbering happens automatically whenever desktops are added or removed. This keeps the pager, window manager, and internal logic aligned at all times.

## Predictable Startup Behavior
The script ensures that every session begins in a clean state. The user always starts on Desktop 1. The session always begins with exactly two desktops. Plasma’s session restore behavior is bypassed so that old desktops are not recreated automatically.

---

# Comparison With the Original Project

| Feature | Original Project (maurges) | This Fork |
|--------|-----------------------------|-----------|
| Plasma 5 support | Yes | No |
| Plasma 6 support | Partial | Full, native |
| Startup desktops | Restores all from last session | Always 2 |
| Startup focus | Last used desktop | Always Desktop 1 |
| Desktop renumbering | No | Yes, always sequential |
| Dynamic behavior | Basic | GNOME like |
| Cleanup model | Direction based shift left logic | Unified GNOME style cleanup |
| Workspace lifecycle | Mixed rules | Strictly append only |
| Code complexity | Higher | Reduced, Plasma 6 only |
| Window shifting | Required | Removed |
| Session consistency | Variable | Deterministic |

# License

This fork maintains the BSD 3 license of the original project with proper attribution.

# Credits

Inspired by and built upon the original dynamic_workspaces by maurges, whose work established dynamic workspaces on KDE.

