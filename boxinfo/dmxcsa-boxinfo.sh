#!/bin/sh
# dmxcsa box survey - reads only, changes nothing.
# Usage on the box:  sh /tmp/dmxcsa-boxinfo.sh > /tmp/dmxcsa-boxinfo-$(hostname).txt 2>&1
# Then send that /tmp/dmxcsa-boxinfo-<box>.txt back. No passwords or reader data are read.

echo "== system"
uname -a
cat /proc/cmdline
grep -iE "^distro|^imageversion|^imagebuild|^machinebuild|^model|^box_type" /etc/image-version 2>/dev/null
for f in model boxtype hwmodel chipset vumodel gbmodel; do [ -r /proc/stb/info/$f ] && echo "$f: $(cat /proc/stb/info/$f)"; done
grep -iE "Hardware|model name|Features|CPU part" /proc/cpuinfo | sort -u
opkg print-architecture 2>/dev/null | tail -3

echo "== kernel config"
if [ -r /proc/config.gz ]; then
	zcat /proc/config.gz | grep -E "CONFIG_MODVERSIONS|CONFIG_MODULE_SIG=|CONFIG_KALLSYMS|CONFIG_KERNEL_MODE_NEON|CONFIG_NEON=|CONFIG_ARM64=|CONFIG_CPU_V7=|CONFIG_THUMB2_KERNEL|CONFIG_MIPS=|CONFIG_64BIT=|CONFIG_CPU_BIG_ENDIAN|CONFIG_CPU_LITTLE_ENDIAN|CONFIG_SMP=|CONFIG_PREEMPT=|CONFIG_PREEMPT_NONE|CONFIG_HZ=|CONFIG_DVB_CORE|CONFIG_DVB_MAX_ADAPTERS|CONFIG_DVB_DEMUX|CONFIG_VMAP_STACK|CONFIG_ARM_LPAE|CONFIG_THREAD_INFO_IN_TASK"
else
	echo "no /proc/config.gz"
fi

echo "== modules"
lsmod
ls -la /lib/modules/$(uname -r)/extra/ 2>/dev/null
for f in /lib/modules/$(uname -r)/extra/*.ko /lib/modules/$(uname -r)/extra/*/*.ko; do
	[ -f "$f" ] && echo "-- $(basename $f): $(modinfo $f 2>/dev/null | grep -E "^(vermagic|version|license|depends):" | tr '\n' ' ')"
done
for f in /etc/modules-load.d/*.conf /etc/modprobe.d/*.conf; do
	[ -f "$f" ] && echo "-- $f: $(tr '\n' ' ' < $f)"
done

echo "== dmxcsa"
if [ -r /proc/dmxcsa ]; then
	cat /proc/dmxcsa
else
	echo "dmxcsa not loaded (no /proc/dmxcsa)"
fi

echo "== dvb nodes"
ls /dev/dvb/
ls -l /dev/dvb/adapter0/
ls /sys/class/dvb/ 2>/dev/null
cat /proc/stb/frontend/dvr_source_offset 2>/dev/null || echo "no dvr_source_offset"
cat /proc/bus/nim_sockets 2>/dev/null | grep -iE "NIM Socket|Type|Name|Frontend_Device"

echo "== who serves the dvb devices"
# symbol names only, the kernel addresses are cut off
grep -E " (dvb_register_device|dvb_dmxdev_init|dvb_dmx_init|dvb_generic_ioctl|dvb_generic_open|dvb_demux_ioctl|dvb_demux_read|dvb_dvr_write|dvb_dvr_ioctl|dvb_dmx_swfilter|dvb_dmx_swfilter_packets|dvb_ca_en50221_init)(\s|$)" /proc/kallsyms | sed 's/^[0-9a-fA-F]* //'
grep -iE " t .*(video|audio|ca|dvr|demux|dmx)_(ioctl|write|open|release|poll)(\s|$)" /proc/kallsyms | grep -v "snd_\|v4l\|uvc" | head -40 | sed 's/^[0-9a-fA-F]* //'
grep -iE " (t|T) .*(set_source|ca_set_pid|ca_set_descr|descrambl|keyslot)" /proc/kallsyms | head -40 | sed 's/^[0-9a-fA-F]* //'

echo "== processes holding dvb nodes"
for p in /proc/[0-9]*; do
	n=$(ls -l $p/fd 2>/dev/null | grep -c "/dev/dvb/")
	[ "$n" -gt 0 ] && echo "$(basename $p) $(cat $p/comm 2>/dev/null): $(ls -l $p/fd 2>/dev/null | grep -o '/dev/dvb/adapter[0-9]*/[a-z]*[0-9]*' | sed 's|/dev/dvb/||' | sort | uniq -c | awk '{printf "%s%s ", $2, ($1>1?"x"$1:"")}')"
done

echo "== kernel modules installed"
opkg list-installed 2>/dev/null | grep -E "^kernel-image|libdvbcsa"

echo "== done"
