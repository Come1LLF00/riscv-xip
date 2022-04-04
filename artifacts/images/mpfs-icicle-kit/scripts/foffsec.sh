#!/usr/bin/bash
grep $1 <&0 | awk -F' ' '{print $6}'
