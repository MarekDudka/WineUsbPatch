#!/bin/bash
# Run the application with the patched WinUSB support.
#
# The patched driver is loaded by Wine's background services, which read WINEDLLPATH
# only when they start. If Wine was already running in this prefix without it (for
# example another Wine program was started earlier), the application will not see
# the device. In that case stop Wine first:  wineserver -k   (or run with WINUSB_RESTART=1).
. "$(dirname "$0")/config.sh"
export WINEDLLPATH="$WINUSB_LIB"
export WINEDLLOVERRIDES="winusb=n,b"

stale=0
for pid in $(pgrep -f winedevice.exe 2>/dev/null); do
    env=$(tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null) || continue
    echo "$env" | grep -qx "WINEPREFIX=$WINEPREFIX" || continue
    echo "$env" | grep -qx "WINEDLLPATH=$WINUSB_LIB" || stale=1
done
if [ "$stale" = 1 ]; then
    if [ "${WINUSB_RESTART:-0}" = 1 ]; then
        wineserver -k; sleep 2
    else
        echo "Wine is already running in $WINEPREFIX without the patched driver." >&2
        echo "Run 'wineserver -k' (this closes all Wine programs in the prefix) or set WINUSB_RESTART=1." >&2
        exit 1
    fi
fi

cd "$APP_DIR" || exit 1
exec wine "$APP_EXE" "$@"
