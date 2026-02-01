# Home Assistant OpenClaw Skill Documentation

## Overview

The Home Assistant OpenClaw Skill provides a secure, read-only-by-default interface to interact with your Home Assistant instance. This skill enables Clawbot to monitor your smart home, provide insights, and (when explicitly gated) execute automations.

## Architecture

```
┌─────────────────────┐
│    Clawbot Agent    │
│   (OpenClaw Skill)  │
└──────────┬──────────┘
           │
           │ HTTPS + Bearer Token
           │
           ▼
┌─────────────────────┐
│  Home Assistant     │
│   REST API          │
│  (Port 8123)        │
└─────────────────────┘
```

## Features

### Read-Only Operations (Default)
- **Probe**: Test connectivity and retrieve version/config info
- **List Entities**: View all entities and their current states
- **Get State**: Query specific entity states

### Write Operations (Gated)
- **Call Service**: Execute service calls (requires `--intent` flag)

## Prerequisites

1. **Home Assistant Instance**: Running and accessible
2. **Long-Lived Access Token**: Generated from your HA profile
3. **Network Access**: Ability to reach your HA instance
4. **Dependencies**: `curl`, `jq`, `bash`

## Installation

### 1. Install Dependencies

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl jq
```

**macOS:**
```bash
brew install curl jq
```

**Verify:**
```bash
curl --version
jq --version
```

### 2. Clone Repository

```bash
git clone https://github.com/plures/clawbot-home-assistant.git
cd clawbot-home-assistant
```

### 3. Make Scripts Executable

```bash
chmod +x scripts/*.sh
```

### 4. Configure Environment

Create a `.env` file (don't commit this!):

```bash
cat > .env << EOF
HA_URL=http://homeassistant.local:8123
HA_TOKEN=your-long-lived-access-token-here
EOF
```

Add `.env` to `.gitignore`:
```bash
echo ".env" >> .gitignore
```

Load environment:
```bash
set -a
source .env
set +a
```

## Quick Start

### Test Connectivity

```bash
./scripts/ha_probe.sh
```

Expected output:
```
=== Home Assistant Probe ===
URL: http://homeassistant.local:8123

Testing connectivity...
✓ Connection successful

API Status:
{
  "message": "API running."
}

Configuration:
{
  "location_name": "Home",
  "latitude": 37.7749,
  "longitude": -122.4194,
  "elevation": 0,
  "unit_system": {...},
  "time_zone": "America/Los_Angeles",
  "version": "2024.1.0",
  "components": 150
}

...
```

### List All Entities

```bash
./scripts/ha_list_entities.sh
```

### List Specific Domain

```bash
# List only lights
./scripts/ha_list_entities.sh --domain light

# List only sensors
./scripts/ha_list_entities.sh --domain sensor

# List only switches
./scripts/ha_list_entities.sh --domain switch
```

### Different Output Formats

```bash
# Compact format
./scripts/ha_list_entities.sh --format compact

# JSON format
./scripts/ha_list_entities.sh --format json | jq '.[0]'

# Table format (default)
./scripts/ha_list_entities.sh --format table
```

## Script Reference

### ha_probe.sh

Tests connectivity and retrieves basic configuration.

**Usage:**
```bash
./scripts/ha_probe.sh [OPTIONS]
```

**Options:**
- `-u, --url URL`: Home Assistant URL
- `-t, --token TOKEN`: Access token
- `-h, --help`: Show help

**Examples:**
```bash
# Using environment variables
export HA_URL="http://192.168.1.100:8123"
export HA_TOKEN="your-token"
./scripts/ha_probe.sh

# Using command line arguments
./scripts/ha_probe.sh -u http://192.168.1.100:8123 -t your-token
```

**Returns:**
- API status
- Configuration (location, version, timezone)
- Component count
- Version information

### ha_list_entities.sh

Lists all entities and their current states.

**Usage:**
```bash
./scripts/ha_list_entities.sh [OPTIONS]
```

**Options:**
- `-u, --url URL`: Home Assistant URL
- `-t, --token TOKEN`: Access token
- `-d, --domain DOMAIN`: Filter by domain
- `-f, --format FORMAT`: Output format (json, table, compact)
- `-h, --help`: Show help

**Examples:**
```bash
# List all entities
./scripts/ha_list_entities.sh

# List only lights
./scripts/ha_list_entities.sh --domain light

# List all sensors in JSON format
./scripts/ha_list_entities.sh -d sensor -f json

# Compact output for all switches
./scripts/ha_list_entities.sh -d switch -f compact
```

**Output Formats:**
- `table`: Human-readable table (default)
- `json`: Full JSON array
- `compact`: One line per entity (entity_id: state)

### ha_call_service.sh (GATED)

Executes Home Assistant service calls (write operations).

**⚠️ WARNING:** This script performs write operations. Use with caution.

**Usage:**
```bash
./scripts/ha_call_service.sh [OPTIONS] --intent <domain> <service> [service_data_json]
```

**Options:**
- `-u, --url URL`: Home Assistant URL
- `-t, --token TOKEN`: Access token
- `--intent`: **REQUIRED** - Explicit intent flag
- `--dry-run`: Show what would be executed without doing it
- `--yes`: Skip confirmation prompt
- `-h, --help`: Show help

**Examples:**

```bash
# Dry-run: See what would happen
./scripts/ha_call_service.sh --dry-run --intent light turn_on '{"entity_id": "light.living_room"}'

# Turn on a light
./scripts/ha_call_service.sh --intent light turn_on '{"entity_id": "light.living_room"}'

# Turn off a switch
./scripts/ha_call_service.sh --intent switch turn_off '{"entity_id": "switch.coffee_maker"}'

# Set temperature
./scripts/ha_call_service.sh --intent climate set_temperature '{"entity_id": "climate.bedroom", "temperature": 72}'

# Activate a scene
./scripts/ha_call_service.sh --intent scene turn_on '{"entity_id": "scene.movie_time"}'

# Set light brightness and color
./scripts/ha_call_service.sh --intent light turn_on '{
  "entity_id": "light.bedroom",
  "brightness": 128,
  "rgb_color": [255, 0, 0]
}'
```

**Safety Gates:**
1. Requires `--intent` flag (prevents accidents)
2. Confirmation prompt (unless `--yes` flag)
3. Dry-run mode for testing
4. Full logging of operations

## Common Use Cases

### 1. Daily System Health Check

Create a script to check critical sensors:

```bash
#!/bin/bash
# daily_health_check.sh

source .env

echo "=== Daily Home Assistant Health Check ==="
date

# Check connectivity
./scripts/ha_probe.sh | grep "Connection successful" || exit 1

# Get all battery sensors
echo -e "\n=== Battery Levels ==="
./scripts/ha_list_entities.sh -d sensor -f compact | grep battery

# Get all sensors with "unavailable" state
echo -e "\n=== Unavailable Entities ==="
./scripts/ha_list_entities.sh -f compact | grep unavailable

# Get alarm states
echo -e "\n=== Alarm States ==="
./scripts/ha_list_entities.sh -d alarm_control_panel -f compact
```

### 2. Monitor Specific Entities

```bash
#!/bin/bash
# monitor_critical.sh

# Watch for water leak sensors
./scripts/ha_list_entities.sh -d binary_sensor -f json | \
  jq '.[] | select(.entity_id | contains("water_leak")) | 
    {entity_id, state, last_changed}'

# Check smoke detectors
./scripts/ha_list_entities.sh -d binary_sensor -f json | \
  jq '.[] | select(.entity_id | contains("smoke")) | 
    {entity_id, state, last_changed}'
```

### 3. Automation Trigger (Gated)

```bash
#!/bin/bash
# goodnight_routine.sh

source .env

# Turn off all lights
./scripts/ha_call_service.sh --intent --yes light turn_off '{"entity_id": "all"}'

# Set thermostat to sleep mode
./scripts/ha_call_service.sh --intent --yes climate set_temperature '{
  "entity_id": "climate.bedroom",
  "temperature": 68,
  "hvac_mode": "heat"
}'

# Activate goodnight scene
./scripts/ha_call_service.sh --intent --yes scene turn_on '{"entity_id": "scene.goodnight"}'
```

### 4. Integration with OpenClaw

Example OpenClaw skill configuration:

```python
# Example: OpenClaw skill integration
from openclaw import Skill

class HomeAssistantSkill(Skill):
    def probe(self):
        """Check Home Assistant connectivity"""
        result = self.execute("./scripts/ha_probe.sh")
        return result
    
    def list_entities(self, domain=None):
        """List entities, optionally filtered by domain"""
        cmd = ["./scripts/ha_list_entities.sh", "-f", "json"]
        if domain:
            cmd.extend(["-d", domain])
        result = self.execute(cmd)
        return json.loads(result)
    
    def call_service(self, domain, service, data=None):
        """Execute service call (requires explicit intent)"""
        # This should only be called after explicit user confirmation
        cmd = [
            "./scripts/ha_call_service.sh",
            "--intent",
            "--yes",
            domain,
            service,
            json.dumps(data or {})
        ]
        result = self.execute(cmd)
        return result
```

## Troubleshooting

### Connection Failed

**Problem:** `✗ Connection failed`

**Solutions:**
1. Check if Home Assistant is running
2. Verify `HA_URL` is correct
3. Ensure network connectivity
4. Check firewall rules
5. Verify token is valid

```bash
# Test basic connectivity
curl -I http://homeassistant.local:8123

# Test with token
curl -H "Authorization: Bearer $HA_TOKEN" \
  http://homeassistant.local:8123/api/
```

### Invalid Token

**Problem:** HTTP 401 Unauthorized

**Solutions:**
1. Verify token is correct (no extra spaces)
2. Check if token was revoked
3. Generate a new token
4. Ensure token has necessary permissions

### JSON Parse Error

**Problem:** `Failed to parse response`

**Solutions:**
1. Install/update `jq`: `sudo apt-get install jq`
2. Check if API response is valid JSON
3. Update Home Assistant to latest version

### Service Call Failed

**Problem:** Service call returns error

**Solutions:**
1. Use `--dry-run` to test first
2. Verify entity_id exists
3. Check service parameters
4. Review Home Assistant logs

```bash
# Test service data format
echo '{"entity_id": "light.living_room"}' | jq '.'

# Verify entity exists
./scripts/ha_list_entities.sh -f compact | grep living_room
```

## Security

**See [SECURITY.md](SECURITY.md) for detailed security guidance.**

Key points:
- Store tokens securely (environment variables, not in code)
- Use HTTPS when possible
- Never commit tokens to version control
- Rotate tokens regularly
- Use read-only operations by default
- Audit service calls

## API Reference

### Home Assistant REST API Endpoints

Used by these scripts:

| Endpoint | Method | Purpose | Script |
|----------|--------|---------|--------|
| `/api/` | GET | API status | ha_probe.sh |
| `/api/config` | GET | Configuration | ha_probe.sh |
| `/api/states` | GET | All entity states | ha_list_entities.sh |
| `/api/states/<entity>` | GET | Specific entity | (future) |
| `/api/services/<domain>/<service>` | POST | Call service | ha_call_service.sh |

### Common Service Calls

**Lights:**
```bash
# Turn on
--intent light turn_on '{"entity_id": "light.bedroom"}'

# Turn off
--intent light turn_off '{"entity_id": "light.bedroom"}'

# Set brightness (0-255)
--intent light turn_on '{"entity_id": "light.bedroom", "brightness": 128}'

# Set color (RGB)
--intent light turn_on '{"entity_id": "light.bedroom", "rgb_color": [255, 0, 0]}'
```

**Switches:**
```bash
# Turn on
--intent switch turn_on '{"entity_id": "switch.fan"}'

# Turn off
--intent switch turn_off '{"entity_id": "switch.fan"}'
```

**Climate:**
```bash
# Set temperature
--intent climate set_temperature '{"entity_id": "climate.living_room", "temperature": 72}'

# Set HVAC mode
--intent climate set_hvac_mode '{"entity_id": "climate.living_room", "hvac_mode": "heat"}'
```

**Scenes:**
```bash
# Activate scene
--intent scene turn_on '{"entity_id": "scene.movie_time"}'
```

## Development

### Running Tests

(Tests to be added)

```bash
# Test all scripts with mock HA instance
./tests/run_tests.sh

# Test specific script
./tests/test_probe.sh
```

### Contributing

1. Follow existing code style
2. Add tests for new features
3. Update documentation
4. Security review for any write operations
5. Submit pull request

## Support

- **Issues**: [GitHub Issues](https://github.com/plures/clawbot-home-assistant/issues)
- **Documentation**: This file and `docs/` directory
- **Security**: See [SECURITY.md](SECURITY.md)

## License

See LICENSE file in repository root.

## Changelog

### v1.0.0 (Initial Release)
- `ha_probe.sh`: Connectivity and version check
- `ha_list_entities.sh`: List all entities and states
- `ha_call_service.sh`: Gated service calls
- Security documentation
- Usage examples

## Roadmap

Future enhancements:
- [ ] WebSocket API support for real-time updates
- [ ] Event stream monitoring
- [ ] Automation templates
- [ ] Health check scripts
- [ ] Integration tests
- [ ] Docker container for easy deployment
- [ ] Python wrapper library
- [ ] Additional output formats (CSV, YAML)

## References

- [Home Assistant REST API Documentation](https://developers.home-assistant.io/docs/api/rest/)
- [Home Assistant Authentication](https://www.home-assistant.io/docs/authentication/)
- [Home Assistant Service Calls](https://www.home-assistant.io/docs/scripts/service-calls/)
- [OpenClaw Documentation](https://github.com/plures/openclaw)
