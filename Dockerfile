FROM ubuntu AS builder

RUN apt-get update && \
    apt-get -y install wget && \
    apt-get -y install gcc binutils build-essential && \
    apt-get -y install bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo && \
    apt-get -y install libisl-dev && \
    apt-get -y install libcloog-isl-dev

RUN adduser --disabled-password --gecos "" builder
USER builder

ENV HOME=/home/builder

RUN mkdir -p $HOME/opt/cross && mkdir -p $HOME/src

WORKDIR $HOME/src

RUN wget -q https://mirrors.ocf.berkeley.edu/gnu/binutils/binutils-2.34.tar.gz
RUN wget -q https://bigsearcher.com/mirrors/gcc/releases/gcc-10.1.0/gcc-10.1.0.tar.gz

ENV PREFIX="$HOME/opt/cross"
ENV TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"

RUN tar -xzf binutils-2.34.tar.gz
RUN tar -xzf gcc-10.1.0.tar.gz

RUN mkdir build-binutils && \
    mkdir build-gcc

WORKDIR build-binutils

RUN ../binutils-2.34/configure \
      --target=$TARGET \
      --prefix="$PREFIX" \
      --with-sysroot \
      --disable-nls \
      --disable-werror && \
    make && \
    make install

WORKDIR $HOME/src/build-gcc

RUN ../gcc-10.1.0/configure \
      --target=$TARGET \
      --prefix="$PREFIX" \
      --disable-nls \
      --enable-languages=c,c++ \
      --without-headers

# Very time consuming, break up for maximum cachability
RUN make all-gcc
RUN make all-target-libgcc

RUN make install-gcc && \
    make install-target-libgcc

FROM ubuntu

COPY --from=builder /home/builder/opt /home/runner/opt
COPY --from=builder /home/builder/opt /home/runner/opt

RUN apt-get update && \
    apt-get -y install wget && \
    apt-get -y install gcc binutils build-essential && \
    apt-get -y install bison flex libgmp3-dev libmpc-dev libmpfr-dev texinfo && \
    apt-get -y install libisl-dev && \
    apt-get -y install libcloog-isl-dev

RUN apt-get -y install grub-efi-ia32 mtools grub-pc-bin xorriso

RUN adduser --disabled-password --gecos "" runner

USER runner
WORKDIR /home/runner/src

ENV HOME=/home/runner
ENV PREFIX="$HOME/opt/cross"
ENV TARGET=i686-elf
ENV PATH="$PREFIX/bin:$PATH"
