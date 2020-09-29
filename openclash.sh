#!/bin/bash
if [ -d "OpenClash" ]; then
    git pull
else
    git clone https://github.com/vernesong/OpenClash.git -b master
fi
cd OpenClash
rm -rf ../package/lean/luci-app-openclash
cp -r luci-app-openclash ../package/lean/
cd ..