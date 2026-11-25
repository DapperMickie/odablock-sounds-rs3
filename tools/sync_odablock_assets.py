"""Download Ogg Vorbis and PNG assets from the public Odablock Sounds RS3 branches."""

import argparse
from concurrent.futures import ThreadPoolExecutor
import hashlib
import json
from pathlib import Path
import re
from tempfile import TemporaryDirectory
from urllib.parse import quote
from urllib.request import urlopen


PROJECT = Path(__file__).resolve().parents[1]
REPOSITORY = "DapperMickie/odablock-sounds-rs3"
UPSTREAM = f"https://raw.githubusercontent.com/{REPOSITORY}/"
MAX_ASSET_BYTES = 64 * 1024 * 1024
PNG_HEADER = b"\x89PNG\r\n\x1a\n"


def fetch(branch, name):
    with urlopen(UPSTREAM + branch + "/" + quote(name), timeout=20) as response:
        data = response.read(MAX_ASSET_BYTES + 1)
    if len(data) > MAX_ASSET_BYTES:
        raise ValueError(f"Asset exceeds 64 MB: {name}")
    return data


def manifest(branch):
    data = json.loads(fetch(branch, branch + ".json"))
    if type(data["version"]) is not int or data["version"] < 1:
        raise ValueError(f"Invalid {branch} data version")
    return data


def download(branch, filename, checksum, destination):
    content = fetch(branch, filename)
    if hashlib.sha256(content).hexdigest() != checksum:
        raise ValueError(f"Checksum mismatch: {filename}")
    if branch == "sounds":
        if not content.startswith(b"OggS") or b"\x01vorbis" not in content[:4096]:
            raise ValueError(f"Invalid Ogg Vorbis: {filename}")
    else:
        if content[:8] != PNG_HEADER or len(content) < 33 or content[12:16] != b"IHDR":
            raise ValueError(f"Invalid PNG: {filename}")
        width = int.from_bytes(content[16:20], "big")
        height = int.from_bytes(content[20:24], "big")
        if not 1 <= width <= 1024 or not 1 <= height <= 1024:
            raise ValueError(f"Unsupported PNG size: {filename}")
    destination.write_bytes(content)


def install(staging, target):
    for source in sorted(staging.rglob("*")):
        if source.is_file():
            destination = target / source.relative_to(staging)
            destination.parent.mkdir(parents=True, exist_ok=True)
            temporary = destination.with_name(destination.name + ".oda-sync")
            temporary.write_bytes(source.read_bytes())
            temporary.replace(destination)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    default_target = PROJECT if (PROJECT / "plugin.json").is_file() else PROJECT / "odablock-sounds-rs3"
    parser.add_argument("--target", type=Path, default=default_target)
    parser.add_argument("--force", action="store_true")
    args = parser.parse_args()
    target = args.target.resolve()
    plugin = json.loads((target / "plugin.json").read_text(encoding="utf-8-sig"))
    if plugin["name"] != "Odablock Sounds RS3":
        raise ValueError("Target is not the Odablock Sounds RS3 plugin")

    packs = {branch: manifest(branch) for branch in ("sounds", "emotes")}
    versions = {"source": REPOSITORY, **{branch: pack["version"] for branch, pack in packs.items()}}
    version_file = target.parent / f".{target.name}-asset-versions.json"
    current = json.loads(version_file.read_text()) if version_file.exists() else {}
    if current.get("source") != REPOSITORY:
        current = {}

    jobs = []
    catalog = ["return {"]
    seen_triggers = set()
    with TemporaryDirectory(prefix="oda-assets-") as directory:
        staging = Path(directory)
        for branch, pack in packs.items():
            seen_files = set()
            for entry in pack[branch]:
                filename, digest = entry["file"], entry["sha256"]
                extension = "ogg" if branch == "sounds" else "png"
                if not re.fullmatch(r"[a-zA-Z0-9_-]+\." + extension, filename) or filename in seen_files:
                    raise ValueError(f"Invalid or duplicate asset name: {filename}")
                if not re.fullmatch(r"[a-f0-9]{64}", digest):
                    raise ValueError(f"Invalid checksum: {filename}")
                seen_files.add(filename)
                relative = Path("resources") / filename
                if branch == "emotes":
                    relative = Path("resources", "emotes", filename)
                    triggers = [entry["trigger"], *entry.get("altTriggers", [])]
                    for trigger in triggers:
                        if not re.fullmatch(r"[a-zA-Z0-9_():-]+", trigger) or trigger.lower() in seen_triggers:
                            raise ValueError(f"Invalid or duplicate emote trigger: {trigger}")
                        seen_triggers.add(trigger.lower())
                    values = [Path(filename).stem, *(trigger.lower() for trigger in triggers)]
                    catalog.append("    { " + ", ".join(json.dumps(value) for value in values) + " },")
                if args.force or current.get(branch) != pack["version"] or not (target / relative).is_file():
                    jobs.append((branch, filename, digest, staging / relative))
            if not seen_files:
                raise ValueError(f"Empty {branch} catalog")
        catalog.append("}")
        contents = "\n".join(catalog) + "\n"
        current_catalog = target / "emote_catalog.lua"
        if not current_catalog.exists() or current_catalog.read_text(encoding="utf-8") != contents:
            (staging / "emote_catalog.lua").write_text(contents, encoding="utf-8")
        for _, _, _, destination in jobs:
            destination.parent.mkdir(parents=True, exist_ok=True)
        with ThreadPoolExecutor(max_workers=8) as pool:
            pending = [pool.submit(download, *job) for job in jobs]
            for job in pending:
                job.result()
        install(staging, target)
    version_file.write_text(json.dumps(versions) + "\n", encoding="utf-8")
    print(f"Sounds v{versions['sounds']}, emotes v{versions['emotes']}: {len(jobs)} assets downloaded")


if __name__ == "__main__":
    main()
