#!/usr/bin/env bash
set -e

LUA=lua5.3
test -f /c/tools/ZeroBraneStudio/bin/lua53.exe && LUA=/c/tools/ZeroBraneStudio/bin/lua53.exe

(
set -e
cd GroundBranch/Content/GroundBranch/Lua
$LUA TestSuite.lua
)

STAGING=`mktemp -d`
UNINSTALL="$PWD/uninstall-gbgmc-files.cmd"

rm -f GBGMC.zip
./gbt pack GBGMC.json
NAME="$PWD/GBGMC.zip"

cd $STAGING
mv -v "$NAME" .
unzip -q *.zip

# Generate uninstall script
echo @echo Uninstalling GBGMC files > $UNINSTALL
echo @pause >> $UNINSTALL
zipinfo -1 *.zip |grep -v uninstall-gbgmc-files.cmd | sort | tr / '\\' | sed 's/^/del /' >> $UNINSTALL

(
echo ./GroundBranch/Content/GroundBranch/AI/Loadouts/MidEas/AK-Guy.kit
) | tr / '\\' | sed 's/^/del /' >> $UNINSTALL
(
echo ./GroundBranch/Content/GroundBranch/Lua/Common
echo ./GroundBranch/Content/GroundBranch/Lua/Objectives
echo ./GroundBranch/Content/GroundBranch/Lua/Players
echo ./GroundBranch/Content/GroundBranch/Lua/Spawns
echo ./GroundBranch/Content/GroundBranch/AI/Loadouts/EurAsi
echo ./GroundBranch/Content/GroundBranch/AI/Loadouts/MidEas
echo ./GroundBranch/Content/GroundBranch/AI/Loadouts/Narcos
) | tr / '\\' | sed 's/^/rd /' >> $UNINSTALL
echo @echo Done. >> $UNINSTALL
echo @pause >> $UNINSTALL
unix2dos $UNINSTALL

# Install mission files manually
if [[ "$1" != "--all" ]]
then
  find -name '*.mis' -delete
fi

cp -vur GroundBranch $HOME/.gb
cp -vur "$UNINSTALL" $HOME/.gb

rm -r $STAGING
