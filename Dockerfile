FROM adoptopenjdk/openjdk8:jdk8u212-b03
LABEL maintainer="Mark Vainomaa <mikroskeem@mikroskeem.eu>"

# Set up base system
RUN    DEBIAN_FRONTEND=noninteractive apt-get -y update \
    && DEBIAN_FRONTEND=noninteractive apt-get -y install curl git tar sqlite tzdata locales iproute2 libjemalloc1 \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
    && rm -rf /var/lib/apt/lists/*

# Set up container user
RUN    groupadd -g 1000 container \
    && useradd -d /home/container -m -u 1000 -g 1000 container

# Set up default user and environment
USER container
ENV USER=container HOME=/home/container LANG=en_US.UTF-8
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
