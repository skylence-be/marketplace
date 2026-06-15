#!/bin/sh
# Codex SessionStart hook for the agent-org-codex plugin.
cat <<'EOF'
## agent-org Codex worker lane

If this session is a Solo-dispatched worker, invoke the solo-worker skill and
read the todo body before implementing. Compiling commands must go through
build-slot, cargo nextest stays banned, and milestone reports need exact
commands, counts, SHAs, and artifact paths.
EOF
exit 0
