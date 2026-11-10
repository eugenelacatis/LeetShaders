import { Alert, Box, CircularProgress, Snackbar, Typography } from '@mui/material';
import { keyframes } from '@mui/material/styles';
import { Link, useParams } from 'react-router-dom';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Monaco from '../editor/Monaco';
import RenderStage from '../editor/RenderStage';
import type { Lens } from '../editor/RenderStage';
import CapstoneCells from '../editor/CapstoneCells';
import ErrorConsole from '../editor/ErrorConsole';
import ResultPanel from '../editor/ResultPanel';
import type { Verdict } from '../editor/ResultPanel';
import { describeDifference } from '../editor/diffReason';
import { useChallenge, useChallenges, submitSolve } from '../backend/useChallenges';
import { nextOnPath } from '../challenges/path';
import { useReducedMotion } from '../hooks/useReducedMotion';
import { judge } from '../judge/combiner';
import { llmJudge, llmCheatCheck } from '../judge/llm';
import { computeMAEResult } from '../judge/mae';
import { compileAndRender, CANVAS_SIZE } from '../judge/pipeline';
import { sampleUniforms, freshSeed } from '../judge/uniforms';
import { DEFAULT_BANDS } from '../ai/bandLogic';
import type { Challenge, PipelineError } from '../judge/types';
import { tokens } from '../tokens';

const STARTER = `#version 300 es
precision highp float;

uniform float u_time;
uniform vec2 u_resolution;
uniform vec2 u_mouse;

out vec4 fragColor;

void main() {
  vec2 uv = gl_FragCoord.xy / u_resolution.xy;
  fragColor = vec4(uv, 0.0, 1.0);
}
`;

const DEBOUNCE_MS = 300;
const NAV_HEIGHT = 60;
// The backdrop is blurred heavily, so a tiny copy of the render is enough.
const BACKDROP_SIZE = 64;

const t = tokens.color;
const NARROW = '@media (max-width: 859.95px)';
const PRESS = `${tokens.motion.press} ${tokens.motion.pressEasing}`;
const SHEET_W = 'min(46%, 560px)';

// Derived shades. Each one mixes locked tokens, so no new raw colors enter the page.
const GLASS = `color-mix(in srgb, ${t.ground} 84%, transparent)`;
const GLASS_EDGE = `color-mix(in srgb, ${t.text} 16%, transparent)`;
const GLASS_RULE = `color-mix(in srgb, ${t.text} 10%, transparent)`;
const GHOST_EDGE = `color-mix(in srgb, ${t.text} 25%, transparent)`;
const FLOAT_SHADOW = `0 30px 60px color-mix(in srgb, ${t.edge} 70%, transparent)`;
const LENS_BEZEL = `color-mix(in srgb, ${t.edge} 70%, transparent)`;
const LENS_KEY = `color-mix(in srgb, ${t.surfaceRaised} 85%, transparent)`;

type Difficulty = Challenge['difficulty'];

const DIFFICULTY_LABEL: Record<Difficulty, string> = {
  beginner: 'Easy',
  intermediate: 'Medium',
  advanced: 'Hard',
  expert: 'Expert',
};

const DIFFICULTY_COLOR: Record<Difficulty, string> = {
  beginner: t.pass,
  intermediate: t.blueUi,
  advanced: `color-mix(in srgb, ${t.red} 60%, ${t.text})`,
  expert: t.gold,
};

const scan = keyframes`
  from { background-position: 0 120%; }
  to { background-position: 0 -100%; }
`;

// When this frame matches but the submission still failed: another input, or how it was drawn.
const SAME_FRAME_REASON =
  'This frame looks right, but your shader differs somewhere else the judge looked. Check anything that changes with time or the mouse.';

// Where your render differs from the reference at the default inputs, in words.
function differenceReason(src: string, referenceSrc: string): string | null {
  const yours = compileAndRender(src);
  const ref = compileAndRender(referenceSrc);
  if ('type' in yours || 'type' in ref) return null;
  return describeDifference(yours.pixels, ref.pixels, CANVAS_SIZE);
}

