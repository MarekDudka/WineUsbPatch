#!/bin/bash
# Revert install.sh.
set -euo pipefail
. "$(dirname "$0")/config.sh"
wineserver -k 2>/dev/null || true
wine reg add 'HKLM\System\CurrentControlSet\Services\wineusb' /v ImagePath /t REG_EXPAND_SZ \
    /d 'C:\windows\system32\drivers\wineusb.sys' /f >/dev/null 2>&1
wine reg delete "HKLM\\Software\\Wine\\WineUSB\\$USB_ID" /f /reg:64 >/dev/null 2>&1 || true
rm -f "$APP_DIR/winusb.dll" "$WINEPREFIX/drive_c/windows/system32/drivers/wineusb2.sys"
rm -rf "$WINUSB_LIB"
wineserver -k 2>/dev/null || true
echo "Removed."
