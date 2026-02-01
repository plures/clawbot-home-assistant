# Security Guide: Home Assistant Long-Lived Access Tokens

## Overview

The Home Assistant integration uses long-lived access tokens for authentication. This document provides security best practices for handling these tokens safely.

## Token Generation

1. Log in to your Home Assistant instance
2. Go to your profile (click your username in the sidebar)
3. Scroll down to "Long-Lived Access Tokens"
4. Click "Create Token"
5. Give it a descriptive name (e.g., "Clawbot Read-Only")
6. Copy the token immediately (it won't be shown again)

## Security Best Practices

### 1. Token Storage

**DO:**
- Store tokens in environment variables
- Use a secrets management system (e.g., HashiCorp Vault, AWS Secrets Manager)
- Use a password manager for personal use
- Encrypt tokens at rest

**DON'T:**
- Commit tokens to version control
- Store tokens in plain text files
- Share tokens via email or chat
- Include tokens in screenshots or logs

### 2. Token Scope

Home Assistant long-lived access tokens have **full access** to your instance by default. To minimize risk:

**DO:**
- Create separate tokens for different purposes
- Document what each token is used for
- Use descriptive names when creating tokens
- Revoke tokens when no longer needed

**DON'T:**
- Reuse the same token across multiple applications
- Share tokens between users
- Use administrator tokens for automation

### 3. Token Lifecycle

**Rotation:**
- Rotate tokens periodically (recommend: every 90 days)
- Rotate immediately if you suspect compromise
- Keep track of token creation dates

**Revocation:**
- Revoke tokens when:
  - They are no longer needed
  - You suspect compromise
  - An application is decommissioned
  - A team member leaves

### 4. Network Security

**DO:**
- Use HTTPS for all connections to Home Assistant
- Consider using a VPN when accessing from outside your network
- Use local network access when possible
- Enable firewall rules to restrict access

**DON'T:**
- Expose your Home Assistant instance directly to the internet without proper security
- Use HTTP for token transmission
- Access Home Assistant from untrusted networks without VPN

### 5. Read-Only vs Write Access

The scripts in this repository are designed with a security-first approach:

**Read-Only Scripts (Default):**
- `ha_probe.sh` - Only reads configuration and version
- `ha_list_entities.sh` - Only reads entity states

**Write Scripts (Gated):**
- `ha_call_service.sh` - Requires `--intent` flag to prevent accidental execution

**Principle:** Start with read-only access and only enable write operations when explicitly needed.

## Environment Variable Setup

### Linux/macOS

Add to your `~/.bashrc`, `~/.zshrc`, or `~/.profile`:

```bash
# Home Assistant Configuration
export HA_URL="http://homeassistant.local:8123"
export HA_TOKEN="your-long-lived-access-token"
```

Then reload:
```bash
source ~/.bashrc  # or ~/.zshrc
```

### Temporary Session (More Secure)

For one-time use without persisting to disk:

```bash
read -s HA_TOKEN
export HA_TOKEN
export HA_URL="http://homeassistant.local:8123"
```

This prompts for the token without echoing it to the terminal.

### Using `.env` Files

Create a `.env` file (add to `.gitignore`!):

```bash
HA_URL=http://homeassistant.local:8123
HA_TOKEN=your-long-lived-access-token
```

Load it before running scripts:

```bash
set -a
source .env
set +a
./scripts/ha_probe.sh
```

**Important:** Always add `.env` to `.gitignore`!

## Token Compromise Response

If you suspect your token has been compromised:

1. **Immediately revoke the token:**
   - Log in to Home Assistant
   - Go to your profile
   - Find the token in "Long-Lived Access Tokens"
   - Click the delete/revoke button

2. **Review Home Assistant logs:**
   - Check for suspicious activity
   - Look for unexpected service calls
   - Review entity state changes

3. **Create a new token:**
   - Generate a new token with a different name
   - Update your applications/scripts
   - Test the new token

4. **Review security:**
   - Check where the token was stored
   - Review who had access
   - Update security practices

## Audit and Monitoring

### Logging

Enable Home Assistant logging to track API usage:

```yaml
# configuration.yaml
logger:
  default: info
  logs:
    homeassistant.components.api: debug
```

### Regular Reviews

- Monthly: Review active tokens and revoke unused ones
- Monthly: Check Home Assistant logs for suspicious activity
- Quarterly: Rotate tokens
- Yearly: Full security audit

## Additional Resources

- [Home Assistant Authentication Documentation](https://www.home-assistant.io/docs/authentication/)
- [Home Assistant Security Best Practices](https://www.home-assistant.io/docs/configuration/securing/)
- [Home Assistant REST API Documentation](https://developers.home-assistant.io/docs/api/rest/)

## Support

For security issues or questions:
- File an issue on the repository (without including sensitive information)
- Consult Home Assistant community forums
- Review Home Assistant security advisories

## Checklist

Before using the integration:

- [ ] Token is stored securely (environment variable or secrets manager)
- [ ] Token is not in version control
- [ ] Using HTTPS (or local network only)
- [ ] Documented token purpose and creation date
- [ ] Understand read-only vs write operations
- [ ] Know how to revoke token if needed
- [ ] Reviewed Home Assistant security settings
