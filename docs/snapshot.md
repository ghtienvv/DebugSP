# Snapshot

## Overview

Snapshot is the visual inspection tool in DebugSP for understanding how a screen is rendered at a given moment.

Instead of focusing only on the logical view tree, Snapshot helps you reason about the rendered result: overlapping content, visual stacking, complex compositions, and screen states that are difficult to understand from source code alone.

## Why it matters

Many UI problems are not obvious from hierarchy alone.

A view can exist in the correct place in the tree and still be visually wrong because of rendering order, transforms, clipping, offscreen composition, overlays, or container behavior.

Snapshot helps answer questions such as:

- What does the screen look like as a rendered composition?
- Which parts of the interface overlap each other?
- Why does a screen feel visually layered or hard to parse?
- Which part of the UI is in front, behind, or isolated?
- How does the current view structure translate into what the user actually sees?

## Technology

The snapshot flow uses UIKit rendering capture and view traversal support from the DebugSP Objective-C inspection stack.

At runtime, DebugSP can capture the current state of the active UI and turn it into a visual model that is easier to inspect than a static screenshot alone.

This makes Snapshot useful for:

- rendered-state analysis
- visual layering checks
- composition review
- comparing complex UI arrangements during runtime

## Typical use cases

### Overlay debugging

Use Snapshot when banners, modals, floating panels, HUDs, or gesture overlays are covering one another unexpectedly.

### Rendering verification

Use it to understand how a complex screen is visually composed after runtime state, animation, and conditional rendering have taken effect.

### Design QA

Use it when a screen feels visually off and you need a runtime-oriented way to inspect its composition.

### Complex surface analysis

Use it for dashboards, editors, feed cells, nested containers, and other high-density interfaces.

## What it is good at

- understanding rendered visual composition
- debugging overlap and stacking issues
- analyzing dense, multi-layered screens
- reviewing runtime screen state without leaving the app

## Best paired with

Snapshot works especially well together with:

- Hierarchy: to connect visual composition with the underlying view tree
- UI Measurement: to validate actual distances and dimensions after identifying the relevant region
- UI Debug: to move from selection to deeper visual inspection

## In DebugSP

In DebugSP, Snapshot belongs to the UI inspection workflow and is intended to complement Hierarchy rather than replace it.

A practical flow is:

1. Open DebugSP.
2. Start UI Debug.
3. Select or inspect the relevant screen area.
4. Use Snapshot to understand how the current UI is visually composed at runtime.
