import { Box, Typography } from '@mui/material';
import { Link } from 'react-router-dom';
import { useEffect, useMemo, useRef, useState } from 'react';
import { DiffCanvas, ShaderCanvas } from './ShaderCanvas';
import { DEMO_INPUTS, mouseLit } from './demoShaders';
import { useReducedMotion } from '../hooks/useReducedMotion';
import { tokens } from '../tokens';

const t = tokens.color;
const NARROW = '@media (max-width: 859.95px)';
const FADE = '300ms ease-out';

type Mode = 'split' | 'inputs' | 'diff' | 'read' | 'verdict';

interface Step {
  title: string;
  copy: string;
  mode: Mode;
  word: string;
  why: string;
}

const STEPS: Step[] = [
  {
    title: 'You submit',
    copy: 'Your shader goes through the same WebGL code as your live preview. One pipeline, so what you saw is what gets judged.',
    mode: 'split',
    word: 'Submitted',
    why: 'Same code as your preview',
  },
  {
    title: 'It renders at several inputs',
    copy: "Time and mouse position change between renders. A shader that only matches at the starting values won't pass.",
    mode: 'inputs',
    word: 'Rendering',
    why: 'Inputs keep changing',
  },
  {
    title: 'Pixels get compared',
    copy: 'Each render is compared with the reference. The limit is set per challenge and calibrated against 360 labeled shaders.',
    mode: 'diff',
    word: 'Comparing',
    why: 'Bright means different',
  },
  {
    title: 'Close calls get a second look',
    copy: "When the pixels can't decide, a vision model compares the images and reads your source as untrusted input.",
    mode: 'read',
    word: 'Close call',
    why: 'Asking the vision model',
  },
  {
    title: 'You get a verdict',
    copy: 'Results are cached per challenge and shader, so resubmitting the same code answers instantly.',
    mode: 'verdict',
    word: 'Passed',
    why: 'The vision model agreed',
  },
];

const SOURCE_LINES = [
  'float sphereSDF(vec3 p, float r) {',
  '  return length(p) - r;',
  '}',
  'float diff = max(dot(n, l), 0.0);',
  'fragColor = vec4(color, 1.0);',
];

// Deck slots: front card first. Always three, fanned, so it reads as "several".
const DECK_SLOTS = [
  { transform: 'translate(0, 0) rotate(0deg)', zIndex: 3, opacity: 1 },
  { transform: 'translate(58%, -8%) rotate(5deg)', zIndex: 2, opacity: 0.85 },
  { transform: 'translate(116%, -16%) rotate(10deg)', zIndex: 1, opacity: 0.65 },
];

function wordColor(mode: Mode): string {
  if (mode === 'verdict') return t.pass;
  if (mode === 'read') return t.blueUi;
  return t.text;
}

interface HowItWorksProps {
  refSrc: string;
  yoursSrc: string;
}

