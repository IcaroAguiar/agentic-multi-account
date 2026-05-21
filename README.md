# Agentic Multi Account

Small macOS/zsh toolkit for running Codex, Claude Code, OpenCode, VSCode and GitHub CLI with separate local state per account.

It is designed for people who need personal and work accounts open at the same time without mixing auth, sessions, threads, logs, caches or workspace history.

## What It Does

Creates isolated account homes like:

```text
~/AgenticAccounts/
  personal/
    codex/
    claude/
    opencode/
    xdg/config/
    xdg/cache/
    xdg/data/
    xdg/state/
    github/
    git/config
    tmp/
    workspaces/
    env/account.env
    env/inheritance.env
  corp/
    ...
  shared/
    agents/
    policies/
    skills/
    mcp/
```

Each wrapper exports account-scoped environment variables before launching the tool:

- `CODEX_HOME`
- `CLAUDE_CONFIG_DIR`
- `OPENCODE_CONFIG_DIR`
- `XDG_CONFIG_HOME`
- `XDG_CACHE_HOME`
- `XDG_DATA_HOME`
- `XDG_STATE_HOME`
- `GH_CONFIG_DIR`
- `GIT_CONFIG_GLOBAL`
- `TMPDIR`

The scripts also unset common provider tokens before loading the selected account env file, reducing accidental cross-account leakage.

## Install

Clone the repo and run the bootstrap:

```zsh
git clone https://github.com/IcaroAguiar/agentic-multi-account.git
cd agentic-multi-account
./scripts/bootstrap-agentic-accounts.sh
```

Add the wrappers to your shell:

```zsh
export AGENTIC_MULTI_ACCOUNT_HOME="$HOME/src/agentic-multi-account"
export AGENTIC_ACCOUNTS_ROOT="$HOME/AgenticAccounts"
export PATH="$AGENTIC_MULTI_ACCOUNT_HOME/bin:$PATH"
```

Recommended aliases:

```zsh
alias codex-me="agentic-codex personal"
alias codex-corp="agentic-codex corp"
alias app-me="agentic-codex-app personal"
alias app-corp="agentic-codex-app corp"

alias claude-me="agentic-claude personal"
alias claude-corp="agentic-claude corp"
alias opencode-me="agentic-opencode personal"
alias opencode-corp="agentic-opencode corp"

alias code-me="agentic-code personal"
alias code-corp="agentic-code corp"
alias gh-me="agentic-gh personal"
alias gh-corp="agentic-gh corp"

alias shell-me="agentic-shell personal"
alias shell-corp="agentic-shell corp"
alias doctor-me="agentic-doctor personal"
alias doctor-corp="agentic-doctor corp"
```

## First Login

Do not copy `auth.json` between accounts. Log in inside each isolated home:

```zsh
agentic-codex personal login
agentic-codex corp login

agentic-gh personal auth login
agentic-gh corp auth login
```

For Claude Code and OpenCode, launch through the wrapper and complete their normal login/config flow:

```zsh
agentic-claude corp
agentic-opencode corp
```

## Daily Use

```zsh
codex-corp                 # Codex CLI with corp state
app-corp                   # Codex App with corp CODEX_HOME
claude-corp                # Claude Code with corp config
opencode-corp              # OpenCode with corp config/XDG state
code-corp ~/AgenticAccounts/corp/workspaces/my-repo
gh-corp auth status
doctor-corp
```

Use the matching `*-me` aliases for your personal account.

## Codex Work App Icon

Do not modify a copied Electron `Codex.app` bundle. Changing `Contents/Info.plist`, helper bundle identifiers or signed resources can make Electron crash with `Unable to find helper app`.

Install the supported `Codex Work.app` launcher instead:

```zsh
./scripts/install-codex-work-app.sh
```

The launcher has its own icon and opens the official `/Applications/Codex.app` with the corp environment (`CODEX_HOME`, XDG paths and account roots). The runtime isolation still comes from the account environment, not from mutating the signed Electron app.

## Account Env Files

Per-account env lives here:

```text
~/AgenticAccounts/personal/env/account.env
~/AgenticAccounts/corp/env/account.env
~/AgenticAccounts/personal/env/inheritance.env
~/AgenticAccounts/corp/env/inheritance.env
```

Use `account.env` for account-specific secrets and provider settings:

```zsh
OPENAI_PROJECT=
OPENAI_ORGANIZATION=
ANTHROPIC_API_KEY=
OPENCODE_MODEL=
```

Use `inheritance.env` for non-secret decisions about what a wrapped account may reuse from the normal macOS user:

```zsh
# 0 = isolated gh auth under ~/AgenticAccounts/<account>/github
# 1 = inherit the normal global gh auth from ~/.config/gh
AGENTIC_INHERIT_GH=0
```

Keep both files private. The bootstrap creates them with `0600`.

