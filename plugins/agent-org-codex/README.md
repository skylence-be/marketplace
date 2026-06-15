# agent-org-codex

Codex-native companion to the Claude Code `agent-org` plugin.

This package is the worker-side half of the Solo-orchestrated agent org:

- `skills/solo-worker/` — Codex worker conduct for todo-body briefs, milestone reporting, build-slot gates, shared branches, and incident handling.
- `AGENTS.md` — portable global Codex agent guidance.
- `rules/org.rules` — execpolicy snippets for the nextest ban and build-slot law.
- `scripts/build-slot` — machine-wide compile serializer.
- `scripts/ghost-probe.sh` — helper for distinguishing rendered Claude suggestion ghosts from real operator typing in Solo PTYs.
- `hooks/hooks.json` — Codex lifecycle hooks: `SessionStart` worker-lane steering and `PreToolUse` Bash checks for nextest/build-slot violations.

It intentionally does not package Claude-only orchestrator hooks or role skills. The Claude `agent-org` plugin remains the orchestrator-side package; this Codex plugin is for Codex worker lanes. Hook behavior is implemented against Codex lifecycle events and goes through Codex hook trust review.

Install from the repo-local Codex marketplace:

```sh
codex plugin marketplace add /Users/jv/Code/skylence/marketplace/.agents/plugins
codex plugin add agent-org-codex@skylence-marketplace
```
