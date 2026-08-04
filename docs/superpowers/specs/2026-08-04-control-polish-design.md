# STRATOSPHERE Control Polish Design

**Status:** Approved direction, design ready for implementation planning  
**Date:** 2026-08-04  
**Base:** `agent/phase-0-1-flight-room` at `6dea1a4f60b522b365732a5ca5045c28cce9b3b4`

## 1. Purpose

Phase 0–1 proved that the craft can take off, vector between hover and forward flight, follow a route, land, crash, restart, and export to Windows. The next milestone must improve the quality of flying before adding combat, progression, open-world systems, or more content.

The current input path converts mouse displacement from one physics tick directly into normalized pitch and yaw commands. The flight model then multiplies those values by raw torque constants. This creates abrupt torque spikes, physics-rate sensitivity, inconsistent stopping, and a craft that feels difficult for the wrong reasons.

This design replaces raw torque input with a simulation-preserving angular-rate controller.

## 2. Experience Goal

Keyboard-and-mouse flight should feel precise, physical, and learnable without becoming an attitude-hold arcade system.

The pilot should be able to:

- make small hover corrections without wobbling;
- command a deliberate sustained turn;
- stop rotation predictably when mouse movement stops;
- feel the craft's mass and rotational inertia;
- transition into forward flight without losing control authority;
- perform a fast roll or pitch manoeuvre without sudden torque spikes;
- rotate without artificial loss of linear velocity;
- land using manual control rather than altitude-hold automation;
- read the craft's control demand through a restrained HUD cue;
- use chase view without excessive camera roll or motion sickness.

## 3. Scope

### Included

- physics-rate-independent mouse processing;
- target angular-rate commands for pitch, yaw, and roll;
- axis-specific rate limits and control authority;
- closed-loop angular-rate torque control;
- response curves, smoothing, release behaviour, and clamping;
- hover and forward-flight control-authority blending;
- nominal-hover collective detent without altitude hold;
- improved thrust-vector input response;
- chase-camera position/rotation separation, velocity look-ahead, and dynamic FOV;
- a minimal control-demand HUD cue;
- deterministic unit, integration, and gameplay-smoke coverage;
- one implementation batch and one final repository push.

### Excluded

- auto-level or attitude hold;
- altitude hold;
- autopilot;
- controller or HOTAS support;
- control rebinding UI;
- combat;
- damage-system expansion;
- new world content;
- runtime integration of the Codex-produced hero model;
- final sound, VFX, or cockpit art.

The new Blender model remains an independent reviewed asset package until the user reports that it is ready.

## 4. Chosen Architecture

### 4.1 Input sampling

`PilotInputAdapter` remains responsible for Godot input events and action bindings, but it will no longer translate one tick's mouse pixels directly into raw torque demand.

For each physics tick:

1. Accumulate relative mouse movement received since the previous tick.
2. Divide accumulated movement by the safe physics delta to obtain mouse velocity in pixels per second.
3. Map mouse velocity into normalized pitch/yaw rate demand.
4. Apply per-axis sensitivity, inversion, bounded exponential response, and output clamping.
5. Smooth the demand with separate attack and release rates.
6. Ramp keyboard roll demand rather than switching instantly between zero and full roll.
7. Emit a sanitized `PilotCommand`.

Using pixels per second rather than pixels per physics tick makes equivalent physical mouse movement produce equivalent commands at different physics frequencies.

### 4.2 Control tuning resource

Introduce a `FlightControlProfile` resource as the single source of control-feel tuning.

It owns:

- mouse pixels per second required for full pitch demand;
- mouse pixels per second required for full yaw demand;
- pitch and yaw inversion flags;
- pitch/yaw response exponent;
- pitch/yaw attack and release rates;
- keyboard roll attack and release rates;
- maximum pitch, yaw, and roll rates in hover;
- maximum pitch, yaw, and roll rates in forward flight;
- per-axis rate-controller gains;
- per-axis maximum torque;
- nominal-hover collective value;
- hover-detent window and pull strength;
- collective and vector-transition rates;
- chase-camera response and FOV limits.

All values are clamped to safe ranges before use. The default resource is tuned for keyboard and mouse and is replaceable later without rewriting the controller.

### 4.3 Angular-rate controller

`PilotCommand.pitch`, `yaw`, and `roll` remain normalized values in `[-1, 1]`, preserving the existing command contract. Their meaning changes from "raw torque percentage" to "requested angular-rate percentage."

