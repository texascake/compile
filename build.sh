#!/usr/bin/env bash
#
# Copyright (C) 2023 Kneba <abenkenary3@gmail.com>
#

#
# Function to show an informational message
#

msg() {
	echo
    echo -e "\e[1;32m$*\e[0m"
    echo
}

err() {
    echo -e "\e[1;41m$*\e[0m"
}

cdir() {
	cd "$1" 2>/dev/null || \
		err "The directory $1 doesn't exists !"
}

# Main
MainPath="$(pwd)"
MainClangPath="${MainPath}/clang"
MainClangZipPath="${MainPath}/clang-zip"
ClangPath="${MainClangZipPath}"
GCCaPath="${MainPath}/GCC64"
GCCbPath="${MainPath}/GCC32"
MainZipGCCaPath="${MainPath}/GCC64-zip"
MainZipGCCbPath="${MainPath}/GCC32-zip"

# Identity
VERSION=4.4.312
KERNELNAME=TheOneMemory
CODENAME=X00TD
VARIANT=AEXHMP

LINKER=ld.lld

# Show manufacturer info
MANUFACTURERINFO="Asus Computer Inc."

# Clone Kernel Source
git clone --depth=1 https://github.com/texascake/android_kernel_asus_sdm660-4.4 kernel

# Clone clang Toolchain
msg "|| Cloning clang. . . ||"
ClangPath=${MainClangZipPath}
[[ "$(pwd)" != "${MainPath}" ]] && cd "${MainPath}"
mkdir $ClangPath
rm -rf $ClangPath/*
wget -q https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/master/clang-r522817.tar.gz -O "clang-r522817.tar.gz"
tar -xf clang-r522817.tar.gz -C $ClangPath

# Clone GCC Toolchain
msg "|| Cloning GCC. . . ||"
mkdir $GCCaPath
mkdir $GCCbPath
wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz -O "gcc64.tar.gz"
tar -xf gcc64.tar.gz -C $GCCaPath
wget -q https://android.googlesource.com/platform/prebuilts/gcc/linux-x86/arm/arm-linux-androideabi-4.9/+archive/refs/tags/android-12.1.0_r27.tar.gz -O "gcc32.tar.gz"
tar -xf gcc32.tar.gz -C $GCCbPath

# Prepared
KERNEL_ROOTDIR=$(pwd)/kernel # IMPORTANT ! Fill with your kernel source root directory.
export TZ=Asia/Jakarta # Change with your local timezone.
export LD=ld.lld
export KBUILD_BUILD_USER=queen # Change with your own name or else.
IMAGE=$(pwd)/kernel/out/arch/arm64/boot/Image.gz-dtb
CLANG_VER="$("$ClangPath"/bin/clang --version | head -n 1 | perl -pe 's/\(http.*?\)//gs' | sed -e 's/  */ /g' -e 's/[[:space:]]*$//')"
#LLD_VER="$("$ClangPath"/bin/ld.lld --version | head -n 1)"
export KBUILD_COMPILER_STRING="$CLANG_VER"
#ClangMoreStrings="AR=llvm-ar NM=llvm-nm AS=llvm-as STRIP=llvm-strip OBJCOPY=llvm-objcopy OBJDUMP=llvm-objdump READELF=llvm-readelf HOSTAR=llvm-ar HOSTAS=llvm-as LD_LIBRARY_PATH=$ClangPath/lib LD=ld.lld HOSTLD=ld.lld"
export PATH=${ClangPath}/bin:${GCCaPath}/bin:${GCCbPath}/bin:${PATH}
DATE=$(date +"%Y%m%d-%H%M")
START=$(date +"%s")

# Java
command -v java > /dev/null 2>&1

# Telegram
export BOT_MSG_URL="https://api.telegram.org/bot$TG_TOKEN/sendMessage"
export BOT_BUILD_URL="https://api.telegram.org/bot$TG_TOKEN/sendDocument"