const LENSES: { key: Lens; label: string }[] = [
  { key: 'yours', label: 'Yours' },
  { key: 'reference', label: 'Reference' },
  { key: 'difference', label: 'Difference' },
];

interface SubmissionRecord {
  timestamp: number;
  score: number;
  passed: boolean;
}

function getSubmissionHistory(challengeId: string): SubmissionRecord[] {
  try {
    const raw = localStorage.getItem(`ls_history_${challengeId}`);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function saveSubmission(challengeId: string, record: SubmissionRecord) {
  const history = getSubmissionHistory(challengeId);
  history.unshift(record);
  localStorage.setItem(`ls_history_${challengeId}`, JSON.stringify(history.slice(0, 50)));
}

function isTyping(target: EventTarget | null): boolean {
  return (
    target instanceof Element &&
    target.closest('input, textarea, [contenteditable="true"], .monaco-editor') !== null
  );
}

const btnBase = {
  minHeight: tokens.minTapTarget,
  px: '18px',
  borderRadius: tokens.radius.md,
  border: `${tokens.border} solid transparent`,
  fontFamily: tokens.font.sans,
  fontWeight: 800,
  fontSize: tokens.type.label.size,
  color: t.text,
  cursor: 'pointer',
  whiteSpace: 'nowrap',
  transition: `transform ${PRESS}, box-shadow ${PRESS}`,
  '&:active:not(:disabled)': { transform: 'translate(2px, 2px)' },
  '&:disabled': { opacity: 0.45, cursor: 'not-allowed' },
  '&:focus-visible': { outline: `2px solid ${t.blueUi}`, outlineOffset: '2px' },
} as const;

const ghostBtn = { ...btnBase, backgroundColor: 'transparent', borderColor: GHOST_EDGE };
const goBtn = {
  ...btnBase,
  backgroundColor: t.redUi,
  boxShadow: `0 0 0 1px color-mix(in srgb, ${t.edge} 30%, transparent), 0 8px 24px color-mix(in srgb, ${t.red} 40%, transparent)`,
};

export default function ChallengePage() {
  const { slug = '' } = useParams();
  const { data: challenge, loading } = useChallenge(slug);
  const { data: allChallenges } = useChallenges();
  const reducedMotion = useReducedMotion();
  const [src, setSrc] = useState(STARTER);
  const [debouncedSrc, setDebouncedSrc] = useState(STARTER);
  const [errors, setErrors] = useState<PipelineError[]>([]);
  const [submitting, setSubmitting] = useState(false);
  const [submitStage, setSubmitStage] = useState('');
  const [verdict, setVerdict] = useState<Verdict | null>(null);
  const [runNote, setRunNote] = useState<string | null>(null);
  const [running, setRunning] = useState(false);
  const [solveSaveError, setSolveSaveError] = useState<string | null>(null);
  const [lens, setLens] = useState<Lens>('yours');
  const [holdingR, setHoldingR] = useState(false);
  const [hintOpen, setHintOpen] = useState(false);

  const jumpToLineRef = useRef<((line: number) => void) | null>(null);
  const timeRef = useRef(0);
  const backdropRef = useRef<HTMLCanvasElement | null>(null);

  const referenceSrc = useMemo(() => challenge?.referenceShaderSrc ?? '', [challenge]);
  const hasCompileError = errors.some((e) => e.kind === 'compile-error');
  const shownLens: Lens = holdingR ? 'reference' : lens;

  // Each challenge starts from its own starter, or the shared one.
  const starter = challenge ? (challenge.starterSrc ?? STARTER) : null;
  useEffect(() => {
    if (starter === null) return;
    setSrc(starter);
    setDebouncedSrc(starter);
    setVerdict(null);
    setRunNote(null);
  }, [starter]);

  useEffect(() => {
    const id = setTimeout(() => setDebouncedSrc(src), DEBOUNCE_MS);
    return () => clearTimeout(id);
  }, [src]);

  useEffect(() => {
    let raf = 0;
    const start = performance.now();
    function tick() {
      timeRef.current = (performance.now() - start) / 1000;
      raf = requestAnimationFrame(tick);
    }
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, []);

  // Hold R to flip to the reference, unless the key is going into the editor.
  useEffect(() => {
    const down = (e: KeyboardEvent): void => {
      if (e.key.toLowerCase() !== 'r' || e.repeat || e.metaKey || e.ctrlKey || e.altKey) return;
      if (isTyping(e.target)) return;
      setHoldingR(true);
    };
    const up = (e: KeyboardEvent): void => {
      if (e.key.toLowerCase() === 'r') setHoldingR(false);
    };
    const reset = (): void => setHoldingR(false);
    window.addEventListener('keydown', down);
    window.addEventListener('keyup', up);
    window.addEventListener('blur', reset);
    return () => {
      window.removeEventListener('keydown', down);
      window.removeEventListener('keyup', up);
      window.removeEventListener('blur', reset);
    };
  }, []);

  const handleUserErrors = useCallback((errs: PipelineError[]) => {
    setErrors(errs);
  }, []);

  // A verdict or quick check belongs to the code it judged; editing clears it.
  const handleEdit = useCallback((value: string) => {
    setSrc(value);
    setVerdict(null);
    setRunNote(null);
  }, []);

  const dismissVerdict = useCallback(() => setVerdict(null), []);
  const backToRender = useCallback(() => {
    setVerdict(null);
    setLens('yours');
  }, []);

  const handleRun = useCallback(() => {
    if (!challenge || hasCompileError) return;
    setRunning(true);
    setRunNote(null);
    setVerdict(null);

    setTimeout(() => {
      const userResult = compileAndRender(src);
      if ('type' in userResult) {
        setRunning(false);
        return;
      }
      const refResult = compileAndRender(challenge.referenceShaderSrc);
      if ('type' in refResult) {
        setRunning(false);
        return;
      }

      const mae = computeMAEResult(
        userResult.pixels,
        refResult.pixels,
        challenge.tolerance,
        challenge.useBlur,
      );
      if (mae.score >= DEFAULT_BANDS.upperBand) {
        setRunNote('Quick check: looks like a match. Submit for the full judge.');
      } else {
        const reason = describeDifference(userResult.pixels, refResult.pixels, CANVAS_SIZE);
        setRunNote(
          reason
            ? `Quick check: not yet. ${reason}`
            : 'Quick check: close, but not quite. Look closely at the edges and colors.',
        );
      }
      setDebouncedSrc(src);
      setRunning(false);
    }, 50);
  }, [challenge, src, hasCompileError]);

  const handleSubmit = useCallback(async () => {
    if (!challenge || submitting) return;
    setSubmitting(true);
    setVerdict(null);
    setRunNote(null);
    setLens('yours');
    setSubmitStage('Comparing pixels at several inputs.');

    try {
      const judgeResult = await judge(
        src,
        challenge,
        async (input) => {
          setSubmitStage('Still checking. This can take a few seconds.');
          return llmJudge(input);
        },
        DEFAULT_BANDS,
        sampleUniforms(freshSeed()),
        llmCheatCheck,
      );
      // A close call the vision model didn't answer isn't a fail: keep it out of history.
      const notJudged = !judgeResult.passed && judgeResult.breakdown.llmUnavailable === true;
      if (judgeResult.passed) {
        const next = allChallenges ? nextOnPath(allChallenges, challenge) : null;
        setVerdict({ kind: 'matched', next: next && { slug: next.slug, title: next.title } });
      } else if (notJudged) {
        setVerdict({ kind: 'not-judged' });
      } else {
        const reason = differenceReason(src, challenge.referenceShaderSrc) ?? SAME_FRAME_REASON;
        setVerdict({ kind: 'not-yet', reason });
        setLens('difference');
      }

      if (!notJudged) {
        saveSubmission(challenge.id, {
          timestamp: Date.now(),
          score: judgeResult.finalScore,
          passed: judgeResult.passed,
        });
      }

      if (judgeResult.passed) {
        try {
          await submitSolve(challenge.id, judgeResult, src);
        } catch (err) {
          // The pass already shows in the result panel; tell the user the
          // solve record (leaderboard / solved badge) didn't save.
          const message = err instanceof Error ? err.message : String(err);
          console.error('submitSolve failed:', err);
          setSolveSaveError(message);
        }
      }
    } catch (err) {
      setVerdict(null);
      setErrors([
        {
          kind: 'context-lost',
          message: err instanceof Error ? err.message : 'Submission failed',
        },
      ]);
    } finally {
      setSubmitting(false);
      setSubmitStage('');
    }
  }, [challenge, src, submitting, allChallenges]);

  if (loading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          height: `calc(100dvh - ${NAV_HEIGHT}px)`,
        }}
      >
        <CircularProgress size={20} sx={{ color: t.blueUi }} />
      </Box>
    );
  }

  if (!challenge) {
    return (
      <Box sx={{ px: 4, py: 6 }}>
        <Typography sx={{ color: t.textSoft, mb: 2 }}>Challenge not found.</Typography>
        <Box
          component={Link}
          to="/challenges"
          sx={{ ...ghostBtn, display: 'inline-flex', alignItems: 'center', textDecoration: 'none' }}
        >
          Back to challenges
        </Box>
      </Box>
    );
  }

  let status = 'Hold R to flip. Click a pixel to compare. Option-drag a number to scrub.';
  if (submitting) status = submitStage;
  else if (running) status = 'Running a quick check.';
  else if (hasCompileError) status = 'Paused on your last working render.';
  else if (runNote) status = runNote;
  else if (shownLens === 'difference') status = 'Difference view. Bright means different.';
  else if (shownLens === 'reference') status = 'Showing the reference.';

  const busy = running || submitting;
  // The phone hides the status line unless it carries news.
  const statusOnPhone = submitting || running || runNote !== null;

  return (
    <Box
      sx={{
        position: 'relative',
        height: `calc(100dvh - ${NAV_HEIGHT}px)`,
        overflow: 'hidden',
        backgroundColor: t.previewBg,
        fontFamily: tokens.font.sans,
        color: t.text,
      }}
    >
      {/* Blurred, dimmed copy of your render behind the glass */}
      <Box sx={{ position: 'absolute', inset: '-60px', pointerEvents: 'none' }} aria-hidden="true">
        <canvas
          ref={backdropRef}
          width={BACKDROP_SIZE}
          height={BACKDROP_SIZE}
          style={{
            display: 'block',
            width: '100%',
            height: '100%',
            filter: 'blur(48px) brightness(0.32) saturate(1.3)',
          }}
        />
      </Box>

      {/* Render, lens keys, status line */}
      <Box
        sx={{
          position: 'absolute',
          top: '20px',
          bottom: '20px',
          right: '20px',
          left: `calc(${SHEET_W} + 40px)`,
          display: 'grid',
          gridTemplateRows: 'minmax(0, 1fr) auto auto',
          justifyItems: 'center',
          gap: tokens.space[3],
          [NARROW]: {
            left: '12px',
            right: '12px',
            top: '12px',
            bottom: '54%',
            gap: tokens.space[2],
          },
        }}
      >
        <Box
          sx={{
            width: '100%',
            height: '100%',
            containerType: 'size',
            display: 'grid',
            placeItems: 'center',
          }}
        >
          <Box
            sx={{
              position: 'relative',
              width: 'min(100cqw, 100cqh)',
              height: 'min(100cqw, 100cqh)',
              borderRadius: '18px',
              overflow: 'clip',
              boxShadow: `0 0 0 1px ${GLASS_EDGE}, ${FLOAT_SHADOW}`,
            }}
          >
            <RenderStage
              userSrc={debouncedSrc}
              referenceSrc={referenceSrc}
              lens={shownLens}
              showThumb={shownLens === 'yours' && !submitting}
              timeRef={timeRef}
              onErrors={handleUserErrors}
              backdropRef={backdropRef}
            />
            {submitting && !reducedMotion && (
              <Box
                aria-hidden="true"
                sx={{
                  position: 'absolute',
                  inset: 0,
                  pointerEvents: 'none',
                  background: `linear-gradient(180deg, transparent 0, transparent 40%, color-mix(in srgb, ${t.blueUi} 35%, transparent) 50%, transparent 52%)`,
                  backgroundSize: '100% 220%',
                  mixBlendMode: 'screen',
                  animation: `${scan} 1.8s linear infinite`,
                }}
              />
            )}
            {verdict && !busy && (
              <ResultPanel
                verdict={verdict}
                reducedMotion={reducedMotion}
                onDismiss={dismissVerdict}
                onBackToRender={backToRender}
                onSubmitAgain={handleSubmit}
              />
            )}
          </Box>
        </Box>

        <Box
          role="group"
          aria-label="Lens"
          sx={{
            width: 'min(100%, 420px)',
            display: 'grid',
            gridTemplateColumns: 'repeat(3, 1fr)',
            gap: '6px',
            p: '6px',
            borderRadius: '12px',
            backgroundColor: LENS_BEZEL,
            backdropFilter: 'blur(10px)',
            WebkitBackdropFilter: 'blur(10px)',
          }}
        >
          {LENSES.map((l) => {
            const on = shownLens === l.key;
            return (
              <Box
                key={l.key}
                component="button"
                type="button"
                aria-pressed={on}
                onClick={() => setLens(l.key)}
                sx={{
                  minHeight: tokens.minTapTarget,
                  border: 0,
                  borderRadius: '8px',
                  backgroundColor: on ? t.text : LENS_KEY,
                  color: on ? t.ground : t.text,
                  fontFamily: tokens.font.sans,
                  fontWeight: 700,
                  fontSize: tokens.type.label.size,
                  cursor: 'pointer',
                  '&:focus-visible': { outline: `2px solid ${t.blueUi}`, outlineOffset: '2px' },
                  [NARROW]: { minHeight: '40px', fontSize: '14px' },
                }}
              >
                {l.label}
              </Box>
            );
          })}
        </Box>

        <Typography
          aria-live="polite"
          sx={{
            fontSize: tokens.type.label.size,
            fontWeight: 600,
            color: t.textSoft,
            textAlign: 'center',
            minHeight: '22px',
            maxWidth: '60ch',
            [NARROW]: statusOnPhone
              ? { fontSize: tokens.type.small.size, minHeight: 0 }
              : { display: 'none' },
          }}
        >
          {status}
        </Typography>
      </Box>

      {/* Glass code sheet */}
      <Box
        component="section"
        aria-label="Challenge and code"
        sx={{
          position: 'absolute',
          left: '20px',
          top: '20px',
          bottom: '20px',
          width: SHEET_W,
          display: 'flex',
          flexDirection: 'column',
          borderRadius: '18px',
          overflow: 'clip',
          backgroundColor: GLASS,
          backdropFilter: 'blur(18px) saturate(1.2)',
          WebkitBackdropFilter: 'blur(18px) saturate(1.2)',
          border: `1px solid ${GLASS_EDGE}`,
          boxShadow: FLOAT_SHADOW,
          [NARROW]: {
            left: 0,
            right: 0,
            top: 'auto',
            bottom: 0,
            width: 'auto',
            height: '52%',
            borderRadius: `${tokens.radius.xl} ${tokens.radius.xl} 0 0`,
            borderBottom: 0,
            '&::before': {
              content: '""',
              position: 'absolute',
              top: '6px',
              left: '50%',
              width: '44px',
              height: '5px',
              ml: '-22px',
              borderRadius: '3px',
              backgroundColor: `color-mix(in srgb, ${t.text} 35%, transparent)`,
            },
          },
        }}
      >
        <Box
          sx={{
            display: 'grid',
            gap: '6px',
            p: '16px 18px 12px',
            borderBottom: `1px solid ${GLASS_RULE}`,
            maxHeight: '35%',
            overflow: 'auto',
            flexShrink: 0,
            [NARROW]: { pt: '18px', maxHeight: '30%' },
          }}
        >
          <Box sx={{ display: 'flex', alignItems: 'center', gap: '10px', flexWrap: 'wrap' }}>
            <Typography
              component="h1"
              sx={{
                m: 0,
                fontSize: tokens.type.h3.size,
                fontWeight: tokens.type.h3.weight,
                letterSpacing: tokens.type.h3.tracking,
                lineHeight: tokens.type.h3.leading,
              }}
            >
              {challenge.title}
            </Typography>
            <Box
              component="span"
              sx={{
                display: 'inline-flex',
                alignItems: 'center',
                gap: '6px',
                fontSize: tokens.type.small.size,
                fontWeight: 700,
                px: '10px',
                py: '3px',
                borderRadius: tokens.radius.sm,
                color: DIFFICULTY_COLOR[challenge.difficulty],
                backgroundColor: `color-mix(in srgb, ${DIFFICULTY_COLOR[challenge.difficulty]} 16%, transparent)`,
                '&::before': {
                  content: '""',
                  width: '8px',
                  height: '8px',
                  borderRadius: '50%',
                  backgroundColor: 'currentColor',
                },
              }}
            >
              {DIFFICULTY_LABEL[challenge.difficulty]}
            </Box>
          </Box>
          <Typography
            sx={{
              m: 0,
              fontSize: tokens.type.label.size,
              fontWeight: 400,
              lineHeight: 1.5,
              color: t.textSoft,
            }}
          >
            {challenge.description}
          </Typography>
          {challenge.source && challenge.source.length > 0 && (
            <Typography sx={{ m: 0, fontSize: tokens.type.small.size, color: t.textSoft }}>
              Adapted from{' '}
              {challenge.source.map((c, i) => (
                <span key={c.url}>
                  {i > 0 && ', '}
                  <Box component="a" href={c.url} target="_blank" rel="noreferrer" sx={{ color: 'inherit' }}>
                    {c.title}
                  </Box>{' '}
                  by {c.author} ({c.license})
                </span>
              ))}
            </Typography>
          )}
          {hintOpen && challenge.hintText && (
            <Typography
              id="challenge-hint"
              sx={{
                m: 0,
                mt: '4px',
                p: '10px 12px',
                borderRadius: tokens.radius.md,
                fontSize: tokens.type.label.size,
                fontWeight: 400,
                lineHeight: 1.5,
                color: t.text,
                backgroundColor: `color-mix(in srgb, ${t.blueUi} 12%, transparent)`,
              }}
            >
              {challenge.hintText}
            </Typography>
          )}
        </Box>

        {challenge.starterSrc ? (
          <CapstoneCells src={src} onChange={handleEdit} errors={errors} onJumpToLine={jumpToLineRef} />
        ) : (
          <Box sx={{ flex: 1, minHeight: 0 }}>
            <Monaco value={src} onChange={handleEdit} errors={errors} onJumpToLine={jumpToLineRef} />
          </Box>
        )}

        <ErrorConsole errors={errors} onJumpToLine={(line) => jumpToLineRef.current?.(line)} />

        <Box
          sx={{
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            p: '12px 16px',
            borderTop: `1px solid ${GLASS_RULE}`,
            flexShrink: 0,
          }}
        >
          <Box
            component="button"
            type="button"
            onClick={handleRun}
            disabled={hasCompileError || busy}
            sx={ghostBtn}
          >
            Run
          </Box>
          <Box
            component="button"
            type="button"
            onClick={handleSubmit}
            disabled={hasCompileError || busy}
            sx={goBtn}
          >
            {submitting ? 'Judging' : 'Submit'}
          </Box>
          {challenge.hintText && (
            <Box
              component="button"
              type="button"
              aria-expanded={hintOpen}
              aria-controls="challenge-hint"
              onClick={() => setHintOpen((v) => !v)}
              sx={{ ...ghostBtn, ml: 'auto' }}
            >
              {hintOpen ? 'Hide hint' : 'Hint'}
            </Box>
          )}
        </Box>
      </Box>

      <Snackbar
        open={solveSaveError !== null}
        autoHideDuration={8000}
        onClose={() => setSolveSaveError(null)}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert severity="warning" onClose={() => setSolveSaveError(null)}>
          Passed, but your solve wasn't saved: {solveSaveError}
        </Alert>
      </Snackbar>
    </Box>
  );
}
