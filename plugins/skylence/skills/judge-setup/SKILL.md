---
name: judge-setup
description: "Set up the judge layer: write a ## Judge section to ~/.claude/CLAUDE.md, seed ~/.claude/judge-rules.json from the bundled example, and register judge-hook.sh as a user-scope PreToolUse hook in ~/.claude/settings.json. Triggers: 'judge setup', 'set up judge layer', 'install the judge hook', 'add judge section to CLAUDE.md'."
disable-model-invocation: true
---

Configure the judge layer at user scope. Three pieces: a `## Judge` section in `~/.claude/CLAUDE.md` (when to invoke the judge-design skill chain + anti-theater rules), a rules file seeded from the plugin's example, and the PreToolUse hook registered in `~/.claude/settings.json`.

Requires `jq`. Check first; stop if missing:

```bash
command -v jq >/dev/null || { echo "STOP: jq is required. macOS: brew install jq · Linux: apt/dnf install jq"; exit 1; }
```

## Step 1: Backup and strip the ## Judge section

```bash
CLAUDE_MD="$HOME/.claude/CLAUDE.md"
touch "$CLAUDE_MD"

BACKUP="$HOME/.claude/CLAUDE.md.bak.$(date +%Y%m%d-%H%M%S)"
cp "$CLAUDE_MD" "$BACKUP"
echo "Backup: $BACKUP"

awk '
  BEGIN {
    managed["## Judge"] = 1
    in_strip = 0
  }
  $0 in managed { in_strip = 1; next }
  in_strip && /^## / { in_strip = 0 }
  !in_strip { print }
' "$CLAUDE_MD" > "$CLAUDE_MD.tmp" && mv "$CLAUDE_MD.tmp" "$CLAUDE_MD"
```

## Step 2: Append the ## Judge section

```bash
cat >> "$CLAUDE_MD" << 'EOF'

## Judge

Use judge-design workflow before shipping any agent or automation that takes consequential autonomous actions. Design gate before agent goes live.

### When to invoke the workflow

If agent can do any of following without human in the loop, run workflow first:

- Merge PRs or push to protected branches
- Deploy or restart services
- Run DB migrations or write to production databases
- Send external messages (Slack, email, webhooks, SMS)
- Spend money or authorize purchases
- Change infrastructure, permissions, or access controls

Chain: `skylence:action-surface-audit-skill` to map action surface, then `skylence:judge-criteria-skill` to design criteria and structured proposal format actor must submit, then `skylence:judge-prompt-writer-skill` to produce judge system prompt, then `skylence:judge-eval-suite-skill` to validate it. Before scaling (more actions, more agents, higher stakes), run `skylence:judge-architecture-review-skill`.

### Anti-theater rules

Judge that looks like control layer but catches nothing is worse than no judge. It adds latency, creates false confidence, and delays finding real gap.

**Different failure modes, or it does not count.** Actor and judge using same model, same prompt context, and same reasoning style will share same blind spots. They fail on same inputs. Use different prompt with tighter criteria for judge. Smaller, cheaper model (Haiku is runtime default in `judge-hook.sh`) often diverges usefully from actor. Goal is not a second opinion from a copy of yourself.

**No eval suite, no deployment.** Run `skylence:judge-eval-suite-skill` before any judge goes live. Suite must cover all four outcomes: allow, block, revise, escalate. Weight toward mundane boundary failures (one step too far, authorization scope creep, stale evidence) rather than adversarial red-team. Judge with no passing eval suite is another model call, not a control layer.

**Hard blocks need deterministic rules.** LLM judges fail open on infra errors, timeouts, and ambiguous inputs. Anything that must block reliably belongs in `~/.claude/judge-rules.json` as a `class=deny` rule, enforced by the `judge-hook.sh` PreToolUse hook from the skylence plugin. Design skills define what those rules should contain and verify they actually fire.

**Judge that never blocks in testing is not working; it is unconfigured.** Verify during eval that block and revise cases are caught. If every test case returns ALLOW, criteria are too loose or judge is ignoring proposal format.
EOF

echo "CLAUDE.md updated."
```

## Step 3: Seed the rules file from the example

Don't clobber an existing rules file.

```bash
PLUGIN_HOOKS="${CLAUDE_PLUGIN_ROOT}/hooks"

if [ ! -f ~/.claude/judge-rules.json ]; then
  cp "$PLUGIN_HOOKS/judge-rules.example.json" ~/.claude/judge-rules.json
  echo "Wrote ~/.claude/judge-rules.json from example. Review and customize before relying on it."
else
  echo "~/.claude/judge-rules.json already exists: left untouched."
fi
```

## Step 4: Register the hook in user-scope settings.json

Copy the hook script to `~/.claude/` and register it, idempotently. This makes the judge active even in sessions where the skylence plugin is disabled. Note: the plugin's own `hooks/hooks.json` also registers this hook while the plugin is enabled — both fire, same verdict, harmless redundancy.

```bash
SETTINGS="$HOME/.claude/settings.json"
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

cp "$PLUGIN_HOOKS/judge-hook.sh" ~/.claude/judge-hook.sh && chmod +x ~/.claude/judge-hook.sh

if ! jq -e '.hooks.PreToolUse // [] | map(.hooks // [] | map(.command // "")) | flatten | any(contains("judge-hook.sh"))' "$SETTINGS" >/dev/null 2>&1; then
  jq '.hooks //= {} | .hooks.PreToolUse //= [] | .hooks.PreToolUse += [{
    "matcher": "Bash|Write|Edit|NotebookEdit|mcp__",
    "hooks": [{"type": "command", "command": "bash ~/.claude/judge-hook.sh", "statusMessage": "Judging tool call..."}]
  }]' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "judge-hook wired in settings.json."
else
  echo "judge-hook already registered in settings.json: left untouched."
fi
```

## Step 5: Verify and summarize

Run the bundled eval suite against the deterministic rules to prove the hook fires:

```bash
bash "$PLUGIN_HOOKS/judge-eval/run-evals.sh"
```

Then print:

```
Judge Setup
-----------------------------------------
CLAUDE.md ## Judge section              done
Backup: ~/.claude/CLAUDE.md.bak.<ts>
~/.claude/judge-rules.json              seeded | existing
~/.claude/judge-hook.sh                 copied
settings.json PreToolUse registration   wired | existing
Eval suite                              <pass/fail counts>
```

Remind the user: the hook fails open on infrastructure errors. Deterministic `class=deny` rules are the hard boundary; the LLM escalation path is best-effort. New session or `/reload-plugins` for hooks to take effect.