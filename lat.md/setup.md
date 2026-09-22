# Setup

Build and install Quiet Clock, then customize its native desktop widget. The project is available under the [MIT license](../LICENSE).

## Build and install

Building requires macOS 14 or later and Apple’s Command Line Tools. No third-party packages or network access are required.

```sh
bash scripts/build.sh
open "build/Quiet Clock.app"
```

For a permanent installation, copy the built app to your Applications folder and open that copy. Right-click the desktop → **Edit Widgets** → search **Quiet Clock** → add the small, medium, or large widget. You can then quit the app; keep it installed so macOS can find its extension.

See [[architecture#Architecture#Packaging]] for signing and extension startup details. Distributable builds require an appropriate Apple signing identity through `CODE_SIGN_IDENTITY` and notarization.

## Customize

Open Quiet Clock or click the time on the widget to edit the appearance. Changes save automatically and refresh all clock widgets after a brief pause in adjustments.

Choose a font family, automatic or fixed clock size (8–240 pt), weight, spacing, left/center/right alignment, and automatic or custom text color. The preview switches between Small, Medium, and Large; Large is scaled down in the editor. To allocate more desktop height, right-click the widget and choose **Large**. The preview selector does not change its desktop size, and native widgets cannot grow dynamically. **Reset** saves defaults and removes shortcuts. Closing the editor preserves the latest edit.

The background is always transparent using the private implementation confirmed on macOS 27. There are no background controls. After upgrading an older installation, remove and re-add the widget once if its cached background persists. Select **Full-color** in System Settings → Desktop & Dock → Widgets to preserve your chosen text color. See [[architecture#Architecture#Transparent background]].

Under **Shortcuts**, choose **Add shortcut**, enter a website URL, and optionally set a label. Choose **Icon**, **Text**, or **Icon + text**, select any of the 3,291 bundled Simple Icons using search, and use the single **All link sizes** slider (8–32 pt) for every link. **Link spacing** adjusts the vertical gap between link rows (0–48 pt). **Divider brightness** adjusts the dotted line from hidden to full opacity (0–100%). Up/down buttons reorder links; the trash button removes one. Up to six links appear below a subtle dotted divider, each on its own row. Labels wrap without ellipsis; crowded groups shrink to fit. Clicking the time opens settings; empty space and the divider do not. Incomplete URLs stay saved as drafts, and bare hostnames use HTTPS. Click a link on the widget or use **Open** in the editor to launch the default browser. See [[architecture#Architecture#Shortcut links]].

WidgetKit can delay time updates, especially around sleep or system time changes. See [[architecture#Architecture#Scheduling]] and [Apple’s refresh guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Validate

Run the automated checks before testing the widget on the desktop. The signed sandbox check uses a disposable settings file and leaves your appearance unchanged.

```sh
bash scripts/test.sh
bash scripts/test-sandbox.sh
lat check
```

See [[tests#Validation]] for coverage and manual desktop checks. The build script also verifies the signed bundle and extension entry point.
