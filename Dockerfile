ARG VARIANT="noble"

FROM ubuntu:${VARIANT} AS build

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
            tzdata gcc g++ gperf bison flex texinfo help2man make libncurses5-dev \
            python3-dev autoconf automake libtool libtool-bin gawk wget bzip2 xz-utils unzip \
            patch libstdc++6 libzstd-dev pkg-config rsync git meson ninja-build

WORKDIR /build
RUN wget http://crosstool-ng.org/download/crosstool-ng/crosstool-ng-1.29.0.tar.xz && \
    tar -xvf crosstool-ng-1.29.0.tar.xz && \
    rm crosstool-ng-1.29.0.tar.xz && \
    cd crosstool-ng-1.29.0 && \
    ./configure --prefix=/usr/local/ct && \
    make && \
    make install && \
    cd .. && \
    rm -rf crosstool-ng-1.29.0

# to store downloaded source temporarily
RUN mkdir src
ADD ppc-wii-gcc13.config .config
RUN /usr/local/ct/bin/ct-ng build
ADD armeb-starlet-gcc8.config .config
RUN /usr/local/ct/bin/ct-ng build
RUN cd /build/ && git clone https://github.com/fail0verflow/hbc.git /build/hbc && cd /build/hbc/channel/wiiload && make
RUN git clone https://github.com/fail0verflow/bootmii-utils.git /build/bootmii-utils && cd /build/bootmii-utils/client && make 
## Final build image
FROM  ubuntu:${VARIANT}

RUN DEBIAN_FRONTEND="noninteractive" apt-get update && \
    DEBIAN_FRONTEND="noninteractive" apt-get -y install \
            patch ninja-build make bc ccache gcc libncurses-dev \
            kmod bison flex libssl-dev openssl && \
    DEBIAN_FRONTEND="noninteractive" apt clean

COPY --from=build /root/x-tools/ /usr/local/crosstool
COPY --from=build /build/hbc/channel/wiiload/wiiload /usr/local/crosstool/bin/wiiload
COPY --from=build /build/bootmii-utils/client/bootmii /usr/local/crosstool/bin/bootmii

ENV PATH=/usr/local/crosstool/powerpc-unknown-linux-gnu/bin:/usr/local/crosstool/armeb-eabi/bin:$PATH
# Linux
ENV CROSS_COMPILE=powerpc-unknown-linux-gnu-
ENV CC=powerpc-unknown-linux-gnu-gcc
ENV ARCH=powerpc
# BootMii/MINI
ENV WIIDEV=/usr/local/crosstool/armeb-eabi/

WORKDIR /code
