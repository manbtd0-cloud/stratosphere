# Phase 0 AAA Graphics Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Status:** Implemented and verified on Linux; physical Windows/GPU checks are recorded separately.

**Goal:** Complete Phase 0 with cross-platform core services, scalable AAA-target rendering profiles, auditable asset standards, and reproducible graphics benchmarks.

**Architecture:** Typed Godot resources define settings, graphics profiles, saves, and asset records. Autoload services apply settings and own persistence without containing gameplay rules. Graphics workloads are isolated scenes, and verification invokes every contract independently on Windows and Linux.

**Tech Stack:** Godot 4.7.1, GDScript 2.0, Forward+, Bash, Windows PowerShell 5.1+

## Global Constraints

- Windows x86_64 and Linux x86_64 are first-class desktop targets.
- Forward+ is the only supported renderer for the first major version.
- Primary performance target is 1920×1080 at 60 FPS on GTX 1660 / RX 580-class hardware using an appropriate quality profile and resolution scaling.
- Cinematic quality is a developer reference, not a minimum-hardware performance promise.
- No GitHub Actions; all verification runs locally.
- Core systems remain modular, data-driven, independently testable, and platform-neutral.
- Use `res://` and `user://`; never hard-code Windows or Linux filesystem paths in gameplay code.
- Use one meaningful commit per independently reviewable group, not micro-commits.

---

### Task 1: Record the graphics architecture and cross-platform policy

**Files:**
- Create: `docs/superpowers/specs/2026-08-06-aaa-graphics-foundation-design.md`
- Create: `docs/standards/graphics-and-assets.md`
- Modify: `docs/superpowers/specs/2026-08-06-open-world-racing-game-design.md`
- Modify: `README.md`
- Modify: `.gitignore`
- Modify: `.gitattributes`

**Produces:** committed quality tiers, material rules, asset budgets, frame budgets, and Windows/Linux export policy.

- [x] Write the approved graphics design.
- [x] Add exact standards and acceptance budgets.
- [x] Version-control `export_presets.cfg`; ignore only `.godot/` credentials and generated builds.
- [x] Verify documentation contains no `TBD`, `TODO`, or contradictory platform language.

### Task 2: Complete typed settings and input foundations

**Files:**
- Create: `src/settings/game_settings.gd`
- Create: `src/settings/settings_service.gd`
- Create: `src/input/input_profile.gd`
- Create: `src/input/input_router.gd`
- Create: `tests/unit/test_game_settings.gd`
- Create: `tests/unit/test_input_profile.gd`
- Modify: `project.godot`
- Modify: `tools/verify/verify.ps1`
- Modify: `tools/verify/verify.sh`

**Produces:** `GameSettings`, `SettingsService`, `InputProfile`, and `InputRouter` with typed APIs and JSON persistence.

- [x] Write failing tests for defaults, sanitization, round-tripping, keyboard ramping, and controller dead zones.
- [x] Run tests and confirm missing-class failures.
- [x] Implement typed resources and services.
- [x] Configure canonical drive input actions.
- [x] Run all verification and commit with the graphics-service work in Task 3.

### Task 3: Add scalable graphics profiles and runtime application

**Files:**
- Create: `src/graphics/render_quality_profile.gd`
- Create: `src/graphics/graphics_quality_service.gd`
- Create: `src/graphics/performance_budget.gd`
- Create: `data/graphics/low.tres`
- Create: `data/graphics/medium.tres`
- Create: `data/graphics/high.tres`
- Create: `data/graphics/ultra.tres`
- Create: `data/graphics/cinematic.tres`
- Create: `tests/unit/test_render_quality_profile.gd`
- Create: `tests/unit/test_graphics_quality_service.gd`
- Modify: `project.godot`

**Produces:** quality profiles with explicit feature toggles, density multipliers, render scale, LOD policy, and performance budgets.

