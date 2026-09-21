#!/bin/sh
# Check the CV for the mistakes that creep in when entries are added by hand.
#
#   bin/check_cv.sh
#
# Fails if a DOI is listed twice, if a DOI list disagrees with what the CV
# shows, or if the two language versions have drifted apart.
set -eu

cd "$(dirname "$0")/.."

python3 - <<'PYTHON'
import collections
import pathlib
import re
import sys

PAIRS = [("## 査読付き論文", "## Publications (Peer-reviewed)"), ("## プレプリント", "## Preprints")]
LISTS = [("data/publications_doi.txt", 0), ("data/preprints_doi.txt", 1)]
problems = []


def section(path, heading):
    lines = pathlib.Path(path).read_text(encoding="utf-8").splitlines()
    start = lines.index(heading)
    end = next(i for i in range(start + 1, len(lines)) if lines[i].startswith("## "))
    return [ln for ln in lines[start + 1 : end] if ln.startswith("1. ")]


def dois(items):
    return [it.rsplit("doi:", 1)[1].strip().rstrip(".").lower() for it in items]


def read_list(path):
    out = []
    for line in pathlib.Path(path).read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            out.append(line.lower())
    return out


for path in ("docs/cv.md", "docs/cv_en.md"):
    found = [d.rstrip(".").lower() for d in re.findall(r"doi:(\S+)", pathlib.Path(path).read_text(encoding="utf-8"))]
    for doi, count in collections.Counter(found).items():
        if count > 1:
            problems.append("%s lists %s %d times" % (path, doi, count))

for ja_head, en_head in PAIRS:
    ja, en = section("docs/cv.md", ja_head), section("docs/cv_en.md", en_head)
    if ja != en:
        problems.append("%s and %s have drifted apart" % (ja_head, en_head))

for path, index in LISTS:
    listed = read_list(path)
    shown = dois(section("docs/cv.md", PAIRS[index][0]))
    for doi in listed:
        if doi not in shown:
            problems.append("%s has %s but the CV does not show it" % (path, doi))
    for doi in shown:
        if doi not in listed:
            problems.append("the CV shows %s but %s does not list it" % (doi, path))

for path in ("data/publications_doi.txt", "data/preprints_doi.txt", "data/excluded_doi.txt"):
    for doi, count in collections.Counter(read_list(path)).items():
        if count > 1:
            problems.append("%s lists %s %d times" % (path, doi, count))

for problem in problems:
    print(problem)
print("%d problem(s)" % len(problems))
sys.exit(1 if problems else 0)
PYTHON
