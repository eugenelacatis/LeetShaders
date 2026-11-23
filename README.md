# LeetShaders

A browser-native GLSL shader coding challenge platform with a hybrid AI-powered judging system.

Live at [leetshaders.vercel.app](https://leetshaders.vercel.app/).

## Overview

LeetShaders is "LeetCode for shaders". You write a GLSL fragment shader in a Monaco editor, watch it render live next to the reference, and submit it to a judge that compares the two images.

This is a fork of an old class project. I wanted to expand upon it to fill the gap in graphics programming assessment.

### Challenges

The bank has 50 challenges (16 beginner, 21 intermediate, 13 advanced), each tagged with a track: color, shapes, combining, patterns, noise, raymarching, or capstone. The list page lays them out as a circuit board in path order, with a live thumbnail rendered through the shared pipeline for every key. The challenge page shows your render, the reference, and their difference, and a verdict sticker reports Matched, Not yet, or Not judged. Capstone challenges give a starter scene and ask you to fill in code cells. The landing page has a "how it works" section that explains the judge.

Each challenge is a `.glsl` reference, a `.json` file with metadata and a calibrated tolerance, and a `.md` file with the intended solution. Reference shaders and the live preview run through one WebGL2 pipeline, so what you see is what the judge scores.

### The hybrid judge

Automated grading is the hard part of shader education: two correct shaders rarely match pixel for pixel, and a cheating shader can match exactly. The judge in `src/judge/combiner.ts` works in stages:

1. Render the submission and the reference at four uniform samples (the defaults plus three seeded random `u_time` / `u_mouse` values) and keep the worst mean absolute error. A shader that only matches at the default inputs fails here.
2. Route on that score. Clear failures stop with no LLM call. Borderline scores go to Claude Opus 5.5, which compares both renders and reads the source. Clear passes get a source-only cheat check from Claude Haiku 5.5, which catches renders that match by cheating, such as a baked color table.
3. Either model flagging the source as cheating fails the submission. Both prompts treat shader source as untrusted input, so a comment addressed to the grader counts as cheating.

LLM results are cached by challenge and shader hash, and the API key stays in a Vercel function (`api/anthropic.ts`).

### Judge eval

`src/ai/eval/` measures that exact pipeline in headless Chromium against 2,000 fixtures: correct, almost-correct, wrong, and adversarial shaders, 10 per category for each of the 50 challenges, split 1,500 tuning / 500 held out. Per-challenge tolerances and the routing bands are derived from the tuning set; the method and numbers are in [`src/ai/eval/CALIBRATION.md`](src/ai/eval/CALIBRATION.md).

## Tech Stack

- **Frontend:** React 19, Vite, Material UI v7
- **Graphics:** Raw WebGL2 (no abstractions)
- **Editor:** Monaco Editor (@monaco-editor/react)
- **Backend:** Supabase (Auth, Postgres, RLS)
- **AI:** Anthropic Claude API (Opus 5.5 visual judge, Haiku 5.5 cheat check, Sonnet 5.5 hints)
- **Eval:** Playwright with SwiftShader WebGL2, Vitest

## Project Structure

- `src/judge/`: WebGL2 rendering pipeline and scoring logic.
- `src/editor/`: Monaco integration, GLSL highlighting, the render stage, and capstone cells.
- `src/pages/`: landing, how-it-works, challenge list, and challenge pages.
- `src/ai/`: prompts, band logic, and the judge eval harness.
- `src/backend/`: Supabase integration, seeding, and the local challenge loader.
- `src/challenges/`: the GLSL challenge bank.
- `api/`: the Vercel function that proxies Anthropic calls.
- `supabase/migrations/`: database schema and changes.

## Running it

```bash
npm install
npm run dev        # http://localhost:5173
npm test           # unit tests
npm run lint
```

Without Supabase settings the app loads challenges from `src/challenges/`. LLM judging needs the API route, so run it with `vercel dev` and an `ANTHROPIC_API_KEY` in `.env.local` (see `.env.example`).

The eval's MAE pass is free and needs no key:

```bash
npx playwright install chromium
npx tsx src/ai/eval/run.ts --mae-only --set=tuning
```

`--live` adds the LLM calls; it prints a cost estimate first and stops at `--max-cost` (default $5).

## Forking

To run your own copy, create a Supabase project, apply `supabase/migrations/` in order, and put `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` in `.env.local`. Then run `npm run seed`. On Vercel, set `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, and `ANTHROPIC_API_KEY`, and leave the service-role key out.
