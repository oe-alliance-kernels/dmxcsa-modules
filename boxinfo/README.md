# Box survey

`dmxcsa-boxinfo.sh` is a **read-only** survey for the dmxcsa test. It changes
nothing on the box: no files are written (other than the output you redirect),
no module is loaded, no service is restarted. It reads **no passwords and no
reader data**.

Its purpose is to let us trace the per-box choices in the module (bitslice
backend, rebind value, shadow source, kernel quirks) back to what the hardware
actually reports, and to find out on which receivers the module does not work
yet.

## Run it on the box (one line, Telnet/SSH)

```sh
wget -qO /tmp/dmxcsa-boxinfo.sh https://raw.githubusercontent.com/oe-alliance-kernels/dmxcsa-modules/master/boxinfo/dmxcsa-boxinfo.sh && sh /tmp/dmxcsa-boxinfo.sh > /tmp/dmxcsa-boxinfo-$(hostname).txt 2>&1 && echo "DONE: /tmp/dmxcsa-boxinfo-$(hostname).txt"
```

If `wget` on your box has no HTTPS, use `curl`:

```sh
curl -fsSL https://raw.githubusercontent.com/oe-alliance-kernels/dmxcsa-modules/master/boxinfo/dmxcsa-boxinfo.sh | sh > /tmp/dmxcsa-boxinfo-$(hostname).txt 2>&1 && echo "DONE: /tmp/dmxcsa-boxinfo-$(hostname).txt"
```

Then send the **`/tmp/dmxcsa-boxinfo-<box>.txt`** file back, together with your **box model**,
**image/version** and whether descrambling worked.

## What it reports

System and kernel, CPU features (NEON, arch), the relevant kernel config
(`MODVERSIONS`, `KERNEL_MODE_NEON`, `ARM64`/`CPU_V7`/`MIPS`, endianness, `HZ`,
DVB core), loaded modules and their vermagic, the DVB nodes, which driver serves
the demux/ca/video/audio nodes, which processes hold the DVB nodes, and the
installed kernel and libdvbcsa versions.
