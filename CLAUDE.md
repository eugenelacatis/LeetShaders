# LeetShaders, Project Context

This file is context for every Claude Code session on this repo. Read it before starting work.

This is Eugene's fork of the original team project, maintained solo as a portfolio piece. The team roles, Discord sign-off, and ownership notes below describe the original project. They don't block changes here: Eugene decides dependencies, contracts, and scope.

## What we are building

LeetShaders is a browser-native GLSL shader coding challenge platform. Users write fragment shaders in a Monaco editor, see their output rendered live, and submit against curated reference shaders. A hybrid judge (MAE pixel comparison plus an LLM vision model) decides whether the submission passes.

Think LeetCode for shader graphics. The hard problem is the judge.

## Tech stack

| Layer | Choice |
| --- | --- |
| Frontend framework | React 19, Vite |
| Code editor | @monaco-editor/react v4.7.0, GLSL registered manually |
| WebGL runtime | Raw WebGL2, no abstraction |
| UI | Material UI v7.3.9 (optional; can be replaced or removed) |
| State | Zustand 5.0.5 |
| Backend | Supabase, Auth plus Postgres |
| AI judge | Anthropic Claude Opus 5.5 vision; Claude Haiku 5.5 source-only cheat check on MAE passes |
| AI hints | Anthropic Claude Sonnet 5.5 |
| Deployment | Vercel for frontend, Supabase hosted for backend |
| Judge eval (dev only) | @playwright/test, headless Chromium with SwiftShader WebGL2 |

New libraries are fine when they earn their place. Say what you're adding and why in one line, then add it.

## Architecture overview

Three big pieces.

**The render pipeline** lives in a framework-free TypeScript module owned by the Judge & Rendering Lead. It exposes a shared WebGL2 context, compiles GLSL fragment shaders, renders them to offscreen framebuffers at 512x512, and returns RGBA `Uint8Array` buffers via `readPixels`. The live preview in the editor and the submission judge both consume this same module. There is exactly one WebGL pipeline in this codebase.

**The hybrid judge** runs in two stages. Stage one renders both shaders at four uniform samples (defaults plus three seeded random `u_time` / `u_mouse` values) and keeps the worst MAE score, with an optional Gaussian blur pre-pass. Stage two depends on that score (bands in `src/ai/bandLogic.ts`): below the lower band the submission fails with no LLM call; in the borderline band an Opus vision call scores visual similarity and inspects the source; at or above the upper band it passes after a cheap source-only cheat check by Haiku. Either model flagging cheating fails the submission.

**The challenge bank** is a folder of `.glsl` reference shaders plus `.json` metadata, seeded into Supabase. Each challenge has its own tolerance, calibrated against the eval fixtures in `src/ai/eval/` (`npx tsx src/ai/eval/run.ts --mae-only --set=tuning` prints the derivation; method in `src/ai/eval/CALIBRATION.md`). Reseed Supabase after changing one.

## Shared interfaces

These are the contracts everyone codes against. The Judge & Rendering Lead owns the file that exports them and locks them by end of week one.

```ts
interface Challenge {
  id: string;
  slug: string;
  title: string;
  description: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  referenceShaderSrc: string;
  tolerance: number;
  useBlur: boolean;
  hintText?: string;
}

interface JudgeResult {
  maeScore: number;
  llmScore: number | null;
  finalScore: number;
  passed: boolean;
  breakdown: {
    maeRaw: number;
    llmReasoning?: string;
    stageTwoInvoked: boolean;
    llmUnavailable?: boolean;
    cheatCheckInvoked?: boolean;
  };
  renderLatencyMs: number;
  judgeLatencyMs: number;
}
```

Changing these types is allowed. Update every consumer in the same change.

## Repo layout

