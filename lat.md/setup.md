# Setup

Build and install Quiet Clock as an always-running transparent desktop app. The project is [MIT licensed](../LICENSE).

## Build and install

Building requires macOS 14 or later and Apple’s Command Line Tools. No third-party packages or network access are required.

```sh
bash scripts/build.sh
open "build/Quiet Clock.app"
```

For permanent use, quit the previous app and replace it in your Applications folder with the built bundle. When upgrading from the WidgetKit version, remove the old desktop widget through its context menu. The new app creates its own desktop clock and does not appear in the widget gallery.

Keep the app running; closing settings is fine. To start automatically, add Quiet Clock in System Settings → General → Login Items. See [[architecture#Architecture#Packaging]] for signing details.

## Customize

Click the time or use the menu-bar clock’s Settings command. Changes save and appear immediately. Your existing appearance and links carry over.

Enable **Move clock** in settings or **Move / Lock Clock** in the menu bar, then drag the outlined clock on the desktop. Disable move mode to restore link and settings clicks. Use **Width** and **Height** to resize; **Reset Position** brings it back to the main display. Position and size survive relaunch and are remembered separately for each connected monitor group. Returning to a known group restores its placement automatically. Moving, resizing, and Reset Position affect only the current group. Rearranging monitors keeps the clock on the same physical display.

Choose clock and link fonts, weights, sizes, alignment, text color, line height, and negative or positive padding. Shortcut controls include searchable icons, icon size/gap, row spacing, and divider length/brightness. Each link has its own row and opens the default browser. **Reset** restores appearance defaults and removes links. See [[architecture#Architecture#Shortcut links]] and [[architecture#Architecture#Clock appearance]].

The background is always clear. A dashed outline appears only in move mode. Ordinary app windows cover the clock; it follows desktop Spaces, but is not intended to float above full-screen apps. Quit from the menu bar to remove the clock.

## Validate

Run automated checks before interactive desktop verification. The sandbox probe uses a disposable file and preserves your appearance.

```sh
bash scripts/test.sh
bash scripts/test-sandbox.sh
lat check
```

The build also verifies signing, bundle contents, and absence of WidgetKit linkage. See [[tests#Validation]] for manual checks.
