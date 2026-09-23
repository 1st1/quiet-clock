"""Validate the desktop agent and its bundled resources."""
import pathlib
import plistlib
import re
import subprocess
import sys

app = pathlib.Path(sys.argv[1])
info = plistlib.loads((app / "Contents/Info.plist").read_bytes())
assert info["LSUIElement"] is True
assert not (app / "Contents/PlugIns").exists(), "Obsolete widget extension must not ship"
binary = app / "Contents/MacOS" / info["CFBundleExecutable"]
libraries = subprocess.check_output(["otool", "-L", str(binary)], text=True)
assert "WidgetKit" not in libraries and "Chrono" not in libraries
print("Desktop agent bundle checks passed.")

# @lat: [[tests#Validation#Bundled service icons]]
import json
for bundle in [app]:
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
