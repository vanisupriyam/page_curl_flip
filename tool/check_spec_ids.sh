#!/usr/bin/env bash
# Traceability gate between the QA spec and the test suite.
#
# Every case the spec marks [A] (automated) must exist as a test whose name
# carries the spec ID — so a claimed-but-missing test fails the build instead
# of surviving until a human audit (that is exactly how NAV-05 and TTS-13
# shipped falsely marked [A] once). Extend the list whenever the spec
# promotes a case to [A].
set -euo pipefail
cd "$(dirname "$0")/.."

ids=(
  NAV-05
  TTS-13
  SWP-10
  EDG-01 EDG-02 EDG-03 EDG-04 EDG-05 EDG-06 EDG-07 EDG-08
  ACC-01
  LAY-06
  TOC-07
)

missing=0
for id in "${ids[@]}"; do
  if ! grep -rq "$id" test/; then
    echo "MISSING spec-ID test: $id"
    missing=1
  fi
done

if [ "$missing" -eq 0 ]; then
  echo "traceability OK: all ${#ids[@]} spec-ID tests present"
fi
exit "$missing"