- [x] Write failing tests for profile validation and ordering.
- [x] Confirm failures because classes do not exist.
- [x] Implement profile resources and clamped sanitization.
- [x] Implement application through `ProjectSettings`, `Viewport`, and `SceneTree` APIs that are safe at runtime.
- [x] Register `GraphicsQualityService` as an autoload.
- [x] Verify all tests.

### Task 4: Add versioned atomic save persistence

**Files:**
- Create: `src/persistence/save_data.gd`
- Create: `src/persistence/save_service.gd`
- Create: `tests/unit/test_save_service.gd`
- Modify: `project.godot`
- Modify: verification scripts

**Produces:** versioned save slots with temporary-file writes, backups, corruption recovery, and migration dispatch.

- [x] Write failing fresh-save, round-trip, backup, corruption, and future-version tests.
- [x] Confirm failures.
- [x] Implement typed `SaveData` and atomic `SaveService`.
- [x] Run all verification.

### Task 5: Add the auditable asset registry

**Files:**
- Create: `src/assets/asset_record.gd`
- Create: `src/assets/asset_registry.gd`
- Create: `data/assets/.gitkeep`
- Create: `tests/unit/test_asset_registry.gd`
- Modify: `project.godot`
- Modify: verification scripts

**Produces:** asset registration, validation, JSON audit export, and AAA-target metadata checks.

- [x] Write failing tests for duplicate IDs, invalid paths, nonpositive scale, unknown kinds, missing LOD metadata, and material budgets.
- [x] Confirm failures.
- [x] Implement records, validation, registry lookup, and audit export.
- [x] Run all verification.

### Task 6: Build the graphics laboratory and benchmark reporter

**Files:**
- Create: `src/benchmark/benchmark_controller.gd`
- Create: `src/benchmark/graphics_lab_builder.gd`
- Create: `src/benchmark/graphics_lab.tscn`
- Create: `src/benchmark/open_world_proxy.tscn`
- Create: `src/benchmark/pipeline_warmup.tscn`
- Create: `tests/smoke/test_benchmark_contract.gd`
- Create: `tests/unit/test_benchmark_report.gd`
- Modify: verification scripts

**Produces:** reproducible workloads and reports containing frame, renderer, memory, draw, primitive, and pipeline-compilation metrics.

- [x] Write failing scene and report contract tests.
- [x] Confirm failures.
- [x] Implement benchmark measurement and non-authoritative headless detection.
- [x] Build deterministic primitive workloads with instancing, lights, decals, transparent materials, wet-surface proxies, and moving camera paths.
- [x] Add `--benchmark` / `-Benchmark` wrapper options.
- [x] Run contract benchmarks and full verification.

### Task 7: Add Windows and Linux export contracts

**Files:**
- Create: `export_presets.cfg`
- Create: `tests/smoke/test_export_contract.gd`
- Modify: `.gitignore`
- Modify: verification scripts

**Produces:** Windows Desktop and Linux x86_64 presets using Forward+, shader baking, and deterministic output paths.

- [x] Write a failing test that checks both preset names and required options.
- [x] Confirm failure.
- [x] Add presets and enable shader baking.
- [x] Verify preset parsing without requiring export templates.

### Task 8: Complete the Phase 0 quality gate

**Files:**
- Create: `docs/status/phase-0-report.md`
- Modify: `README.md`
- Modify: this plan

**Produces:** exact test totals, engine version, renderer status, benchmark report status, and remaining hardware-only validations.

- [x] Run full Linux verification.
- [x] Run benchmark contract and record whether the renderer is authoritative.
- [x] Scan production files for unresolved placeholders.
- [x] Confirm all documented paths exist and all tests are listed in both wrappers.
- [x] Record Windows-native checks that cannot be executed in the Linux environment.
- [x] Commit the completed Phase 0 implementation.

## Self-review

- All approved Phase 0 services are assigned to explicit tasks.
- The graphics addendum covers quality profiles, lighting, materials, LOD, shader pipelines, benchmarks, exports, and hardware truthfulness.
- Vehicle physics, road generation, race AI, career gameplay, police, and final art remain outside Phase 0.
- No implementation step uses undefined interfaces or placeholders.
