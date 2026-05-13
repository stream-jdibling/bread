# Bread Calculator — Reverse Proxy Migration Spec

## Context

The calculator is live. This spec rewires the bread container to sit behind the `darkstar-proxy` Caddy reverse proxy rather than handling TLS itself. The `index.html` does not change.

## Decisions Already Made

- Caddy reverse proxy lives in a separate `darkstar-proxy` repo and owns ports 80/443
- Bread container joins the external `proxy` Docker network
- Bread container publishes no ports to the host — only reachable via Caddy
- TLS and domain routing are handled entirely by the proxy — bread serves plain HTTP internally
- `darkstar-proxy` must be deployed before bread

## Before Writing Any Code

1. Read the existing `Dockerfile`, `docker-compose.yml`, and `Makefile`
2. Explain your intended approach — what changes and why
3. Wait for confirmation before writing anything

## File Changes

### Dockerfile

Swap Caddy for nginx — bread just serves a static file over plain HTTP now. TLS is the proxy's job.

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
```

### docker-compose.yml

```yaml
services:
  bread:
    build: .
    expose:
      - "80"
    networks:
      - proxy
    restart: unless-stopped

networks:
  proxy:
    external: true
    name: proxy
```

Key points:
- `expose` makes port 80 visible to other containers on the `proxy` network — it does NOT publish to the host
- `external: true` — this network is owned by `darkstar-proxy`, not this compose file
- No `Caddyfile` needed — remove it if it exists

### Makefile

```makefile
DARKSTAR := 192.168.1.192

deploy:
	rsync -av --exclude='.git' . stream@$(DARKSTAR):~/bread/
	ssh stream@$(DARKSTAR) "cd ~/bread && docker compose up -d --build"
```

## Implementation Order

1. Update `Dockerfile`
2. Update `docker-compose.yml`
3. Remove `Caddyfile` if present
4. Update `Makefile` if needed

## Prerequisites

`darkstar-proxy` must already be deployed and the `proxy` network must exist on darkstar before deploying bread. If it doesn't exist, `docker compose up` will fail with a network not found error.

## Deploy & Verify

1. Confirm `proxy` network exists: `docker network ls | grep proxy`
2. Run `make deploy`
3. Verify bread container is on the proxy network: `docker network inspect proxy`
4. Verify `https://bread.aldenkitchen.com` loads correctly (Caddy issues cert on first request — may take ~30 seconds)
5. Confirm no ports are published directly on the bread container: `docker ps` should show no port mappings for bread
6. Do not mark complete until HTTPS URL is confirmed working