## Credential Inheritance

The default is strict isolation. Each account gets separate Codex state, XDG state, GitHub CLI config, Git config, tmp, logs and workspaces.

Selective inheritance is intentionally opt-in and depends on the credential type:

| Surface | Default | How to inherit | Notes |
| --- | --- | --- | --- |
| GitHub CLI | isolated | set `AGENTIC_INHERIT_GH=1` in `env/inheritance.env` | Then `gh-corp` uses the same `~/.config/gh` auth as plain `gh`. |
| GitHub Codex plugin | follows `gh` CLI | same as GitHub CLI | The GitHub plugin shells out to `gh` for many workflows. |
| Vercel CLI/env | provider tokens scrubbed | put corp-specific `VERCEL_TOKEN` etc. in `account.env` | Do not inherit by default if personal and corp projects differ. |
| Hostinger env | provider tokens scrubbed | put corp-specific token/env in `account.env` | Hosted Codex connectors may also require login in the target Codex account. |
| Chrome/browser profile | normal macOS profile unless separately isolated | use your normal Chrome profile or create a separate Chrome profile manually | `CODEX_HOME` does not isolate Chrome cookies. |
| Teams/Gmail/Drive hosted connectors | connector/account controlled | connect the plugin inside the target Codex/ChatGPT account | Do not copy local files to inherit these sessions. |
| Codex auth/session/history | isolated | do not inherit | Never copy `auth.json`, state DBs, sessions, logs or rollouts. |

Example: make only the corp account inherit global GitHub CLI auth:

```zsh
printf '%s\n' 'AGENTIC_INHERIT_GH=1' > ~/AgenticAccounts/corp/env/inheritance.env
chmod 600 ~/AgenticAccounts/corp/env/inheritance.env
gh-corp auth status
```

When GitHub inheritance is enabled, the wrapper sets `GH_CONFIG_DIR=$HOME/.config/gh` explicitly. This matters because the wrapper still isolates `XDG_CONFIG_HOME`, and the GitHub CLI otherwise follows XDG paths.

If global `gh auth status` reports an invalid token, inherited `gh-corp auth status` will report the same invalid token. Re-authenticate the global GitHub CLI with:

```zsh
gh auth login -h github.com
```

If you want corp GitHub to be separate instead, keep `AGENTIC_INHERIT_GH=0` and run:

```zsh
gh-corp auth login -h github.com
```

## Sync Codex Harness And Plugins

If you already have a well-maintained personal Codex setup and want to copy approved configuration into another account:

```zsh
./scripts/sync-codex-harness.sh ~/.codex corp
./scripts/sync-codex-plugins.sh ~/.codex corp
agentic-codex corp plugin list
```

The sync scripts are intentionally conservative:

- copy `AGENTS.md`, `agents/`, selected config, hooks and plugin bundles;
- rewrite hook paths to the target `CODEX_HOME`;
- keep hook state under the target account;
- do not copy auth, sessions, threads, logs, state DBs or prompt history.

## VSCode

`agentic-code` opens VSCode with separate user data and extensions per account:

```zsh
agentic-code corp ~/AgenticAccounts/corp/workspaces/my-repo
```

That isolates VSCode settings, extension state and workspace storage. For highly sensitive corporate work, a separate macOS user is still the stronger isolation boundary because GUI apps may use the same Login Keychain.

## direnv

Copy `examples/direnv.envrc` into a repo as `.envrc`, adjust the account and run `direnv allow`.

```zsh
export AGENTIC_EXPECTED_ACCOUNT=corp
```

This makes shells inside that repo automatically adopt the right account environment.

## Security Notes

This project is for local operational isolation. It does not create a separate macOS keychain, browser profile or OS user.

Good defaults:

- never copy `auth.json`;
- never share account env files;
- do not symlink live caches between accounts;
- keep workspaces separated by account;
- prefer login inside each wrapper;
- use a separate macOS user for strict enterprise isolation.

## Files

```text
bin/agentic-codex          Codex CLI wrapper
bin/agentic-codex-app      Codex App launcher with isolated env
bin/agentic-claude         Claude Code wrapper
bin/agentic-opencode       OpenCode wrapper
bin/agentic-code           VSCode wrapper
bin/agentic-gh             GitHub CLI wrapper
bin/agentic-shell          account-scoped interactive shell
bin/agentic-doctor         prints effective paths

lib/account-env.sh         shared env resolver

scripts/bootstrap-agentic-accounts.sh
scripts/install-codex-work-app.sh
scripts/sync-codex-harness.sh
scripts/sync-codex-plugins.sh
```

## Rollback

The setup is additive. To stop using it:

1. Remove the aliases/PATH entries from your shell config.
2. Stop launching tools through the wrappers.
3. Optionally archive or delete `~/AgenticAccounts`.

No default personal tool state is modified by the bootstrap.
