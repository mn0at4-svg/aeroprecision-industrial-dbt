# Disaster Recovery Runbook

## AeroPrecision Industrial — BigQuery, dbt and Evidence Recovery

Last verified: 2026-07-17  
Project: `aeroprecision-data-pipeline`  
BigQuery location: `US`

## Purpose

This runbook restores the AeroPrecision Industrial analytics platform after
BigQuery Sandbox tables or views expire.

The verified recovery path is:

```text
Version-controlled CSV and schema files
  → BigQuery Raw tables
  → dbt full-refresh
  → Analytics models and tests
  → Evidence data sources
  → Evidence production build
  → GitHub Pages deployment