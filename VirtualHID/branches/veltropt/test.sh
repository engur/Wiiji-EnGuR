#!/bin/bash
sudo cp -R build/Release/virtualhid.kext /tmp
sudo kextload /tmp/virtualhid.kext
kextstat
sleep 5
sudo kextunload /tmp/virtualhid.kext
