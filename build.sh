#!/usr/bin/env bash
# build.sh — Pixel Adventure v1.0.0 release builder
# Targets: .love package, Linux AppImage, Android debug APK
#
# Usage:
#   ./build.sh            — build all available targets
#   ./build.sh love       — .love package only
#   ./build.sh linux      — Linux AppImage (includes love step)
#   ./build.sh android    — Android APK (includes love step)
#   ./build.sh all        — all targets

set -euo pipefail

# ─── Configuration ────────────────────────────────────────────────────────────
GAME_NAME="PixelAdventure"
VERSION="1.0.2"
LOVE_VERSION="11.4"
LOVE_APPIMAGE_URL="https://github.com/love2d/love/releases/download/${LOVE_VERSION}/love-${LOVE_VERSION}-x86_64.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
LOVE_ANDROID_REPO="https://github.com/love2d/love-android"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="${PROJECT_ROOT}/dist"
LOVE_FILE="${DIST_DIR}/${GAME_NAME}.love"
LINUX_DIR="${DIST_DIR}/linux"
ANDROID_DIR="${DIST_DIR}/android"
TOOLS_DIR="${DIST_DIR}/.tools"
LOVE_APPIMAGE_CACHE="${TOOLS_DIR}/love-${LOVE_VERSION}.AppImage"
LOVE_ANDROID_DIR="${TOOLS_DIR}/love-android"

# Android SDK: respect env vars, fall back to ~/Android/Sdk
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Android/Sdk}}"

# ─── Helpers ──────────────────────────────────────────────────────────────────
info()    { printf '\e[34m[INFO]\e[0m  %s\n' "$*"; }
success() { printf '\e[32m[OK]\e[0m    %s\n' "$*"; }
warn()    { printf '\e[33m[WARN]\e[0m  %s\n' "$*"; }
die()     { printf '\e[31m[ERROR]\e[0m %s\n' "$*" >&2; exit 1; }

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: '$1'. Install it and retry."
}

# ─── Step 1: Package .love file ───────────────────────────────────────────────
build_love() {
    info "Packaging ${GAME_NAME}.love ..."
    require_cmd zip

    mkdir -p "${DIST_DIR}"
    rm -f "${LOVE_FILE}"

    cd "${PROJECT_ROOT}"
    zip -9 -r "${LOVE_FILE}" \
        main.lua \
        conf.lua \
        src/ \
        assets/ \
        --exclude "*/spec/*" \
        --exclude "*/docs/*" \
        --exclude "test.lua" \
        --exclude "*.md" \
        --exclude "build.sh" \
        --exclude "dist/*" \
        --exclude ".git*"

    local size
    size=$(du -sh "${LOVE_FILE}" | cut -f1)
    success ".love package: ${LOVE_FILE} (${size})"
}

