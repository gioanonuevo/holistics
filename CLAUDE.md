## Holistics AMQL
This project uses Holistics AMQL - a domain-specific language for analytics-as-code (`.aml` files), with its own syntax for models, datasets, dashboards, and metrics, plus AQL for querying. Your training data on AML, AQL, and the Holistics platform is likely outdated or wrong; working from memory will produce broken code. **Always** load the `holistics-development` plugin skills before writing AML/AQL or answering Holistics questions:

- `holistics-development:setup-amql-development` - start here; environment, CLI, MCP setup
- `holistics-development:develop-amql` - writing models, datasets, dashboards, metrics
- `holistics-development:write-aql` - querying datasets via AQL
- ...and others (e.g. `search-docs`, `analyze-data`, `visualize-data`) - browse the `holistics-development` plugin's skill list

If you catch yourself guessing at AML syntax or Holistics behavior, load the relevant skill instead.

## Syncing with Holistics cloud
This WSL clone is the working copy that syncs with Holistics cloud; do all syncing and validating here. The Windows copy at `C:\Users\gldan\Desktop\Holistics` must never sync, because the Windows CLI pushes files under backslash paths.

- CLI: `~/.holistics/bin/holistics` (not on PATH; call it by full path). Auth is `us`, branch `develop`.
- Sync: `~/.holistics/bin/holistics sync-code --background` (check with `--status`; `--status --wait` blocks until a fresh cycle finishes). Resolve conflict markers in place without stopping the sync.
- Validate after every change: `~/.holistics/bin/holistics aml validate <files...>`
- Tools: `~/.holistics/bin/holistics mcp <tool> '<json>'` (read `--help` first; `execute_aql` needs `refresh_cache`)
