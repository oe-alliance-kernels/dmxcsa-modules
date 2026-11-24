# kernel-module-dmxcsa

`dmxcsa` descrambles **CSA-ALT** inside the kernel, so the userspace player does
not have to. One scrambled service is handled in software by the module; free
and plain-CSA services stay on the hardware path, untouched.

This repository contains the **kernel modules** and the ready-to-use
**opkg (`.ipk`) and Debian (`.deb`) installers**, one per receiver, published as
GitHub **Releases**.

## How it works

![How dmxcsa works](docs/how-it-works.svg)

The module taps the service's demux node the way a recording would, descrambles
the stream in software, and plays the result to the decoder through a second
"shadow" demux node. Keys, pids and the algorithm come from the CA ioctls a
local CA client writes.

## Install

Download the package for your receiver from the latest
[Release](../../releases/latest) and install it.

**opkg receivers** (most enigma2 images):

```sh
opkg install kernel-module-dmxcsa_<version>_<box>.ipk
```

**Debian-based receivers** (certain Dreamboxes):

```sh
dpkg -i kernel-module-dmxcsa_<version>_<box>.deb
```

The installer copies the module to `/lib/modules/<kernel>/extra/`, runs
`depmod`, and sets up boot autoload so the module loads after the DVB driver.
**Reboot** afterwards.

## Checking status

The module exports a live status page and a small sysfs attribute.

```sh
cat /proc/dmxcsa
```

shows the version, whether it is enabled, which shadow demux node it uses,
the active path when it is descrambling, and running counters: packets read and
written, scrambled / descrambled / no-key, PES starts that came out good or bad,
CA ioctls seen and used, even/odd control words, decoder-filter moves, the
playback delay, and a per-service line with its algorithm, key state, table and
pids.

```sh
cat /sys/module/dmxcsa/active
```

lists the demux node numbers currently being descrambled (empty when idle). The
module raises a sysfs/uevent notification whenever this changes, so a client can
subscribe instead of polling.

## Parameters

Parameters are read from `/sys/module/dmxcsa/parameters/<name>`. The writable
ones can be changed at runtime, e.g. `echo 1 > /sys/module/dmxcsa/parameters/debug`;
all of them can also be set at load time, e.g. `modprobe dmxcsa shadow=5` or in
`/etc/modprobe.d/dmxcsa.conf` with `options dmxcsa delay=0`.

| Parameter | Default | Writable | Meaning |
|---|---|---|---|
| `adapter` | `0` | load only | DVB adapter the module works on |
| `shadow` | `-1` | load only | demux node the decoder runs on while descrambling; `-1` picks an unused one near the middle |
| `enabled` | `1` | yes | `0` = stay out entirely |
| `delay` | `-1` | yes | playback delay in ms: `-1` automatic, `0` off, up to `5000` fixed |
| `debug` | `0` | yes | `1` log table probes and bad PES starts, `2` also every PES filter, `3` also every CA call |
| `relink` | per box | yes | `1` = CSA-ALT pids are re-linked to their slot and taken back after every filter start, so a channel the driver left on old keys is let through |
| `rebind` | per box | yes | bitmask for decoders whose filters moved: `1` stop/play, `2` + select source, `4` + stream type, `16` no PCR on the shadow, `32` the full start sequence |
| `test_cw` | — | yes | testing aid for the next control word (see below) |

`relink` and `rebind` default to values chosen per receiver at build time; the
installed module already carries the right ones, so you normally leave them
alone.

### Testing with `test_cw`

`test_cw` tampers with the **next** control word once, to check how the chain
copes:

```sh
# make the next control word wrong
echo bad > /sys/module/dmxcsa/parameters/test_cw

# hold the next control word back by 850 ms (100–5000 allowed)
echo 850 > /sys/module/dmxcsa/parameters/test_cw
```

Watch the effect in `/proc/dmxcsa`.

## What a Release contains

Each release `vX.Y` provides, per receiver:

| File | What it is |
|---|---|
| `dmxcsa-<box>-<kernel version>.ko` | the raw kernel module |
| `kernel-module-dmxcsa_<version>_<box>.ipk` | opkg installer (module + autoload) |
| `kernel-module-dmxcsa_<version>_<box>.deb` | Debian installer (selected Dreamboxes) |

Each module is built against that receiver's exact kernel, so it matches the
running kernel's version magic (and, where the kernel uses it, its symbol
versions).

Some receivers come with two modules, and their installer picks the one for
the running kernel:

- dreamone and dreamtwo: one module per kernel version (4.9.269 and 4.9.113)
- dm900 and dm920: `dmxcsa-<box>-<kernel version>-noneon.ko` next to the
  regular one, for kernels of the same version without kernel mode NEON

## Requirements

- a local CA client that writes the descrambler keys with
  **`extended_cw_api = 1`** (so the algorithm is signalled to the kernel)
- where the userspace player has a software descrambler of its own, disable it,
  otherwise the two work against each other

## License

GPL-2.0-or-later.
