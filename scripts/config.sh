# Shared settings. Everything can be overridden from the environment.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
ROOT="$(dirname "$HERE")"
export WINEPREFIX="${WINEPREFIX:-$HOME/.wine}"
# Where build.sh puts its results and where install.sh installs them.
BUILD_DIR="${BUILD_DIR:-$ROOT/build}"
WINUSB_LIB="${WINUSB_LIB:-$HOME/.local/share/wine-winusb/lib/wine}"
# Application that needs WinUSB: directory of its .exe inside the prefix, and its .exe name.
APP_DIR="${APP_DIR:-$WINEPREFIX/drive_c/Program Files (x86)/FlyPRO}"
APP_EXE="${APP_EXE:-FlyPRO.exe}"
# USB device (as Wine names it) and the WinUSB interface GUID the application opens.
# Defaults: Sofi SP8-A programmer and the GUID from its vendor INF.
USB_ID="${USB_ID:-VID_5346&PID_5109}"
DEVICE_GUID="${DEVICE_GUID:-{3448B97E-EE3A-4ebb-8E6D-01A81B21FC67}}"
