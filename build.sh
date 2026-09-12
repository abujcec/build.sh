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
lunch lineage_${DEVICE}-userdebug

# Run compilation
mka bacon -j$(nproc --all)
