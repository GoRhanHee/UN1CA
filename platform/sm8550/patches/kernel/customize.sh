LOG_STEP_IN "- Processing SM8550-Common Kernel by @GoRhanHee"

PDR="$(pwd)"
BOOT_IMG_URL="https://github.com/GoRhanHee/android_kernel_samsung_sm8550_common/releases/download/5.15.206/boot.img"
KERNELSU_MANAGER_APK="https://github.com/GoRhanHee/android_kernel_samsung_sm8550_common/releases/download/5.15.206/KernelSU_Next_v3.2.0-21-g5a4a7187_33150-release.apk"

REPLACE_KERNEL_BINARIES()
{
    echo "Downloading prebuilt boot.img..."
    mkdir -p "$WORK_DIR/kernel"
    
    # Download GoRhanHee Kernel
    DOWNLOAD_FILE "$BOOT_IMG_URL" "$WORK_DIR/kernel/boot.img"
}

ADD_MANAGER_APK_TO_PRELOAD()
{
    # https://github.com/tiann/KernelSU/issues/886
    local APK_PATH="system/preload/KernelSU-Next/com.rifsxd.ksunext-mesa==/base.apk"

    echo "Adding KernelSU-Next.apk to preload apps"
    mkdir -p "$WORK_DIR/system/$(dirname "$APK_PATH")"
    curl -L -s -o "$WORK_DIR/system/$APK_PATH" -z "$WORK_DIR/system/$APK_PATH" "$KERNELSU_MANAGER_APK"

    sed -i "/system\/preload/d" "$WORK_DIR/configs/fs_config-system" \
        && sed -i "/system\/preload/d" "$WORK_DIR/configs/file_context-system"
    while read -r i; do
        FILE="$(echo -n "$i"| sed "s.$WORK_DIR/system/..")"
        [ -d "$i" ] && echo "$FILE 0 0 755 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        [ -f "$i" ] && echo "$FILE 0 0 644 capabilities=0x0" >> "$WORK_DIR/configs/fs_config-system"
        FILE="$(echo -n "$FILE" | sed 's/\./\\./g')"
        echo "/$FILE u:object_r:system_file:s0" >> "$WORK_DIR/configs/file_context-system"
    done <<< "$(find "$WORK_DIR/system/system/preload")"

    rm -f "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    while read -r i; do
        FILE="$(echo "$i" | sed "s.$WORK_DIR/system..")"
        echo "$FILE" >> "$WORK_DIR/system/system/etc/vpl_apks_count_list.txt"
    done <<< "$(find "$WORK_DIR/system/system/preload" -name "*.apk" | sort)"
}

REPLACE_KERNEL_BINARIES
ADD_MANAGER_APK_TO_PRELOAD

unset PDR KERNEL_URL BOOT_EDITOR_URL KERNELSU_MANAGER_APK