The flight model will:

1. Blend hover and forward-flight maximum angular rates using the craft's vector-transition state.
2. Convert normalized pilot demand into local target angular velocity.
3. Convert current world angular velocity into craft-local angular velocity.
4. Calculate local rate error: `target_rate - current_rate`.
5. Multiply each axis error by its rate-controller gain.
6. Clamp each axis to its configured maximum torque.
7. Transform the resulting torque back into world space.

There is no attitude target and no world-up correction. When input returns to zero, the controller requests zero angular velocity and removes rotation without levelling the craft.

The linear-force calculation remains independent of rotational input. Rotation must not directly reduce or redirect existing linear velocity beyond forces physically caused by the craft's changed orientation, thrust, lift, drag, and gravity.

### 4.4 Mode-dependent authority

Control response changes continuously with thrust-vector transition.

Default intended behaviour:

- **Hover:** strong yaw authority, controlled pitch, moderate roll.
- **Forward flight:** stronger pitch and roll rate, reduced yaw rate, increased aerodynamic feel.
- **Transition:** no discontinuity or sudden rate-limit jump.

The blend uses the same sanitized transition value as thrust vectoring. It must remain continuous from zero to one.

### 4.5 Collective and vector transition

Collective remains manually controlled.

A nominal-hover detent helps the player find approximately neutral vertical thrust:

- it activates only when neither collective key is held;
- it acts only inside a small configurable window around the nominal-hover value;
- it moves collective gently rather than snapping instantly;
- it does not inspect altitude or vertical speed;
- it is not altitude hold.

Vector transition remains a held-key accumulated control but uses bounded smoothing so rapid taps and releases do not produce mechanical-looking jumps.

### 4.6 Camera response

Cockpit mode remains rigidly attached to the cockpit anchor and follows the craft completely.

Chase mode separates:

- positional follow response;
- rotational follow response;
- roll-follow amount;
- velocity look-ahead;
- speed-based FOV.

The chase camera remains craft-relative but attenuates a configurable portion of roll. It does not become permanently world-level. FOV grows smoothly with forward speed and returns smoothly at low speed. Look-ahead uses bounded velocity projected into the craft's motion direction and cannot move the camera through the craft.

Camera calculations remain visual only and must never alter physics.

### 4.7 Control-demand cue

The HUD gains one restrained control cue:

- a small central marker shows current smoothed pitch/yaw demand;
- it remains inside a bounded region;
- it fades toward centre when demand releases;
- it is hidden or minimized in cockpit view if it obstructs instruments;
- it does not resemble a weapon crosshair.

This gives the player feedback about what the rate controller is being asked to do.

## 5. Component Boundaries

### `FlightControlProfile`

Pure configuration resource. No input reading, scene access, or physics mutation.

### `PilotInputAdapter`

Reads Godot input, tracks accumulated mouse delta and stateful smoothing, and emits normalized `PilotCommand` values. It does not calculate torque.

### `FlightModel`

Converts sanitized commands and physical state into force and torque results. It does not access the input singleton or camera.

### `FrontierVtolController`

Owns the physical body integration, supplies angular velocity and transition state to the flight model, and applies returned results exactly once.

### `FlightCameraRig`

Consumes craft transform and velocity for visual follow. It never writes to the craft.

### `FlightHud`

Displays telemetry and control demand. It does not decide or modify command values.

These boundaries keep tuning, input, physics, camera, and UI independently testable.

## 6. Data Flow

```text
Godot input events/actions
        |
        v
PilotInputAdapter
  - mouse velocity normalization
  - response curve
  - attack/release smoothing
  - roll ramp
  - collective/vector state
        |
        v
sanitized PilotCommand
        |
        +-----------------------> FlightHud control cue
        |
        v
FrontierVtolController
        |
        v
FlightModel
  - mode-blended target rates
  - local angular-rate error
  - bounded control torque
  - thrust/lift/drag/gravity
        |
        v
PhysicsDirectBodyState3D
        |
        +-----------------------> telemetry
                                      |
                                      +--> FlightHud
                                      +--> FlightCameraRig
```

## 7. Safety and Error Handling

