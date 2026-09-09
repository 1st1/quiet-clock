# Quiet Clock

A native macOS desktop widget showing only hours and minutes, in a large rounded system font with a soft text shadow. Supports small and medium sizes, light/dark appearance, and the system’s preferred 12/24-hour format, without an AM/PM label.

Requires macOS 14 or later and Apple’s Command Line Tools to build. No packages or network access are needed.

## Build and add to the desktop

```sh
bash scripts/build.sh
open "build/Quiet Clock.app"
```

For a permanent installation, copy `build/Quiet Clock.app` to your Applications folder and open that copy. Right-click the desktop → **Edit Widgets** → search **Quiet Clock** → add the small or medium widget. You can then quit the app. Keep the application installed so macOS can find its widget extension.

## Appearance

Open Quiet Clock (or click its desktop widget) to edit the appearance. Choose a system design or installed font family, automatic or fixed font size, weight, letter spacing, text color, and background color. The preview switches between small and medium sizes. Changes save automatically and refresh all Quiet Clock widgets after a brief pause in adjustments. **Reset** restores and saves the defaults immediately. Closing or quitting the editor preserves the latest edit.

**Use system widget background** omits the clock’s own fill. The tested macOS 15 desktop still shows an opaque black tile: this is not true transparency. The editor shows an approximate system tile rather than a see-through preview. Existing saved settings remain compatible. In System Settings → Desktop & Dock → Widgets, **Full-color** preserves chosen colors. Custom fonts use the nearest available weight, and oversized text shrinks to fit.

Settings are stored in `~/Library/Application Support/Quiet Clock/appearance.json`. The app can read/write this folder; the widget can only read it. The local build uses narrowly scoped sandbox file exceptions so it works without a developer account. App Store distribution should use a provisioned App Group instead.

## Refresh behavior

The widget supplies three hours of entries at minute boundaries and requests a replacement timeline after one hour. It uses no polling timer, network, login item, or continuously running app. WidgetKit owns scheduling and can delay updates, particularly around sleep or system time changes. It cannot promise an update every ten seconds or exact minute changes on macOS 14/15. See [Apple’s WidgetKit refresh guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

The companion preview updates while its window is open; the desktop widget uses the timeline. If the time zone changes, the next timeline reload adopts the new zone.

## Validation

```sh
bash scripts/test.sh
```

The executable tests cover minute boundaries, midnight rollover, spacing, and 12/24-hour formatting. The build script compiles both executables, embeds the WidgetKit extension, checks the signed bundle, and verifies its extension service entry point. A local build uses ad-hoc signing; a distributable build needs an appropriate Apple identity (`CODE_SIGN_IDENTITY`) and notarization.

Settings tests also cover persistence, invalid values, corrupt data, and reset. Run `bash scripts/test-sandbox.sh` to check sharing between signed probes with the app and widget entitlements. It creates and removes a disposable file in the Quiet Clock settings folder; it does not change your appearance.

To check integration manually, add both widget sizes, observe a minute transition, test light/dark appearance and sleep/wake, and confirm the widget remains visible after quitting the app. Desktop rendering and scheduler behavior require this interactive check.
