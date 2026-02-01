# Quick Reference Guide

## Installation (3 steps)

1. **Install dependencies:**
   ```bash
   sudo apt-get install curl jq  # Ubuntu/Debian
   brew install curl jq          # macOS
   ```

2. **Setup configuration:**
   ```bash
   cp .env.example .env
   # Edit .env with your HA_URL and HA_TOKEN
   ```

3. **Test it:**
   ```bash
   source .env
   ./scripts/ha_probe.sh
   ```

## Scripts at a Glance

| Script | Purpose | Safety | Example |
|--------|---------|--------|---------|
| `ha_probe.sh` | Test connectivity & get version | ✅ Read-only | `./scripts/ha_probe.sh` |
| `ha_list_entities.sh` | List all entities/states | ✅ Read-only | `./scripts/ha_list_entities.sh --domain light` |
| `ha_call_service.sh` | Execute service calls | ⚠️ Write (gated) | `./scripts/ha_call_service.sh --intent light turn_on '{"entity_id": "light.room"}'` |

## Common Commands

```bash
# Check connectivity
./scripts/ha_probe.sh

# List all lights
./scripts/ha_list_entities.sh --domain light --format compact

# List all sensors in JSON
./scripts/ha_list_entities.sh --domain sensor --format json

# Dry-run a service call
./scripts/ha_call_service.sh --dry-run --intent light turn_on '{"entity_id": "light.room"}'

# Turn on a light (requires confirmation)
./scripts/ha_call_service.sh --intent light turn_on '{"entity_id": "light.room"}'
```

## Safety Features

1. **Read-only by default** - Probe and list scripts cannot modify your HA instance
2. **--intent flag required** - Service calls require explicit `--intent` flag
3. **Confirmation prompt** - Service calls ask for confirmation (use `--yes` to skip)
4. **Dry-run mode** - Test service calls with `--dry-run` before executing

## Security Checklist

- [ ] Token stored in `.env` file (not in code)
- [ ] `.env` added to `.gitignore`
- [ ] Using HTTPS or local network only
- [ ] Token documented with purpose and date
- [ ] Know how to revoke token if needed

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Connection failed | Check `HA_URL` is correct and HA is running |
| Invalid token | Verify token in HA profile, regenerate if needed |
| Missing --intent | Add `--intent` flag to service call commands |
| JSON error | Ensure service data is valid JSON, use `jq` to validate |

## Documentation

- [Full Documentation](docs/README.md) - Complete guide with examples
- [Security Guide](docs/SECURITY.md) - Token handling best practices
- [Implementation Plan](docs/PLAN.md) - Project roadmap

## Example Integration

```python
# Example OpenClaw skill usage
import subprocess
import json

class HomeAssistantSkill:
    def probe(self):
        """Test HA connectivity"""
        result = subprocess.run(["./scripts/ha_probe.sh"], 
                              capture_output=True, text=True)
        return result.stdout
    
    def get_entities(self, domain=None):
        """Get entities by domain"""
        cmd = ["./scripts/ha_list_entities.sh", "-f", "json"]
        if domain:
            cmd.extend(["-d", domain])
        result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout)
    
    def call_service(self, domain, service, data):
        """Call HA service (requires explicit confirmation)"""
        cmd = [
            "./scripts/ha_call_service.sh",
            "--intent", "--yes",
            domain, service,
            json.dumps(data)
        ]
        result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout
```

## Support

- **Issues**: https://github.com/plures/clawbot-home-assistant/issues
- **Security**: See [SECURITY.md](docs/SECURITY.md)
- **Home Assistant API**: https://developers.home-assistant.io/docs/api/rest/
