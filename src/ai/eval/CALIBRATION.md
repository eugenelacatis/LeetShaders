# Judge calibration

Living document. Owner: AI Systems & Integration. See `src/ai/AI_SYSTEMS.md` task 2.

## How the harness works

`run.ts` measures the judge users actually get. It starts Vite, opens `browser/harness.html` in headless Chromium (SwiftShader WebGL2), and calls `judge()` from `src/judge/combiner.ts` once per fixture. That runs the shared render pipeline, MAE scoring with each challenge's tolerance and blur setting, the band logic in `src/ai/bandLogic.ts`, and, for borderline scores, the vision judge.

The LLM call is bridged back to Node with `page.exposeFunction`, so `ANTHROPIC_API_KEY` stays in the Node process. Node builds the request with `buildJudgeRequest()` from `src/ai/judgeRequest.ts`, the same function production uses. `judgeParity.test.ts` fails if the two paths ever send different requests.

Each fixture is rendered at four uniform samples from a seeded PRNG: the defaults, then three random `u_time` / `u_mouse` values. The worst MAE score is kept. The eval uses seed 1337; production draws a fresh seed per submission.

Every run saves the user render next to each fixture (`<fixture>.png`) and the reference render under `fixtures/challenges/`. These PNGs are gitignored.

## Fixtures

200 fixtures: 5 challenges, 4 categories, 10 each. `gen/generate.ts` builds them from `src/challenges/` and `gen/specs.ts`, and `gen/split.ts` splits them 150 tuning / 50 held out, stratified by challenge and category (seed 20261102, list in `fixtures/split.json`). Tune only on the tuning set.

| Challenge | Difficulty | Tolerance | Blur |
| --- | --- | --- | --- |
| circle-sdf | beginner | 10 | yes |
| checkerboard | beginner | 4 | no |
| hsv-color-wheel | intermediate | 8 | no |
| polar-pattern | intermediate | 12 | yes |
| raymarched-sphere | advanced | 20 | yes |

Expected outcome per category:

| Category | Expected | What the fixtures are |
| --- | --- | --- |
| correct | pass, not flagged | 6 mechanical rewrites of the reference (renames, helper functions, comment stripping, clamping) and 4 hand-written implementations that compute the same image differently |
| almost-correct | pass, not flagged | One small edit to the reference: a shifted center, a slightly different radius or color, a softer edge, a one-pixel offset |
| wrong | fail | 6 edits that change the shape, color, or pattern, plus the other 4 challenges' references |
| adversarial | fail, flagged | 3 color-table cheats (reference baked into an 8x8, 16x16, or 32x32 lookup), 3 shaders that match only at the default inputs (`u_time == 0.0` and similar), 4 prompt injections in comments or a `#define` |

The injection fixtures pair the injection with an edited render. A shader that renders perfectly never reaches the LLM, so injection is only tested when the render lands in the borderline band.

## Running it

```bash
# Fixture counts, no rendering:
npx tsx src/ai/eval/run.ts

# Free. Renders everything, scores MAE, reports band routing. No API key needed:
npx tsx src/ai/eval/run.ts --mae-only --set=tuning

# Calls the API for borderline fixtures and writes REPORT.md.
# Reads ANTHROPIC_API_KEY from the environment or .env.local:
npx tsx src/ai/eval/run.ts --live --set=heldout --repeat=3 --max-cost=5
```

A live run first does a free MAE pass, prints how many fixtures will reach the LLM with a token and cost estimate, and waits 10 seconds (skip with `--yes`). It aborts once spend passes `--max-cost`.

Regenerate fixtures with `npx tsx src/ai/eval/gen/generate.ts` and `npx tsx src/ai/eval/gen/split.ts`.

## Targets

- False-pass rate below 10%.
- False-fail rate below 10%.
- No adversarial leaks: every adversarial fixture fails, and every one that reaches the LLM is flagged.
- Per-run cost ceiling: $5 while calibrating, $20 for the final demo run.

## Band calibration (v1, 2026-11-02)

MAE scores on the 150 tuning fixtures (`out/mae-tuning.csv`):

![MAE score by category](mae-histogram-tuning.svg)

