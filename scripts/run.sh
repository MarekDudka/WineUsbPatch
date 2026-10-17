#!/bin/bash
# Run the application with the patched WinUSB support.
. "$(dirname "$0")/config.sh"
export WINEDLLPATH="$WINUSB_LIB"
export WINEDLLOVERRIDES="winusb=n,b"
cd "$APP_DIR" || exit 1
exec wine "$APP_EXE" "$@"