# ─── Step 2: Linux AppImage ───────────────────────────────────────────────────
build_linux() {
    info "Building Linux AppImage ..."
    require_cmd curl

    [ -f "${LOVE_FILE}" ] || die ".love not found — run: ./build.sh love"

    mkdir -p "${LINUX_DIR}" "${TOOLS_DIR}"

    # Download Love2D AppImage (cached)
    if [ ! -f "${LOVE_APPIMAGE_CACHE}" ]; then
        info "Downloading Love2D ${LOVE_VERSION} AppImage ..."
        curl -L --progress-bar "${LOVE_APPIMAGE_URL}" -o "${LOVE_APPIMAGE_CACHE}"
        chmod +x "${LOVE_APPIMAGE_CACHE}"
    else
        info "Using cached: ${LOVE_APPIMAGE_CACHE}"
    fi

    # Download appimagetool (cached)
    local APPIMAGETOOL="${TOOLS_DIR}/appimagetool"
    if [ ! -f "${APPIMAGETOOL}" ]; then
        info "Downloading appimagetool ..."
        curl -L --progress-bar "${APPIMAGETOOL_URL}" -o "${APPIMAGETOOL}"
        chmod +x "${APPIMAGETOOL}"
    fi

    # Extract the Love2D AppImage into a build directory (AppDir)
    local APPDIR="${TOOLS_DIR}/appdir"
    rm -rf "${APPDIR}"
    info "Extracting Love2D AppImage ..."
    cd "${TOOLS_DIR}" && "${LOVE_APPIMAGE_CACHE}" --appimage-extract >/dev/null 2>&1
    mv "${TOOLS_DIR}/squashfs-root" "${APPDIR}"

    # Embed game.love inside the AppDir
    cp "${LOVE_FILE}" "${APPDIR}/game.love"

    # Replace AppRun with a shell script that launches love with the embedded game
    cat > "${APPDIR}/AppRun" << 'APPRUN_EOF'
#!/bin/bash
APPDIR="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${APPDIR}/lib:${LD_LIBRARY_PATH}"
exec "${APPDIR}/bin/love" "${APPDIR}/game.love" "$@"
APPRUN_EOF
    chmod +x "${APPDIR}/AppRun"

    # Fix desktop Exec (appimagetool requires no %f when game is embedded)
    sed -i 's/^Exec=love.*$/Exec=love/' "${APPDIR}/love.desktop"

    # Repack as AppImage
    local OUTPUT="${LINUX_DIR}/${GAME_NAME}-${VERSION}-linux-x86_64.AppImage"
    info "Repacking AppImage ..."
    ARCH=x86_64 "${APPIMAGETOOL}" "${APPDIR}" "${OUTPUT}" 2>&1 | grep -v "^$" || true

    local size
    size=$(du -sh "${OUTPUT}" | cut -f1)
    success "Linux AppImage: ${OUTPUT} (${size})"
    info "Test with: ${OUTPUT}"
}

