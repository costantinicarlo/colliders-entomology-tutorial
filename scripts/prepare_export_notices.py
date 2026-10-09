from pathlib import Path
import shutil
import sys


def license_sources(repo_root):
    plugin_root = repo_root / ".obsidian/plugins/slides-extended"
    sources = {
        Path("CC-BY-4.0.txt"): repo_root / "LICENSE",
        Path("fieldnote-academic/LICENSE"):
            repo_root / "assets/fieldnote-academic/LICENSE",
    }
    for source in plugin_root.rglob("*"):
        if source.is_file() and source.name.upper().startswith(
                ("LICENSE", "NOTICE", "COPYING")):
            sources[Path("slides-extended") / source.relative_to(plugin_root)] = source
    return sources


def main():
    repo_root = Path(__file__).resolve().parents[1]
    export_root = (Path(sys.argv[1]) if len(sys.argv) > 1 else
                   repo_root / "export").resolve()
    pages = sorted(export_root.glob("*/index.html"))
    if not pages:
        raise SystemExit(f"No exported presentations found in {export_root}")

    sources = license_sources(repo_root)
    for page in pages:
        deck_root = page.parent
        shutil.copyfile(repo_root / "THIRD_PARTY_NOTICES.md",
                        deck_root / "THIRD_PARTY_NOTICES.md")
        for relative_path, source in sources.items():
            destination = deck_root / "LICENSES" / relative_path
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(source, destination)
        print(f"Prepared license notices: {deck_root}")


if __name__ == "__main__":
    main()