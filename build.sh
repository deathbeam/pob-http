#!/bin/sh

pobdir="pob"
srcdir="src"

# Clone PathOfBuilding
git clone --depth=1 https://github.com/PathOfBuildingCommunity/PathOfBuilding "$pobdir"

# Create links to files
ln -s $PWD/Server.lua pob/src/Server.lua
ln -s $PWD/Parser.lua pob/src/Parser.lua

# Switch to pob dir
cd "$pobdir"

# Unzip runtime
unzip runtime-win32.zip lua/xml.lua lua/base64.lua lua/sha1.lua
mv lua/*.lua "$srcdir"
rm -r lua
