# Hierarchy

## Overview

Hierarchy is the structural inspection tool in DebugSP.

It lets you inspect the live `UIView` tree of the current screen and understand how views are nested, grouped, and owned at runtime. This is useful when the rendered UI looks wrong but the problem is actually caused by container structure, missing parent constraints, clipping, or unexpected wrapper views.

## Why it matters

When debugging UI problems, screenshots alone are often not enough. Two screens can look visually similar while having very different internal hierarchies.

Hierarchy helps answer questions such as:

- Which view is actually being rendered here?
- Which parent view owns this element?
- Is the element inside an unexpected container?
- Why is a view clipped, offset, hidden, or covered?
- Which class in the tree is responsible for the current layout?

## Technology

The hierarchy feature is backed by DebugSP's Objective-C runtime inspection layer and UIKit view traversal utilities.

At runtime, DebugSP walks the active view tree, collects class and structural metadata, and presents it in a form that is easier to inspect than raw LLDB output or ad-hoc logging.

This allows you to:

- inspect the selected view in context
- move through parent-child relationships
- understand nesting depth
- connect what you see on screen with real runtime objects

## Typical use cases

### Layout debugging

Use Hierarchy when Auto Layout results look incorrect but constraints alone do not explain the issue.

### Container debugging

Use it to inspect deeply nested stack views, collection/table wrappers, hosting containers, and custom view hierarchies.

### Ownership tracing

Use it to identify which controller or composite view is actually responsible for a problematic element.

### Visual mismatch investigation

Use it when spacing, clipping, or hit areas look wrong and you need to inspect the live tree rather than the static source code.

## What it is good at

- showing parent-child relationships clearly
- understanding nesting and composition
- debugging wrapper/container views
- investigating hidden or clipped elements
- exploring live UI state without leaving the app

## Best paired with

Hierarchy works especially well together with:

- UI Debug: to select a live view first
- Snapshot: to inspect the same screen from a more visual rendering perspective
- Object Explorer: to inspect the selected runtime object in more detail

## In DebugSP

In DebugSP, Hierarchy is exposed as part of the in-app UI debugging workflow.

A common flow is:

1. Open DebugSP.
2. Start UI Debug.
3. Select a view on screen.
4. Open Hierarchy to inspect where that view lives inside the live tree.