export default function HowItWorks({ refSrc, yoursSrc }: HowItWorksProps): React.JSX.Element {
  const reduce = useReducedMotion();
  const [active, setActive] = useState(0);
  const [deckTurn, setDeckTurn] = useState(0);
  const [line, setLine] = useState(1);
  const stepRefs = useRef<(HTMLDivElement | null)[]>([]);
  const deckSrc = useMemo(() => mouseLit(yoursSrc), [yoursSrc]);
  const mode = STEPS[active].mode;

  // A step activates when it crosses a band in the viewport. On narrow screens the
  // pinned frame covers the middle, so the band sits lower.
  useEffect(() => {
    const narrow = window.matchMedia('(max-width: 859.95px)').matches;
    const io = new IntersectionObserver(
      (entries) =>
        entries.forEach((e) => {
          if (e.isIntersecting) setActive(Number((e.target as HTMLElement).dataset.index));
        }),
      { rootMargin: narrow ? '-62% 0px -30% 0px' : '-45% 0px -45% 0px' },
    );
    stepRefs.current.forEach((el) => el && io.observe(el));
    return () => io.disconnect();
  }, []);

  useEffect(() => {
    if (reduce || mode !== 'inputs') return;
    const id = window.setInterval(() => setDeckTurn((n) => n + 1), 2400);
    return () => window.clearInterval(id);
  }, [reduce, mode]);

  useEffect(() => {
    if (reduce) {
      setLine(1);
      return;
    }
    if (mode !== 'read') return;
    const id = window.setInterval(() => setLine((n) => (n + 1) % SOURCE_LINES.length), 650);
    return () => window.clearInterval(id);
  }, [reduce, mode]);

  const fade = reduce ? 'none' : `opacity ${FADE}`;
  const layer = (show: boolean): object => ({
    position: 'absolute',
    inset: 0,
    opacity: show ? 1 : 0,
    transition: fade,
  });

  return (
    <Box component="section" aria-labelledby="how-title" sx={{ pt: { xs: 7, md: 11 } }}>
      <Box sx={{ mb: { xs: 3, md: 5 }, maxWidth: 640 }}>
        <Typography
          id="how-title"
          component="h2"
          sx={{
            fontSize: 'clamp(30px, 4vw, 44px)',
            fontWeight: 800,
            letterSpacing: '-0.04em',
            lineHeight: 1,
            color: t.text,
            m: 0,
            mb: 1.25,
          }}
        >
          What happens when you submit
        </Typography>
        <Typography sx={{ fontSize: tokens.type.lede.size, color: t.textSoft }}>
          Scroll the steps, or tap one.
        </Typography>
      </Box>

      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: 'minmax(0, 1fr) minmax(0, 1fr)',
          gap: 'clamp(24px, 5vw, 64px)',
          [NARROW]: { gridTemplateColumns: 'minmax(0, 1fr)', gap: 0 },
        }}
      >
        <Box sx={{ pb: '20vh', [NARROW]: { pb: '30vh' } }}>
          {STEPS.map((s, i) => {
            const on = i === active;
            return (
              <Box
                key={s.title}
                ref={(el: HTMLDivElement | null) => {
                  stepRefs.current[i] = el;
                }}
                data-index={i}
                tabIndex={0}
                aria-current={on ? 'step' : undefined}
                onClick={() => setActive(i)}
                onKeyDown={(e: React.KeyboardEvent) => {
                  if (e.key === 'Enter' || e.key === ' ') {
                    e.preventDefault();
                    setActive(i);
                  }
                }}
                sx={{
                  minHeight: 300,
                  display: 'grid',
                  alignContent: 'center',
                  gap: 1.25,
                  pl: 2.75,
                  borderLeft: `3px solid ${on ? t.red : 'rgba(244, 241, 236, 0.12)'}`,
                  transition: reduce ? 'none' : `border-color ${FADE}`,
                  cursor: 'pointer',
                  '&:focus-visible': { outline: `3px solid ${t.blueUi}`, outlineOffset: '4px' },
                  [NARROW]: { minHeight: 220 },
                }}
              >
                <Box
                  aria-hidden="true"
                  sx={{
                    width: 36,
                    height: 36,
                    borderRadius: '8px',
                    display: 'grid',
                    placeItems: 'center',
                    fontWeight: 800,
                    border: `${tokens.border} solid ${t.edge}`,
                    backgroundColor: on ? t.redUi : t.surface,
                    color: on ? t.text : t.textSoft,
                    transition: reduce ? 'none' : `background-color ${FADE}, color ${FADE}`,
                  }}
                >
                  {i + 1}
                </Box>
                <Typography
                  component="h3"
                  sx={{
                    fontSize: 26,
                    fontWeight: 800,
                    letterSpacing: '-0.03em',
                    lineHeight: 1.1,
                    color: on ? t.text : t.textSoft,
                    m: 0,
                  }}
                >
                  {s.title}
                </Typography>
                <Typography sx={{ color: t.textSoft, maxWidth: '42ch', opacity: on ? 1 : 0.6 }}>
                  {s.copy}
                </Typography>
                {i === STEPS.length - 1 && (
                  <Box
                    component={Link}
                    to="/how-it-works"
                    onClick={(e: React.MouseEvent) => e.stopPropagation()}
                    sx={{
                      justifySelf: 'start',
                      display: 'inline-flex',
                      alignItems: 'center',
                      minHeight: tokens.minTapTarget,
                      fontWeight: 800,
                      fontSize: tokens.type.label.size,
                      color: t.text,
                      textDecoration: 'none',
                      borderBottom: `${tokens.border} solid ${t.red}`,
                      '&:hover': { color: t.blueUi },
                      '&:focus-visible': { outline: `3px solid ${t.text}`, outlineOffset: '4px' },
                    }}
                  >
                    See how the judge is built
                  </Box>
                )}
              </Box>
            );
          })}
        </Box>

        <Box
          sx={{
            position: 'sticky',
            top: 84,
            alignSelf: 'start',
            display: 'grid',
            gap: 2,
            [NARROW]: {
              order: -1,
              top: 60,
              zIndex: 3,
              backgroundColor: t.ground,
              py: 1.5,
              justifyItems: 'center',
            },
          }}
        >
          <Box
            sx={{
              position: 'relative',
              // Frame plus status line must fit under the nav while pinned.
              width: 'min(100%, calc(100vh - 180px))',
              justifySelf: 'end',
              aspectRatio: '1',
              border: `${tokens.border} solid ${t.edge}`,
              borderRadius: tokens.radius.lg,
              boxShadow: tokens.shadow.xl,
              backgroundColor: t.previewBg,
              overflow: 'clip',
              [NARROW]: { width: 'min(100%, 280px)', justifySelf: 'center' },
            }}
          >
            <Box sx={layer(mode === 'split')} role="img" aria-label="Reference render">
              <ShaderCanvas src={refSrc} />
            </Box>
            <Box
              sx={{
                ...layer(mode === 'split' || mode === 'read' || mode === 'verdict'),
                clipPath: mode === 'split' ? 'inset(0 0 0 50%)' : 'none',
              }}
              role="img"
              aria-label="Your render"
            >
              <ShaderCanvas src={yoursSrc} />
            </Box>
            <Box sx={layer(mode === 'diff')} role="img" aria-label="Difference image">
              <DiffCanvas refSrc={refSrc} yoursSrc={yoursSrc} />
            </Box>

            <Box
              sx={{ ...layer(mode === 'inputs'), backgroundColor: t.surface }}
              role="img"
              aria-label="Your shader rendered at three different inputs"
            >
              {DEMO_INPUTS.slice(0, 3).map((m, i) => {
                const slot = DECK_SLOTS[(i + deckTurn) % 3];
                return (
                  <Box
                    key={i}
                    sx={{
                      position: 'absolute',
                      left: '5%',
                      top: '32%',
                      width: '40%',
                      aspectRatio: '1',
                      border: `${tokens.border} solid ${t.edge}`,
                      borderRadius: tokens.radius.lg,
                      overflow: 'clip',
                      boxShadow: tokens.shadow.md,
                      ...slot,
                      transition: reduce
                        ? 'none'
                        : 'transform 700ms cubic-bezier(.2,.8,.2,1), opacity 700ms',
                    }}
                  >
                    <ShaderCanvas src={deckSrc} mouse={m} />
                  </Box>
                );
              })}
            </Box>

            {(['left', 'right'] as const).map((side) => (
              <Box
                key={side}
                component="span"
                aria-hidden="true"
                sx={{
                  position: 'absolute',
                  top: 10,
                  [side]: 10,
                  zIndex: 2,
                  font: `600 13px/1 ${tokens.font.sans}`,
                  px: 1,
                  py: 0.75,
                  borderRadius: tokens.radius.sm,
                  backgroundColor: 'rgba(5, 11, 12, 0.8)',
                  color: t.text,
                  opacity: mode === 'split' ? 1 : 0,
                  transition: fade,
                }}
              >
                {side === 'left' ? 'Reference' : 'Yours'}
              </Box>
            ))}
            <Box
              aria-hidden="true"
              sx={{
                position: 'absolute',
                top: 0,
                bottom: 0,
                left: '50%',
                width: 3,
                ml: '-1.5px',
                backgroundColor: t.red,
                zIndex: 2,
                opacity: mode === 'split' ? 1 : 0,
                transition: fade,
              }}
            />

            <Box
              component="pre"
              aria-label="Your source, read by the vision model"
              sx={{
                position: 'absolute',
                left: 10,
                right: 10,
                bottom: 10,
                zIndex: 2,
                m: 0,
                p: '10px 12px',
                backgroundColor: 'rgba(5, 6, 12, 0.92)',
                border: `${tokens.border} solid ${t.edge}`,
                borderRadius: tokens.radius.md,
                font: `400 12.5px/1.7 ${tokens.font.mono}`,
                color: t.textSoft,
                overflow: 'hidden',
                opacity: mode === 'read' ? 1 : 0,
                transform: mode === 'read' || reduce ? 'none' : 'translateY(12px)',
                transition: reduce ? 'none' : `opacity ${FADE}, transform ${FADE}`,
                [NARROW]: { fontSize: 10.5, p: '6px 8px' },
              }}
            >
              {SOURCE_LINES.map((l, i) => (
                <Box
                  key={l}
                  component="span"
                  sx={{
                    display: 'block',
                    px: 0.75,
                    borderRadius: '4px',
                    whiteSpace: 'pre',
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    backgroundColor: i === line ? 'rgba(90, 174, 234, 0.22)' : 'transparent',
                    color: i === line ? t.text : undefined,
                    transition: reduce ? 'none' : 'background-color 200ms, color 200ms',
                  }}
                >
                  {l}
                </Box>
              ))}
            </Box>
          </Box>

          <Box
            aria-live="polite"
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.75,
              minHeight: 44,
              flexWrap: 'wrap',
              width: 'min(100%, calc(100vh - 180px))',
              justifySelf: 'end',
              [NARROW]: { width: 'min(100%, 280px)', justifySelf: 'center', gap: 1, minHeight: 0 },
            }}
          >
            <Typography
              sx={{
                fontSize: tokens.type.h2.size,
                fontWeight: 800,
                letterSpacing: tokens.type.h2.tracking,
                lineHeight: 1,
                color: wordColor(mode),
                [NARROW]: { fontSize: tokens.type.h3.size },
              }}
            >
              {STEPS[active].word}
            </Typography>
            <Typography sx={{ color: t.textSoft, fontSize: 15 }}>{STEPS[active].why}</Typography>
          </Box>
        </Box>
      </Box>
    </Box>
  );
}
