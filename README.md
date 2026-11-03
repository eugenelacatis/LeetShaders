# LeetShaders

A browser-native GLSL shader coding challenge platform with a hybrid AI-powered judging system.

## Overview

LeetShaders is a platform where users can practice and master shader graphics programming. Think of it as "LeetCode for Shaders." It provides a real-time GLSL editor, a live preview, and a sophisticated judging system that validates your visual output against reference solutions.

### The hybrid judge

Automated grading is the hard part of shader education: two correct shaders rarely match pixel for pixel, and a cheating shader can match exactly. The judge in `src/judge/combiner.ts` works in stages:

1. Render the submission and the reference at four uniform samples (the defaults plus three seeded random `u_time` / `u_mouse` values) and keep the worst mean absolute error. A shader that only matches at the default inputs fails here.
2. Route on that score. Clear failures stop with no LLM call. Borderline scores go to Claude Opus 5.5, which compares both renders and reads the source. Clear passes get a source-only cheat check from Claude Haiku 5.5, which catches renders that match by cheating, such as a baked color table.
3. Either model flagging the source as cheating fails the submission. Both prompts treat shader source as untrusted input, so a comment addressed to the grader counts as cheating.

LLM results are cached by challenge and shader hash, and the API key stays in a Vercel function (`api/anthropic.ts`).

### Judge eval

`src/ai/eval/` measures that exact pipeline in headless Chromium against 360 fixtures: correct, almost-correct, wrong, and adversarial shaders for each of the 9 challenges, split 270 tuning / 90 held out. Per-challenge tolerances and the routing bands are derived from the tuning set; the method and numbers are in [`src/ai/eval/CALIBRATION.md`](src/ai/eval/CALIBRATION.md).

## Tech Stack

- **Frontend:** React 19, Vite, Material UI v7
- **Graphics:** Raw WebGL2 (no abstractions)
- **Editor:** Monaco Editor (@monaco-editor/react)
- **Backend:** Supabase (Auth, Postgres, RLS)
- **AI:** Anthropic Claude API (Opus 5.5 visual judge, Haiku 5.5 cheat check, Sonnet 5.5 hints)
- **Eval:** Playwright with SwiftShader WebGL2, Vitest

## Project Structure

- `src/judge/`: WebGL2 rendering pipeline and scoring logic.
- `src/editor/`: Monaco editor integration and GLSL syntax highlighting.
- `src/ai/`: Prompt engineering and LLM evaluation harnesses.
- `src/backend/`: Supabase integration and data hooks.
- `src/challenges/`: Curated GLSL challenge bank.

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

## Deploying your own

1. Create a Supabase project and run `supabase/migrations/20240504_initial_schema.sql` in its SQL editor.
2. Put `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` in `.env.local`, then `npm run seed` to load the challenges.
3. Import the repo into Vercel and set `VITE_SUPABASE_URL`, `VITE_SUPABASE_ANON_KEY`, and `ANTHROPIC_API_KEY` as environment variables. Do not add the service-role key to Vercel.

## Team & Roles

This project is organized into four key leadership roles:
- **Judge & Rendering Lead:** WebGL pipeline and MAE scoring.
- **AI Systems & Integration:** LLM judge prompts and hint systems.
- **Editor & UI Lead:** Monaco integration and core user experience.
- **Content & Backend Lead:** Challenge authoring and Supabase infrastructure.

---

*This project is being developed as a CMPE Final Project.*
