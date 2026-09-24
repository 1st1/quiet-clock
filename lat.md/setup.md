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

Right-click (or Control-click) the clock and choose **Settings…**, or reopen Quiet Clock from Applications. Changes save and appear immediately. Your existing appearance and links carry over.

Choose **Move Clock (Drag & Drop)** from the right-click menu, or enable **Move clock** in settings, then drag the outlined clock on the desktop. Right-click and choose **Lock Position** to restore shortcut clicks. Use **Width** to control horizontal space; height grows or shrinks automatically with the content. The top edge stays anchored as height changes; **Reset Position** brings it back to the main display. Position and width survive relaunch and are remembered separately for each connected monitor group. Returning to a known group restores its placement automatically. Moving, width changes, and Reset Position affect only the current group. Height is recalculated from the current appearance. Rearranging monitors keeps the clock on the same physical display.

Choose clock and link fonts, weights, sizes, alignment, text color, line height, and negative or positive padding. Line height changes row spacing without shrinking fonts. Links wrap at their selected size and add vertical space. Increase Width if a large manual clock font is too wide; very tall content may extend below the display. Shortcut controls include searchable icons, icon size/gap, row spacing, and divider length/brightness. Turn off **Show divider** to remove the divider and its padding entirely; its other settings are retained. Each link has its own row and opens the default browser. **Reset** restores appearance defaults and removes links. See [[architecture#Architecture#Shortcut links]] and [[architecture#Architecture#Clock appearance]].

The background is always clear. A dashed outline appears only in move mode. Ordinary app windows cover the clock; it follows desktop Spaces, but is not intended to float above full-screen apps. Choose **Quit Quiet Clock** from the right-click menu to remove the clock. There is no menu-bar or Dock icon, and left-clicking the time does nothing.

## Desktop corners

Open settings and select **Desktop Corners** to add black rounded wallpaper corners independently to each connected display.

Enable **Rounded corners** for a monitor and adjust **Corner radius** from 1–200 pt. Settings save automatically per physical monitor and return when it reconnects. New monitors start disabled with a 17 pt radius. Existing saved radii are preserved. Masks ignore clicks and remain behind application windows, the menu bar, and Dock. The radius uses points, so Retina displays scale naturally. Disable a monitor’s switch to remove its four masks. Clock appearance and Reset are independent of these settings; quitting Quiet Clock removes all masks.

## Validate

Run automated checks before interactive desktop verification. The sandbox probe uses a disposable file and preserves your appearance.

```sh
bash scripts/test.sh
bash scripts/test-sandbox.sh
lat check
```

The build also verifies signing, bundle contents, and absence of WidgetKit linkage. See [[tests#Validation]] for manual checks.
