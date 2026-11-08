import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
(wheel,) = (root / "dist").glob("*.whl")
with zipfile.ZipFile(wheel) as archive:
    names = archive.namelist()
    required = {
        "flet_movable/movable.py",
        "flutter/flet_movable/lib/src/extension.dart",
        "flutter/flet_movable/lib/src/movable_surface.dart",
        "flutter/flet_movable/pubspec.yaml",
    }
    if not required.issubset(names):
        raise SystemExit("Wheel is missing extension sources")
    for name in names:
        if set(Path(name).parts) & {"build", ".dart_tool", "__pycache__", "test"}:
            raise SystemExit(f"Generated or test content in wheel: {name}")
        if name.endswith(
            (".apk", ".log", ".db", ".sqlite", "pubspec.lock", "pubspec_overrides.yaml")
        ):
            raise SystemExit(f"Unexpected wheel content: {name}")
print(f"Wheel contents passed: {wheel.name}")
