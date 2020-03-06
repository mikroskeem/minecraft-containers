FROM quay.io/mikroskeem/ubuntu-devel:ubuntu_18.04_vanilla
WORKDIR /root

# Install jemalloc
RUN curl -L https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 \
    | tar -xvjf - \
    && cd jemalloc-5.2.1 \
    && ./configure --prefix=/opt/jemalloc --enable-prof --enable-debug --enable-log --with-malloc-conf \
    && make -j2 \
    && make install

# Install mimalloc
RUN curl -L https://github.com/microsoft/mimalloc/archive/v1.6.1.tar.gz \
    | tar -xvzf - \
    && mkdir -p mimalloc-1.6.1/out \
    && cd mimalloc-1.6.1/out \
    && cmake .. \
    && make -j2 \
    && install -D -m 755 -s -o root -g root libmimalloc.so /opt/mimalloc/libmimalloc.so

FROM adoptopenjdk/openjdk11:jdk-11.0.4_11
LABEL maintainer="Mark Vainomaa <mikroskeem@mikroskeem.eu>"

# Set up base system
RUN    DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install curl git tar sqlite tzdata locales iproute2 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && rm -rf /var/lib/apt/lists/*

COPY --from=0 /opt/jemalloc /opt/jemalloc
COPY --from=0 /opt/mimalloc /opt/mimalloc

# Set up container user
RUN    groupadd -g 1000 container \
    && useradd -d /home/container -m -u 1000 -g 1000 container

# Set up default user and environment
USER container
ENV USER=container HOME=/home/container LANG=en_US.UTF-8
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
