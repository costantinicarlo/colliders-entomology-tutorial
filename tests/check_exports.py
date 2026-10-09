"""Check exported decks, including images in Reveal's embedded Markdown.

Run from the workspace root: python3 tests/check_exports.py
An optional export-directory argument supports checking a relocated copy.
"""
from html.parser import HTMLParser
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

repo_root = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(repo_root))
from scripts.prepare_export_notices import license_sources


class Resources(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = set()
        self.in_template = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if "src" in attrs:
            self.urls.add(attrs["src"])
        if tag == "link" and attrs.get("rel") == "stylesheet":
            self.urls.add(attrs["href"])
        if tag == "script" and attrs.get("type") == "text/template":
            self.in_template = True

    def handle_endtag(self, tag):
        if tag == "script":
            self.in_template = False

    def handle_data(self, data):
        # HTMLParser treats script contents as text, including the raw image
        # elements that Reveal later inserts into its slides.
        if self.in_template:
            fragment = Resources()
            fragment.feed(data)
            self.urls.update(fragment.urls)


export_root = (Path(sys.argv[1]) if len(sys.argv) > 1 else
               repo_root / "export").resolve()
pages = sorted(export_root.glob("*/index.html"))
assert pages, f"No exported presentations found in {export_root}"
required_licenses = license_sources(repo_root)

for page in pages:
    notice = page.parent / "THIRD_PARTY_NOTICES.md"
    assert notice.is_file(), f"{page.parent.name}: missing THIRD_PARTY_NOTICES.md"
    assert notice.read_bytes() == (repo_root / "THIRD_PARTY_NOTICES.md").read_bytes(), (
        f"{page.parent.name}: THIRD_PARTY_NOTICES.md is out of date"
    )
    for relative_path, source in required_licenses.items():
        bundled_license = page.parent / "LICENSES" / relative_path
        assert bundled_license.is_file(), (
            f"{page.parent.name}: missing license {bundled_license.relative_to(page.parent)}"
        )
        assert bundled_license.read_bytes() == source.read_bytes(), (
            f"{page.parent.name}: stale license {bundled_license.relative_to(page.parent)}"
        )

    html = page.read_text()
    resources = Resources()
    resources.feed(html)
    # Slides Extended leaves linked images in its Markdown templates until
    # Reveal renders them in the browser; an HTML-only check would miss them.
    resources.urls.update(re.findall(r"!\[[^\]]*\]\(([^)]+)\)", html))
    local_count = 0
    for url in sorted(resources.urls):
        parts = urlsplit(url)
        if parts.scheme or parts.netloc or not parts.path:
            continue
        path = unquote(parts.path)
        assert not path.startswith("/"), f"{page.name}: root-relative resource: {url}"
        target = (page.parent / path).resolve()
        assert target.is_relative_to(page.parent), f"{page.name}: resource outside deck: {url}"
        assert target.is_file(), f"{page.parent.name}: missing resource: {url}"
        local_count += 1
    print(f"PASS: {page.parent.name}: {local_count} local resources inside the exported deck")
