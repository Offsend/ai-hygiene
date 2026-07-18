# Offsend GitHub Action

[![Offsend — AI hygiene](docs/badge.svg)](https://offsend.io/)

CI check for **AI-context risks**: secrets in the tree, missing AI ignore files, and workspace hygiene — before Cursor, Copilot, Claude Code, and similar tools read your repo.

```yaml
- uses: actions/checkout@v4
- uses: Offsend/ai-hygiene@v1
  with:
    fail-on: block
```

That's it. The action installs [`offsend-cli`](https://github.com/Offsend/Offsend/releases) and runs `offsend check`. No Homebrew, no extra setup.

Part of [Offsend](https://offsend.io/).

## What it catches

| Check | Example |
| --- | --- |
| Secrets & credentials | API keys, tokens, `.env` files committed to the repo |
| AI ignore / policy gaps | Missing or incomplete `.cursorignore`, `.aiignore`, and related files (when policy is enabled) |
| Workspace hygiene | Paths and patterns that widen what AI tools can see |

Tune detectors and excludes with [`.offsend.yml`](https://github.com/Offsend/Offsend/blob/main/README.md#project-config-offsendyml) in your repository.

By default the action follows that file: it does **not** pass `--policy`, so `check.policy` from `.offsend.yml` applies (template default is `false`). That matches repos that keep AI ignore files local via `ignore.commit: false` — those files are not in the CI checkout, so forcing policy would false-fail on “Missing … ignore file”.

## Badge

Add this to your README after enabling the action:

```markdown
[![Offsend — AI hygiene](https://raw.githubusercontent.com/Offsend/ai-hygiene/main/docs/badge.svg)](https://offsend.io/)
```

## Usage

### Fail the job on findings (recommended)

```yaml
name: AI context check

on:
  pull_request:
  push:
    branches: [main]

jobs:
  offsend:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: Offsend/ai-hygiene@v1
        with:
          fail-on: block
```

### Scan only staged changes (PRs)

```yaml
- uses: Offsend/ai-hygiene@v1
  with:
    staged: "true"
    fail-on: block
```

### Also fail on ignore-file / policy gaps

Requires AI ignore files to be present in the checkout (e.g. `ignore.commit: true` in `.offsend.yml`, or generating them in a prior step):

```yaml
- uses: Offsend/ai-hygiene@v1
  with:
    policy: "true"
    fail-on: block
```

### Warn without failing CI

```yaml
- uses: Offsend/ai-hygiene@v1
  with:
    fail-on: warn
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `path` | `.` | Path to scan (relative to the workflow working directory) |
| `staged` | `false` | Scan only git-staged files |
| `policy` | `false` | Force `--policy`. When false, use `.offsend.yml` `check.policy` |
| `fail-on` | `block` | `block` · `warn` · `none` |
| `format` | `text` | `text` · `json` |
| `quiet` | `false` | Print only findings and errors |
| `version` | `0.17.0` | `offsend-cli` release to install |

## Requirements

- Runner: `ubuntu-latest` or `macos-latest`
- Linux: `x86_64` / `aarch64` · macOS: universal binary

## Versioning

```yaml
uses: Offsend/ai-hygiene@v1        # latest v1.x
uses: Offsend/ai-hygiene@v1.0.0    # exact release
```

## Development

```bash
chmod +x scripts/*.sh
OFFSEND_VERSION=0.17.0 ./scripts/install.sh
OFFSEND_PATH=. ./scripts/run.sh
# Force policy checks (fixtures ship ignore files):
OFFSEND_PATH=test/fixtures/clean-repo OFFSEND_POLICY=true OFFSEND_FAIL_ON=block ./scripts/run.sh
```

CI runs the action against fixtures on Ubuntu and macOS.

## License

MIT — see [LICENSE](LICENSE).
