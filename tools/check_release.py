import argparse
import re
import subprocess
import tomllib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACKAGE = "flet_movable/pyproject.toml"


def version_tuple(value):
    if not re.fullmatch(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)", value):
        raise ValueError("Use a major.minor.patch version")
    return tuple(map(int, value.split(".")))


def release_notes(changelog, version):
    match = re.search(r"(?m)^## " + re.escape(version) + r"\s*$", changelog)
    if not match:
        return ""
    return re.split(r"(?m)^## ", changelog[match.end() :], maxsplit=1)[0].strip()


def validate_release(current, previous, changelog, old_changelog=""):
    current_parts = version_tuple(current)
    previous_parts = version_tuple(previous) if previous else None
    if previous_parts and current_parts < previous_parts:
        raise ValueError("Version cannot decrease")
    changed = previous_parts is None or current_parts[:2] != previous_parts[:2]
    if changed:
        notes = release_notes(changelog, current)
        if len(re.findall(r"[A-Za-z0-9]+", notes)) < 5:
            raise ValueError(
                "Major/minor changes require release notes in CHANGELOG.md"
            )
        if previous and notes == release_notes(old_changelog, current):
            raise ValueError("Update release notes for the major/minor change")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--base", default="")
    parser.add_argument("--tag")
    parser.add_argument("--notes-output", type=Path)
    args = parser.parse_args()
    current = tomllib.loads((ROOT / PACKAGE).read_text())["project"]["version"]
    demo = tomllib.loads((ROOT / "pyproject.toml").read_text())["project"]["version"]
    dart = (ROOT / "flet_movable/src/flutter/flet_movable/pubspec.yaml").read_text()
    if demo != current or not re.search(
        r"(?m)^version: " + re.escape(current) + r"$", dart
    ):
        raise ValueError("Python, Flutter and demo versions must match")
    previous = None
    old_notes = ""
    if args.base and set(args.base) != {"0"}:
        previous_text = subprocess.check_output(
            ["git", "show", f"{args.base}:{PACKAGE}"], cwd=ROOT, text=True
        )
        previous = tomllib.loads(previous_text)["project"]["version"]
        old_notes = subprocess.check_output(
            ["git", "show", f"{args.base}:CHANGELOG.md"], cwd=ROOT, text=True
        )
    changelog = (ROOT / "CHANGELOG.md").read_text()
    validate_release(current, previous, changelog, old_notes)
    if args.tag and args.tag != f"v{current}":
        raise ValueError("Tag must match the package version")
    if args.notes_output:
        notes = release_notes(changelog, current)
        if not notes:
            raise ValueError("Tagged releases require release notes")
        args.notes_output.write_text(notes + "\n")
    print(f"Release policy passed: {current}")


if __name__ == "__main__":
    main()
