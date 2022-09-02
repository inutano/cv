#!/bin/sh
STYLE="american-medical-association-no-et-al"
cat "${1}" | while read doi; do
  curl -s -LH "Accept: text/x-bibliography; style=${STYLE}" "https://doi.org/${doi}" | \
    sed -e 's:^ *::g' | \
    tr -d '\n' | \
    awk '$0' | \
    sed -e 's:Ohta T:**Ohta T**:g'
  sleep 1
done
