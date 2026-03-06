# FileUni Release Flow (Community Side)

## Purpose
This workflow file documents the public build-and-release pipeline in `FileUni-Community`.
The pipeline is dispatched from `FileUni-WorkSpace` or manually triggered.

## Workflow
- Workflow: `NewBuildReleaesByZig.yml`
- Trigger: `workflow_dispatch`
- Required secret: `FILEUNI_WORKSPACE_PAT`

## Current Design
The release pipeline is based on:
- `workspace/build.zig`
- `workspace/script-new-zig/`
- this workflow file

Legacy paths are explicitly out of scope for this flow:
- `workspace/script/` (Go backend)
- `workspace/script-zig/`
- `workspace/script-zig-next/`

## Step Responsibilities
1. Bootstrap checkout of `fileuni/FileUni-WorkSpace`.
2. Setup Rust/Zig (no Go runtime dependency in this flow).
3. Resolve release metadata via `zig build release-run -- ci:resolve-community-build`.
4. Build frontend once and reuse dist artifacts.
5. Prepare tools via `zig build release-run -- ci:prepare-tools`.
6. Build artifacts via `zig build release-run -- release:build-all` and validate via `ci:assert-artifacts`.
7. Publish release via `ci:publish-community-release`.
8. Write summary via `ci:write-release-summary`.

## Caching Strategy
- `~/.cargo-tools` for installed tool binaries.
- `~/.cache/cargo-binstall` for binstall metadata.
- `~/.cargo/registry` and `~/.cargo/git` for cargo dependency caches.
- `workspace/target` keyed by mode + `Cargo.lock` hash.
- `~/.bun/install/cache` for Bun package downloads.

## Tool Installation Strategy
For `tauri-cli`, `cargo-zigbuild`, and `cargo-xwin`:
1. Prefer `cargo-binstall` / prebuilt binaries.
2. Fallback to `cargo install` only if prebuilt install is unavailable.

This reduces environment preparation time on cache hits and avoids unnecessary source builds.

## Policy Notes
- New CI and release verification must use the `script-new-zig` command surface only.
- If a document or script still references `go run script/tools.go` or `script-zig*`, treat it as legacy and do not use it for release jobs.
