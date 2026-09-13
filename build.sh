#!/bin/bash
set -e

# $1 is the first argument (e.g., device codename like "veux")
# $2 is the second argument (e.g., "1" for clean build, "0" for incremental)
DEVICE=$1
CLEAN=$2

# Set defaults if no arguments are passed
DEVICE=${DEVICE:-"veux"}
CLEAN=${CLEAN:-"0"}

echo "=== Building for Device: $DEVICE ==="

# Optional clean build check
if [ "$CLEAN" == "1" ]; then
    echo "=== Performing Clean Build ==="
    make clean
fi

# Sync source using Crave's fast mirror
/opt/crave/resync.sh

# Build environment setup
source build/envsetup.sh
lunch lineage_${DEVICE}-ap4a-userdebug

# Run compilation
mka bacon -j$(nproc --all)

# Check if device tree exists
if [ ! -d "device/xiaomi/veux" ]; then
    echo "Device tree missing! Cloning manually..."
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_veux.git device/xiaomi/veux -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common.git device/xiaomi/sm6375-common --depth=1
    git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_sm6375.git kernel/xiaomi/sm6375 --depth=1
fi
