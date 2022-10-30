Quick/dirty packaging of sel4cp as a docker container.

The sel4cp README instructions are written for ubuntu, and have specific requirements
about the versions of dependencies.
However 1. my main machine runs arch linux and 2. I don't want to pollute
my machine with all the dependencies. Hence the use of a container.

Disclaimer: I have only been learning about sel4 over the last few days, I am
only handling here the use cases I know about.

The container contains:
- sel4, sel4cp
- the xilinx qemu, required for testing the builtin sel4cp example zcu102/hello

The provided script `sel4cp-cont` invokes the container to compile examples and run
them with qemu (zcu102 only atm).

Usage:
```
# build the container image (requires docker buildx to be installed)
./sel4cp-cont docker-build

# add the script to your PATH, eg
ln -s $(pwd)/sel4cp-cont ~/bin

# create a new dir hosting your own examples
mkdir /tmp/my-sel4cp-examples
cd /tmp/my-sel4cp-examples

# start with the official examples
cp -r /some/path/sel4cp/examples .

# run dev_build.py, artifacts will be created under `./tmp/build`
sel4cp-cont dev-build --example hello --board zcu102

# runs the hello image in qemu
sel4cp-cont qemu

# start a shell in the container
sel4cp-cont shell
```
