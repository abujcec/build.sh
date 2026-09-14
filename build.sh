#!/bin/bash
set -e

DEVICE=$1
CLEAN=$2
DEVICE=${DEVICE:-"veux"}
CLEAN=${CLEAN:-"0"}

echo "=== Building for Device: $DEVICE ==="

if [ "$CLEAN" == "1" ]; then
    echo "=== Performing Clean Build ==="
    make clean
fi

/opt/crave/resync.sh

# Check if device tree exists BEFORE building
if [ ! -d "device/xiaomi/veux" ]; then
    echo "Device tree missing! Cloning manually..."
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_veux.git device/xiaomi/veux -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common.git device/xiaomi/sm6375-common --depth=1
    git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_sm6375.git kernel/xiaomi/sm6375 --depth=1
fi

# Get vendor blobs
if [ ! -d "vendor/xiaomi/veux" ]; then
    echo "Getting vendor blobs..."
    mkdir -p vendor_dump/vendor
    wget --no-check-certificate "https://drive.google.com/uc?export=download&id=14gZlIb5q4BYgShBmo7F4G499x09Qs972" -O vendor.img
    sudo apt-get install -y e2fsprogs
    mkdir -p vendor_dump/vendor
    debugfs -R "rdump / vendor_dump/vendor" vendor.img
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/veux/extract-files.py vendor_dump
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/veux/extract-files.py -m
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/sm6375-common/extract-files.py -m
    rm -f vendor.img
fi

source build/envsetup.sh
lunch lineage_${DEVICE}-ap4a-userdebug
mka bacon -j$(nproc --all)
