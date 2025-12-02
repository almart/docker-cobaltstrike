FROM kalilinux/kali-rolling

ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v0.4.1"  
# Update system + install only what we actually need
RUN apt-get -y update && apt-get -y dist-upgrade && apt-get clean

# Java 17 is required for CS 4.12+
RUN apt-get update-alternatives --remove-all java || true && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iproute2 \
        openjdk-17-jdk \              # ← changed from 11 to 17
        expect \
    `# still needed by your entrypoint probably` \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Make Java 17 the default (Kali already does this, but be explicit)
RUN update-java-alternatives -s java-1.17.0-openjdk-amd64 || true

WORKDIR /opt
RUN mkdir /opt/cobaltstrike

COPY ./docker-entrypoint.sh /opt/
RUN chmod +x /opt/docker-entrypoint.sh

WORKDIR /opt/cobaltstrike 

EXPOSE 50050

ENTRYPOINT ["/opt/docker-entrypoint.sh"]
STOPSIGNAL SIGKILL

LABEL org.opencontainers.image.ref.name="warhorse/cobaltstrike" \
      org.opencontainers.image.created=$BUILD_RFC3339 \
      org.opencontainers.image.authors="warhorse <warhorse@thedarkcloud.net>" \
      org.opencontainers.image.documentation="https://github.com/war-horse/docker-cobaltstrike/README.md" \
      org.opencontainers.image.description="Cobaltstrike Docker Build" \
      org.opencontainers.image.licenses="GPLv3" \
      org.opencontainers.image.source="https://github.com/war-horse/docker-cobaltstrike" \
      org.opencontainers.image.revision=$COMMIT \
      org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.url="https://hub.docker.com/r/warhorse/cobaltstrike/"

ENV BUILD_RFC3339 "$BUILD_RFC3339"
ENV COMMIT "$COMMIT"
ENV VERSION "$VERSION"
