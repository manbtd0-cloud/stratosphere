# Windows and Linux Support Decision

**Date:** 2026-08-06

## Decision

Develop and maintain the game for Windows x86_64 and Linux x86_64 from the beginning.

This decision supersedes the Windows-only wording in the initial design specification and Phase 0 plan. Windows remains an important player target, but Linux is a first-class development and runtime target rather than a later port.

## Shared implementation

Both platforms use the same:

- Godot project
- GDScript gameplay code
- scenes and resources
- asset imports
- save schemas
- input actions
- test contracts
- renderer configuration

## Platform-specific surface

Only these areas may differ:

- `tools/verify/verify.ps1` for Windows
- `tools/verify/verify.sh` for Linux
- export presets and package names
- optional code signing and desktop integration
- graphics-driver, audio-device, and controller validation

## Rules

- Resource paths and file names must match exact case.
- Runtime file access must use `res://` and `user://`, not hard-coded host paths.
- Production code must not invoke PowerShell, Bash, or platform executables directly unless isolated behind a platform adapter.
- Every local verification test must run through both wrappers.
- Native Windows and Linux builds receive smoke testing before milestone completion.