# ─── Step 3: Android APK ──────────────────────────────────────────────────────
build_android() {
    info "Building Android APK ..."
    require_cmd git
    require_cmd java

    [ -f "${LOVE_FILE}" ] || die ".love not found — run: ./build.sh love"

    # SDK check
    [ -d "${ANDROID_SDK_ROOT}" ] || die "Android SDK not found at: ${ANDROID_SDK_ROOT}
Install it with Android Studio, or set ANDROID_SDK_ROOT.
Then install missing components:
  sdkmanager 'platforms;android-34'
  sdkmanager 'ndk;21.3.6528147'"

    # NDK check
    # Use the NDK version that love-android requires; fall back to latest if not found.
    local REQUIRED_NDK="21.3.6528147"
    local NDK_DIR="${ANDROID_SDK_ROOT}/ndk/${REQUIRED_NDK}"
    if [ ! -d "${NDK_DIR}" ]; then
        NDK_DIR=$(ls -d "${ANDROID_SDK_ROOT}/ndk/"* 2>/dev/null | sort -V | tail -1 || true)
    fi
    [ -n "${NDK_DIR}" ] || die "Android NDK not found in ${ANDROID_SDK_ROOT}/ndk/
Install it:
  ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager 'ndk;21.3.6528147'"
    info "NDK: ${NDK_DIR}"

    # Platform check
    local PLATFORM_DIR
    PLATFORM_DIR=$(ls -d "${ANDROID_SDK_ROOT}/platforms/android-"* 2>/dev/null | sort -V | tail -1 || true)
    [ -n "${PLATFORM_DIR}" ] || die "No Android platform found in ${ANDROID_SDK_ROOT}/platforms/
Install it:
  ${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager 'platforms;android-34'"
    info "Platform: $(basename "${PLATFORM_DIR}")"

    mkdir -p "${ANDROID_DIR}" "${TOOLS_DIR}"

    # Clone love-android (cached)
    if [ ! -d "${LOVE_ANDROID_DIR}" ]; then
        info "Cloning love-android (tag ${LOVE_VERSION}) ..."
        git clone --depth=1 --branch "${LOVE_VERSION}" \
            "${LOVE_ANDROID_REPO}" "${LOVE_ANDROID_DIR}" 2>/dev/null \
        || git clone --depth=1 "${LOVE_ANDROID_REPO}" "${LOVE_ANDROID_DIR}"
        cd "${LOVE_ANDROID_DIR}"
        info "Initialising submodules (Love2D source — this takes a while) ..."
        git submodule update --init --recursive
    else
        info "Using cached love-android: ${LOVE_ANDROID_DIR}"
    fi

    # ndk-build cannot handle paths with spaces. Copy to /tmp if needed.
    local BUILD_DIR="${LOVE_ANDROID_DIR}"
    if [[ "${LOVE_ANDROID_DIR}" == *" "* ]]; then
        BUILD_DIR="/tmp/love-android-build"
        info "Project path contains spaces — copying build tree to ${BUILD_DIR} ..."
        rm -rf "${BUILD_DIR}"
        cp -r "${LOVE_ANDROID_DIR}" "${BUILD_DIR}"
    fi

    # Embed game
    local ASSETS_DIR="${BUILD_DIR}/app/src/main/assets"
    mkdir -p "${ASSETS_DIR}"
    cp "${LOVE_FILE}" "${ASSETS_DIR}/game.love"
    info "Embedded game.love into build assets"

    # Write local.properties
    cat > "${BUILD_DIR}/local.properties" <<EOF
sdk.dir=${ANDROID_SDK_ROOT}
ndk.dir=${NDK_DIR}
EOF

    # python shim (Ubuntu uses python3; ndk-build scripts call python)
    local PYSHIM_DIR
    PYSHIM_DIR="$(mktemp -d)"
    if ! command -v python >/dev/null 2>&1; then
        ln -sf "$(command -v python3)" "${PYSHIM_DIR}/python"
        info "Created python→python3 shim"
    fi

    # Build
    cd "${BUILD_DIR}"
    export ANDROID_HOME="${ANDROID_SDK_ROOT}"
    chmod +x ./gradlew
    info "Running Gradle assembleDebug (first run compiles Love2D from source — be patient) ..."
    PATH="${PYSHIM_DIR}:${PATH}" ./gradlew assembleDebug --no-daemon 2>&1 | grep -E '(BUILD|FAILED|error:|Task :app:assemble|Task :app:package)' || true
    rm -rf "${PYSHIM_DIR}"

    # Locate APK
    local APK_SRC
    APK_SRC=$(find "${BUILD_DIR}" -name "*.apk" -path "*/debug/*" ! -name "*unsigned*" 2>/dev/null | head -1 || true)
    [ -n "${APK_SRC}" ] || die "APK not found after build. Check Gradle output above."

    local APK_DST="${ANDROID_DIR}/${GAME_NAME}-${VERSION}-debug.apk"
    cp "${APK_SRC}" "${APK_DST}"

    local size
    size=$(du -sh "${APK_DST}" | cut -f1)
    success "Android debug APK: ${APK_DST} (${size})"
    info "Install on device: adb install '${APK_DST}'"
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
TARGET="${1:-all}"

case "${TARGET}" in
    love)
        build_love
        ;;
    linux)
        build_love
        build_linux
        ;;
    android)
        build_love
        build_android
        ;;
    all)
        build_love
        build_linux
        if [ -d "${ANDROID_SDK_ROOT}" ]; then
            build_android
        else
            warn "Android SDK not found at ${ANDROID_SDK_ROOT} — skipping Android build."
            warn "Run './build.sh android' after completing the Android SDK setup."
        fi
        ;;
    *)
        echo "Usage: $0 [love|linux|android|all]"
        echo ""
        echo "  love     package .love file only"
        echo "  linux    build Linux AppImage (includes love step)"
        echo "  android  build Android debug APK (includes love step)"
        echo "  all      build everything available (default)"
        exit 1
        ;;
esac

echo ""
info "Output directory: ${DIST_DIR}/"
