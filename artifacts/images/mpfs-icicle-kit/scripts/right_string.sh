#!/usr/bin/bash
riscv64-linux-gcc -o example.o -c example.S
riscv64-linux-objdump -d example.o
