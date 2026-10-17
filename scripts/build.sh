#!/bin/bash
# Build the patched modules from Wine 10.0 + patches/wine-10.0-winusb.patch.
# Needs: git, gcc, make, flex, bison, clang, llvm (llvm-dlltool), libusb-1.0-0-dev, apt (for lld).
# Only the PE modules and the Unix library are built (headless, no X11). lld is
# unpacked from a downloaded .deb into the build directory, so no root is needed.
set -euo pipefail
. "$(dirname "$0")/config.sh"
mkdir -p "$BUILD_DIR"/{bin,debs,tools,out}
cd "$BUILD_DIR"

if ! command -v lld-link >/dev/null && [ ! -x tools/usr/lib/llvm-19/bin/lld-link ]; then
    (cd debs && apt download lld-19)
    dpkg -x debs/lld-19_*.deb tools
    for t in lld lld-link ld.lld; do ln -sf "$BUILD_DIR/tools/usr/lib/llvm-19/bin/$t" bin/$t; done
fi
export PATH="$BUILD_DIR/bin:/usr/lib/llvm-19/bin:$PATH"

[ -d wine ] || git clone --depth 1 -b wine-10.0 https://gitlab.winehq.org/wine/wine.git wine
if git -C wine apply --check "$ROOT/patches/wine-10.0-winusb.patch" 2>/dev/null; then
    git -C wine apply "$ROOT/patches/wine-10.0-winusb.patch"
else
    echo "patch already applied (or does not apply cleanly); continuing"
fi

mkdir -p obj && cd obj
[ -f Makefile ] || ../wine/configure --enable-archs=i386,x86_64 --disable-tests --without-x \
    --without-freetype --without-gstreamer --without-pulse --without-alsa --without-cups \
    --without-sdl --without-wayland --without-vulkan --without-opengl --without-pcap \
    --without-gphoto --without-sane --without-v4l2 --without-krb5 --without-gnutls \
    --without-oss --without-udev --without-unwind --without-capi --without-pcsclite
make -j"$(nproc)" __tooldeps__
make -j"$(nproc)" dlls/winusb/all dlls/wineusb.sys/all

# wineusb.sys / wineusb.so are installed as wineusb2: Wine otherwise loads its
# own system copy of wineusb.sys ahead of this one.
O="$BUILD_DIR/out"
mkdir -p "$O"/{x86_64-windows,i386-windows,x86_64-unix}
cp dlls/winusb/x86_64-windows/winusb.dll        "$O/x86_64-windows/"
cp dlls/wineusb.sys/x86_64-windows/wineusb.sys  "$O/x86_64-windows/wineusb2.sys"
cp dlls/winusb/i386-windows/winusb.dll          "$O/i386-windows/"
cp dlls/wineusb.sys/wineusb.so                  "$O/x86_64-unix/wineusb2.so"
echo "Built into $O. Next: scripts/install.sh"
