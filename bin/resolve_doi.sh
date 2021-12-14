#!/bin/sh
STYLE="american-medical-association-no-et-al"
cat "${1}" | while read doi; do
  curl -s -LH "Accept: text/x-bibliography; style=${STYLE}" "https://doi.org/${doi}"
  sleep 1
done
