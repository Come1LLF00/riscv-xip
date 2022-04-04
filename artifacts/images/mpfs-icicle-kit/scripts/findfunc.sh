#!/usr/bin/bash
grep -n $1 <&0 | awk -F: '{print $1}'
