#!/usr/bin/env zsh
set -euo pipefail

umask 077

ROOT="${AGENTIC_ACCOUNTS_ROOT:-$HOME/AgenticAccounts}"
SCRIPT_DIR="${0:A:h}"
KIT_ROOT="${SCRIPT_DIR:h}"

mkdir -p "$ROOT/shared"/{agents,policies,skills,mcp,opencode,codex,claude}

for account in personal corp; do
  base="$ROOT/$account"
  mkdir -p \
    "$base"/{codex,claude,opencode,github,git,mcp,logs,tmp,workspaces,env} \
    "$base"/xdg/{config,cache,data,state} \
    "$base"/vscode/{user-data,extensions}

  chmod 700 "$base" "$base"/{codex,claude,opencode,github,git,mcp,logs,tmp,workspaces,env} "$base"/xdg "$base"/vscode

  if [[ ! -f "$base/env/account.env" ]]; then
    cat > "$base/env/account.env" <<EOF
# Secrets/env for $account only. Keep this file chmod 600.
# Examples:
# OPENAI_API_KEY=
# OPENAI_ORGANIZATION=
# OPENAI_PROJECT=
# ANTHROPIC_API_KEY=
# OPENCODE_MODEL=
EOF
    chmod 600 "$base/env/account.env"
  fi

  if [[ ! -f "$base/env/inheritance.env" ]]; then
    cat > "$base/env/inheritance.env" <<EOF
# Non-secret inheritance policy for $account. Keep this file chmod 600.
# Default is strict local isolation. Enable only what this account may reuse.
#
# GitHub CLI:
#   0 = isolated GH_CONFIG_DIR under this account's CODEX_HOME
#   1 = use the normal global gh auth at ~/.config/gh
AGENTIC_INHERIT_GH=0
#
# Optional custom gh config directory. Leave empty unless you know why.
# AGENTIC_GH_CONFIG_DIR=
#
# Browser/Chrome and Codex App connectors are not copied by this file.
# See README.md for the difference between CLI credentials, browser profiles,
# and cloud connector sessions.
EOF
    chmod 600 "$base/env/inheritance.env"
  fi

  if [[ ! -f "$base/git/config" ]]; then
    cat > "$base/git/config" <<EOF
[init]
	defaultBranch = main
[pull]
	ff = only
[credential]
	helper = osxkeychain
EOF
    chmod 600 "$base/git/config"
  fi

  if [[ ! -f "$base/opencode/opencode.json" ]]; then
    cat > "$base/opencode/opencode.json" <<'EOF'
{
  "$schema": "https://opencode.ai/config.json",
  "permission": {
    "edit": "ask",
    "bash": "ask"
  },
  "enabled_providers": ["openai", "anthropic"]
}
EOF
    chmod 600 "$base/opencode/opencode.json"
  fi

  if [[ ! -f "$base/codex/AGENTS.md" && -f "$ROOT/shared/agents/AGENTS.md" ]]; then
    cp "$ROOT/shared/agents/AGENTS.md" "$base/codex/AGENTS.md"
    chmod 600 "$base/codex/AGENTS.md"
  fi
done

print "created isolated account roots under $ROOT"
print "add to zsh if desired:"
print "  export AGENTIC_ACCOUNTS_ROOT=\"$ROOT\""
print "  export PATH=\"$KIT_ROOT/bin:\\$PATH\""
