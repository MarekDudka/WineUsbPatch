#!/bin/bash
# Install the built modules and configure the Wine prefix.
set -euo pipefail
. "$(dirname "$0")/config.sh"
OUT="$BUILD_DIR/out"
[ -f "$OUT/x86_64-windows/wineusb2.sys" ] || { echo "Run scripts/build.sh first" >&2; exit 1; }
[ -d "$APP_DIR" ] || { echo "Application directory not found: $APP_DIR (set APP_DIR)" >&2; exit 1; }
wineserver -k 2>/dev/null || true

mkdir -p "$WINUSB_LIB"/{x86_64-windows,i386-windows,x86_64-unix}
cp "$OUT"/x86_64-windows/* "$WINUSB_LIB/x86_64-windows/"
cp "$OUT"/i386-windows/*   "$WINUSB_LIB/i386-windows/"
cp "$OUT"/x86_64-unix/*    "$WINUSB_LIB/x86_64-unix/"

cp "$OUT/x86_64-windows/wineusb2.sys" "$WINEPREFIX/drive_c/windows/system32/drivers/wineusb2.sys"
WINEDLLPATH="$WINUSB_LIB" wine reg add 'HKLM\System\CurrentControlSet\Services\wineusb' \
    /v ImagePath /t REG_EXPAND_SZ /d 'C:\windows\system32\drivers\wineusb2.sys' /f >/dev/null 2>&1
# 64-bit registry view: the driver is 64-bit.
WINEDLLPATH="$WINUSB_LIB" wine reg add "HKLM\\Software\\Wine\\WineUSB\\$USB_ID" \
    /v DeviceInterfaceGUIDs /t REG_MULTI_SZ /d "$DEVICE_GUID" /f /reg:64 >/dev/null 2>&1

# 32-bit winusb.dll next to the application. The "Wine builtin DLL" marker is
# overwritten so Wine treats the file as native instead of substituting its stub.
python3 - "$OUT/i386-windows/winusb.dll" "$APP_DIR/winusb.dll" <<'PY'
import sys
b = bytearray(open(sys.argv[1], 'rb').read())
i = b.find(b'Wine builtin DLL')
if i >= 0:
    b[i:i+16] = b'Wine patched DLL'
open(sys.argv[2], 'wb').write(b)
PY
# Wrapper so that a plain `wine ...` also works (see wine-wrapper.sh). It is placed
# first in PATH (~/.local/bin); set WRAPPER_DIR= (empty) to skip it.
WRAPPER_DIR="${WRAPPER_DIR-$HOME/.local/bin}"
if [ -n "$WRAPPER_DIR" ]; then
    REAL_WINE="$(PATH="${PATH//$WRAPPER_DIR:/}" command -v wine)"
    mkdir -p "$WRAPPER_DIR"
    sed -e "s|@WINUSB_LIB@|$WINUSB_LIB|" -e "s|@REAL_WINE@|$REAL_WINE|" "$HERE/wine-wrapper.sh" > "$WRAPPER_DIR/wine"
    chmod +x "$WRAPPER_DIR/wine"
    echo "Wrapper installed: $WRAPPER_DIR/wine -> $REAL_WINE"
fi
wineserver -k 2>/dev/null || true
echo "Installed. Start the application with scripts/run.sh, or plain: wine $APP_EXE"
