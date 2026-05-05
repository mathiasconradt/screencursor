# Screen Cursor

Native macOS menu bar app that draws a configurable highlight circle around the cursor.

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
- Highlight color, including alpha

## Notes

This project currently builds an Apple Silicon app bundle with the command line tools:

```sh
swiftc -target arm64-apple-macos13.0
```

No screen recording or accessibility permission is required for the highlight overlay because the app only reads the current mouse location and draws its own click-through window.

## License

MIT. See `LICENSE`.
