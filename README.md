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

### Security & permission gating

- `ha_probe.sh` / `ha_list_entities.sh` only perform GET requests.
- `ha_call_service.sh` requires explicit opt-in:
  1) `--intent` flag
  2) confirmation prompt (bypass with `--yes`)
  3) `--dry-run` support to preview the call

Gate is enforced inside `scripts/ha_call_service.sh` before any API call is made.

See [docs/SECURITY.md](docs/SECURITY.md).

### Examples

```bash
# Read-only operations
./scripts/ha_probe.sh
./scripts/ha_list_entities.sh --domain light

# Write operation (explicit intent)
./scripts/ha_call_service.sh --intent light turn_on '{"entity_id": "light.living_room"}'

# Preview a write (no side effects)
./scripts/ha_call_service.sh --intent --dry-run light turn_on '{"entity_id": "light.living_room"}'
```

### Tests

```bash
# Run all tests
./tests/run_tests.sh

# Run specific test
./tests/test_permission_gate.sh
```

## Contributing

Docs:
- [docs/README.md](docs/README.md) (usage)
- [docs/SECURITY.md](docs/SECURITY.md) (token handling)
- [QUICKSTART.md](QUICKSTART.md) (3-minute setup)
- [docs/PLAN.md](docs/PLAN.md) (plan/roadmap)

## License

MIT
