# Offsend GitHub Action

Check **AI-context risks** in CI — secrets, missing ignore files, and workspace hygiene before AI coding tools read your repository.

Part of [Offsend](https://offsend.io/) — local-first tools that help developers control what AI assistants can see.

```yaml
- name: Check AI-context risks
  uses: Offsend/offsend-action@v1
  with:
    policy: "true"
    fail-on: block
```

## Requirements

- **Runner:** `ubuntu-latest` or `macos-latest` (GitHub-hosted or self-hosted)
- The action downloads [`offsend-cli`](https://github.com/Offsend/Offsend/releases) from GitHub Releases — no Homebrew required
- Linux: `x86_64` / `aarch64` tarballs · macOS: universal zip with frameworks

## Usage

### Fail CI on findings (recommended)

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

      - name: Check AI-context risks
        uses: Offsend/offsend-action@v1
        with:
          path: .
          policy: "true"
          fail-on: block
```

### Scan only staged changes (pull requests)

```yaml
- name: Check staged changes
  uses: Offsend/offsend-action@v1
  with:
    staged: "true"
    policy: "true"
    fail-on: block
```

## Inputs

| Input | Required | Default | Description |
| --- | --- | --- | --- |
| `path` | No | `.` | Path to scan, relative to the workflow working directory |
| `staged` | No | `false` | Scan only git-staged files |
| `policy` | No | `true` | Include AI ignore files and workspace policy checks |
| `fail-on` | No | `block` | Exit policy: `block`, `warn`, or `none` |
| `format` | No | `text` | Output format: `text` or `json` |
| `quiet` | No | `false` | Only print findings and errors |
| `version` | No | `0.10.0` | `offsend-cli` release version to install |

## Project configuration

Add [`.offsend.yml`](https://github.com/Offsend/Offsend/blob/main/README.md#project-config-offsendyml) to your repository to tune detectors, exclude globs, and default check behavior.

## Versioning

Pin to a major tag for automatic patch updates:

```yaml
uses: Offsend/offsend-action@v1
```

Or pin an exact release:

```yaml
uses: Offsend/offsend-action@v1.0.0
```

## Development

```bash
chmod +x scripts/*.sh
OFFSEND_VERSION=0.10.0 ./scripts/install.sh
OFFSEND_PATH=. OFFSEND_POLICY=true ./scripts/run.sh
```

CI in this repository runs the action against test fixtures on `ubuntu-latest` and `macos-latest`.

## License

MIT — see [LICENSE](LICENSE).
