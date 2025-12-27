# Immich PostgreSQL for FreeBSD

PostgreSQL 14 with pgvector + VectorChord for [Immich](https://immich.app/).

Drop-in compatible with official Immich PostgreSQL image.

## Features

- PostgreSQL 14 (matches official Immich)
- pgvector 0.8.x extension
- VectorChord 0.4.x extension
- Auto-initialization on first run

## Usage

```bash
podman run -d --name immich-postgres \
  --annotation 'org.freebsd.jail.allow.sysvipc=true' \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=immich \
  -v /containers/immich/postgres:/config \
  ghcr.io/daemonless/immich-postgres:latest
```

**Note:** The `org.freebsd.jail.allow.sysvipc=true` annotation is required for PostgreSQL shared memory.

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| POSTGRES_USER | postgres | Database superuser name |
| POSTGRES_PASSWORD | postgres | Superuser password |
| POSTGRES_DB | immich | Default database to create |

## Volumes

- `/config` - Data directory (PGDATA)

## Ports

- `5432` - PostgreSQL

## Extensions

Extensions are automatically enabled:

```sql
CREATE EXTENSION IF NOT EXISTS vector;      -- pgvector
CREATE EXTENSION IF NOT EXISTS vchord;      -- VectorChord
```

## Migration

Your existing Immich PostgreSQL data directory works as-is. Both official and daemonless use PostgreSQL 14 with VectorChord.

## Part of Immich for FreeBSD

See [daemonless/immich](https://github.com/daemonless/immich) for the complete stack.
