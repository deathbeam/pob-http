#!/bin/sh

SCRIPT=$(readlink -f "$0")
BASEDIR=$(dirname "$SCRIPT")
pobdir="$BASEDIR/pob"
srcdir="$pobdir/src"

# Clone PathOfBuilding
git clone --depth=1 https://github.com/PathOfBuildingCommunity/PathOfBuilding $pobdir

# Create links to files
ln -s $BASEDIR/src/Server.lua $srcdir/Server.lua
ln -s $BASEDIR/src/Parser.lua $srcdir/Parser.lua

# Switch to pob dir
cd $pobdir

# Unzip runtime
unzip runtime-win32.zip lua/xml.lua lua/base64.lua lua/sha1.lua
mv lua/*.lua src
rm -r lua