- Negative or zero delta is treated safely and cannot divide by zero.
- Non-finite mouse values, commands, rates, tuning values, force results, or torque results are replaced with safe defaults before physics application.
- Sensitivities, exponents, gains, rates, torque limits, detent values, look-ahead, and FOV are clamped.
- A missing control profile falls back to a default profile.
- A missing craft binding leaves camera and HUD inactive without crashing.
- Input is neutralized while the gameplay state is crashed or completed.
- Reset clears accumulated mouse input, smoothing state, roll state, collective state, and vector-transition state deterministically.
- No control code may apply forces outside `_integrate_forces`.

## 8. Testing Strategy

Implementation follows test-first development.

### 8.1 Input unit tests

- Equivalent mouse speed at 60 Hz and 120 Hz produces equivalent normalized demand.
- Pitch and yaw demand remain bounded.
- Response exponent is monotonic and preserves sign.
- Attack smoothing approaches demand without overshoot.
- Release smoothing returns toward zero.
- Keyboard roll ramps instead of stepping instantly.
- Reset clears all smoothing and restores nominal initial controls.
- Collective detent acts only inside its window and only without active collective input.
- Vector transition remains bounded and continuous.

### 8.2 Flight-model unit tests

- Zero rate error produces approximately zero command torque.
- Positive and negative rate errors produce torque in the correct direction.
- Per-axis torque never exceeds configured limits.
- Hover and forward rate limits blend continuously.
- Forward flight reduces yaw-rate target while increasing pitch/roll targets according to the profile.
- Rotational input changes torque but does not directly change linear-force output.
- Non-finite input cannot produce non-finite force or torque.

### 8.3 Controller integration tests

- A constant rate command accelerates angular velocity toward its target.
- Releasing input reduces angular velocity toward zero.
- The controller does not auto-level an intentionally banked craft.
- Identical scripted inputs remain deterministic at the project's 120 Hz physics rate.
- Reset returns the craft and controller state to a reproducible baseline.

### 8.4 Camera tests

- Cockpit mode matches the cockpit anchor exactly.
- Position and rotation follow use independent response values.
- Chase roll attenuation remains bounded.
- FOV increases monotonically with speed and stays inside configured limits.
- Velocity look-ahead is bounded and returns smoothly at low speed.

### 8.5 Acceptance playtest

The batch is not accepted from automated tests alone. The Windows build must be manually checked for:

1. Stable takeoff from the starting pad.
2. Fine hover corrections without repeated oscillation.
3. A controlled 90-degree yaw turn.
4. A controlled pitch-over into forward flight.
5. A full roll that stops predictably after release.
6. Smooth hover-to-forward and forward-to-hover transitions.
7. Chase-camera comfort during turns and rolls.
8. Route completion and landing without control-state bugs.
9. Crash and restart with no stale input.
10. No obvious framerate-dependent control change.

## 9. Initial Tuning Targets

These are starting targets, not immutable gameplay guarantees:

- full mouse demand at roughly 850–1100 pixels per second;
- hover pitch rate around 55–70 degrees per second;
- hover yaw rate around 45–60 degrees per second;
- hover roll rate around 65–85 degrees per second;
- forward pitch rate around 80–105 degrees per second;
- forward yaw rate around 20–35 degrees per second;
- forward roll rate around 110–140 degrees per second;
- strong-input response reaching most of the target in roughly 0.25–0.45 seconds;
- release settling without visible oscillation in roughly 0.35–0.75 seconds;
- chase FOV approximately 76 degrees at low speed and no more than 92 degrees at high speed.

Final values are chosen through the acceptance playtest and committed with rationale.

## 10. Repository and CI Budget Policy

This milestone uses batch-based delivery:

1. Design is stored on the non-CI branch `design/control-polish`.
2. Implementation is performed locally through Codex in an isolated worktree or local branch.
3. Codex must not push, open pull requests, or trigger Actions.
4. All tests and local Godot verification run before repository publication.
5. Changes are reviewed as one complete diff.
6. The final implementation is published as one atomic or squashed commit to a dedicated implementation branch.
7. Exactly one canonical GitHub Actions verification/export run is expected for the completed batch, except when that run exposes a genuine defect requiring correction.
8. No generated-asset workflow participates in this control-only milestone.

## 11. Deliverable

The completed milestone is one verified Windows build in which flying the existing craft is substantially more precise, predictable, and comfortable while preserving momentum, inertia, manual piloting, and simulation-first behaviour.

The milestone does not claim final controls. It establishes a robust control architecture that can be tuned in later builds without another physics rewrite.
