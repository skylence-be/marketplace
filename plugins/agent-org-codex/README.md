# agent-org-codex

Codex-native companion to the Claude Code `agent-org` plugin.

This package is the Codex side of the Solo-orchestrated agent org and includes every shared `agent-org` skill from the Claude package, plus the Codex worker variant:

- `skills/orchestrator/` — symlink to the shared Claude `agent-org` orchestrator skill.
- `skills/replacer/` — symlink to the shared Claude `agent-org` replacer skill.
- `skills/org-audit/` — symlink to the shared Claude `agent-org` org-audit skill.
- `skills/solo-worker/` — symlink to the Codex worker conduct skill for todo-body briefs, milestone reporting, build-slot gates, shared branches, and incident handling.
- `AGENTS.md` — portable global Codex agent guidance.
- `rules/org.rules` — execpolicy snippets for the nextest ban and build-slot law.
- `scripts/build-slot` — machine-wide compile serializer.
- `scripts/ghost-probe.sh` — helper for distinguishing rendered Claude suggestion ghosts from real operator typing in Solo PTYs.
- `hooks/hooks.json` — Codex lifecycle hooks: `SessionStart` agent-org steering and `PreToolUse` Bash checks for nextest/build-slot violations.

The skill directories are symlinks back to the source package so shared doctrine only needs to be edited once. Hook behavior is implemented against Codex lifecycle events and goes through Codex hook trust review.

Install from the repo-local Codex marketplace:

```sh
codex plugin marketplace add /Users/jv/Code/skylence/marketplace/.agents/plugins
codex plugin add agent-org-codex@skylence-marketplace
```
