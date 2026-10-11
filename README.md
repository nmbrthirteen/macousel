# Macousel

A scrolling window manager for macOS.

Every window is a column on one horizontal strip. The strip is wider than your screen, so you scroll it. Opening a window never resizes the ones you already have.

It is the model niri and PaperWM use on Linux, built as a native Mac app.

## Status

Early. I wrote it on macOS 27 with two displays. The layout engine is well tested. The parts that talk to macOS have had little real use so far, so expect bugs and please report them.

## What it does

**The strip**

- New windows open next to the focused one.
- Focus moves with the keyboard, and the strip scrolls just far enough to show the window.
- Each display and each Space has its own strip.
- Column order, widths, and stacks come back after a restart.

**Columns**

- Stack several windows in one column and resize the rows.
- Turn a stack into tabs.
- Cycle a column through preset widths, or nudge it wider and narrower.
- Drag a window onto another spot to reorder.

**Input**

- Every shortcut can be rebound. One action can have several shortcuts.
- Swipe with three or four fingers, or hold Control-Option and scroll.
- Optional focus follows mouse and mouse follows focus.

**The rest**

- A minimap of the strip, a focus border, and dimming for inactive windows.
- Per-app rules: float, open at a set width, or open in a set slot.
- A URL scheme and a command line client for scripts.
- Quitting or pausing puts every window back where it was.

## Requirements

- macOS 26 or later.
- Accessibility permission. macOS only lets an app move other apps' windows through the Accessibility API. It is the only permission Macousel asks for.

## Install

Run the installer. It downloads the latest release, puts `Macousel.app` in `/Applications`, and replaces an older copy:

```sh
curl -fsSL https://github.com/nmbrthirteen/macousel/releases/latest/download/install.sh | bash
```

Or download `Macousel.dmg` from the [releases page](https://github.com/nmbrthirteen/macousel/releases) and drag the app to Applications.

Then open Macousel and grant Accessibility access when macOS asks.

### Updating

Open Settings > About and click "Check for updates". Macousel checks once a day on its own, and you can turn that off in Settings > General. You can also run the installer again. After either one, macOS asks for Accessibility access again, because every release has a new signature.

### The app is not notarized

I do not have an Apple Developer ID, so releases are signed ad hoc. Two things follow from that:

- If you used the DMG, macOS blocks the first launch. Open System Settings > Privacy & Security and click "Open Anyway". The installer script clears the quarantine flag, so it skips this step.
- macOS ties the Accessibility grant to the signature, and every release has a new one. After an update, remove Macousel from the Accessibility list and add it again.

### Build from source

```sh
git clone https://github.com/nmbrthirteen/macousel.git
cd macousel
scripts/bundle.sh
open build/Macousel.app
```

To keep the Accessibility grant across your own rebuilds, sign with a certificate from your keychain:

```sh
CODESIGN_IDENTITY="My Certificate" scripts/bundle.sh
```

## Default shortcuts

Most of them use Control-Option. The column numbers use plain Option, which takes over the symbols macOS types with Option-1 to Option-9. Rebind them in Settings > Shortcuts if you need those symbols.

| Action | Keys |
| --- | --- |
| Focus left, down, up, right | ⌃⌥ H J K L, or the arrows |
| Move the window | ⌃⌥⇧ and the same keys |
| First or last window | ⌃⌥⌘ ← → |
| Jump to column 1 to 8, or 9 for the last | ⌥ 1 to 9 |
| Move the window to that column | ⌥⇧ 1 to 9 |
| Move the window to the first or last spot | ⌃⌥⌘⇧ ← → |
| Cycle width, full width, center | ⌃⌥ R, F, C |
| Wider, narrower | ⌃⌥ = and - |
| Taller, shorter, equalize | ⌃⌥⇧ = and -, ⌃⌥ 0 |
| Stack into the left or right column | ⌃⌥ ] and [ |
| Pop out to the right or left | ⌃⌥⇧ ] and [ |
| Tabbed column | ⌃⌥⇧ T |
| Float | ⌃⌥ T |
| Send to the next display | ⌃⌥ N |
| Pause tiling | ⌃⌥ Q |

## Reporting a problem

Choose "Save diagnostics…" from the menu bar icon. It writes one text file to your Desktop with the app's log, your settings, your displays, and the names of any crash reports. Attach it to the issue.

## Scripting

Every action has a command name. List them:

```sh
build/Macousel.app/Contents/MacOS/Macousel list
```

Run one from the command line or through the URL scheme:

```sh
build/Macousel.app/Contents/MacOS/Macousel focus-left
open "macousel://cycle-width"
```

Write a Raycast script command for every action:

```sh
build/Macousel.app/Contents/MacOS/Macousel raycast-scripts ~/raycast-scripts
```

## Development

```sh
swift build
swift test
```

The package has three targets:

- `StripCore` is the layout engine. It is pure Swift with no AppKit, and it holds most of the tests.
- `WindowSystem` wraps the Accessibility API, hotkeys, displays, and gestures.
- `Macousel` is the app: the window manager, settings, and overlays.

The code has no comments. Names carry the meaning.

### Releasing

Push a version tag. The release workflow runs the tests, builds the app with that version, and publishes `Macousel.dmg`, `Macousel.zip`, and `install.sh` to a GitHub release.

```sh
git tag v0.1.0
git push origin v0.1.0
```

To build the same files locally:

```sh
VERSION=0.1.0 scripts/bundle.sh
scripts/package.sh
```

### Private APIs

Macousel uses a few private macOS calls. Every Mac window manager needs the same ones, and they rule out the Mac App Store.

- `_AXUIElementGetWindow` maps an Accessibility element to a window ID.
- `CGSManagedDisplayGetCurrentSpace` reads the active Space of a display.
- `_SLPSSetFrontProcessWithOptions` and `SLPSPostEventRecordTo` focus one window without raising the whole app. If they stop working, Macousel falls back to normal app activation.
- `MultitouchSupport` reads raw trackpad touches for the swipe gesture.

## License

MIT. See [LICENSE](LICENSE).
