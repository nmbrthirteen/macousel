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

There is no signed download yet. I do not have a Developer ID, so the app is not notarized. Build it yourself:

```sh
git clone https://github.com/nmbrthirteen/macousel.git
cd macousel
scripts/bundle.sh
open build/Macousel.app
```

Then grant Accessibility access when macOS asks. The script signs the app ad hoc, so macOS asks again after every rebuild. To keep the permission across rebuilds, sign with a certificate of your own:

```sh
CODESIGN_IDENTITY="My Certificate" scripts/bundle.sh
```

## Default shortcuts

All of them use Control-Option. Plain Option stays with macOS.

| Action | Keys |
| --- | --- |
| Focus left, down, up, right | ⌃⌥ H J K L, or the arrows |
| Move the window | ⌃⌥⇧ and the same keys |
| First or last window | ⌃⌥⌘ ← → |
| Cycle width, full width, center | ⌃⌥ R, F, C |
| Wider, narrower | ⌃⌥ = and - |
| Taller, shorter, equalize | ⌃⌥⇧ = and -, ⌃⌥ 0 |
| Stack into the left or right column | ⌃⌥ ] and [ |
| Pop out to the right or left | ⌃⌥⇧ ] and [ |
| Tabbed column | ⌃⌥⇧ T |
| Float | ⌃⌥ T |
| Send to the next display | ⌃⌥ N |
| Pause tiling | ⌃⌥ Q |

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

### Private APIs

Macousel uses a few private macOS calls. Every Mac window manager needs the same ones, and they rule out the Mac App Store.

- `_AXUIElementGetWindow` maps an Accessibility element to a window ID.
- `CGSManagedDisplayGetCurrentSpace` reads the active Space of a display.
- `_SLPSSetFrontProcessWithOptions` and `SLPSPostEventRecordTo` focus one window without raising the whole app. If they stop working, Macousel falls back to normal app activation.
- `MultitouchSupport` reads raw trackpad touches for the swipe gesture.

## License

MIT. See [LICENSE](LICENSE).
