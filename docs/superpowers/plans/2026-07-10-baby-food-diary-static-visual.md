# Baby Food Diary Static Visual Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate one polished, warm, mobile-first visual board containing five Baby Food Diary app screens.

**Architecture:** A single raster visual board uses five consistent 390 × 844 mobile frames. The reference prototypes set the information architecture; the approved spec supplies color, typography, content, and safety-recommendation emphasis.

**Tech Stack:** Built-in Image Generation, provided prototype screenshots, manual visual inspection.

## Global Constraints

- Use a cream `#FFF9F5` background, apricot `#FF9B7B` primary actions, and sage `#7EC8A3` positive/safe states.
- Use Quicksand-like rounded display lettering and DM Sans-like body lettering.
- Include five Chinese-language mobile screens: home, recipes, analysis, history, and add meal.
- Preserve four-item bottom navigation and central apricot add button.
- Include a visible “14 天未食用” safe reintroduction recommendation on the home screen.
- Deliver a static raster visual only; no functional prototype, persistence, or backend.

---

### Task 1: Generate the high-fidelity visual board

**Files:**
- Create: `assets/baby-food-diary-mobile-visual-board.png`

**Interfaces:**
- Consumes: `docs/superpowers/specs/2026-07-10-baby-food-diary-static-visual-design.md` and the five supplied prototype references.
- Produces: One 5-screen vertical mobile visual board suitable for design review.

- [x] **Step 1: Generate the visual**

Use the built-in image generator with the approved layout, exact Chinese screen labels, warm palette, rounded cards, food illustrations, and no watermarks or placeholder copy.

- [x] **Step 2: Inspect the visual**

Check that all five screens are readable, their bottom navigation is visible, the home screen contains the 14-day recommendation, and no screen is cropped.

- [x] **Step 3: Iterate once if key typography, content, or composition is inaccurate**

Regenerate with only the observed correction and preserve the approved colors, frame count, and navigation structure.

### Task 2: Record delivery QA

**Files:**
- Create: `design-qa.md`

**Interfaces:**
- Consumes: `assets/baby-food-diary-mobile-visual-board.png`.
- Produces: A short evidence-based record of visual checks and final delivery state.

- [x] **Step 1: Verify the five required fidelity surfaces**

Verify typography, layout rhythm, warm tokens, food illustration quality, and Chinese app copy against the approved spec.

- [x] **Step 2: Save the QA result**

Write the visual file path, inspected state, findings, any correction made, and `final result: passed` when no actionable issue remains.
