# mac-devpod-template
Template for DevPod on macOS (NoIDE).

## How to build Docker images

Build the base Ubuntu image (`devpod:0.0.1`) used by `Dockerfile-custom`:

```bash
docker buildx build -t devpod:0.0.1 -f Dockerfile .
```

Or build the Alpine variant:

```bash
docker buildx build -t devpod-template:alpine -f Dockerfile-alpine .
```

## How to start DevPod (NoIDE)

Clone or place this configuration into `.devpod/` inside your project repository, then run:

```bash
devpod up --devcontainer-path .devpod/devcontainer.json --ide none --dotfiles https://github.com/dewwripper/dotfiles --dotfiles-script .setup-no-install.sh .
```

## code-review-graph

[code-review-graph](https://github.com/tirth8205/code-review-graph) is baked into `Dockerfile-custom` and exposed to Claude Code as an MCP server. It is set up so that **client repositories are never modified**:

- The CLI is installed with `uv` into `/opt/code-review-graph` (pinned via `ARG CRG_VERSION`), because `~/.local` is bind-mounted from the host.
- `/usr/local/bin/code-review-graph` is a wrapper (`scripts/code-review-graph`) that stores each repo's graph in `$CRG_HOME/graphs/<repo>-<hash>` (`CRG_HOME=~/.local/share/code-review-graph`, persisted on the host) instead of `<repo>/.code-review-graph/`.
- `code-review-graph install` / `init` are blocked, since they write `.mcp.json`, `CLAUDE.md`, skills, hooks and `.gitignore` into the repo. Set `CRG_ALLOW_REPO_WRITES=1` to bypass.
- `postCreateCommand` registers the MCP server once at Claude Code **user** scope (`~/.claude.json`), not per repo.

Usage inside the devcontainer:

```bash
cd ~/workspace/<client-repo>
code-review-graph build     # first time
code-review-graph update    # incremental refresh after changes (or: code-review-graph watch)
claude                      # code-review-graph MCP tools are available
```

Verify the setup:

```bash
code-review-graph --version
claude mcp get code-review-graph
```

> Note: `~/.claude.json` is shared with the host, so Claude Code on the host lists `code-review-graph` as a failed MCP server unless it is installed there too. This is harmless.
