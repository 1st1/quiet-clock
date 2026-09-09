# Setup

Build and install Quiet Clock, then customize its native desktop widget. The project is available under the [MIT license](../LICENSE).

## Build and install

Building requires macOS 14 or later and Apple’s Command Line Tools. No third-party packages or network access are required.

```sh
bash scripts/build.sh
open "build/Quiet Clock.app"
```

For a permanent installation, copy the built app to your Applications folder and open that copy. Right-click the desktop → **Edit Widgets** → search **Quiet Clock** → add the small or medium widget. You can then quit the app; keep it installed so macOS can find its extension.

See [[architecture#Architecture#Packaging]] for signing and extension startup details. Distributable builds require an appropriate Apple signing identity through `CODE_SIGN_IDENTITY` and notarization.

## Customize

Open Quiet Clock or click its desktop widget to edit the appearance. Changes save automatically and refresh all clock widgets after a brief pause in adjustments.

Choose a font family, automatic or fixed size, weight, spacing, text color, and background color. The preview switches between small and medium sizes. **Reset** immediately saves the defaults. Closing the editor preserves the latest edit.

The system-background option does not provide true transparency on the tested macOS 15 desktop. To preserve chosen colors, select **Full-color** in System Settings → Desktop & Dock → Widgets. See [[architecture#Architecture#Appearance settings]] for background limitations and settings storage.

WidgetKit can delay time updates, especially around sleep or system time changes. See [[architecture#Architecture#Scheduling]] and [Apple’s refresh guidance](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).

## Validate

Run the automated checks before testing the widget on the desktop. The signed sandbox check uses a disposable settings file and leaves your appearance unchanged.

```sh
bash scripts/test.sh
bash scripts/test-sandbox.sh
lat check
```

See [[tests#Validation]] for coverage and manual desktop checks. The build script also verifies the signed bundle and extension entry point.
