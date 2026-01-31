# Clawbot Home Assistant skill (plan)

## Goal
Dogfood a Clawbot integration for Home Assistant (HA) ASAP.

Deliver a practical assistant that:
- reads state (sensors, switches, alarms)
- can suggest automations
- can execute safe actions (opt-in, gated)
- logs events + decisions (auditable)

## Scope (v1)
- Connect to Home Assistant via long-lived access token (HA REST API)
- Read-only by default
- Optional write actions (turn on/off, set climate, etc.) behind explicit intent gate
- Provide a small set of high-value automations:
  - daily/weekly system health summary
  - battery/low-signal alerts
  - water leak / smoke alarm escalations
  - “away/home” mode checks

## Interfaces
- Home Assistant REST API
- Optional WebSocket API later for realtime

## Deliverables
1) OpenClaw skill: `clawbot-home-assistant`
2) Scripts:
   - probe: connectivity + version
   - list entities
   - get state
   - (gated) call service
3) References:
   - HA API docs + examples
4) Security:
   - token handling guidance
   - least privilege / limited scope

## Dogfooding checklist
- Install in one HA instance
- Run daily summaries
- File issues for friction
