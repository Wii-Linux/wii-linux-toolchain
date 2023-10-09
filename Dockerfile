FROM ubuntu:22.04

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get -y install tzdata

RUN apt-get update && apt-get install -y gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
    python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
    patch libstdc++6 rsync git meson ninja-build ccache
RUN wget -P /tmp/ http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.xz
RUN cd /tmp/
RUN tar xvf /tmp/crosstool-ng-1.26.0.tar.xz -C /tmp/
ADD ct-ng.config /tmp/crosstool-ng-1.26.0/.config
RUN cd /tmp/crosstool-ng-1.26.0/ && ./configure --enable-local && make && ./ct-ng build
ADD wiiload.tar.gz /opt/
RUN cd /opt/wiiload && make && make install
ENV CROSS_COMPILE=powerpc-unknown-linux-gnu-
ENV ARCH=powerpc
ENV PATH=/root/x-tools/powerpc-unknown-linux-gnu/bin:$PATH
