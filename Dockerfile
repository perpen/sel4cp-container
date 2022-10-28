FROM ubuntu:18.04
COPY provision /
RUN /provision
COPY dev_build.py.patch /tmp
RUN cd /sel4cp && patch -p1 </tmp/dev_build.py.patch && mkdir tmp
ENV PATH /usr/local/musl/bin:/gcc-aarch64/bin:$PATH
