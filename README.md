# Screen Cursor

[![Build](https://github.com/mathiasconradt/screencursor/actions/workflows/build.yml/badge.svg)](https://github.com/mathiasconradt/screencursor/actions/workflows/build.yml) [![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=mathiasconradt_screencursor&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=mathiasconradt_screencursor)

Native macOS menu bar app that draws a configurable highlight circle around the cursor.

<img src="docs/assets/screencursor.png" alt="Screen Cursor promo image" width="100%">

## Build

```sh
make
```

The app bundle is written to:

```text
build/Screen Cursor.app
```

## Run

```sh
make run
```

Use the pointer icon in the menu bar to open settings, toggle the highlight, or quit.
Press `Option-H` to toggle the highlight globally, even when another app is focused.

## Release Zip

```sh
make dist
```

The release archive is written to:

```text
dist/Screen-Cursor-<version>.zip
```

## Homebrew

After a GitHub release is published, install from this tap with:

```sh
brew tap mathiasconradt/screencursor https://github.com/mathiasconradt/screencursor
brew install --cask screen-cursor
```

Settings are saved with `UserDefaults`:

- Highlight enabled
- Highlight radius
- Border width
- Inner opacity
- Click feedback
- Highlight color, including alpha
- Jiggle enabled
- Jiggle interval (seconds)

## Notes

This project currently builds an Apple Silicon app bundle with the command line tools:

```sh
swiftc -target arm64-apple-macos13.0
```

No screen recording or accessibility permission is required for the highlight overlay because the app only reads the current mouse location and draws its own click-through window.
No accessibility permission is required for the global `Option-H` hotkey because it is registered with macOS as an application hotkey.

The jiggle feature uses `CGWarpMouseCursorPosition` to move the cursor, which also requires no accessibility permission. It only fires after the mouse has been idle for the configured interval — any user mouse movement resets the countdown.

## License

MIT. See `LICENSE`.
