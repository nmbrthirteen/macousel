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
- Quitting or pausing puts every window back where it was. If Macousel crashes, it relaunches, puts the windows back, and stays paused until you resume it.

## Requirements

- macOS 26 or later.
- Accessibility permission. macOS only lets an app move other apps' windows through the Accessibility API. It is the only permission Macousel asks for.

## Install

Run the installer. It downloads the latest release, puts `Macousel.app` in `/Applications`, and replaces an older copy:

```sh
curl -fsSL https://github.com/nmbrthirteen/macousel/releases/latest/download/install.sh | bash
```

With Homebrew:

```sh
brew tap nmbrthirteen/macousel https://github.com/nmbrthirteen/macousel
brew install --cask macousel
```

Or download `Macousel.dmg` from the [releases page](https://github.com/nmbrthirteen/macousel/releases) and drag the app to Applications.

Then open Macousel and grant Accessibility access when macOS asks.

### Updating

Open Settings > About and click "Check for updates". Macousel checks once a day on its own, and you can turn that off in Settings > General. You can also run the installer again. After either one, macOS asks for Accessibility access again, because every release has a new signature.

Macousel only installs an update whose archive carries a valid signature from my update signing key. If the check fails, nothing is installed.

### The app is not notarized

I do not have an Apple Developer ID. Releases are signed with a certificate of my own, which macOS does not recognise. Two things follow from that:

- If you used the DMG or Homebrew, macOS blocks the first launch. Open System Settings > Privacy & Security and click "Open Anyway". The installer script clears the quarantine flag, so it skips this step.
- The Accessibility grant is tied to that certificate, so it carries over from one release to the next. Releases up to 0.1.4 were signed ad hoc, so the first update from one of them asks for access once more.

Updates are verified with a signing key that I hold, and the app is not notarized. The signature proves an update came from me. It does not replace Apple's notarization.

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

Most of them use Control-Option, including the column numbers. Plain Option plus a digit would block characters on layouts such as German, where Option-5 to Option-9 type brackets and braces. Rebind any of them in Settings > Shortcuts. A shortcut you already changed keeps its binding.

| Action | Keys |
| --- | --- |
| Focus left, down, up, right | ⌃⌥ H J K L, or the arrows |
| Move the window | ⌃⌥⇧ and the same keys |
| First or last window | ⌃⌥⌘ ← → |
| Jump to column 1 to 8, or 9 for the last | ⌃⌥ 1 to 9 |
| Move the window to that column | ⌃⌥⇧ 1 to 9 |
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

## What Macousel stores and sends

Layout restore keeps the app identifiers and a hash of each window title in the app's preferences. It never stores a title in plain text. Nothing is sent anywhere, except two requests to GitHub: the update check once a day, which you can turn off in Settings > General, and the download when you install an update.

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

Push a version tag. The release workflow runs the tests, builds the app with that version, signs the zip with the update key, attests build provenance, and publishes `Macousel.dmg`, `Macousel.zip`, `Macousel.zip.sig`, and `install.sh` to a GitHub release. The release notes list the SHA-256 sums of the DMG and the zip.

The workflow reads the base64 private key from the `UPDATE_SIGNING_KEY` repository secret. To sign a zip by hand:

```sh
UPDATE_SIGNING_KEY="..." swift scripts/sign-update.swift build/Macousel.zip build/Macousel.zip.sig
```

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