# Telegram messaging
tg_post_msg() {
  curl -s -X POST "$BOT_MSG_URL" -d chat_id="$TG_CHAT_ID" \
    -d "disable_web_page_preview=true" \
    -d "parse_mode=html" \
    -d text="$1"
}

# Compiler
compile(){
cd ${KERNEL_ROOTDIR}
msg "|| Cooking kernel. . . ||"
export HASH_HEAD=$(git rev-parse --short HEAD)
export COMMIT_HEAD=$(git log --oneline -1)
make -j$(nproc) O=out ARCH=arm64 X00TD_defconfig
make -j$(nproc) ARCH=arm64 SUBARCH=arm64 O=out \
    LD_LIBRARY_PATH="${ClangPath}/lib64:${LD_LIBRARY_PATH}" \
    CC=${ClangPath}/bin/clang \
    NM=${ClangPath}/bin/llvm-nm \
    CXX=${ClangPath}/bin/clang++ \
    AR=${ClangPath}/bin/llvm-ar \
    STRIP=${ClangPath}/bin/llvm-strip \
    OBJCOPY=${ClangPath}/bin/llvm-objcopy \
    OBJDUMP=${ClangPath}/bin/llvm-objdump \
    OBJSIZE=${ClangPath}/bin/llvm-size \
    READELF=${ClangPath}/bin/llvm-readelf \
    CROSS_COMPILE=aarch64-linux-android- \
    CROSS_COMPILE_ARM32=arm-linux-androideabi- \
    CLANG_TRIPLE=aarch64-linux-gnu- \
    HOSTAR=${ClangPath}/bin/llvm-ar \
    HOSTCC=${ClangPath}/bin/clang \
    HOSTCXX=${ClangPath}/bin/clang++

   if ! [ -a "$IMAGE" ]; then
	finerr
	exit 1
   fi

   msg "|| Cloning AnyKernel ||"
   git clone --depth=1 https://github.com/Tiktodz/AnyKernel3 -b 44 AnyKernel
	cp $IMAGE AnyKernel
}

# Push kernel to telegram
function push() {
    cd AnyKernel
    curl -F document="@$ZIP_FINAL.zip" "https://api.telegram.org/bot$TG_TOKEN/sendDocument" \
        -F chat_id="$TG_CHAT_ID" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="🔐<b>Build Done</b>
        - <code>$((DIFF / 60)) minute(s) $((DIFF % 60)) second(s)... </code>

        <b>📅 Build Date: </b>
        -<code>$DATE</code>

        <b>🐧 Linux Version: </b>
        -<code>$VERSION</code>

         <b>💿 Compiler: </b>
        -<code>$KBUILD_COMPILER_STRING</code>

        <b>📱 Device: </b>
        -<code>$DEVICE_CODENAME($MANUFACTURERINFO)</code>

        <b>🆑 Changelog: </b>
        - <code>$COMMIT_HEAD</code>
        <b></b>
        #$KERNELNAME #$VARIANT"
}
# Find Error
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
        -d text="❌ Tetap menyerah...Pasti bisa!!!"
    exit 1
}
# Zipping
function zipping() {
    cd AnyKernel
    zip -r9 $KERNELNAME-$CODENAME-$VARIANT-"$DATE" . -x ".git*" -x "README.md" -x "./*placeholder" "*.zip"

    ZIP_FINAL="$KERNELNAME-$CODENAME-$VARIANT-$DATE"

    msg "|| Signing Zip ||"
    tg_post_msg "<code>🔑 Signing Zip file with AOSP keys..</code>"

    curl -sLo zipsigner-3.0.jar https://github.com/Magisk-Modules-Repo/zipsigner/raw/master/bin/zipsigner-3.0-dexed.jar
    java -jar zipsigner-3.0.jar "$ZIP_FINAL".zip "$ZIP_FINAL"-signed.zip
    ZIP_FINAL="$ZIP_FINAL-signed"
    cd ..
}

compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
