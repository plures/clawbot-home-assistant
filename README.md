# clawbot-home-assistant

<!-- plures-readme-banner -->
[![CI](https://github.com/plures/clawbot-home-assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/plures/clawbot-home-assistant/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Clawbot integration for Home Assistant (dogfooding + automations). Read-only by default with gated write operations.

---

<!-- plures-readme-standard-sections -->

## Overview

This repo contains scripts and docs intended to be used as an OpenClaw skill/integration for Home Assistant:

- `scripts/ha_probe.sh`: connectivity + config probe (read-only)
- `scripts/ha_list_entities.sh`: list entities/states (read-only)
- `scripts/ha_call_service.sh`: call HA services (write), **requires explicit `--intent`**

## Install

Dependencies:

- `curl`
- `jq`

## Development

### Quick start

```bash
cp .env.example .env
# Edit .env with your Home Assistant URL and long-lived access token
source .env
./scripts/ha_probe.sh
```

### Examples

```bash
# List all lights
./scripts/ha_list_entities.sh --domain light

# Turn on a light (write operation; requires explicit intent)
./scripts/ha_call_service.sh --intent light turn_on '{"entity_id": "light.living_room"}'
```

### Tests

```bash
./tests/run_tests.sh
```

## Contributing

Docs:
- [docs/README.md](docs/README.md) (usage)
- [docs/SECURITY.md](docs/SECURITY.md) (token handling)
- [docs/PLAN.md](docs/PLAN.md) (plan/roadmap)

## License

MIT
