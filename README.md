# Sash

A lightweight macOS menu bar app for reliably cycling through windows of the current application.

macOS's built-in window switching shortcut can be unreliable. Sash lets you set any global keyboard shortcut to reliably cycle through windows of the frontmost app. The default shortcut is `⇧⌘2`.

## Features

- Configurable shortcut
- Menu bar app
- Launch at Login
- Zero dependencies
- Tiny/Lightweight

## Install

Download `Sash.zip` from the [latest release](../../releases/latest), unzip, and drag to Applications.

> The app is not notarized. On first launch, right-click the app and choose **Open** (or go to System Settings > Privacy & Security and click **Open Anyway**).

## Requirements (building from source)

- macOS 13 (Ventura) or later
- Accessibility permission (prompt on first launch)

## Build

Requires Swift 5.9+ (Xcode Command Line Tools).

```sh
make bundle   # build and create .app bundle
make run      # build, bundle, and launch
make install  # copy to /Applications
make clean    # remove build artifacts
```

## Usage

1. Launch the app — it appears as an icon in the menu bar
2. Click the menu icon and record your preferred shortcut if desired (default is `⇧⌘2`)
3. Grant Accessibility permission when prompted
4. Press your shortcut to cycle through windows of the current app

## How it works

When the shortcut is pressed, Sash uses the macOS Accessibility API (`AXUIElement`) to get the window list of the frontmost application, then raises the next window in the stack. This rotates through all non-minimized windows on each press.

## License

MIT
