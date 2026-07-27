# Local Langfuse Infrastructure

This directory contains the sanitized and digest-pinned Docker Compose definition for the Phase 3 local Langfuse environment.

## Security boundaries

- Langfuse UI is bound only to `127.0.0.1:3000`.
- Postgres, ClickHouse, Redis, MinIO, and Worker have no host-published ports.
- Langfuse telemetry is disabled.
- Runtime secrets are stored outside the Git repository.
- The actual environment file is `%USERPROFILE%\.aeroprecision-secrets\langfuse.env`.
- API keys and runtime credentials must not be committed or copied into workflow exports.
- Do not use `docker compose down -v` without explicit approval because it deletes persistent volumes.

## Private network

The Compose project creates `aeroprecision-observability`.

After Langfuse is healthy, the existing n8n container may be attached to this network. n8n will then use:

`http://aeroprecision-langfuse-web:3000`

This network attachment and all n8n credential changes require separate verification.

## Official health endpoints

- Web health: `/api/public/health`
- Web readiness: `/api/public/ready`
- Worker health: `/api/health`

## Current scope

This infrastructure is a local portfolio demonstration. It does not provide high availability, automatic backups, public access, or production SLA.
