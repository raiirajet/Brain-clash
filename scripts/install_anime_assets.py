"""Install only the expected character files from the optional roster archive."""
from pathlib import Path
from zipfile import ZipFile

root = Path(__file__).resolve().parents[1]
archive = root / "BrainClash_Anime_Assets.zip"
names = ("luna", "kaito", "sora", "kai", "asuka", "rex", "goro", "nova", "titan")
paths = [f"assets/characters/{name}.webp" for name in names]
if archive.is_file():
    with ZipFile(archive) as z:
        data = {}
        for path in paths:
            info = z.getinfo(path)
            if not 0 < info.file_size <= 2_000_000:
                raise ValueError(f"Unexpected asset size: {path}")
            blob = z.read(info)
            if blob[:4] != b"RIFF" or blob[8:12] != b"WEBP":
                raise ValueError(f"Invalid WebP: {path}")
            data[path] = blob
        for path, blob in data.items():
            target = root / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(blob)
    print("Installed all nine anime character atlases.")
else:
    print("Anime archive not present; checking directly committed atlases.")
missing = [path for path in paths if not (root / path).is_file()]
if missing:
    raise SystemExit("Upload BrainClash_Anime_Assets.zip to the branch root or commit all nine atlases. Missing: " + ", ".join(missing))
