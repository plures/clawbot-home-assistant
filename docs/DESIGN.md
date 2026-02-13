# Home Assistant Skill Design

## Architecture

### Core Design Principles
- **Read-only by default**: All state queries are safe and non-destructive
- **Explicit intent gating**: Write operations require explicit `--intent` flag
- **Security first**: Tokens stored securely, minimal privilege scope
- **Auditable**: All actions logged for review
- **Fail-safe**: Network/auth failures gracefully handled

### Component Structure

```
clawbot-home-assistant/
├── scripts/
│   ├── probe.sh           # Connectivity test, version info
│   ├── list-entities.sh   # Enumerate all entities and states  
│   ├── get-state.sh       # Query specific entity state
│   ├── call-service.sh    # Execute HA service (gated)
│   └── config.sh          # Token/endpoint configuration
├── examples/
│   ├── daily-summary.sh   # Automated daily health report
│   ├── battery-alerts.sh  # Low battery notifications
│   └── security-check.sh  # Away mode validation
└── docs/
    ├── SECURITY.md        # Security best practices
    └── README.md          # Setup and usage guide
```

### API Integration

**Home Assistant REST API:**
- Base URL: `http[s]://<ha-host>:8123/api/`
- Authentication: `Authorization: Bearer <token>`
- Primary endpoints:
  - `/api/states` - Entity states
  - `/api/services` - Available services
  - `/api/config` - Instance configuration

### Security Model

1. **Token Management**
   - Long-lived access tokens (preferred)
   - Environment variable storage (`HA_TOKEN`)
   - No token in command line arguments

2. **Privilege Separation**
   - Read operations: No special permissions
   - Write operations: Gated behind `--intent` flag
   - Service calls: Whitelist approach for safety-critical services

3. **Network Security**
   - HTTPS preferred, HTTP allowed for local instances
   - Connection timeout limits
   - Error message sanitization

## Current Implementation Status

### ✅ Completed
- Basic REST API connectivity (`probe.sh`)
- Entity listing and state queries
- Token-based authentication
- Read-only operations fully functional
- Comprehensive documentation and examples

### 🔄 In Progress
- Write operation gating mechanism
- Service call safety validation
- Error handling improvements

### 📋 Planned
- WebSocket API support for real-time events
- Advanced automation templates
- Integration with OpenClaw memory system
- Dashboard view for entity status

## Integration Points

### OpenClaw Skill Interface
- Commands exposed via `ha-*` prefixed functions
- JSON output for structured data consumption
- Standard error codes and messages
- Compatible with OpenClaw's exec tool

### Memory Integration
- Entity state changes logged to daily memory
- Automation decisions tracked for audit
- Pattern recognition for proactive suggestions
- Historical data for trend analysis

## Extension Architecture

### Automation Templates
Reusable automation patterns:
- **Health Check**: Daily system status report
- **Security Sweep**: Validate locks/sensors before "away" mode
- **Energy Report**: Power consumption insights
- **Maintenance Alerts**: Filter/battery replacement reminders

### Event Handling
Future real-time integration:
- State change notifications
- Alarm/alert escalation
- Automatic responses to critical events
- Integration with OpenClaw's cron system

## Performance Considerations

- API calls batched where possible
- Rate limiting respected (HA default: 10 req/sec)
- Caching for frequently accessed static data
- Minimal memory footprint for continuous monitoring

## Error Recovery

- Graceful degradation on network issues
- Retry logic with exponential backoff
- Fallback to cached data when appropriate
- Clear error messages for troubleshooting