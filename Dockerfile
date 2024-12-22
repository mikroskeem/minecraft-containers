ARG UBUNTU_VERSION=22.04
#ARG JVM_DOWNLOAD_URL
#ARG JVM_SHA256_CHECKSUM
#ARG JVM_VERSION

FROM ubuntu:${UBUNTU_VERSION} AS dep-jvm

# NOTE: while jvm unpacking does not require cmake nor build-essential, they're here because this layer can be cached & shared with other steps
RUN    env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl cmake tar build-essential

ARG JVM_DOWNLOAD_URL
ARG JVM_SHA256_CHECKSUM
ARG JVM_VERSION

RUN    set -x \
    && curl -s -L -o /jvm.tar.gz "${JVM_DOWNLOAD_URL}" \
    && mkdir -p "/opt/jvm/${JVM_VERSION}" \
    && test "$(sha256sum /jvm.tar.gz | cut -d' ' -f1)" = "${JVM_SHA256_CHECKSUM}" \
    && tar --strip-components=1 -C "/opt/jvm/${JVM_VERSION}" -xvf /jvm.tar.gz \
    && rm /jvm.tar.gz

FROM ubuntu:${UBUNTU_VERSION} AS dep-jemalloc

RUN    env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl cmake tar build-essential

ARG JEMALLOC_VERSION=5.3.0
RUN    mkdir -p "/build/jemalloc-${JEMALLOC_VERSION}/build" \
    && curl -s -L -o /jemalloc.tar.bz2 "https://github.com/jemalloc/jemalloc/releases/download/${JEMALLOC_VERSION}/jemalloc-${JEMALLOC_VERSION}.tar.bz2" \
    && tar --strip-components=1 -C "/build/jemalloc-${JEMALLOC_VERSION}" -xf /jemalloc.tar.bz2 \
    && rm /jemalloc.tar.bz2 \
    && cd "/build/jemalloc-${JEMALLOC_VERSION}/build" \
    && "/build/jemalloc-${JEMALLOC_VERSION}/configure" --prefix=/opt/jemalloc --enable-shared --disable-static --enable-prof --enable-debug --enable-log --with-malloc-conf \
    && make -j"$(grep -c "^processor" /proc/cpuinfo)" build_lib_shared \
    && make install_lib_shared

FROM ubuntu:${UBUNTU_VERSION} AS dep-mimalloc

RUN    env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y curl cmake tar build-essential

ARG MIMALLOC_VERSION=v2.1.2
RUN    mkdir -p "/build/mimalloc-${MIMALLOC_VERSION}/build" \
    && curl -s -L -o /mimalloc.tar.gz "https://github.com/microsoft/mimalloc/archive/refs/tags/${MIMALLOC_VERSION}.tar.gz" \
    && tar --strip-components=1 -C "/build/mimalloc-${MIMALLOC_VERSION}" -xf /mimalloc.tar.gz \
    && rm /mimalloc.tar.gz \
    && cd "/build/mimalloc-${MIMALLOC_VERSION}/build" \
    && cmake .. -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_LIBDIR=/opt/mimalloc/lib -DMI_INSTALL_TOPLEVEL=ON -DMI_BUILD_STATIC=OFF -DMI_BUILD_OBJECT=OFF \
    && make -j"$(grep -c "^processor" /proc/cpuinfo)" \
    && make install

FROM ubuntu:${UBUNTU_VERSION} AS final

RUN    env DEBIAN_FRONTEND=noninteractive apt-get update \
    && env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends catatonit curl tar sqlite tzdata locales iproute2 \
    && env DEBIAN_FRONTEND=noninteractive apt-get clean

RUN    locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8 \
    && ln -svf /usr/share/zoneinfo/UTC /etc/localtime

# Set up container user
RUN    groupadd -g 1000 container \
    && useradd -d /home/container -m -u 1000 -g 1000 container

# Set up default user and environment
USER container
WORKDIR /home/container

COPY --from=dep-jemalloc /opt/jemalloc /opt/jemalloc
COPY --from=dep-mimalloc /opt/mimalloc /opt/mimalloc

ENV USER=container
ENV HOME=/home/container

ARG JVM_VERSION
COPY --from=dep-jvm /opt/jvm /opt/jvm
ENV JAVA_HOME="/opt/jvm/${JVM_VERSION}"
ENV PATH="${JAVA_HOME}/bin:${PATH}"
ENV LANG=en_US.UTF-8

VOLUME /tmp

COPY ./entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/usr/bin/catatonit", "--"]
CMD ["/entrypoint.sh"]
