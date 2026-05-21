#!/usr/bin/env zsh
set -euo pipefail

agentic_usage() {
  print -u2 "usage: $0 <personal|corp> [command...]"
}

agentic_resolve_account() {
  local account="${1:-}"
  case "$account" in
    personal|corp) print -- "$account" ;;
    *) agentic_usage; return 64 ;;
  esac
}

agentic_export_env() {
  local account
  account="$(agentic_resolve_account "${1:-}")"

  export AGENTIC_ACCOUNT="$account"
  export AGENTIC_ACCOUNTS_ROOT="${AGENTIC_ACCOUNTS_ROOT:-$HOME/AgenticAccounts}"
  export AGENTIC_ACCOUNT_ROOT="$AGENTIC_ACCOUNTS_ROOT/$account"
  export AGENTIC_SHARED_ROOT="$AGENTIC_ACCOUNTS_ROOT/shared"

  export CODEX_HOME="$AGENTIC_ACCOUNT_ROOT/codex"
  export CLAUDE_CONFIG_DIR="$AGENTIC_ACCOUNT_ROOT/claude"
  export OPENCODE_CONFIG_DIR="$AGENTIC_ACCOUNT_ROOT/opencode"

  export XDG_CONFIG_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/config"
  export XDG_CACHE_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/cache"
  export XDG_DATA_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/data"
  export XDG_STATE_HOME="$AGENTIC_ACCOUNT_ROOT/xdg/state"

  export GH_CONFIG_DIR="$AGENTIC_ACCOUNT_ROOT/github"
  export GIT_CONFIG_GLOBAL="$AGENTIC_ACCOUNT_ROOT/git/config"
  export TMPDIR="$AGENTIC_ACCOUNT_ROOT/tmp"

  export CLAUDE_CODE_TMPDIR="$AGENTIC_ACCOUNT_ROOT/tmp"
  export CLAUDE_CODE_SUBPROCESS_ENV_SCRUB="${CLAUDE_CODE_SUBPROCESS_ENV_SCRUB:-1}"

  unset OPENAI_API_KEY
  unset ANTHROPIC_API_KEY
  unset ANTHROPIC_AUTH_TOKEN
  unset GH_TOKEN
  unset GITHUB_TOKEN
  unset GOOGLE_APPLICATION_CREDENTIALS
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN

  local env_file="$AGENTIC_ACCOUNT_ROOT/env/account.env"
  if [[ -f "$env_file" ]]; then
    set -a
    source "$env_file"
    set +a
  fi

  mkdir -p "$TMPDIR"
}

