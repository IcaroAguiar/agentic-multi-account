#!/usr/bin/env zsh
set -euo pipefail

KIT_ROOT="${0:A:h:h}"
APP_PATH="${CODEX_WORK_APP_PATH:-/Applications/Codex Work.app}"
CODEX_APP_PATH="${CODEX_APP_PATH:-/Applications/Codex.app}"
ICON_PATH="${CODEX_WORK_ICON_PATH:-$KIT_ROOT/assets/icons/codex-work.icns}"
BACKUP_ROOT="${CODEX_WORK_BACKUP_ROOT:-$HOME/AgenticAccounts/shared/backups}"

if [[ ! -d "$CODEX_APP_PATH" ]]; then
  print -u2 "missing Codex app: $CODEX_APP_PATH"
  exit 66
fi

if [[ ! -f "$ICON_PATH" ]]; then
  print -u2 "missing Codex Work icon: $ICON_PATH"
  exit 66
fi

if [[ -e "$APP_PATH" ]]; then
  current_exec="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$APP_PATH/Contents/Info.plist" 2>/dev/null || true)"
  if [[ "$current_exec" != "codex-work-launcher" ]]; then
    mkdir -p "$BACKUP_ROOT"
    backup="$BACKUP_ROOT/Codex Work.app.backup.$(date +%Y%m%d%H%M%S)"
    mv "$APP_PATH" "$backup"
    print "moved existing Codex Work.app to $backup"
  fi
fi

mkdir -p "$APP_PATH/Contents/MacOS" "$APP_PATH/Contents/Resources"
cp "$ICON_PATH" "$APP_PATH/Contents/Resources/codex-work.icns"

cat > "$APP_PATH/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDisplayName</key>
  <string>Codex Work</string>
  <key>CFBundleExecutable</key>
  <string>codex-work-launcher</string>
  <key>CFBundleIconFile</key>
  <string>codex-work</string>
  <key>CFBundleIdentifier</key>
  <string>dev.agentic.codex-work</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Codex Work</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>12.0</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

launcher="$APP_PATH/Contents/MacOS/codex-work-launcher"
c_source="$(mktemp /private/tmp/codex-work-launcher.XXXXXX.c)"
cat > "$c_source" <<C_SOURCE
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/wait.h>
#include <unistd.h>

static void join3(char *out, size_t out_size, const char *a, const char *b, const char *c) {
  snprintf(out, out_size, "%s/%s/%s", a, b, c);
}

int main(int argc, char **argv) {
  const char *home = getenv("HOME");
  if (home == NULL || home[0] == '\\0') {
    home = "";
  }

  char accounts_root[PATH_MAX];
  const char *root_env = getenv("AGENTIC_ACCOUNTS_ROOT");
  if (root_env != NULL && root_env[0] != '\\0') {
    snprintf(accounts_root, sizeof(accounts_root), "%s", root_env);
  } else {
    snprintf(accounts_root, sizeof(accounts_root), "%s/AgenticAccounts", home);
  }

  char account_root[PATH_MAX];
  snprintf(account_root, sizeof(account_root), "%s/corp", accounts_root);

  char codex_home[PATH_MAX], xdg_config[PATH_MAX], xdg_cache[PATH_MAX], xdg_data[PATH_MAX], xdg_state[PATH_MAX], workspace[PATH_MAX];
  join3(codex_home, sizeof(codex_home), account_root, "codex", "");
  join3(xdg_config, sizeof(xdg_config), account_root, "xdg/config", "");
  join3(xdg_cache, sizeof(xdg_cache), account_root, "xdg/cache", "");
  join3(xdg_data, sizeof(xdg_data), account_root, "xdg/data", "");
  join3(xdg_state, sizeof(xdg_state), account_root, "xdg/state", "");

  if (argc > 1 && argv[1] != NULL && argv[1][0] != '\\0' && strncmp(argv[1], "-psn_", 5) != 0) {
    snprintf(workspace, sizeof(workspace), "%s", argv[1]);
  } else {
    join3(workspace, sizeof(workspace), account_root, "workspaces", "");
  }

  char env_account[64], env_accounts_root[PATH_MAX + 32], env_account_root[PATH_MAX + 32], env_codex_home[PATH_MAX + 32];
  char env_xdg_config[PATH_MAX + 32], env_xdg_cache[PATH_MAX + 32], env_xdg_data[PATH_MAX + 32], env_xdg_state[PATH_MAX + 32];

  snprintf(env_account, sizeof(env_account), "AGENTIC_ACCOUNT=corp");
  snprintf(env_accounts_root, sizeof(env_accounts_root), "AGENTIC_ACCOUNTS_ROOT=%s", accounts_root);
  snprintf(env_account_root, sizeof(env_account_root), "AGENTIC_ACCOUNT_ROOT=%s", account_root);
  snprintf(env_codex_home, sizeof(env_codex_home), "CODEX_HOME=%s", codex_home);
  snprintf(env_xdg_config, sizeof(env_xdg_config), "XDG_CONFIG_HOME=%s", xdg_config);
  snprintf(env_xdg_cache, sizeof(env_xdg_cache), "XDG_CACHE_HOME=%s", xdg_cache);
  snprintf(env_xdg_data, sizeof(env_xdg_data), "XDG_DATA_HOME=%s", xdg_data);
  snprintf(env_xdg_state, sizeof(env_xdg_state), "XDG_STATE_HOME=%s", xdg_state);

  pid_t pid = fork();
  if (pid == 0) {
    execl("/usr/bin/open", "open", "-n", "-a", "$CODEX_APP_PATH",
      "--env", env_account,
      "--env", env_accounts_root,
      "--env", env_account_root,
      "--env", env_codex_home,
      "--env", env_xdg_config,
      "--env", env_xdg_cache,
      "--env", env_xdg_data,
      "--env", env_xdg_state,
      (char *)NULL);
    _exit(127);
  }

  if (pid < 0) {
    return 1;
  }

  int status = 0;
  waitpid(pid, &status, 0);
  sleep(8);
  return WIFEXITED(status) ? WEXITSTATUS(status) : 1;
}
C_SOURCE

/usr/bin/cc -Os -Wall -Wextra -o "$launcher" "$c_source"
rm -f "$c_source"
xattr -cr "$APP_PATH"
codesign --force --deep --sign - "$APP_PATH" >/dev/null
touch "$APP_PATH"

print "installed Codex Work launcher at $APP_PATH"
