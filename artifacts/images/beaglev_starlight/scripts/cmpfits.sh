#!/usr/bin/bash
dumpimage -l $1 | diff - <(dumpimage -l $2)
