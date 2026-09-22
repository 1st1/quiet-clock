"""Reject bundles that compile but exit before serving WidgetKit requests."""
import pathlib
import plistlib
import re
import subprocess
import sys

app = pathlib.Path(sys.argv[1])
extension = app / "Contents/PlugIns/QuietClockWidget.appex"
info = plistlib.loads((extension / "Contents/Info.plist").read_bytes())
assert info["NSExtension"]["NSExtensionPointIdentifier"] == "com.apple.widgetkit-extension"
binary = extension / "Contents/MacOS" / info["CFBundleExecutable"]
commands = subprocess.check_output(["otool", "-l", str(binary)], text=True)
entry_offset = int(re.search(r"cmd LC_MAIN\s+cmdsize \d+\s+entryoff (\d+)", commands)[1])
text_segment = re.search(r"segname __TEXT\s+vmaddr (0x[0-9a-f]+)\s+vmsize \S+\s+fileoff (\d+)", commands)
entry_address = int(text_segment[1], 16) + entry_offset - int(text_segment[2])
indirect = subprocess.check_output(["otool", "-Iv", str(binary)], text=True)
extension_stubs = [int(value, 16) for value in re.findall(r"^(0x[0-9a-f]+)\s+\d+\s+_NSExtensionMain$", indirect, re.M)]
assert entry_address in extension_stubs, "Widget must launch through NSExtensionMain, not Swift main"
print("Widget bundle and extension entry point checks passed.")

# @lat: [[tests#Validation#Bundled service icons]]
import json
for bundle in [app, extension]:
    resources = bundle / "Contents/Resources/ServiceIcons"
    catalog = json.loads((resources / "catalog.json").read_text())
    assert len(catalog) == 3291
    assert {"linear", "github", "x"} <= {icon["id"] for icon in catalog}
    for icon in catalog:
        assert (resources / (icon["id"] + ".svg")).is_file(), icon
    assert (resources / "LICENSE.md").is_file()
app_info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
assert "quietclock" in app_info["CFBundleURLTypes"][0]["CFBundleURLSchemes"]
print("Complete icon catalogs and shortcut URL registration passed.")
