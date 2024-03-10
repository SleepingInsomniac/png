#!/bin/sh

URL="https://sleepinginsomniac.github.io/png/png-suite.tbz"
DEST="spec/fixtures"

mkdir -p tmp
if [ ! -f "tmp/png-suite.tbz" ]; then
  curl -sL $URL -o "tmp/png-suite.tbz"
fi
tar -xjf "tmp/png-suite.tbz" -C $DEST
[ -f "$DEST/png-suite/PngSuite.png" ] && rm "$DEST/png-suite/PngSuite.png"
