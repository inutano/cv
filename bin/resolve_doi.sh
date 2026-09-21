#!/bin/sh
# Resolve a list of DOIs into Markdown list items for the CV publication sections.
#
#   bin/resolve_doi.sh data/publications_doi.txt
#
# Reads one DOI per line; blank lines and '#' comments (whole-line or trailing)
# are ignored.
# Prints one "1. ..." item per DOI, in input order, with the CV owner bolded.
set -eu

if [ $# -lt 1 ]; then
  echo "usage: $0 <doi-list-file>" >&2
  exit 1
fi

python3 - "$1" <<'PYTHON'
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

STYLE = "american-medical-association-no-et-al"
AUTHOR = "Ohta T"
UA = "cv-builder (https://github.com/inutano/cv; mailto:inutano@gmail.com)"


def fetch(url, accept):
    req = urllib.request.Request(url, headers={"Accept": accept, "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as res:
        return res.read().decode("utf-8")


def preprint_venue(doi):
    """CSL drops the server name for preprints; recover it from Crossref."""
    url = "https://api.crossref.org/works/" + urllib.parse.quote(doi, safe="")
    try:
        msg = json.loads(fetch(url, "application/json"))["message"]
    except (urllib.error.URLError, ValueError, KeyError):
        return None
    if msg.get("type") != "posted-content":
        return None
    for institution in msg.get("institution") or []:
        if institution.get("name"):
            return institution["name"]
    return msg.get("group-title") or None


def tidy(citation):
    text = re.sub(r"<i>(.*?)</i>", r"*\1*", citation, flags=re.S)
    text = re.sub(r"<[^>]+>", "", text)
    text = html.unescape(text)
    text = " ".join(text.split())
    text = re.sub(r"^\d+\.\s*", "", text)   # the style's own list number
    text = re.sub(r"^,\s*", "", text)       # unnamed leading (group) author
    text = re.sub(r"\.\s*,\s*ed\.\s*", ". ", text)  # empty editor slot
    return re.sub(r"\b%s\b" % re.escape(AUTHOR), "**%s**" % AUTHOR, text)


def main(path):
    with open(path, encoding="utf-8") as handle:
        dois = [ln.split("#", 1)[0].strip() for ln in handle]
    dois = [d for d in dois if d]

    failed = []
    for doi in dois:
        url = "https://doi.org/" + urllib.parse.quote(doi, safe="/")
        try:
            raw = fetch(url, "text/x-bibliography; style=%s" % STYLE)
        except urllib.error.URLError as err:
            failed.append("%s (%s)" % (doi, err))
            time.sleep(1)
            continue

        text = tidy(raw)
        if not text:
            failed.append("%s (empty citation)" % doi)
            time.sleep(1)
            continue

        venue = preprint_venue(doi)
        if venue and "*%s*" % venue not in text and "Published online" in text:
            text = text.replace("Published online", "*%s*. Published online" % venue, 1)

        print("1. " + text)
        sys.stdout.flush()
        time.sleep(1)

    for problem in failed:
        print("could not resolve: " + problem, file=sys.stderr)
    return 1 if failed else 0


sys.exit(main(sys.argv[1]))
PYTHON
