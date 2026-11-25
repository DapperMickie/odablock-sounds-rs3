"""Build a self-contained Odablock Sounds RS3 install ZIP."""

import argparse
import json
import re
import shutil
import subprocess
import sys
from pathlib import Path
from tempfile import TemporaryDirectory
from zipfile import ZIP_DEFLATED, ZipFile


PROJECT = Path(__file__).resolve().parent.parent
SOURCE = PROJECT if (PROJECT / "plugin.json").is_file() else PROJECT / "odablock-sounds-rs3"
RUNTIME_FILES = ("plugin.json", "main.lua", "alerts.lua", "inline_emotes.lua")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=PROJECT / "dist")
    args = parser.parse_args()
    manifest = json.loads((SOURCE / "plugin.json").read_text(encoding="utf-8-sig"))
    version = manifest["version"]
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError(f"Invalid release version: {version}")

    output_dir = args.output_dir.resolve()
    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f"odablock-sounds-rs3-{version}.zip"
    with TemporaryDirectory(prefix="oda-release-", dir=output_dir) as directory:
        staging = Path(directory) / "plugin"
        staging.mkdir()
        for filename in RUNTIME_FILES:
            shutil.copy2(SOURCE / filename, staging)
        license_file = PROJECT / "LICENSE"
        if not license_file.is_file():
            raise FileNotFoundError("Run this builder from the published plugin source with its LICENSE")
        shutil.copy2(license_file, staging)
        subprocess.run(
            [sys.executable, str(PROJECT / "tools" / "sync_odablock_assets.py"), "--target", str(staging)],
            check=True,
        )
        archive_path = Path(directory) / output.name
        with ZipFile(archive_path, "w", compression=ZIP_DEFLATED) as archive:
            for file in sorted(staging.rglob("*")):
                if file.is_file():
                    archive.write(file, file.relative_to(staging).as_posix())
        with ZipFile(archive_path) as archive:
            if archive.testzip() is not None:
                raise ValueError("Release ZIP failed its integrity check")
        archive_path.replace(output)
    print(output)


if __name__ == "__main__":
    main()
