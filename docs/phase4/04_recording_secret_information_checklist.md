# Phase 4 Recording and Publication Safety Checklist

## Scope

Use this checklist before recording screenshots or local MP4 files for the AeroPrecision Industrial portfolio. This checklist applies to every capture, export, subtitle file, thumbnail, and future upload.

The recording stage is local only. Uploading, hosting, external sharing, and LinkedIn posting require separate explicit approval.

## 1. Data boundary

- [ ] Every visible RFQ, product, quote, trace, and workflow execution uses synthetic L0/L1 data only.
- [ ] No real customer, supplier, employee, order, project, or financial data is visible.
- [ ] No L2/L3 data is sent to or displayed from the LLM or Langfuse.
- [ ] The visible scenario is one of the documented synthetic acceptance cases.

## 2. Credentials and configuration

- [ ] No API key, secret, password, token, private key, OAuth value, webhook secret, or credential ID is visible.
- [ ] No `.env`, `.env.example`, local-secret file, credential store, browser password manager, or settings page is open.
- [ ] n8n Credentials is never opened during recording.
- [ ] Langfuse project settings, API-key pages, and Input/Output tabs are never opened during recording.
- [ ] Browser address bars, bookmarks, extensions, profile menus, notifications, and unrelated tabs are hidden or cropped.

## 3. LLM and observability content

- [ ] No raw prompt is visible in a node, execution view, terminal, subtitle, screenshot, or video.
- [ ] No raw LLM output is visible in a node, execution view, terminal, subtitle, screenshot, or video.
- [ ] Langfuse captures show redacted metadata only: attempt, token count, latency, validation, retry, hash, and stop reason.
- [ ] Trace and execution identifiers are redacted unless necessary and safe to display.
- [ ] The model is never presented as the authority for cost, margin, price, approval, or rejection.

## 4. Workflow safety claims

- [ ] The recording accurately states that pricing and CFO controls are deterministic.
- [ ] The recording accurately states the three-attempt maximum.
- [ ] The fail-closed path visibly stops before Human Approval, persistence, notification, or external sending.
- [ ] The recording does not imply production deployment, autonomous approval, real-time customer communication, or external webhook exposure.
- [ ] The words `synthetic data` appear when test evidence is shown.

## 5. Screen capture hygiene

- [ ] Use a dedicated browser window and a clean desktop.
- [ ] Close messaging applications, email, calendars, cloud storage, terminals, and personal folders.
- [ ] Crop n8n to workflow topology; do not show node parameter panels.
- [ ] Crop Langfuse to trace metadata or timeline; do not show Input or Output.
- [ ] Review every screenshot at 100% zoom before using it.
- [ ] Review the final MP4 frame-by-frame around transitions, tab switches, and notification areas.

## 6. Git and publication controls

- [ ] Commit diagrams, redacted screenshots, case-study text, and scripts only.
- [ ] Do not commit MP4, MOV, WAV, raw capture files, subtitle exports containing unsafe text, or generated build caches.
- [ ] Do not change IAM, secrets, Docker, webhook exposure, or notification settings for portfolio recording.
- [ ] Do not upload or publish until the exact destination, audience, visibility, and final redaction review are explicitly approved.
