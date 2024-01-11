# [Choice] bionic (18.04), focal (20.04)
ARG VARIANT="focal"

FROM ubuntu:${VARIANT} AS build

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
            tzdata gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
            python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
            patch libstdc++6 rsync git meson ninja-build

WORKDIR /build
RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.26.0.tar.xz && \
    tar -xvf crosstool-ng-1.26.0.tar.xz && \
    rm crosstool-ng-1.26.0.tar.xz && \
    cd crosstool-ng-1.26.0 && \
    ./configure --prefix=/usr/local/ct && \
    make && \
    make install && \
    cd .. && \
    rm -rf crosstool-ng-1.26.0
    
ADD ct-ng.config .config
RUN /usr/local/ct/bin/ct-ng build
RUN cd /build/ && git clone https://github.com/fail0verflow/hbc.git /build/hbc && cd /build/hbc/channel/wiiload && make
RUN git clone https://github.com/fail0verflow/bootmii-utils.git /build/bootmii-utils && cd /build/bootmii-utils/client && make 
## Final build image
FROM  ubuntu:${VARIANT}

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
            patch ninja-build make bc ccache gcc libncurses-dev

COPY --from=build /root/x-tools/powerpc-unknown-linux-gnu/ /usr/local/crosstool
COPY --from=build /build/hbc/channel/wiiload/wiiload /usr/local/crosstool/bin/wiiload
COPY --from=build /build/hbc/channel/wiiload/bootmii /usr/local/crosstool/bin/bootmii

ENV PATH=/usr/local/crosstool/bin:$PATH
ENV CROSS_COMPILE=powerpc-unknown-linux-gnu-
ENV CC=powerpc-unknown-linux-gnu-gcc
ENV ARCH=powerpc

WORKDIR /code
