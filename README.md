# Immich PostgreSQL

PostgreSQL 14 with pgvector/pgvecto.rs extensions for Immich.

| | |
|---|---|
| **Port** | 5432 |
| **Registry** | `ghcr.io/daemonless/immich-postgres` |
| **Source** | [https://github.com/immich-app/immich](https://github.com/immich-app/immich) |
| **Website** | [https://immich.app/](https://immich.app/) |

## Deployment

### Podman Compose

```yaml
services:
  immich-postgres:
    image: ghcr.io/daemonless/immich-postgres:latest
    container_name: immich-postgres
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=immich
    volumes:
      - /path/to/containers/immich/postgres:/var/lib/postgresql/data
    ports:
      - 5432:5432
    restart: unless-stopped
```

### Podman CLI

```bash
podman run -d --name immich-postgres \
  -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=immich \
  -v /path/to/containers/immich/postgres:/var/lib/postgresql/data \ 
  ghcr.io/daemonless/immich-postgres:latest
```
Access at: `http://localhost:5432`

### Ansible

```yaml
- name: Deploy immich-postgres
  containers.podman.podman_container:
    name: immich-postgres
    image: ghcr.io/daemonless/immich-postgres:latest
    state: started
    restart_policy: always
    env:
      POSTGRES_USER: "postgres"
      POSTGRES_PASSWORD: "postgres"
      POSTGRES_DB: "immich"
    ports:
      - "5432:5432"
    volumes:
      - "/path/to/containers/immich/postgres:/var/lib/postgresql/data"
```

## Configuration
### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_USER` | `postgres` | Database superuser (default: postgres) |
| `POSTGRES_PASSWORD` | `postgres` | Database password (default: postgres) |
| `POSTGRES_DB` | `immich` | Database name (default: immich) |
### Volumes

| Path | Description |
|------|-------------|
| `/var/lib/postgresql/data` | Database data directory |
### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `5432` | TCP | PostgreSQL Port |

This image is part of the [Immich Stack](https://daemonless.io/images/immich).

## Notes

- **User:** `postgres` (UID/GID set via PUID/PGID)
- **Base:** Built on `ghcr.io/daemonless/base` (FreeBSD)