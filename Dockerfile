# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:18.04

# deps for building sel4cp
RUN <<EOF
set -ex
apt-get update -y
DEBIAN_FRONTEND=noninteractive TZ=Europe/London apt-get install -y \
        tzdata \
        sudo \
        vim \
        kakoune \
        less \
        build-essential \
        git \
        curl \
        software-properties-common \
        libxml2-utils \
        texlive-latex-base \
        texlive-fonts-recommended \
        texlive-formats-extra \
        pandoc \
        ninja-build \
        gcc-aarch64-linux-gnu \
        device-tree-compiler \
        ca-certificates \
        gnupg
EOF

# recent cmake
RUN <<EOF
set -ex
curl -f https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
apt-get install -y cmake
EOF

# python 3.9
RUN <<EOF
set -ex
add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get install -y python3.9 python3.9-venv
cd /
python3.9 -m venv pyenv
/pyenv/bin/pip install --upgrade pip \
    setuptools \
    wheel \
    jinja2 \
    pyfdt \
    pyyaml \
    ply\
    six\
    future
EOF

# musl
RUN <<EOF
set -ex
git clone https://github.com/bminor/musl.git /musl
cd /musl
git checkout v1.2.2
./configure
make -j$(nproc)
make install
EOF
ENV PATH /usr/local/musl/bin:$PATH

# gcc-arm
RUN <<EOF
set -ex
mkdir /gcc-aarch64
curl -sL 'https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz?revision=79f65c42-1a1b-43f2-acb7-a795c8427085&hash=61BBFB526E785D234C5D8718D9BA8E61' \
| tar xJf - -C /gcc-aarch64 --strip-components=1
EOF
ENV PATH /gcc-aarch64/bin:$PATH

# version of sel4 required by sel4cp
RUN <<EOF
set -ex
git clone https://github.com/BreakawayConsulting/seL4.git /sel4
cd /sel4
git checkout 92f0f3ab28f00c97851512216c855f4180534a60
EOF

# sel4cp
RUN <<EOF
set -ex
git clone https://github.com/BreakawayConsulting/sel4cp.git /sel4cp
/pyenv/bin/pip install -r /sel4cp/requirements.txt
cd /sel4cp
/pyenv/bin/python build_sdk.py --sel4=/sel4
EOF

# patch dev_build.py to build into a subdir which can be mounted as a volume
COPY dev_build.py.patch /tmp
RUN <<EOF
set -ex
cd /sel4cp
patch -p1 </tmp/dev_build.py.patch
mkdir tmp
EOF
ENV PATH /usr/local/musl/bin:/gcc-aarch64/bin:$PATH

# the xilinx qemu, see https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/822312999/Building+and+Running+QEMU+from+Source+Code
RUN <<EOF
sudo apt install -y libglib2.0-dev libgcrypt20-dev zlib1g-dev autoconf automake libtool bison flex libpixman-1-dev
cd
git clone https://github.com/Xilinx/qemu.git /xilinx-qemu
cd /xilinx-qemu
git checkout xilinx_v2022.2
git submodule update --init dtc
mkdir build
cd build
../configure --target-list=aarch64-linux-user,aarch64-softmmu --enable-fdt
make -j$(nproc)
make install
cd
rm -rf /xilinx-qemu
EOF

# Generate zcu102-arm.dtb etc
RUN <<EOF
set -ex
cd
git clone https://github.com/Xilinx/qemu-devicetrees.git /qemu-devicetrees
cd /qemu-devicetrees
make
find . -name zcu102-arm.dtb
EOF

COPY /entrypoint /
ENTRYPOINT ["/entrypoint"]
