# WineUsbPatch

A patch for Wine 10.0 that adds a working **WinUSB** implementation, together with
scripts to build and install it into a Wine prefix.

**Why it exists:** it was created to fix USB communication with the Sofi **SP8-A**
programmer when its Windows software (FlyPRO) is installed in Wine. Stock Wine 10.0
cannot talk to the programmer, because its `winusb.dll` is made of stubs and no
device interface is registered for a device that uses a WinUSB vendor driver.
The patch is not specific to that device: any Windows application that opens a
WinUSB device by its interface GUID should be able to use it, but the SP8-A is the
only device it has been tested with.

Status: with the patch, FlyPRO detects the SP8-A and exchanges data with it.
A complete read/program/verify cycle of a chip has not been verified.

## What the patch changes

* `dlls/wineusb.sys` (Wine's libusb-based USB bus driver)
  * registers device interfaces for the GUIDs configured in the registry,
  * accepts user-mode requests on the device (create/close/cleanup/IOCTL),
  * turns them into URBs: descriptors, interface claim, bulk/interrupt/control
    transfers with timeouts, pipe reset and abort.
* `dlls/wineusb.sys/unixlib.c`: libusb side claims the interface (with kernel driver
  auto-detach) and sets the alternate setting, supports generic control transfers,
  and passes per-transfer timeouts to libusb.
* `dlls/winusb`: real implementation of `WinUsb_Initialize`, `Free`,
  `QueryInterfaceSettings`, `QueryPipe`, `QueryDeviceInformation`,
  `Get/SetCurrentAlternateSetting`, `GetDescriptor`, `ControlTransfer`, `ReadPipe`,
  `WritePipe`, `GetOverlappedResult`, `ResetPipe`, `AbortPipe`, `FlushPipe`,
  `Get/SetPipePolicy`, `Get/SetPowerPolicy`, `ParseDescriptors`,
  `ParseConfigurationDescriptor`. Both synchronous and overlapped I/O work.
* `include/winusb.h`: the public WinUSB declarations.
* `dlls/winusb/winusb_ioctl.h`: private IOCTL protocol between `winusb.dll` and the driver.

Design in short:

    application --WinUsb_*--> winusb.dll --DeviceIoControl--> wineusb.sys --URB--> libusb

The device interface GUIDs come from the `DeviceInterfaceGUIDs` value of the device's
`Device Parameters` key, or from `HKLM\Software\Wine\WineUSB\<VID_xxxx&PID_xxxx>`
(64-bit registry view), which survives re-plugging into another port.

Debugging: `WINEDEBUG=+usbcap` prints every transfer with a hex dump;
`trace+winusb,trace+wineusb` show the API and driver activity.

## Requirements

Debian 13 (Wine 10.0), x86_64. To build: git, gcc, make, flex, bison, clang, llvm,
`libusb-1.0-0-dev` and `apt` (used to fetch `lld` without root; Wine builds its PE
modules with clang + lld, so mingw-w64 is not needed). The build needs about 1 GB.
To run: a 64-bit Wine prefix (default `~/.wine`) with the application installed, and
read/write access to the USB device node.

## Usage

    scripts/build.sh        # clones Wine 10.0, applies the patch, builds only winusb/wineusb
    scripts/install.sh      # installs into the prefix
    scripts/run.sh          # starts the application with the patched modules
    scripts/uninstall.sh    # reverts the prefix

Settings are environment variables (see `scripts/config.sh`): `WINEPREFIX`,
`APP_DIR` / `APP_EXE` (the application inside the prefix), `USB_ID`, `DEVICE_GUID`,
`BUILD_DIR`, `WINUSB_LIB`. The defaults are for FlyPRO and the SP8-A
(`USB_ID=VID_5346&PID_5109`, `DEVICE_GUID` from its vendor INF). For another device,
use its VID/PID and the interface GUID from its Windows INF.

If a device stops answering, unplug and replug it.

## Why the installation looks unusual

* The bus driver is installed as `wineusb2.sys`: Wine loads its own system copy of a
  builtin module ahead of `WINEDLLPATH` and ahead of the file in the prefix, so a new
  name is needed. The `wineusb` service's `ImagePath` is pointed at it.
* `winusb.dll` is placed next to the application's `.exe` with the "Wine builtin DLL"
  marker overwritten, and `run.sh` sets `WINEDLLOVERRIDES=winusb=n,b`, so Wine uses
  the patched file instead of its stub. 32-bit applications use the i386 build.
* The driver runs in the 64-bit wineserver; the Unix library is built for x86_64
  only, so a pure 32-bit prefix is not supported.

`install.sh` also installs a small `wine` wrapper into `~/.local/bin` (first in `PATH`).
It sets `WINEDLLPATH` and the `winusb` override for every `wine` command, so a plain
`wine app.exe` works as well as `scripts/run.sh`. Without it, a `wine` started without
those variables would start Wine's services without the patched driver's library and
USB would stop working for every program in that prefix (`err:wineusb:DriverEntry
Failed to initialize Unix library`). Skip it with `WRAPPER_DIR= scripts/install.sh`;
`uninstall.sh` removes it. The patched driver is loaded by Wine's background services when they
start, so if Wine was already running in the prefix without it, `run.sh` stops with a
message: run `wineserver -k` (closes all Wine programs in that prefix) or use
`WINUSB_RESTART=1 scripts/run.sh`. After a Wine package update, run `scripts/install.sh` again.

## Limitations

* Tested only with one device and one application, on Wine 10.0 / Debian 13.
* No isochronous pipes. Pipe policies other than the transfer timeout are accepted
  but have no effect. `QueryDeviceInformation` always reports full speed.
  `QueryPipe` works for the current alternate setting only.
  `GetAssociatedInterface` is not supported.
* The libusb side claims the interface whenever `SELECT_CONFIGURATION` is issued; a
  failure to claim is only a warning, but it may change behaviour for other devices
  that use Wine's bus driver.
* Not yet suitable for upstream Wine as is: no conformance tests, the commit is not
  split, and the design (private IOCTLs on the bus driver's PDO rather than a
  separate WinUSB function driver) may not be what the Wine maintainers want.

## License

The patch modifies Wine and is distributed under the same terms, the GNU Lesser
General Public License version 2.1 or later (see `LICENSE`, copied from Wine).
The files it extends keep their original copyright notices (Zebediah Figura for
`wineusb.sys`, Mohamad Al-Jaf for `winusb`). This repository does not contain any
code or files from the vendor of the programmer or its software.

Parts of this work were developed with the help of an AI assistant (Claude).
No warranty; use at your own risk.
