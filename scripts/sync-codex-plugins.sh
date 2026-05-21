#!/usr/bin/env zsh
set -euo pipefail

source "${0:A:h}/../lib/account-env.sh"

src_home="${1:-$HOME/.codex}"
target_account="${2:-corp}"

agentic_export_env "$target_account"

src_cache="$src_home/plugins/cache"
dst_cache="$CODEX_HOME/plugins/cache"
src_marketplaces="$src_home/.tmp/marketplaces"
dst_marketplaces="$CODEX_HOME/.tmp/marketplaces"
bundled_marketplace="$CODEX_HOME/.tmp/bundled-marketplaces/openai-bundled"
primary_runtime_marketplace="${CODEX_PRIMARY_RUNTIME_MARKETPLACE:-$HOME/.cache/codex-runtimes/codex-primary-runtime/plugins/openai-primary-runtime}"

if [[ ! -d "$src_cache" ]]; then
  print -u2 "source plugin cache not found: $src_cache"
  exit 66
fi

mkdir -p "$dst_cache"
chmod 700 "$CODEX_HOME" "$CODEX_HOME/plugins" "$dst_cache"

for marketplace in "$src_cache"/*; do
  [[ -d "$marketplace" ]] || continue
  name="${marketplace:t}"
  rm -rf "$dst_cache/$name"
  cp -R "$marketplace" "$dst_cache/$name"
done

mkdir -p "$dst_marketplaces"
for marketplace_name in lazyweb goalbuddy; do
  if [[ -d "$src_marketplaces/$marketplace_name" ]]; then
    rm -rf "$dst_marketplaces/$marketplace_name"
    cp -R "$src_marketplaces/$marketplace_name" "$dst_marketplaces/$marketplace_name"
  fi
done

find "$dst_cache" -type d -exec chmod 700 {} +
find "$dst_cache" -type f -exec chmod 600 {} +
if [[ -d "$dst_marketplaces" ]]; then
  find "$dst_marketplaces" -type d -exec chmod 700 {} +
  find "$dst_marketplaces" -type f -exec chmod 600 {} +
fi

lazyweb_mcp="$dst_cache/lazyweb/lazyweb/0.1.1/.mcp.json"
if [[ -f "$lazyweb_mcp" ]]; then
  tmp_mcp="$(mktemp)"
  sed 's#\$HOME/.lazyweb/lazyweb_mcp_token#${AGENTIC_ACCOUNT_ROOT:-$HOME}/.lazyweb/lazyweb_mcp_token#g; s#\$HOME/.codex/lazyweb_mcp_token#${CODEX_HOME:-$HOME/.codex}/lazyweb_mcp_token#g' "$lazyweb_mcp" > "$tmp_mcp"
  mv "$tmp_mcp" "$lazyweb_mcp"
  chmod 600 "$lazyweb_mcp"
fi

config="$CODEX_HOME/config.toml"
touch "$config"

tmp_config="$(mktemp)"
awk '
  /# >>> agentic synced plugin config >>>/ { skip=1; next }
  /# <<< agentic synced plugin config <<</ { skip=0; next }
  !skip { print }
' "$config" > "$tmp_config"
cat >> "$tmp_config" <<EOF

# >>> agentic synced plugin config >>>
[marketplaces.openai-bundled]
source_type = "local"
source = "$bundled_marketplace"

[marketplaces.openai-primary-runtime]
source_type = "local"
source = "$primary_runtime_marketplace"

[marketplaces.lazyweb]
source_type = "local"
source = "$dst_marketplaces/lazyweb"

[marketplaces.goalbuddy]
source_type = "local"
source = "$dst_marketplaces/goalbuddy"

[plugins."github@openai-curated"]
enabled = true

[plugins."google-drive@openai-curated"]
enabled = true

[plugins."gmail@openai-curated"]
enabled = true

[plugins."teams@openai-curated"]
enabled = true

[plugins."superpowers@openai-curated"]
enabled = true

[plugins."computer-use@openai-bundled"]
enabled = true

[plugins."browser@openai-bundled"]
enabled = true

[plugins."chrome@openai-bundled"]
enabled = true

[plugins."documents@openai-primary-runtime"]
enabled = true

[plugins."spreadsheets@openai-primary-runtime"]
enabled = true

[plugins."presentations@openai-primary-runtime"]
enabled = true

[plugins."hostinger@openai-curated"]
enabled = true

[plugins."vercel@openai-curated"]
enabled = true

[plugins."codex-security@openai-curated"]
enabled = true

[plugins."remotion@openai-curated"]
enabled = true

[plugins."lazyweb@lazyweb"]
enabled = true

[plugins."goalbuddy@goalbuddy"]
enabled = true
# <<< agentic synced plugin config <<<
EOF
mv "$tmp_config" "$config"
chmod 600 "$config"

print "synced Codex plugin bundles"
print "source: $src_cache"
print "target: $dst_cache"
print "updated config: $config"
