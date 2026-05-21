#!/usr/bin/env zsh
set -euo pipefail

source "${0:A:h}/../lib/account-env.sh"

src_home="${1:-$HOME/.codex}"
target_account="${2:-corp}"

agentic_export_env "$target_account"
src_home="${src_home:A}"

if [[ ! -f "$src_home/config.toml" ]]; then
  print -u2 "source config not found: $src_home/config.toml"
  exit 66
fi

mkdir -p "$CODEX_HOME"
chmod 700 "$CODEX_HOME"

if [[ -f "$src_home/AGENTS.md" ]]; then
  cp "$src_home/AGENTS.md" "$CODEX_HOME/AGENTS.md"
  chmod 600 "$CODEX_HOME/AGENTS.md"
fi

if [[ -d "$src_home/agents" ]]; then
  rm -rf "$CODEX_HOME/agents"
  cp -R "$src_home/agents" "$CODEX_HOME/agents"
  find "$CODEX_HOME/agents" -type d -exec chmod 700 {} +
  find "$CODEX_HOME/agents" -type f -exec chmod 600 {} +
fi

if [[ -d "$src_home/hooks" ]]; then
  rm -rf "$CODEX_HOME/hooks"
  cp -R "$src_home/hooks" "$CODEX_HOME/hooks"
  find "$CODEX_HOME/hooks" -type f -name '*.bak-*' -delete
  find "$CODEX_HOME/hooks" -type d -exec chmod 700 {} +
  find "$CODEX_HOME/hooks" -type f -exec chmod 600 {} +

  # Keep hook operational state inside the target CODEX_HOME, not the personal ~/.codex.
  if [[ -f "$CODEX_HOME/hooks/harness_guard.py" ]]; then
    sed -i '' "s#Path('$src_home/hook-state')#Path('$CODEX_HOME/hook-state')#g" "$CODEX_HOME/hooks/harness_guard.py"
  fi
  if [[ -f "$CODEX_HOME/hooks/lib/harness_common.py" ]]; then
    sed -i '' "s#Path(\"$src_home/state/hooks\")#Path(os.environ.get(\"CODEX_HOME\", \"$CODEX_HOME\")) / \"state\" / \"hooks\"#g" "$CODEX_HOME/hooks/lib/harness_common.py"
  fi
  if [[ -f "$CODEX_HOME/hooks/pr_babysitter.py" ]]; then
    sed -i '' "s#STATE_DIR = Path.home() / \".codex\" / \"state\" / \"pr-babysitter\"#STATE_DIR = Path(os.environ.get(\"CODEX_HOME\", str(Path.home() / \".codex\"))) / \"state\" / \"pr-babysitter\"#g" "$CODEX_HOME/hooks/pr_babysitter.py"
  fi
fi

if [[ -f "$src_home/hooks.json" ]]; then
  sed "s#$src_home/hooks#$CODEX_HOME/hooks#g" "$src_home/hooks.json" > "$CODEX_HOME/hooks.json"
  chmod 600 "$CODEX_HOME/hooks.json"
fi

base_tmp="$(mktemp)"
awk '
  /^\[plugins\./ { exit }
  /^\[projects\./ { exit }
  /^\[apps\./ { exit }
  /^\[marketplaces\./ { exit }
  /^\[memories\]/ { exit }
  /^\[hooks\.state\]/ { exit }
  /^\[\[skills\.config\]\]/ { exit }
  { print }
' "$src_home/config.toml" > "$base_tmp"

plugin_block_tmp="$(mktemp)"
if [[ -f "$CODEX_HOME/config.toml" ]]; then
  awk '
    /# >>> agentic synced plugin config >>>/ { capture=1 }
    capture { print }
    /# <<< agentic synced plugin config <<</ { capture=0 }
  ' "$CODEX_HOME/config.toml" > "$plugin_block_tmp"
fi

cat "$base_tmp" > "$CODEX_HOME/config.toml"
cat >> "$CODEX_HOME/config.toml" <<EOF

[memories]
disable_on_external_context = true
EOF

if [[ -s "$plugin_block_tmp" ]]; then
  print "" >> "$CODEX_HOME/config.toml"
  cat "$plugin_block_tmp" >> "$CODEX_HOME/config.toml"
fi

rm -f "$base_tmp" "$plugin_block_tmp"
chmod 600 "$CODEX_HOME/config.toml"

print "synced Codex harness"
print "source: $src_home"
print "target: $CODEX_HOME"
