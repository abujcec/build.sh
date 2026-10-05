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

if [ ! -d "device/xiaomi/veux" ]; then
    echo "Device tree missing! Cloning manually..."
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_veux.git device/xiaomi/veux -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_device_xiaomi_sm6375-common.git device/xiaomi/sm6375-common --depth=1
    git clone https://github.com/LineageOS/android_hardware_xiaomi.git hardware/xiaomi -b lineage-23.2 --depth=1
    git clone https://github.com/xiaomi-sm6375-devs/android_kernel_xiaomi_sm6375.git kernel/xiaomi/sm6375 --depth=1
    sed -i 's/TARGET_KERNEL_CONFIG := veux_defconfig/TARGET_KERNEL_CONFIG := gki_defconfig vendor\/holi_GKI.config/' device/xiaomi/veux/BoardConfig.mk
fi

# Fix UprobeStats dependency chain everywhere
rm -rf packages/modules/UprobeStats
grep -rl "cts-statsd-atom-host-test-utils" --include="Android.bp" --exclude-dir=out --exclude-dir=.repo . 2>/dev/null | xargs --no-run-if-empty sed -i '/"cts-statsd-atom-host-test-utils"/d' || true
grep -rl "uprobestats" --include="Android.bp" --exclude-dir=out --exclude-dir=.repo . 2>/dev/null | xargs --no-run-if-empty sed -i '/"uprobestats/d' || true
grep -rl "libuprobestats_client" --include="Android.bp" --exclude-dir=out --exclude-dir=.repo . 2>/dev/null | xargs --no-run-if-empty sed -i '/"libuprobestats_client"/d' || true

# Fix SDK version 36 not available
grep -rl 'sdk_version.*36' --include="Android.bp" --exclude-dir=out --exclude-dir=.repo . 2>/dev/null | xargs --no-run-if-empty sed -i 's/sdk_version: "36"/sdk_version: "35"/g' || true

if [ ! -d "vendor/xiaomi/veux" ]; then
    echo "Getting vendor blobs..."
    wget --no-check-certificate "https://drive.usercontent.google.com/download?id=14gZlIb5q4BYgShBmo7F4G499x09Qs972&export=download&confirm=t" -O vendor.img
    sudo apt-get install -y e2fsprogs
    mkdir -p vendor_dump/vendor
    debugfs -R "rdump / vendor_dump/vendor" vendor.img
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/veux/extract-files.py vendor_dump || true
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/veux/extract-files.py -m || true
    PYTHONPATH=tools/extract-utils python3 device/xiaomi/sm6375-common/extract-files.py -m || true
    rm -f vendor.img
fi

# Safe fix - remove specific undefined lib lines from vendor
for lib in libQSEEComAPI libcdsprpc libsensorslog libGPTEE_vendor libfastcvopt libfastcvdsp_stub libscveCommon libscveCommon_stub libscveObjectTracker libscveObjectTracker_stub libscveObjectSegmentation libscveObjectSegmentation_stub libsnsapi libssc libsnsdiaglog libsns_fastRPC_util libbluetooth_audio_session_qti_2_1 libbluetooth_audio_session_qti libqmi_cci libqmi_common_so libqmi_encdec libdsprpc libadsprpc libvpphvx libvppclient libdataqmiservices libqmiservices libtime_genoff; do
    sed -i "/\"${lib}\"/d" vendor/xiaomi/veux/Android.bp || true
    sed -i "/\"${lib}\"/d" vendor/xiaomi/sm6375-common/Android.bp || true
done

# Fix all vendor.qti HAL references
for vlib in "vendor.qti.hardware.vpp@1.1" "vendor.qti.hardware.vpp@1.2" "vendor.qti.hardware.vpp@1.3" "vendor.qti.hardware.vpp@2.0"; do
    sed -i "/\"${vlib}\"/d" vendor/xiaomi/veux/Android.bp || true
    sed -i "/\"${vlib}\"/d" vendor/xiaomi/sm6375-common/Android.bp || true
done

export ALLOW_MISSING_DEPENDENCIES=true

source build/envsetup.sh
lunch lineage_${DEVICE}-ap4a-userdebug
mka bacon -j$(nproc --all)