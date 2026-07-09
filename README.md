# Offsend GitHub Action

[![Offsend — AI hygiene](docs/badge.svg)](https://offsend.io/)

CI check for **AI-context risks**: secrets in the tree, missing AI ignore files, and workspace hygiene — before Cursor, Copilot, Claude Code, and similar tools read your repo.

```yaml
- uses: actions/checkout@v4
- uses: Offsend/offsend-action@v1
  with:
    fail-on: block
```

That's it. The action installs [`offsend-cli`](https://github.com/Offsend/Offsend/releases) and runs `offsend check`. No Homebrew, no extra setup.

Part of [Offsend](https://offsend.io/).

## What it catches

| Check | Example |
| --- | --- |
| Secrets & credentials | API keys, tokens, `.env` files committed to the repo |
| AI ignore / policy gaps | Missing or incomplete `.cursorignore`, `.aiignore`, and related files |
| Workspace hygiene | Paths and patterns that widen what AI tools can see |

Tune detectors and excludes with [`.offsend.yml`](https://github.com/Offsend/Offsend/blob/main/README.md#project-config-offsendyml) in your repository.

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
      - uses: Offsend/offsend-action@v1
        with:
          fail-on: block
```

### Scan only staged changes (PRs)

```yaml
- uses: Offsend/offsend-action@v1
  with:
    staged: "true"
    fail-on: block
```

### Warn without failing CI

```yaml
- uses: Offsend/offsend-action@v1
  with:
    fail-on: warn
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `path` | `.` | Path to scan (relative to the workflow working directory) |
| `staged` | `false` | Scan only git-staged files |
| `policy` | `true` | Include AI ignore files and workspace policy checks |
| `fail-on` | `block` | `block` · `warn` · `none` |
| `format` | `text` | `text` · `json` |
| `quiet` | `false` | Print only findings and errors |
| `version` | `0.10.0` | `offsend-cli` release to install |

## Requirements

- Runner: `ubuntu-latest` or `macos-latest`
- Linux: `x86_64` / `aarch64` · macOS: universal binary

## Versioning

```yaml
uses: Offsend/offsend-action@v1        # latest v1.x
uses: Offsend/offsend-action@v1.0.0    # exact release
```

## Development

```bash
chmod +x scripts/*.sh
OFFSEND_VERSION=0.10.0 ./scripts/install.sh
OFFSEND_PATH=. OFFSEND_POLICY=true ./scripts/run.sh
```

CI runs the action against fixtures on Ubuntu and macOS.

## License

MIT — see [LICENSE](LICENSE).