```
src/
  judge/          # owned by Judge & Rendering Lead
    pipeline.ts   # WebGL2 context, compile, render, readPixels
    mae.ts        # stage one scoring
    llm.ts        # stage two LLM judge interface (impl by AI Systems)
    combiner.ts   # decides which stages run (impl by AI Systems)
    uniforms.ts   # seeded uniform samples for stage one
    types.ts      # Challenge, JudgeResult
    test/         # standalone HTML + Vitest harness
  editor/         # owned by Editor & UI Lead
    Monaco.tsx
    glsl-language.ts  # Monarch tokenizer
    LivePreview.tsx
    ErrorConsole.tsx
  pages/          # owned by Editor & UI Lead
    ChallengeList.tsx
    ChallengePage.tsx
  ai/             # owned by AI Systems & Integration
    models.ts     # model strings, the only place they are defined
    judgeRequest.ts  # judge + cheat-check prompts, shared by production and eval
    judgePrompt.ts
    hintPrompt.ts
    bandLogic.ts  # bands, weights, pass threshold
    eval/         # judge eval harness, fixtures, CALIBRATION.md
  backend/        # owned by Content & Backend
    supabase.ts
    useAuth.ts
    seed.ts
  challenges/     # owned by Content & Backend
    [slug].glsl
    [slug].json
    [slug].md
api/
  anthropic.ts    # Vercel proxy; holds ANTHROPIC_API_KEY, the browser never does
```

## Working with Claude Code, conventions for everyone

- **Read your own role-specific .md** second. Your tasks live there.
- **One pipeline rule.** The live preview and the judge consume the same compile path. If Claude Code starts writing a second WebGL context manager, stop it.
- **Lock the contract first.** The `Challenge` and `JudgeResult` types above are the integration seam. Do not let Claude Code drift them silently.
- **Prefer scaffolding standalone.** When a module has a clear contract (judge, prompts, challenge files), build it in isolation with a test harness before integrating. This is faster than fighting React lifecycle while debugging WebGL or LLM calls.
- **Verify model strings.** The current Anthropic models are `claude-opus-5-5` (judge), `claude-sonnet-5-5` (hints), and `claude-haiku-5-5` (cheat check), defined once in `src/ai/models.ts`. Claude Code may suggest older model names from its training data. Override.
- **Material UI v7 has API differences from v5.** While MUI is still in use, check the v7 docs when scaffolding components.
- **Supabase RLS.** Do not skip row-level security. Even though scoring is client-side, solve records and user data need policies.

## Code style

- TypeScript strict mode, no `any` without comment justification.
- Functional React, hooks, no class components.
- Prettier defaults, no debate.
- Commits follow `type(scope): message`, e.g. `feat(judge): add gaussian blur prepass`.

## Branching

- `main` is protected. PRs required, one reviewer minimum.
- Feature branches: `feature/[scope]`, e.g. `feature/judge-mae`, `feature/editor-monaco`.
- Vercel preview deployments per PR. Use these for visual review, the screenshot or live link is part of the PR description.

## Communication

- Discord for sync, Notion for async progress.
- If you are blocked on someone else's interface, post in Discord and tag them. Do not silently work around it, that creates integration debt.

## Milestones

This project ships across midterm and final.

**Midterm (Dec 4):** Core features only. MAE judge working with calibrated tolerances on at least 6 challenges. Editor live preview functional. Auth and submit flow wired. LLM judge can be stubbed if needed but the seam must exist.

**Final:** LLM judge stage two live and calibrated. AI hint system. Diff overlay. Leaderboard. 8 challenges minimum.

Stretch goals from the original proposal (community submissions, animated challenges) are out of scope. If they come up, defer.

## Risks to keep in mind

- **GPU/driver variance.** Same shader renders slightly differently across machines. The LLM judge stage absorbs this; MAE alone does not. Do not over-tighten MAE tolerances.
- **LLM latency and cost.** Every borderline submission is an Opus call and every MAE pass is a Haiku call. Both are cached by `(challenge_id, shader_hash)`.
- **Adversarial shaders.** Users can bake the reference into a color table, match it only at default uniforms, or write comments addressed to the grader. The prompts treat shader source as untrusted input, and the eval fixtures in `src/ai/eval/fixtures/adversarial/` cover each attack.
- **Authoring time.** Writing a good challenge with a calibrated tolerance is harder than writing the shader. Budget accordingly.

## When in doubt

Ask Eugene before expanding scope. New ideas go in the "future work" file, not in this sprint.
