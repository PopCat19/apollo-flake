# Changelog — dev-experimental → dev

**Date:** 2026-02-17
**Branch:** dev-experimental
**Merge type:** Fast-forward (linear history)
**HEAD:** `pending` (rename after merge)

## Commits

- chore: sync dev-conventions ([`545345a`](https://github.com/PopCat19/apollo-flake/commit/545345a))
- docs(readme): update credits for llm contributions ([`a8bdf7e`](https://github.com/PopCat19/apollo-flake/commit/a8bdf7e))
- docs(readme): update credits for llm contributions ([`51935ef`](https://github.com/PopCat19/apollo-flake/commit/51935ef))
- docs(readme): add llm notice and simplify usage ([`6abaa7c`](https://github.com/PopCat19/apollo-flake/commit/6abaa7c))
- style: apply nixfmt formatting ([`0691e36`](https://github.com/PopCat19/apollo-flake/commit/0691e36))
- refactor(flake): scope allowunfree to cuda builds ([`88b83ea`](https://github.com/PopCat19/apollo-flake/commit/88b83ea))
- refactor(flake): extract build deps to let bindings ([`f29b10e`](https://github.com/PopCat19/apollo-flake/commit/f29b10e))
- fix(module): set default package from flake output ([`635082b`](https://github.com/PopCat19/apollo-flake/commit/635082b))
- fix(flake): move nixosModules to top-level output ([`f63c6f1`](https://github.com/PopCat19/apollo-flake/commit/f63c6f1))

## Files changed

```
 README.md                         |   37 +-
 apollo-module.nix                 |   53 +-
 conventions/AGENTS.md             |   93 ++
 conventions/DEV-EXAMPLES.md       |  398 ++++++++
 conventions/DEVELOPMENT.md        | 1885 +++++++++++++++++++++++++++++++++++++
 conventions/generate-changelog.sh |  355 +++++++
 conventions/sync-conventions.sh   |  326 +++++++
 flake.lock                        |   34 -
 flake.nix                         |  487 +++++-----
 9 files changed, 3373 insertions(+), 295 deletions(-)
```
