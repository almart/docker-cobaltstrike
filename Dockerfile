FROM kalilinux/kali-rolling

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v0.5.0"

ENV DEBIAN_FRONTEND=noninteractive

# Clean and update first
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get update --fix-missing && \
    apt-get -y dist-upgrade

# Install ca-certificates-java first to avoid OpenJDK dependency issues
RUN apt-get install -y --no-install-recommends ca-certificates-java

# Now install the rest (using default-jdk which is OpenJDK 17 on Kali Rolling)
RUN apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iproute2 \
        default-jdk \
        expect \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN update-java-alternatives -s java-1.17.0-openjdk-amd64 2>/dev/null || true

WORKDIR /opt
RUN mkdir -p /opt/cobaltstrike

COPY ./docker-entrypoint.sh /opt/
RUN chmod +x /opt/docker-entrypoint.sh

WORKDIR /opt/cobaltstrike

EXPOSE 50050

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
STOPSIGNAL SIGKILL

LABEL org.opencontainers.image.ref.name="warhorse/cobaltstrike" \
      org.opencontainers.image.created="${BUILD_RFC3339}" \
      org.opencontainers.image.authors="warhorse <warhorse@thedarkcloud.net>" \
      org.opencontainers.image.documentation="https://github.com/war-horse/docker-cobaltstrike/README.md" \
      org.opencontainers.image.description="Cobalt Strike Teamserver in Docker" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/war-horse/docker-cobaltstrike" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.url="https://hub.docker.com/r/warhorse/cobaltstrike/"

ENV BUILD_RFC3339="${BUILD_RFC3339}" \
    COMMIT="${COMMIT}" \
    VERSION="${VERSION}"
