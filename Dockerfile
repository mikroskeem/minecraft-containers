FROM quay.io/mikroskeem/ubuntu-devel:ubuntu_18.04_vanilla
WORKDIR /root
RUN curl -L https://github.com/jemalloc/jemalloc/releases/download/5.2.0/jemalloc-5.2.0.tar.bz2 \
    | tar -xvjf - \
    && cd jemalloc-5.2.0 \
    && ./configure --prefix=/opt/jemalloc --enable-prof --enable-debug --enable-log --with-malloc-conf \
    && make -j2 \
    && make install

FROM adoptopenjdk/openjdk8-openj9:jdk8u212-b04_openj9-0.14.2
LABEL maintainer="Mark Vainomaa <mikroskeem@mikroskeem.eu>"

# Set up base system
RUN    DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install curl git tar sqlite tzdata locales iproute2 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && rm -rf /var/lib/apt/lists/*

COPY --from=0 /opt/jemalloc /opt/jemalloc

# Set up container user
RUN    groupadd -g 1000 container \
    && useradd -d /home/container -m -u 1000 -g 1000 container

# Set up default user and environment
USER container
ENV USER=container HOME=/home/container LANG=en_US.UTF-8
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
