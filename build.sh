#!/bin/bash
nasm -felf64 bo.asm -o bo.o
gcc -o bo bo.o
