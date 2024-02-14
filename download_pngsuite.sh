#!/bin/sh

URL="http://www.schaik.com/pngsuite2011/PngSuite-2017jul19.tgz"
DEST="spec/fixtures"

mkdir -p tmp
curl -L $URL -o tmp/png-suite.tgz
mkdir -p "$DEST/png-suite"
tar -xzf tmp/suit.tgz -C "$DEST/png-suite"
rm tmp/png-suite.tgz
rm "$DEST/png-suite/PngSuite.png"
