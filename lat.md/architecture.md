# Architecture

Quiet Clock is an always-running macOS accessory app with a transparent desktop window. AppKit owns the window and SwiftUI renders the clock, links, and settings without WidgetKit or private background hooks.

## Why not WidgetKit

Quiet Clock uses its own desktop window because the native widget host did not reliably preserve a fully transparent, visually quiet clock during minute updates. An always-running app is an accepted tradeoff.

On the tested macOS 27 setup, the transparent WidgetKit clock repeatedly showed glass-like top and bottom borders as the time advanced. Disabling content animations and changing how time updates were delivered did not eliminate the effect. The exact system-rendering cause was not established; this is an observed limitation of our transparent widget, not a claim that all WidgetKit clocks behave this way.

Private widget descriptor hooks could remove the background, but depended on undocumented behavior and cached host configuration. They did not provide consistent border-free updates. WidgetKit also owns refresh scheduling and preset widget sizes, limiting direct control over updates and content-driven height.

The chosen AppKit panel owns its transparent surface and layout, bypassing that widget-host rendering path. Native widget-gallery integration is no longer a requirement; stable appearance takes priority. The app must remain running, manages its own placement, and uses a single minute-boundary timer. It no longer ships a widget extension or private transparency hooks. See [[architecture#Architecture#Transparent background]], [[architecture#Architecture#Scheduling]], and [[architecture#Architecture#Packaging]].

## Clock appearance

The clock shows localized hours and minutes, configurable typography, text color, and optional shortcut links. Defaults use light rounded type, monospaced digits, and a subtle text shadow.

[[Sources/Shared/ClockFace.swift#ClockFace#body|Clock layout]] preserves left/center/right alignment, automatic or fixed [[Sources/Shared/ClockAppearance.swift#ClockAppearance#clockSizeRange|8–240 pt type]], weight, tracking, and [[Sources/Shared/ClockFace.swift#ClockAppearance#typeface|font fallback]]. Automatic line height uses the font’s natural height; a fixed 8–240 pt row changes spacing independently and permits glyph overflow. Clock text never scales to fit a vertical allocation. Manual font sizes stay fixed; automatic size depends only on window width. Clock top/bottom and divider bottom padding use the [[Sources/Shared/ClockAppearance.swift#ClockAppearance#paddingRange|−64–64 pt range]]. Negative padding may overlap neighboring content. Identity transitions and disabled animations prevent digit fades.

## Appearance settings

The editor saves each change immediately and updates the desktop view directly. Existing appearance files retain their typography, layout, text color, and shortcuts. There is no preview or Apply button.

[[Sources/ClockApp/SettingsSlider.swift#SettingsSlider#body|The settings slider]] uses continuous native tracks with stepped value bindings, avoiding dense automatic tick marks on recent macOS versions. Existing increments and accessibility adjustments remain available.

[[Sources/Shared/ClockAppearance.swift#AppearanceStore#save|Appearance saving]] validates and atomically stores settings in the account’s Quiet Clock Application Support folder. [App.entitlements](../Sources/App.entitlements) grants sandboxed read/write access only to that folder. Invalid files produce an editor error; the clock falls back to defaults. Reset restores appearance defaults and removes links, preserving desktop placement.

## Transparent background

The desktop clock uses a clear, nonopaque, borderless AppKit panel with no window shadow. It bypasses WidgetKit’s host rendering and requires no private transparency APIs.

[[Sources/ClockApp/DesktopClock.swift#DesktopClockController#start|Desktop window setup]] places the panel immediately above desktop icons and below normal application windows. It joins desktop Spaces, does not become the key/main window, and stays visible when the app deactivates. Native widget editing, gallery placement, and widget tinting do not apply. Full-screen apps can cover it.

Move mode temporarily draws a dashed outline and captures dragging; locking restores link clicks. Width is adjustable; height follows the content and grows downward from the window’s top edge. Position and width persist separately for each connected monitor group in app preferences. [[Sources/Shared/DesktopPlacement.swift#DesktopPlacement#groupKey|Monitor-group identity]] uses sorted display UUIDs; [[Sources/Shared/DesktopPlacement.swift#DesktopPlacement|placement records]] store offsets from the chosen monitor’s visible top-left corner. Rearranging monitors preserves that monitor-relative placement. Existing single-frame preferences seed the current group on upgrade; unseen groups start from an available clamped placement. [[Sources/Shared/DesktopGeometry.swift#DesktopGeometry#fit|Frame fitting]] keeps the frame within the chosen display after resolution changes. Display notifications settle briefly before restoring a profile; automatic window moves during reconfiguration do not overwrite the previous group. The panel can cover desktop icons within its bounds.

## Desktop corner masks

Optional black masks create rounded wallpaper corners independently on each monitor. Preferences are disabled by default and keyed by stable display UUID, separate from clock appearance and monitor-group placement.

[[Sources/ClockApp/DesktopCornersController.swift#ClockPreferences|Preferences tabs]] separate Clock and Desktop Corners. [[Sources/ClockApp/DesktopCornersController.swift#DesktopCornersEditor|Corner controls]] list connected monitors with an enable switch and a [[Sources/Shared/DesktopCorners.swift#DesktopCornerSettings#radiusRange|1–200 pt radius]]. Changes apply immediately and [[Sources/Shared/DesktopCorners.swift#DesktopCornerStore#save|persist in app preferences]], retaining disconnected monitors’ settings for reconnection. New monitors use the [[Sources/Shared/DesktopCorners.swift#DesktopCornerSettings#radius|17 pt default radius]]; saved radii are preserved. Clock Reset does not change corner preferences.

[[Sources/ClockApp/DesktopCornersController.swift#DesktopCornersController#reconcile|Window reconciliation]] maintains four small borderless, shadowless, nonactivating panels per enabled display and closes them when disabled or disconnected. Panels ignore mouse events, join desktop Spaces, and sit above desktop icons but below ordinary windows, the menu bar, and Dock. They mask wallpaper rather than rounding foreground applications; quitting removes them. Disabled displays allocate no panels, and there is no timer or polling loop for corners.

[[Sources/Shared/DesktopCorners.swift#DesktopCorner#frame|Corner geometry]] uses full screen bounds, including negative desktop coordinates, and clamps the radius to half the smaller display dimension. [[Sources/Shared/DesktopCorners.swift#DesktopCorner#mask|Mask paths]] subtract an inward-facing quarter-circle from each corner square; [[Sources/ClockApp/DesktopCornersController.swift#CornerMaskView#draw|AppKit drawing]] fills the remaining area black with a transparent interior. Screen-configuration and wake notifications refresh positions and restore per-display settings.

## Shortcut links

Up to six website links sit beneath the clock in its text color. Each has a URL, label, icon, display mode, and editable order. Shared typography controls set the link font family, weight, and 8–32 pt size.

[[Sources/Shared/ClockShortcut.swift#ClockShortcut#destination|Shortcut URL validation]] accepts HTTP and HTTPS websites, adds HTTPS to bare hostnames, and rejects credentials and other schemes. Incomplete edits persist as drafts and stay off the clock until valid. Blank labels use the hostname. Stable unique IDs route clicks to the current saved URL; removed or unknown IDs do nothing.

Link labels have their own shared font family and weight, independent of the clock, using the same system designs, installed families, and font fallback. Text size and weight apply only to labels. Shared icon size (8–64 pt) and icon–text gap (0–32 pt, default 5 pt) are independently adjustable. Older files preserve their former link size for icons, including when text size is subsequently changed. Icons, text, and gaps retain their selected sizes; wrapped rows increase the window height.

[[Sources/Shared/ClockFace.swift#ClockFace#body|Clock layout]] places each link on its own row, wrapping long labels without ellipsis. Links never share a row. The shared link-spacing control sets the vertical gap between rows from 0–48 pt, defaulting to 12 pt. A dotted divider appears only when valid links exist and Show divider is enabled (the default for older files). Turning it off removes the line and its padding, while preserving length, brightness, and padding preferences for re-enabling; its brightness control changes opacity from 0–100%, defaulting to 25%, while retaining the text color. Divider length ranges from 0–100% of the padded content width and follows the clock alignment; existing settings default to full width. Zero length or brightness hides the line without changing vertical layout. Clock text and link rows share the selected alignment, defaulting to center for older settings. Links have no fixed height budget or scale-to-fit pass. [[Sources/ClockApp/DesktopClock.swift#DesktopClockController#measureContent|Content measurement]] supplies the natural height to [[Sources/ClockApp/DesktopClock.swift#DesktopClockController#fitContentHeight|window height fitting]]; changes to fonts, wrapping, spacing, or divider visibility resize it without animations. Large manual clock fonts can exceed the selected width; increase width to accommodate them. Content taller than the display can extend below its edge instead of shrinking. The nonactivating desktop panel retains the normal arrow cursor over links. SwiftUI cursor styling and active-always AppKit tracking did not produce a visible hand on the current macOS setup; no cursor workaround or hover-triggered app activation is used. Each SwiftUI Link uses the registered quietclock scheme. [[Sources/ClockApp/ShortcutEditor.swift#BrowserLauncher#handle|Shortcut routing]] resolves the saved link, and [[Sources/ClockApp/ShortcutEditor.swift#BrowserLauncher#open|browser handoff]] opens its address through the default HTTPS browser, rather than relying on the destination’s native-app association. The editor also has an explicit Open button. Icon-picker labels wrap without ellipsis.

The complete [Simple Icons 15.0.0 collection](../Resources/ServiceIcons/SOURCE.md) is bundled in the app: 3,291 monochrome SVGs, original titles, license, and disclaimer. The [[Sources/ClockApp/ShortcutEditor.swift#IconPicker|searchable picker]] matches service names and slugs from the [[Sources/Shared/ClockShortcut.swift#ServiceIcon#all|bundled catalog]], and uses a lazy grid. The [[Sources/Shared/ClockFace.swift#ServiceIconView#images|bounded image cache]] loads only viewed icons; the clock never downloads icons or site content. The Website fallback uses a system globe symbol.

## Settings access

Right-click or Control-click anywhere in the clock window for Move Clock / Lock Position, Settings, and Quit. The time label has no click action. Closing settings leaves the desktop clock running.

[[Sources/ClockApp/QuietClockApp.swift#QuietClockApp#main|Application startup]] selects accessory mode without Dock or menu-bar icons. Reopening the app from Applications opens settings. [[Sources/ClockApp/DesktopClock.swift#DesktopPanel#sendEvent|Panel event dispatch]] handles context clicks before child views, including shortcut links and the drag surface. [[Sources/ClockApp/QuietClockApp.swift#ClockApplicationDelegate#showSettings|Settings presentation]] activates the window only on explicit access or manual app launch. The registered quietclock URL scheme remains supported. Left-clicking the time or empty space does nothing. Move mode disables shortcut clicks but retains the context menu; Reset Position remains in settings.

## Scheduling

A single one-shot timer refreshes the clock at the next minute boundary. It is rescheduled from the current wall time each time, preventing accumulated drift; there is no network access or polling loop.

[[Sources/Shared/ClockTime.swift#ClockTime#format|Time formatting]] controls the clock label, and [[Sources/Shared/ClockTime.swift#ClockTime#nextMinute|minute scheduling]] calculates the next boundary. [[Sources/ClockApp/DesktopClock.swift#DesktopClockController#sleep|Sleep handling]] stops the timer; [[Sources/ClockApp/DesktopClock.swift#DesktopClockController#refresh|refresh handling]] updates the date and reschedules on wake, system-clock, time-zone, and locale changes. The app must stay running; quitting removes the clock.

## Packaging

The build produces one signed, sandboxed macOS application with its bundled icon catalog. No extension, WidgetKit dependency, or private background hook ships in the bundle.

[build.sh](../scripts/build.sh) uses Apple’s Command Line Tools and removes obsolete extensions from an existing build directory. The deployment target is macOS 14. The editor aliases the State property wrapper for SDK 27 Command Line Tools compatibility. Local signing is ad hoc; distribution requires an appropriate identity and notarization.
