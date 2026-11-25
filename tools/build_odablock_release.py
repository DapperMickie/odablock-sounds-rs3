"""Build a self-contained Odablock Sounds RS3 install ZIP."""

import argparse
import json
import re
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZIP_DEFLATED, ZipFile


PROJECT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT if (PROJECT / "plugin.json").is_file() else PROJECT / "odablock-sounds-rs3"
RUNTIME_FILES = ("plugin.json", "main.lua", "alerts.lua", "inline_emotes.lua", "emote_catalog.lua", "valuable_drops.lua")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=PROJECT / "dist")
    args = parser.parse_args()
    manifest = json.loads((SOURCE / "plugin.json").read_text(encoding="utf-8-sig"))
    manifest.get("urls", {}).pop("developerLog", None)
    manifest.get("optionalDependencies", {}).pop("prettyuiDev", None)
    version = manifest["version"]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError(f"Invalid release version: {version}")

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f"odablock-sounds-rs3-{version}.zip"
    with TemporaryDirectory(prefix="oda-release-", dir=output_dir) as directory:
        archive_path = Path(directory) / output.name
        with ZipFile(archive_path, "w", compression=ZIP_DEFLATED) as archive:
            for filename in RUNTIME_FILES:
                if filename == "plugin.json":
                    archive.writestr(filename, json.dumps(manifest, indent=2) + "\n")
                else:
                    archive.write(SOURCE / filename, filename)
            archive.write(SOURCE / "LICENSE", "LICENSE")
            for pattern in ("resources/*.ogg", "resources/emotes/*.png"):
                assets = sorted(SOURCE.glob(pattern))
                if not assets:
                    raise ValueError(f"No assets found matching {pattern}")
                for asset in assets:
                    archive.write(asset, asset.relative_to(SOURCE).as_posix())
        with ZipFile(archive_path) as archive:
            if archive.testzip() is not None:
                raise ValueError("Release ZIP failed its integrity check")
        archive_path.replace(output)
    print(output)


if __name__ == "__main__":
    main()
