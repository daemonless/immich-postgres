# PostgreSQL 14 with pgvector + VectorChord for Immich
# Drop-in compatible with official Immich PostgreSQL image

ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION} AS builder

# Build dependencies for pgvector and VectorChord
# FreeBSD-*-dev packages provide libraries needed for Rust linking
# FreeBSD-toolchain provides ar for linking
RUN pkg update && pkg install -y \
    postgresql14-server postgresql14-contrib \
    FreeBSD-bmake FreeBSD-clibs-dev FreeBSD-clang FreeBSD-clang-dev FreeBSD-toolchain \
    FreeBSD-libexecinfo FreeBSD-libexecinfo-dev FreeBSD-runtime-dev FreeBSD-utilities-dev \
    rust gmake git-lite pkgconf \
    && pkg clean -ay

# Fetch minimal ports tree for pgvector
RUN fetch -qo /tmp/ports.tar.gz \
    "http://ftp.freebsd.org/pub/FreeBSD/ports/ports/ports.tar.gz" && \
    mkdir -p /usr/ports && \
    tar -xzf /tmp/ports.tar.gz -C /usr/ports --strip-components=1 \
        ports/databases/pgvector ports/Mk ports/Templates ports/Keywords && \
    rm /tmp/ports.tar.gz

# Build pgvector for PostgreSQL 14
WORKDIR /usr/ports/databases/pgvector
RUN make DEFAULT_VERSIONS+=pgsql=14 BATCH=yes install clean

# Build VectorChord from source
ARG VECTORCHORD_VERSION=0.4.3
RUN fetch -qo /tmp/vectorchord.tar.gz \
    "https://github.com/tensorchord/VectorChord/archive/refs/tags/${VECTORCHORD_VERSION}.tar.gz" && \
    tar -xzf /tmp/vectorchord.tar.gz -C /tmp && \
    cd /tmp/VectorChord-${VECTORCHORD_VERSION} && \
    gmake build && \
    gmake install

# Production image
FROM ghcr.io/daemonless/base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG PKG_NAME=postgresql14-server
ARG PACKAGES="postgresql14-server postgresql14-contrib"

LABEL org.opencontainers.image.title="Immich PostgreSQL" \
    org.opencontainers.image.description="PostgreSQL 14 with pgvector + VectorChord for Immich" \
    org.opencontainers.image.source="https://github.com/daemonless/immich-postgres" \
    org.opencontainers.image.url="https://immich.app/" \
    org.opencontainers.image.licenses="PostgreSQL" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="5432" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.config-mount="/config" \
    io.daemonless.category="Database" \
    io.daemonless.pkg-name="${PKG_NAME}" \
    io.daemonless.packages="${PACKAGES}"

# Install PostgreSQL, then remove LLVM JIT (saves ~2GB, JIT not needed for Immich)
RUN pkg update && \
    pkg install -y ${PACKAGES} && \
    mkdir -p /app && pkg info postgresql14-server | sed -n 's/.*Version.*: *//p' > /app/version && \
    pkg delete -fy llvm19 perl5 python311 || true && \
    pkg autoremove -y || true && \
    pkg clean -ay && \
    rm -rf /var/cache/pkg/* /var/db/pkg/repos/*

# Copy built extensions from builder and fix permissions
COPY --from=builder /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/extension/vector* /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/vchord.so /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/extension/vchord* /usr/local/share/postgresql/extension/
RUN chmod 644 /usr/local/share/postgresql/extension/vchord* && \
    chmod 755 /usr/local/lib/postgresql/vchord.so

# Create data directory
RUN mkdir -p /config/data /run/postgresql && \
    chown -R bsd:bsd /config /run/postgresql

# Copy service files
COPY root/ /
RUN chmod +x /etc/services.d/*/run /etc/cont-init.d/* 2>/dev/null || true

ENV PGDATA=/config/data
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=postgres
ENV POSTGRES_DB=immich

EXPOSE 5432
VOLUME /config
