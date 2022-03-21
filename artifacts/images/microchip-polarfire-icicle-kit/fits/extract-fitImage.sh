#!/usr/bin/bash
dumpimage -l $1
dumpimage -T flat_dt -p 0 -o $1_kernel $1
dumpimage -T flat_dt -p 1 -o $1_ramdisk $1
dumpimage -T flat_dt -p 2 -o $1_fdt $1
