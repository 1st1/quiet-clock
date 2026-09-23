# Architecture

Quiet Clock is an always-running macOS menu-bar app with a transparent desktop window. AppKit owns the window and SwiftUI renders the clock, links, and settings without WidgetKit or private background hooks.

## Clock appearance

The clock shows localized hours and minutes, configurable typography, text color, and optional shortcut links. Defaults use light rounded type, monospaced digits, and a subtle text shadow.

[ClockFace.swift](../Sources/Shared/ClockFace.swift) preserves left/center/right alignment, automatic or fixed 8–240 pt type, weight, tracking, and font fallback. Automatic line height fills available clock space; a fixed 8–240 pt row permits glyph overflow. Clock top/bottom and divider bottom padding range from −64–64 pt. Negative padding may overlap neighboring content. Identity transitions and disabled animations prevent digit fades.

## Appearance settings

The editor saves each change immediately and updates the desktop view directly. Existing appearance files retain their typography, layout, text color, and shortcuts. There is no preview or Apply button.

[ClockAppearance.swift](../Sources/Shared/ClockAppearance.swift) validates and atomically stores settings in the account’s Quiet Clock Application Support folder. [App.entitlements](../Sources/App.entitlements) grants sandboxed read/write access only to that folder. Invalid files produce an editor error; the clock falls back to defaults. Reset restores appearance defaults and removes links, preserving desktop placement.

## Transparent background

The desktop clock uses a clear, nonopaque, borderless AppKit panel with no window shadow. It bypasses WidgetKit’s host rendering and requires no private transparency APIs.

[DesktopClock.swift](../Sources/ClockApp/DesktopClock.swift) places the panel immediately above desktop icons and below normal application windows. It joins desktop Spaces, does not become the key/main window, and stays visible when the app deactivates. Native widget editing, gallery placement, and widget tinting do not apply. Full-screen apps can cover it.

Move mode temporarily draws a dashed outline and captures dragging; locking restores clock and link clicks. Width and height controls allow custom allocation. Position and size persist separately for each connected monitor group in app preferences. [DesktopPlacement.swift](../Sources/Shared/DesktopPlacement.swift) keys groups by sorted display UUIDs and stores offsets from the chosen monitor’s visible top-left corner. Rearranging monitors preserves that monitor-relative placement. Existing single-frame preferences seed the current group on upgrade; unseen groups start from an available clamped placement. [DesktopGeometry.swift](../Sources/Shared/DesktopGeometry.swift) keeps the frame within the chosen display after resolution changes. Display notifications settle briefly before restoring a profile; automatic window moves during reconfiguration do not overwrite the previous group. The panel can cover desktop icons within its bounds.

## Shortcut links

Up to six website links sit beneath the clock in its text color. Each has a URL, label, icon, display mode, and editable order. Shared typography controls set the link font family, weight, and 8–32 pt size.

[ClockShortcut.swift](../Sources/Shared/ClockShortcut.swift) accepts HTTP and HTTPS websites, adds HTTPS to bare hostnames, and rejects credentials and other schemes. Incomplete edits persist as drafts and stay off the clock until valid. Blank labels use the hostname. Stable unique IDs route clicks to the current saved URL; removed or unknown IDs do nothing.

Link labels have their own shared font family and weight, independent of the clock, using the same system designs, installed families, and font fallback. Text size and weight apply only to labels. Shared icon size (8–64 pt) and icon–text gap (0–32 pt, default 5 pt) are independently adjustable. Older files preserve their former link size for icons, including when text size is subsequently changed. Icons, text, and gaps scale together when rows must shrink to fit.

[ClockFace.swift](../Sources/Shared/ClockFace.swift) places each link on its own row, wrapping long labels without ellipsis. Links never share a row. The shared link-spacing control sets the vertical gap between rows from 0–48 pt, defaulting to 12 pt. A dotted divider appears only when valid links exist; its brightness control changes opacity from 0–100%, defaulting to 25%, while retaining the text color. Divider length ranges from 0–100% of the padded content width and follows the clock alignment; existing settings default to full width. Zero length or brightness hides the line without changing vertical layout. Clock text and link rows share the selected alignment, defaulting to center for older settings. If the links exceed their height budget, the complete group scales down until it fits rather than truncating labels. Each SwiftUI Link uses the registered quietclock scheme. [ShortcutEditor.swift](../Sources/ClockApp/ShortcutEditor.swift) handles that route and opens the saved address through the default HTTPS browser, rather than relying on the destination’s native-app association. The editor also has an explicit Open button. Icon-picker labels wrap without ellipsis.

The complete [Simple Icons 15.0.0 collection](../Resources/ServiceIcons/SOURCE.md) is bundled in the app: 3,291 monochrome SVGs, original titles, license, and disclaimer. The searchable picker matches service names and slugs, and uses a lazy grid. A bounded image cache loads only viewed icons; the clock never downloads icons or site content. The Website fallback uses a system globe symbol.

## Settings access

Clicking the time opens settings directly in the resident app. A menu-bar clock offers Settings, Move / Lock Clock, Reset Position, and Quit. Closing settings leaves the desktop clock running.

[QuietClockApp.swift](../Sources/ClockApp/QuietClockApp.swift) runs as an accessory app without a Dock icon. The settings window activates only on explicit access or manual app launch. The registered quietclock URL scheme remains supported. Empty clock space does not open settings; move mode must be disabled for time/link clicks.

## Scheduling

A single one-shot timer refreshes the clock at the next minute boundary. It is rescheduled from the current wall time each time, preventing accumulated drift; there is no network access or polling loop.

[ClockTime.swift](../Sources/Shared/ClockTime.swift) owns formatting and the next-minute calculation. [DesktopClock.swift](../Sources/ClockApp/DesktopClock.swift) stops the timer during sleep and refreshes on wake, system-clock, time-zone, and locale changes. The app must stay running; quitting removes the clock.

## Packaging

The build produces one signed, sandboxed macOS application with its bundled icon catalog. No extension, WidgetKit dependency, or private background hook ships in the bundle.

[build.sh](../scripts/build.sh) uses Apple’s Command Line Tools and removes obsolete extensions from an existing build directory. The deployment target is macOS 14. The editor aliases the State property wrapper for SDK 27 Command Line Tools compatibility. Local signing is ad hoc; distribution requires an appropriate identity and notarization.
