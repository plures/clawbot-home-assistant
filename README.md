# clawbot-home-assistant

<!-- plures-readme-banner -->
[![CI](https://github.com/plures/clawbot-home-assistant/actions/workflows/ci.yml/badge.svg)](https://github.com/plures/clawbot-home-assistant/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Clawbot integration for Home Assistant (dogfooding + automations). Read-only by default with explicitly gated write operations.

---

<!-- plures-readme-standard-sections -->

## Overview

This repository implements an OpenClaw/Home Assistant REST integration focused on safety:

- Read-only scripts for probing and listing entities
- Write operations require an explicit `--intent` gate
- Security guidance for token handling

Scripts:
- `scripts/ha_probe.sh` (read-only)
- `scripts/ha_list_entities.sh` (read-only)
- `scripts/ha_call_service.sh` (write; requires `--intent`)

## Install

Prereqs:

- `curl`
- `jq`

## Development

### Quick start

```bash
cp .env.example .env
# Edit .env with your Home Assistant URL + long-lived access token
source .env
./scripts/ha_probe.sh
```

### Examples

```bash
./scripts/ha_list_entities.sh --domain light

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
- [QUICKSTART.md](QUICKSTART.md) (3-minute setup)
- [docs/PLAN.md](docs/PLAN.md) (plan/roadmap)

## License

MIT
