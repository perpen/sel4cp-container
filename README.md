Quick/dirty hack for experimenting with sel4cp.

Creates a container with:
- sel4, sel4cp
- the xilinx qemu, required for testing the builtin sel4cp example zcu102/hello

Use of `./dev` script:
```
# start a shell in the container
./dev shell
# run dev_build.py, artifacts stored under `./tmp/build`
./dev entrypoint dev-build --example hello --board zcu102
# runs the hello image in qemu
./dev entrypoint qemu
```
