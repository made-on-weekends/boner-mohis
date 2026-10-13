# DECISIONS.md

> Settled architectural decisions. **Append-only.** Never edit or delete past entries (one exception: `Status` field of a superseded entry).
> If a decision is reversed, append a new entry with `Supersedes: #NNNN`.

## How to use this file

- Read before contradicting any documented pattern.
- New decisions are added with the next sequential number.
- Each entry has: number, title, date, status, context, decision, consequences, optional `Supersedes`.

## Status values

- `Proposed` — under discussion
- `Accepted` — current
- `Superseded by #NNNN` — replaced by a later decision (only the Status field can be edited on a superseded entry)
- `Deprecated` — no longer applies but no replacement

---

## 0001 — Project initialized

**Date:** 2026-10-13  
**Status:** Accepted  
**Context:** Project initialized and scaffolded with Project Ninja.  
**Decision:** Establish AGENTS.md and docs/ as the source of truth for AI agent context and project architecture. Adopt local-first data storage with SQLite and scoped DigiCert TLS certificate pinning for DESCO customer APIs.  
**Consequences:** All AI tools (Claude Code, Antigravity, Cursor) read AGENTS.md before planning changes. Decisions affecting the codebase must be appended here.

---

## 0002 — Google Stitch MCP and Filament Design System Integration

**Date:** 2026-10-13  
**Status:** Accepted  
**Context:** Verification of machine-local brand repository integration and Google Stitch MCP setup for Antigravity.  
**Decision:** Configure Google Stitch MCP locally in `.agents/mcp_config.json` (ignored via `.gitignore`) to govern UI fidelity against validated Stitch screens (`projects/8257482923350679368`), and source all visual brand assets canonically from `/home/asif/Documents/brands/boner-mohis/`.  
**Consequences:** Both Flutter and React extension interfaces adhere to validated Google Stitch screen definitions and the Filament Design System without ad-hoc styling or third-party placeholder graphics.