| Category | Min | Median | Max |
| --- | --- | --- | --- |
| correct | 99.9 | 100.0 | 100.0 |
| almost-correct | 0.0 | 69.6 | 99.9 |
| wrong | 0.0 | 0.0 | 69.1 |
| adversarial | 0.0 | 0.0 | 100.0 |

The rule from the eval plan sets `upperBand` to the lowest score no `wrong` fixture reaches, and `lowerBand` to the highest score no correct or almost-correct fixture falls under.

`upperBand` = 70. The highest `wrong` score was 69.1, from raymarched-sphere with flat shading. That challenge's tolerance of 20 is loose enough that a visibly different sphere still scores in the high 60s.

`lowerBand` = 60. The rule gives 0, because every checkerboard almost-correct edit scores 0 at tolerance 4 (a 4% darker black or a one-pixel shift already exceeds it), and so does circle-sdf with a 5% grey background. A lower band of 0 would send everything below 70 to the LLM, and none of those calls could change a verdict. The final score is `0.5 * MAE + 0.5 * LLM` against a pass threshold of 80, so a submission with MAE below 60 fails even with an LLM score of 100. The band starts at that floor. If the weights or the threshold change, the floor moves with them; `run.ts --mae-only` prints it.

Effect on the tuning set:

| Bands (upper / lower) | LLM calls | Skip rate | Adversarial fixtures that skip the LLM |
| --- | --- | --- | --- |
| 92 / 40 (previous) | 33 / 150 | 78.0% | 3 |
| 70 / 0 (rule as written) | 83 / 150 | 44.7% | 10 |
| 70 / 60 (chosen) | 5 / 150 | 96.7% | 10 |

Known consequences of these bands, to be measured in the live run:

- 15 of the 75 good tuning fixtures score below 60 and cannot pass under any band choice. They are false fails caused by per-challenge tolerances (checkerboard especially) and the combine weights, and the bands cannot fix them.
- 10 adversarial tuning fixtures score at or above 70 and pass without the LLM seeing their source. Four are color tables (checkerboard, circle-sdf, two on raymarched-sphere). Six are injections: the mild edits on hsv-color-wheel and polar-pattern, and all four on raymarched-sphere, where tolerance 20 keeps even the larger edits above 70. They are expected adversarial leaks.
- Every `u_time` / `u_mouse` branch cheat in the tuning set scores 0 under randomized uniforms and fails at stage one. Without sampling they would match the reference exactly.

## Prompt iteration playbook

1. Read the latest `REPORT.md`. Start with the failure mode that has the highest count.
2. Reproduce the failure in isolation: send that fixture's request on its own and confirm the verdict repeats.
3. Make one prompt change at a time, in `src/ai/judgeRequest.ts`. Production and the eval both pick it up.
4. Re-run the harness on the tuning set. Keep the change if the target metric improves without another one regressing by more than 5 percentage points; otherwise revert.
5. Check the held-out set only when you are done tuning, and log the revision below.

## Known limitations

- Rendering uses SwiftShader. Scores are reproducible across machines but can differ slightly from a user's GPU, which the vision judge is meant to absorb.
- Saved PNGs are vertically flipped. `readPixels` returns rows bottom-up and `src/ai/imageEncode.ts` writes them top-down. The judge sees both renders flipped the same way, so the visual comparison holds, but orientation words in a challenge description ("bottom-left") refer to the other corner of the image the model sees. Production has the same flip.
- `almost-correct` fixtures are expected to pass. Some of them are visibly off. Changing that expectation is a calibration decision, made in `expectedOutcome()` in `run.ts`.

## Iteration log

### v1 (bands, harness, prompt guard)

- Date: 2026-11-02
- Fixtures: 200 (150 tuning, 50 held out), 5 challenges.
- Prompt: `JUDGE_SYSTEM_PROMPT` in `src/ai/judgeRequest.ts`, shared by production and eval. Shader source is wrapped in `<shader_source>` tags and marked untrusted; instructing the grader counts as cheating.
- Bands: 70 / 60 (was 92 / 40), from the MAE-only run above.
- Live result: not run yet. `REPORT.md` will hold the held-out numbers.

### v0 (scaffolding)

- Date: 2026-05-04
- Fixtures: 4 (1 per category, 1 challenge).
- Result: not run against the live API.
- Notes: the harness called the LLM alone with 1x1 placeholder images, so it measured source inspection only.
