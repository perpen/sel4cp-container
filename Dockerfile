# syntax=docker/dockerfile:1.3-labs
FROM ubuntu:18.04

RUN <<EOF
set -e
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

RUN <<EOF
set -e
curl -f https://apt.kitware.com/keys/kitware-archive-latest.asc | apt-key add -
apt-add-repository 'deb https://apt.kitware.com/ubuntu/ bionic main'
apt-get install -y cmake
EOF

RUN <<EOF
set -e
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

RUN <<EOF
set -e
git clone https://github.com/bminor/musl.git /musl
cd /musl
git checkout v1.2.2
./configure
make -j$(nproc)
make install
EOF
ENV PATH /usr/local/musl/bin:$PATH

RUN <<EOF
set -e
mkdir /gcc-aarch64
curl -sL 'https://developer.arm.com/-/media/Files/downloads/gnu-a/10.2-2020.11/binrel/gcc-arm-10.2-2020.11-x86_64-aarch64-none-elf.tar.xz?revision=79f65c42-1a1b-43f2-acb7-a795c8427085&hash=61BBFB526E785D234C5D8718D9BA8E61' \
| tar xvJf - -C /gcc-aarch64 --strip-components=1
EOF
ENV PATH /gcc-aarch64/bin:$PATH

RUN <<EOF
set -e
git clone https://github.com/BreakawayConsulting/seL4.git /sel4
cd /sel4
git checkout 92f0f3ab28f00c97851512216c855f4180534a60
EOF

RUN <<EOF
set -e
git clone https://github.com/BreakawayConsulting/sel4cp.git /sel4cp
/pyenv/bin/pip install -r /sel4cp/requirements.txt
cd /sel4cp
/pyenv/bin/python build_sdk.py --sel4=/sel4
EOF

# Patch dev_build.py to build into a subdir which can be mounted as a volume
COPY dev_build.py.patch /tmp
RUN <<EOF
set -e
cd /sel4cp
patch -p1 </tmp/dev_build.py.patch
mkdir tmp
EOF
ENV PATH /usr/local/musl/bin:/gcc-aarch64/bin:$PATH

WORKDIR /sel4cp
ENTRYPOINT ["/pyenv/bin/python", "dev_build.py"]
