#!/usr/bin/env bash

# Copyleft by Timothy Redaelli
# Based on XDA thread: https://forum.xda-developers.com/lg-g5/development/locationmanagerserviceex-wakelock-fix-t3568982

SMALI_VER=2.2.2

set -euo pipefail

wget -nv -c -P tools https://bitbucket.org/JesusFreke/smali/downloads/{bak,}smali-$SMALI_VER.jar
wget -nv -c -P tools https://github.com/ehem/kdztools/archive/master.zip

unzip -o tools/master.zip -d tools/

export PATH="$PWD/tools/kdztools-master:$PATH"

smali() { java -jar "tools/smali-$SMALI_VER.jar" "$@" ; }
baksmali() { java -jar "tools/baksmali-$SMALI_VER.jar"  "$@" ; }

rm -rf tmp
echo "Extracting DZ from KDZ..."
unkdz.py -f "$1" -x -d tmp

echo "Extracting system image from DZ..."
system_slice=$(undz.py -f tmp/*.dz -l | awk -F / '/ system_[0-9]*.bin /{ print $1 ; exit }')
undz.py -f tmp/*.dz -s "$system_slice" -d tmp

echo "Extracting the needed (ODEX) files from system image..."
7z x -otmp/system tmp/system.image framework/oat/arm64/services.odex framework/arm64

echo "Deodex services.odex..."
baksmali deodex tmp/system/framework/oat/arm64/services.odex -d tmp/system/framework/arm64 -o tmp/system.deodex/

echo "Patching the wakelock..."
awk '
	/^\.method private sendIntent\(Landroid\/app\/PendingIntent;Landroid\/content\/Intent;\)V$/ { found=1 }
	/^\s*:goto_10$/ {
		if (found)
			print "    invoke-direct {p0}, Lcom/android/server/LocationManagerServiceEx;->releaseWakeLock()V"
			found=0
		}
	{ print }
' tmp/system.deodex/com/android/server/LocationManagerServiceEx.smali > tmp/system.deodex/com/android/server/LocationManagerServiceEx.smali.new
mv tmp/system.deodex/com/android/server/LocationManagerServiceEx.smali{.new,}

echo "Create the patched and deodex services.jar..."
smali as tmp/system.deodex -o tmp/classes.dex
zip -9j tmp/services.jar tmp/classes.dex

echo "Create the Magisk™ zip file..."
cp -r magisk_template tmp/LocationManagerServiceExWakelockFix
mv tmp/services.jar tmp/LocationManagerServiceExWakelockFix/system/framework/
pushd tmp/LocationManagerServiceExWakelockFix
zip -9r "$OLDPWD/LocationManagerServiceExWakelockFix.zip" .
popd
rm -rf tmp

echo "Flash or load the Magisk™ module LocationManagerServiceExWakelockFix.zip"
