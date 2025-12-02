FROM kalilinux/kali-rolling

# Build arguments for proper OCI image labels
ARG BUILD_RFC3339="1970-01-01T00:00:00Z"
ARG COMMIT="local"
ARG VERSION="v0.5.0"

# Prevent interactive prompts during build
ENV DEBIAN_FRONTEND=noninteractive

# System update + install required packages (Java 17 + utilities)
RUN apt-get update && \
    apt-get -y dist-upgrade && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        iproute2 \
        openjdk-17-jdk \
        expect \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Explicitly set Java 17 as default (safe, works even if multiple JDKs present)
RUN update-java-alternatives -s java-1.17.0-openjdk-amd64 2>/dev/null || \
    echo "java-1.17.0-openjdk-amd64" | alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-openjdk-amd64/bin/java 1710

# Create directories
WORKDIR /opt
RUN mkdir -p /opt/cobaltstrike

# Copy your entrypoint script
COPY ./docker-entrypoint.sh /opt/
RUN chmod +x /opt/docker-entrypoint.sh

# Working directory for Cobalt Strike
WORKDIR /opt/cobaltstrike

# Expose default teamserver port
EXPOSE 50050

# Use your existing entrypoint
ENTRYPOINT ["/opt/docker-entrypoint.sh"]
STOPSIGNAL SIGKILL

# Proper OCI image labels
LABEL org.opencontainers.image.ref.name="warhorse/cobaltstrike" \
      org.opencontainers.image.created="${BUILD_RFC3339}" \
      org.opencontainers.image.authors="warhorse <warhorse@thedarkcloud.net>" \
      org.opencontainers.image.documentation="https://github.com/war-horse/docker-cobaltstrike/README.md" \
      org.opencontainers.image.description="Cobalt Strike Teamserver in Docker — Kali-based, Java 17, ready for 4.12+" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.source="https://github.com/war-horse/docker-cobaltstrike" \
      org.opencontainers.image.revision="${COMMIT}" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.url="https://hub.docker.com/r/warhorse/cobaltstrike/" \
      org.opencontainers.image.title="docker-cobaltstrike" \
      org.opencontainers.image.description="A Cobalt Strike container, built for Warhorse"

# Export build args as environment variables (optional, for runtime inspection)
ENV BUILD_RFC3339="${BUILD_RFC3339}" \
    COMMIT="${COMMIT}" \
    VERSION="${VERSION}"
