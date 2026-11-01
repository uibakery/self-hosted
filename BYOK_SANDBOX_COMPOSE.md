# Self-hosted AI chat: sandboxes with Docker Compose

> Local draft. Release-matched API/runtime images must be supplied and validated
> on Linux before publication. The runtime repository shown below is the proposed
> release layout; it still needs publishing with the same tags as Bakery.

Use this setup for **BYOK with self-hosted Chat**. Configure Chat, models and
storage using [Self-hosted AI chat setup](https://docs.uibakery.io/on-premise/additional-configurations/self-hosted-ai-chat-setup),
then follow this page for sandboxes. Managed Chat needs no local sandboxes.

Use a Linux/amd64 host with Docker Engine and Compose 2.23.1+. This example keeps
**one agent and one build ready**, each limited to 1 GiB RAM, plus API/provider
services. It uses `runc` and OpenSandbox's native egress sidecar. Containers share
the host kernel; only the trusted provider receives the host Docker socket.

**No configuration bundle to download and no new local folders or env files.**
Edit the installation's existing `.env` and `docker-compose.yml` below.

## 1. Set installation values

Add these values to `.env`, replacing the placeholders:

```dotenv
UI_BAKERY_DOCKER_SANDBOX_API_KEY=<client key>
UI_BAKERY_SANDBOX_PROVIDER_API_KEY=<different provider key>
```

Generate each of the two keys separately with `openssl rand -hex 32`.

Both Bakery sandbox images use the installation's existing `UI_BAKERY_VERSION`,
just like the other Bakery services; no separate sandbox version variables are
needed. The example follows the existing `latest` fallback when it is unset.

On initial setup, run this on the Linux Docker host to add its bridge address to
`.env` automatically (do not add a second entry if one already exists):

```bash
docker network inspect bridge --format 'SANDBOX_DOCKER_BRIDGE_IP={{(index .IPAM.Config 0).Gateway}}' >> .env
```

This is the Docker host's IPv4 address as seen from containers, commonly
`172.17.0.1`. The provider binds sandbox control ports to it, and the API connects
to those ports. It is not the public server IP or the address of the Compose
service. Detect it rather than hardcoding a value: Docker address ranges vary.

Keep `.env` private and outside Git. Attachment access is optional and configured
below; it does not require another environment variable.

## 2. Add the sandbox services

Merge the following into `docker-compose.yml`: add the two services under its
existing `services`, and the config/volume under `configs` and `volumes`.
Do not create duplicate top-level sections. If Chat uses a custom network,
attach both services to that network.

The internal provider, pool, resource and security settings are included below;
you do not need separate API/provider configuration files.

<details>
<summary>Compose configuration — copy into docker-compose.yml</summary>

```yaml
services:
  opensandbox:
    image: opensandbox/server:release-1.1.1@sha256:bcd5f264101262cebfa7e1ff9cd0424403e42f31a6596e4364cf90d8cb5c936b
    user: 0:0
    init: true
    restart: unless-stopped
    environment:
      SANDBOX_CONFIG_PATH: /etc/opensandbox/config.toml
      DOCKER_CONFIG: /run/docker-auth
      OPENSANDBOX_SERVER_API_KEY: ${UI_BAKERY_SANDBOX_PROVIDER_API_KEY:?Set the provider key}
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - ${HOME:?}/.docker/config.json:/run/docker-auth/config.json:ro
    - opensandbox-state:/var/lib/opensandbox
    configs:
    - source: opensandbox-config
      target: /etc/opensandbox/config.toml
    security_opt:
    - no-new-privileges:true
    mem_limit: 1g
    cpus: 1
    pids_limit: 128
    healthcheck:
      test:
      - CMD
      - /app/.venv/bin/python
      - -c
      - import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080/health', timeout=4)
      interval: 10s
      timeout: 5s
      retries: 6
  bakery-sandbox-api:
    image: cruibakeryonprem.azurecr.io/cloud/bakery-sandbox-api:${UI_BAKERY_VERSION:-latest}
    init: true
    restart: unless-stopped
    environment:
      UI_BAKERY_DOCKER_SANDBOX_PORT: '7071'
      UI_BAKERY_DOCKER_SANDBOX_IMAGE: cruibakeryonprem.azurecr.io/cloud/bakery-sandbox-runtime:${UI_BAKERY_VERSION:-latest}
      UI_BAKERY_DOCKER_SANDBOX_API_KEY: ${UI_BAKERY_DOCKER_SANDBOX_API_KEY:?Set the client key}
      UI_BAKERY_SANDBOX_PROVIDER: opensandbox
      UI_BAKERY_SANDBOX_PROVIDER_ENDPOINT: http://opensandbox:8080
      UI_BAKERY_SANDBOX_PROVIDER_API_KEY: ${UI_BAKERY_SANDBOX_PROVIDER_API_KEY:?Set the provider key}
      UI_BAKERY_SANDBOX_INSTALLATION: bakery-byok
      UI_BAKERY_SANDBOX_PROVIDER_QUALIFIED: 'true'
      UI_BAKERY_DOCKER_SANDBOX_MAX_POOL_SIZE: '1'
      UI_BAKERY_SANDBOX_BUILD_MAX_WORKLOADS: '1'
      UI_BAKERY_SANDBOX_CPU_LIMIT: '1'
      UI_BAKERY_SANDBOX_CPU_REQUEST: '0.25'
      UI_BAKERY_SANDBOX_MEMORY_LIMIT: '1073741824'
      UI_BAKERY_OPENSANDBOX_AGENT_NETWORK_POLICY: '{"defaultAction":"deny","egress":[{"action":"deny","target":"0.0.0.0/8"},{"action":"deny","target":"10.0.0.0/8"},{"action":"deny","target":"100.64.0.0/10"},{"action":"deny","target":"127.0.0.0/8"},{"action":"deny","target":"169.254.0.0/16"},{"action":"deny","target":"172.16.0.0/12"},{"action":"deny","target":"192.168.0.0/16"},{"action":"deny","target":"224.0.0.0/4"},{"action":"allow","target":"registry.npmjs.org"},{"action":"allow","target":"ui.shadcn.com"}]}'
      UI_BAKERY_OPENSANDBOX_BUILD_NETWORK_POLICY: '{"defaultAction":"deny","egress":[]}'
    depends_on:
      opensandbox:
        condition: service_healthy
    read_only: true
    tmpfs:
    - /tmp
    cap_drop:
    - ALL
    security_opt:
    - no-new-privileges:true
    stop_grace_period: 120s
    mem_limit: 512m
    cpus: 1
    pids_limit: 128
    healthcheck:
      test:
      - CMD
      - node
      - -e
      - fetch('http://127.0.0.1:7071/status',{signal:AbortSignal.timeout(4000)}).then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))
      interval: 10s
      timeout: 5s
      retries: 6
      start_period: 120s
configs:
  opensandbox-config:
    content: |
      [server]
      host = "0.0.0.0"
      port = 8080
      max_sandbox_timeout_seconds = 86400
      [proxy]
      resolve_internal = false
      [runtime]
      type = "docker"
      execd_image = "opensandbox/execd:v1.1.0"
      [docker]
      network_mode = "bridge"
      host_ip = "${SANDBOX_DOCKER_BRIDGE_IP:?Set the Docker bridge IPv4 gateway}"
      publish_host = "${SANDBOX_DOCKER_BRIDGE_IP:?Set the Docker bridge IPv4 gateway}"
      drop_capabilities = ["ALL"]
      no_new_privileges = true
      pids_limit = 4096
      [store]
      type = "sqlite"
      path = "/var/lib/opensandbox/opensandbox.db"
      [egress]
      image = "opensandbox/egress:v1.1.7"
      mode = "dns+nft"
      disable_ipv6 = true
volumes:
  opensandbox-state: null
```

</details>

Add the following to the Chat service, merging its existing `environment` and
`depends_on` entries. The sandbox address is supplied by Compose by default;
only a custom endpoint needs `UI_BAKERY_DOCKER_SANDBOX` in `.env`.

```yaml
environment:
  UI_BAKERY_DOCKER_SANDBOX: ${UI_BAKERY_DOCKER_SANDBOX:-http://bakery-sandbox-api:7071}
  UI_BAKERY_DOCKER_SANDBOX_API_KEY: ${UI_BAKERY_DOCKER_SANDBOX_API_KEY:?Set the client key}
depends_on:
  bakery-sandbox-api:
    condition: service_healthy
```

If Chat's `environment` uses list syntax, add these two entries in the same
syntax. Keep its other settings and dependencies.

By default, agents can reach npm and shadcn; builds are offline. API and provider
publish no public ports; workload ports are bound to the Docker bridge address.

### Optional: attachments

If agents need attachments, add an allow entry to the agent policy's `egress`
array in the Compose block above:

```json
{"action":"allow","target":"YOUR_ATTACHMENT_STORAGE_HOST"}
```

Use the host from `UI_BAKERY_AZURE_CONTAINER_PREFIX`, without scheme/path. Keep
all existing deny rules. Private storage requires a narrow policy exception;
a hostname rule does not override a denied private-address range.

## 3. Start and check

Log into the approved image registry using Docker's normal login on this server.
OpenSandbox mounts the resulting `~/.docker/config.json` read-only for workload
pulls; use credentials scoped to the installation's images. The file must contain
registry authentication usable inside the provider, rather than depend on a
host-only credential helper.

```bash
docker login YOUR_PRIVATE_IMAGE_REGISTRY
# Repeat login if the approved images use another private registry.
docker pull YOUR_RUNTIME_IMAGE
docker pull opensandbox/execd:v1.1.0
docker pull opensandbox/egress:v1.1.7
docker compose config --quiet
docker compose pull opensandbox bakery-sandbox-api
docker compose up -d opensandbox bakery-sandbox-api
docker compose ps
```

Replace the registry/runtime placeholders with the approved image details. Wait
for both services to be healthy, then apply the Chat configuration:

```bash
docker compose up -d chat
docker compose exec bakery-sandbox-api \
  node -e "fetch('http://127.0.0.1:7071/status').then(async r=>{console.log(await r.json());process.exit(r.ok?0:1)})"
```

In Bakery, ask the agent to install an npm package, build the application, and
use an attachment if configured. OpenSandbox creates workload/egress containers
as it fills the pool; no manual service entries are needed for them.

Keep keys, installation ID and the provider volume through updates. Keep a single
API instance. Finish active sessions before maintenance; the 120-second stop
budget is best effort. Optional pool/resource/network tuning is in the Compose
block; ready stock counts inside the pool maximums.
