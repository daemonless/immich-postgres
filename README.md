# immich-postgres

PostgreSQL 14 with pgvector + VectorChord for [Immich](https://immich.app/).

Drop-in compatible with official Immich PostgreSQL image.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `POSTGRES_USER` | Database superuser name | `postgres` |
| `POSTGRES_PASSWORD` | Superuser password | `postgres` |
| `POSTGRES_DB` | Default database to create | `immich` |
| `PGDATA` | Data directory location | `/config/data` |

## Quick Start

```bash
podman run -d --name immich-postgres \
  --annotation 'org.freebsd.jail.allow.sysvipc=true' \
  -p 5432:5432 \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=immich \
  -v /containers/immich/postgres:/config \
  ghcr.io/daemonless/immich-postgres:latest
```

**Note:** The `org.freebsd.jail.allow.sysvipc=true` annotation is required for PostgreSQL shared memory.

## podman-compose

```yaml
services:
  immich-postgres:
    image: ghcr.io/daemonless/immich-postgres:latest
    container_name: immich-postgres
    environment:
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=immich
    volumes:
      - /data/config/postgres:/config
    ports:
      - 5432:5432
    annotations:
      org.freebsd.jail.allow.sysvipc: "true"
    restart: unless-stopped
```

## Tags

| Tag | Source | Description |
|-----|--------|-------------|
| `:latest` | `databases/postgresql14-server` | FreeBSD latest packages (Alias for :pkg-latest) |
| `:pkg` | `databases/postgresql14-server` | FreeBSD quarterly packages |
| `:pkg-latest` | `databases/postgresql14-server` | FreeBSD latest packages |

## Volumes

| Path | Description |
|------|-------------|
| `/config` | Configuration and data directory (PGDATA is in `/config/data`) |

## Ports

| Port | Description |
|------|-------------|
| 5432 | PostgreSQL |

## Features

- **PostgreSQL 14:** Matches official Immich requirements.
- **pgvector:** 0.8.x extension installed (via ports).
- **VectorChord:** 0.4.x extension installed (built from source).
- **Auto-init:** Extensions enabled automatically on database creation.

## Extensions

Extensions are automatically enabled:

```sql
CREATE EXTENSION IF NOT EXISTS vector;      -- pgvector
CREATE EXTENSION IF NOT EXISTS vchord;      -- VectorChord
```

## Notes

- **User:** `bsd` (UID/GID set via PUID/PGID, default 1000)
- **Base:** Built on `ghcr.io/daemonless/base-image` (FreeBSD)
- **Migration:** Fully compatible with official Immich Postgres data.

## Links

- [Immich](https://immich.app/)
- [PostgreSQL](https://www.postgresql.org/)