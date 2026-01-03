# Immich PostgreSQL - layers pgvector + VectorChord on top of postgres:14
# Drop-in compatible with official Immich PostgreSQL image

ARG BASE_VERSION=15
ARG PG_VERSION=14

# Builder stage - compile extensions
FROM ghcr.io/daemonless/base:${BASE_VERSION} AS builder
ARG PG_VERSION

# Build dependencies
RUN pkg update && pkg install -y \
    postgresql${PG_VERSION}-server postgresql${PG_VERSION}-contrib \
    FreeBSD-bmake FreeBSD-clibs-dev FreeBSD-clang FreeBSD-clang-dev FreeBSD-toolchain \
    FreeBSD-libexecinfo FreeBSD-libexecinfo-dev FreeBSD-runtime-dev FreeBSD-utilities-dev \
    rust gmake git-lite pkgconf \
    && pkg clean -ay

# Fetch minimal ports tree for pgvector
RUN fetch -qo /tmp/ports.tar.zst \
    "https://download.freebsd.org/ports/ports/ports.tar.zst" && \
    mkdir -p /usr/ports && \
    tar -xf /tmp/ports.tar.zst -C /usr/ports --strip-components=1 \
        ports/databases/pgvector ports/Mk ports/Templates ports/Keywords && \
    rm /tmp/ports.tar.zst

# Build pgvector for PostgreSQL 14
WORKDIR /usr/ports/databases/pgvector
RUN make DEFAULT_VERSIONS+=pgsql=${PG_VERSION} BATCH=yes install clean

# Build VectorChord from source (not in ports)
ARG VECTORCHORD_VERSION=0.4.3
RUN fetch -qo /tmp/vectorchord.tar.gz \
    "https://github.com/tensorchord/VectorChord/archive/refs/tags/${VECTORCHORD_VERSION}.tar.gz" && \
    tar -xzf /tmp/vectorchord.tar.gz -C /tmp && \
    cd /tmp/VectorChord-${VECTORCHORD_VERSION} && \
    gmake build && \
    gmake install

# Production image - layer on postgres:14
ARG PG_VERSION
FROM localhost/postgres:${PG_VERSION}

ARG FREEBSD_ARCH=amd64
ARG VECTORCHORD_VERSION=0.4.3

LABEL org.opencontainers.image.title="Immich PostgreSQL" \
    org.opencontainers.image.description="PostgreSQL 14 with pgvector + VectorChord for Immich" \
    org.opencontainers.image.source="https://github.com/daemonless/immich-postgres" \
    org.opencontainers.image.url="https://immich.app/" \
    org.opencontainers.image.licenses="PostgreSQL" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="5432" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.category="Databases" \
    io.daemonless.vectorchord-version="${VECTORCHORD_VERSION}"

# Copy built extensions from builder
COPY --from=builder /usr/local/lib/postgresql/vector.so /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/extension/vector* /usr/local/share/postgresql/extension/
COPY --from=builder /usr/local/lib/postgresql/vchord.so /usr/local/lib/postgresql/
COPY --from=builder /usr/local/share/postgresql/extension/vchord* /usr/local/share/postgresql/extension/

# Fix permissions
RUN chmod 644 /usr/local/share/postgresql/extension/vchord* && \
    chmod 755 /usr/local/lib/postgresql/vchord.so

# Immich-specific defaults
ENV POSTGRES_DB=immich
