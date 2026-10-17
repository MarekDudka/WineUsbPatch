#!/bin/sh
# wine-winusb wrapper: runs the system Wine with the patched WinUSB modules available.
# Wine's background services read WINEDLLPATH only when they start, so the variable has
# to be set for every `wine` command, otherwise the prefix's patched USB driver cannot
# load its Unix library and USB stops working for all Wine programs in the prefix.
LIB="@WINUSB_LIB@"
if [ -d "$LIB" ]; then
    export WINEDLLPATH="$LIB${WINEDLLPATH:+:$WINEDLLPATH}"
    export WINEDLLOVERRIDES="winusb=n,b${WINEDLLOVERRIDES:+;$WINEDLLOVERRIDES}"
fi
exec @REAL_WINE@ "$@"
