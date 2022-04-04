#!/usr/bin/bash
head -n $(expr $1 + $2) <&0 | tail -n $(expr $2 + 1)
