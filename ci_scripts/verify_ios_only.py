#!/usr/bin/env python3
"""Reject an iOS archive or IPA that accidentally embeds Apple Watch support."""
import json
import plistlib
import sys
import zipfile
from pathlib import Path


def verify(source):
    problems = []
    bundles = []

    def inspect(name, read):
        path = Path(name)
        if any(part.lower() == "watch" or "watchkit" in part.lower() for part in path.parts):
            problems.append(name)
        if path.name != "Info.plist":
            return
        info = plistlib.loads(read())
        platforms = info.get("CFBundleSupportedPlatforms", [])
        if (any(key.startswith("WK") for key in info)
                or 4 in info.get("UIDeviceFamily", [])
                or any("watch" in platform.lower() for platform in platforms)):
            problems.append(name + ": watchOS bundle metadata")
        if info.get("CFBundleExecutable"):
            bundles.append({"bundle": info.get("CFBundleIdentifier"),
                            "build": info.get("CFBundleVersion"), "platforms": platforms})

    if source.is_dir():
        for path in source.rglob("*"):
            inspect(str(path.relative_to(source)), path.read_bytes)
    else:
        with zipfile.ZipFile(source) as archive:
            for name in archive.namelist():
                inspect(name, lambda name=name: archive.read(name))
    if not any(row["bundle"] == "app.portionnote.food" for row in bundles):
        problems.append("CherrySunny app bundle is missing")
    print(json.dumps({"bundles": bundles, "watch_support_detected": bool(problems),
                      "problems": problems}, indent=2))
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(verify(Path(sys.argv[1])))
