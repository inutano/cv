#!/bin/sh
# Report ORCID works that are not yet classified in data/*_doi.txt.
#
#   bin/orcid_sync.sh [orcid-id]
#
# Read-only: it never edits the DOI lists, it only says what is missing so the
# DOI can be appended to publications_doi.txt, preprints_doi.txt or
# excluded_doi.txt by hand.
set -eu

ORCID="${1:-0000-0003-3777-5945}"
DATA_DIR="$(cd "$(dirname "$0")/../data" && pwd)"

python3 - "$ORCID" "$DATA_DIR" <<'PYTHON'
import json
import sys
import urllib.error
import urllib.request
from collections import OrderedDict

ORCID, DATA_DIR = sys.argv[1], sys.argv[2]
UA = "cv-builder (https://github.com/inutano/cv; mailto:inutano@gmail.com)"
LISTS = OrderedDict(
    [
        ("publications", "publications_doi.txt"),
        ("preprints", "preprints_doi.txt"),
        ("excluded", "excluded_doi.txt"),
    ]
)


def load(filename):
    """DOIs are compared case-insensitively; DOIs are not case-sensitive."""
    path = "%s/%s" % (DATA_DIR, filename)
    dois = []
    try:
        with open(path, encoding="utf-8") as handle:
            for line in handle:
                line = line.split("#", 1)[0].strip()
                if line:
                    dois.append(line.lower())
    except FileNotFoundError:
        pass
    return dois


def works(orcid):
    url = "https://pub.orcid.org/v3.0/%s/works" % orcid
    req = urllib.request.Request(url, headers={"Accept": "application/json", "User-Agent": UA})
    with urllib.request.urlopen(req, timeout=60) as res:
        return json.loads(res.read().decode("utf-8"))["group"]


def summarize(group):
    summary = group["work-summary"][0]
    ids = {
        e["external-id-type"].lower(): e["external-id-value"]
        for e in group["external-ids"]["external-id"]
    }
    date = summary.get("publication-date") or {}
    year = (date.get("year") or {}).get("value") or "????"
    return {
        "doi": ids.get("doi", ""),
        "type": summary.get("type") or "unknown",
        "year": year,
        "title": summary["title"]["title"]["value"],
    }


def main():
    try:
        groups = works(ORCID)
    except urllib.error.URLError as err:
        print("failed to reach the ORCID API: %s" % err, file=sys.stderr)
        return 1

    known = {name: load(filename) for name, filename in LISTS.items()}
    classified = {doi for dois in known.values() for doi in dois}

    for name, dois in known.items():
        seen = set()
        for doi in dois:
            if doi in seen:
                print("duplicate in %s: %s" % (LISTS[name], doi))
            seen.add(doi)

    records = [summarize(g) for g in groups]
    records.sort(key=lambda r: r["year"], reverse=True)

    new = [r for r in records if r["doi"] and r["doi"].lower() not in classified]
    print("## unclassified (%d)" % len(new))
    for record in new:
        print("%s  %-16s %s" % (record["year"], record["type"], record["doi"]))
        print("    %s" % record["title"])

    no_doi = [r for r in records if not r["doi"]]
    print()
    print("## no DOI in ORCID, needs a manual decision (%d)" % len(no_doi))
    for record in no_doi:
        print("%s  %-16s %s" % (record["year"], record["type"], record["title"]))

    in_orcid = {r["doi"].lower() for r in records if r["doi"]}
    missing = [d for d in classified if d not in in_orcid]
    print()
    print("## in the local lists but not in ORCID (%d)" % len(missing))
    for doi in sorted(missing):
        print("  %s" % doi)
    return 0


sys.exit(main())
PYTHON
