import { Box, Typography } from '@mui/material';
import { Link } from 'react-router-dom';
import { useEffect, useMemo, useRef, useState } from 'react';
import { LOCAL_CHALLENGES } from '../backend/localChallenges';
import { DiffCanvas, ShaderCanvas } from '../components/ShaderCanvas';
import { DEMO_INPUTS, mouseLit, nearMiss } from '../components/demoShaders';
import { useReducedMotion } from '../hooks/useReducedMotion';
import { tokens } from '../tokens';

const t = tokens.color;
const NARROW = '@media (max-width: 859.95px)';
const PHONE = '@media (max-width: 519.95px)';
const FAINT = 'rgba(244, 241, 236, 0.22)';

const screen = {
  position: 'relative',
  width: '100%',
  maxWidth: 150,
  aspectRatio: '1',
  border: `${tokens.border} solid ${t.edge}`,
  borderRadius: tokens.radius.md,
  overflow: 'clip',
  boxShadow: tokens.shadow.md,
} as const;

interface TileProps {
  wide?: boolean;
  title: string;
  copy: string;
  children: React.ReactNode;
}

function Tile({ wide, title, copy, children }: TileProps): React.JSX.Element {
  return (
    <Box
      component="article"
      sx={{
        gridColumn: wide ? 'span 2' : undefined,
        display: 'grid',
        gridTemplateRows: '1fr auto',
        minWidth: 0,
        backgroundColor: t.surface,
        border: `${tokens.border} solid ${t.edge}`,
        borderRadius: tokens.radius.lg,
        boxShadow: tokens.shadow.lg,
        overflow: 'clip',
        [NARROW]: { gridColumn: 'auto' },
      }}
    >
      <Box sx={{ p: 2.25, display: 'grid', placeItems: 'center', minHeight: 190 }}>{children}</Box>
      <Box sx={{ px: 2.25, pb: 2.25, display: 'grid', gap: 0.5 }}>
        <Typography
          component="h2"
          sx={{ fontSize: 20, fontWeight: 800, letterSpacing: '-0.02em', lineHeight: 1.15, m: 0 }}
        >
          {title}
        </Typography>
        <Typography sx={{ fontSize: 15, color: t.textSoft, maxWidth: '46ch' }}>{copy}</Typography>
      </Box>
    </Box>
  );
}

function CountUp({ to }: { to: number }): React.JSX.Element {
  const reduce = useReducedMotion();
  const ref = useRef<HTMLSpanElement | null>(null);
  const [n, setN] = useState(to);

  useEffect(() => {
    const el = ref.current;
    if (reduce || !el) return;
    let raf = 0;
    const io = new IntersectionObserver(
      ([e]) => {
        if (!e.isIntersecting) return;
        io.disconnect();
        const start = performance.now();
        const tick = (now: number): void => {
          const k = Math.min(1, (now - start) / 1400);
          setN(Math.round(to * (1 - Math.pow(1 - k, 3))));
          if (k < 1) raf = requestAnimationFrame(tick);
        };
        setN(0);
        raf = requestAnimationFrame(tick);
      },
      { threshold: 0.6 },
    );
    io.observe(el);
    return () => {
      io.disconnect();
      cancelAnimationFrame(raf);
    };
  }, [reduce, to]);

  return <span ref={ref}>{n}</span>;
}

function JumpingInputs({ src }: { src: string }): React.JSX.Element {
  const reduce = useReducedMotion();
  const [i, setI] = useState(0);
  useEffect(() => {
    if (reduce) return;
    const id = window.setInterval(() => setI((n) => (n + 1) % DEMO_INPUTS.length), 1400);
    return () => window.clearInterval(id);
  }, [reduce]);
  const m = DEMO_INPUTS[i];

  return (
    <Box sx={screen} role="img" aria-label="Your shader rendered at a changing mouse position">
      <ShaderCanvas src={src} mouse={m} />
      <Box
        aria-hidden="true"
        sx={{
          position: 'absolute',
          left: `${m[0] * 100}%`,
          top: `${(1 - m[1]) * 100}%`,
          width: 18,
          height: 18,
          m: '-9px 0 0 -9px',
          borderRadius: '50%',
          border: `3px solid ${t.text}`,
          boxShadow: `0 0 0 2px ${t.edge}`,
          transition: reduce
            ? 'none'
            : 'left 500ms cubic-bezier(.2,.8,.2,1), top 500ms cubic-bezier(.2,.8,.2,1)',
        }}
      />
    </Box>
  );
}

const KINDS: [string, string][] = [
  ['Correct', t.pass],
  ['Almost correct', t.blueUi],
  ['Wrong', FAINT],
  ['Adversarial', t.red],
];

export default function HowItWorksPage(): React.JSX.Element {
  const sphere = useMemo(() => LOCAL_CHALLENGES.find((c) => c.slug === 'raymarched-sphere'), []);
  const refSrc = sphere?.referenceShaderSrc ?? '';
  const yoursSrc = useMemo(() => nearMiss(refSrc), [refSrc]);
  const inputsSrc = useMemo(() => mouseLit(yoursSrc), [yoursSrc]);

  return (
    <Box sx={{ maxWidth: 1240, mx: 'auto', px: { xs: 2, md: 4 }, pt: { xs: 4, md: 7 }, pb: 8 }}>
      <Box sx={{ maxWidth: 780, mb: { xs: 4, md: 5 } }}>
        <Typography
          component="h1"
          sx={{
            fontSize: tokens.type.display.size,
            fontWeight: tokens.type.display.weight,
            letterSpacing: tokens.type.display.tracking,
            lineHeight: tokens.type.display.leading,
            m: 0,
            mb: 2.25,
          }}
        >
          Built like a test suite
        </Typography>
        <Typography sx={{ fontSize: tokens.type.lede.size, color: t.textSoft }}>
          What happens between Submit and your verdict.
        </Typography>
      </Box>

      <Box
        sx={{
          display: 'grid',
          gridTemplateColumns: 'repeat(3, minmax(0, 1fr))',
          gridAutoRows: 'minmax(330px, auto)',
          gap: 2,
          [NARROW]: { gridTemplateColumns: 'minmax(0, 1fr)', gridAutoRows: 'auto' },
        }}
      >
        <Tile
          wide
          title="One pipeline for preview and judge"
          copy="The preview you watch while typing and the judge that grades you share one code path. What you see is what gets scored."
        >
          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: 'minmax(0, 1fr) auto minmax(0, 1fr)',
              gap: 1.75,
              alignItems: 'center',
              width: '100%',
              maxWidth: 440,
            }}
          >
            {['Live preview', 'Judge'].map((label, i) => (
              <Box
                key={label}
                sx={{ display: 'grid', gap: 1, justifyItems: 'center', order: i === 0 ? 0 : 2 }}
              >
                <Box sx={screen} role="img" aria-label={`${label} render`}>
                  <ShaderCanvas src={yoursSrc} />
                </Box>
                <Typography sx={{ fontSize: 14, fontWeight: 600 }}>{label}</Typography>
              </Box>
            ))}
            <Box
              sx={{
                order: 1,
                fontWeight: 800,
                fontSize: 14,
                textAlign: 'center',
                px: 1.5,
                py: 1,
                borderRadius: tokens.radius.sm,
                border: `${tokens.border} solid ${t.edge}`,
                backgroundColor: t.blueUi,
                color: t.edge,
                boxShadow: tokens.shadow.sm,
              }}
            >
              One WebGL path
            </Box>
          </Box>
        </Tile>

        <Tile
          title="Several inputs, not the defaults"
          copy="Time and mouse change between renders, so matching one frame isn't enough."
        >
          <JumpingInputs src={inputsSrc} />
        </Tile>

        <Tile
          title="Close calls get a second look"
          copy="When the pixel difference can't decide, a vision model compares the images."
        >
          <Box
            sx={screen}
            role="img"
            aria-label="Difference image: bright where the renders differ"
          >
            <DiffCanvas refSrc={refSrc} yoursSrc={yoursSrc} />
          </Box>
        </Tile>

        <Tile
          wide
          title="Calibrated, then checked"
          copy="Every challenge has correct, almost-correct, wrong and adversarial examples. Limits come from the tuning set. The held-out set checks them."
        >
          <Box sx={{ width: '100%', maxWidth: 480, display: 'grid', gap: 2 }}>
            <Box sx={{ display: 'flex', alignItems: 'baseline', gap: 1.5, flexWrap: 'wrap' }}>
              <Box
                component="span"
                sx={{
                  fontSize: 'clamp(56px, 8vw, 84px)',
                  fontWeight: 800,
                  letterSpacing: '-0.05em',
                  lineHeight: 0.9,
                  fontVariantNumeric: 'tabular-nums',
                }}
              >
                <CountUp to={360} />
              </Box>
              <Typography sx={{ fontSize: 18, fontWeight: 600, color: t.textSoft }}>
                labeled shaders
              </Typography>
            </Box>
            <Box
              role="img"
              aria-label="270 shaders set the limits, 90 held out to check them"
              sx={{
                display: 'grid',
                gridTemplateColumns: '3fr 1fr',
                height: 44,
                border: `${tokens.border} solid ${t.edge}`,
                borderRadius: tokens.radius.md,
                overflow: 'clip',
                boxShadow: tokens.shadow.md,
                '& > div': {
                  display: 'flex',
                  alignItems: 'center',
                  px: 1.5,
                  fontWeight: 800,
                  fontSize: 15,
                  color: t.edge,
                  whiteSpace: 'nowrap',
                  overflow: 'hidden',
                },
                // The bar keeps its 3:1 proportion; narrow screens move the labels below it.
                [PHONE]: { height: 20, '& > div > span': { display: 'none' } },
              }}
            >
              <Box sx={{ backgroundColor: t.blueUi }}>
                <span>270 tuning</span>
              </Box>
              <Box sx={{ backgroundColor: t.pass, borderLeft: `${tokens.border} solid ${t.edge}` }}>
                <span>90 held out</span>
              </Box>
            </Box>
            <Box
              aria-hidden="true"
              sx={{
                display: 'none',
                justifyContent: 'space-between',
                mt: -1,
                fontSize: 14,
                fontWeight: 800,
                [PHONE]: { display: 'flex' },
              }}
            >
              <span>270 tuning</span>
              <span>90 held out</span>
            </Box>
            <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
              {KINDS.map(([label, color]) => (
                <Box
                  key={label}
                  sx={{
                    display: 'inline-flex',
                    alignItems: 'center',
                    gap: 1,
                    fontSize: 14,
                    fontWeight: 600,
                  }}
                >
                  <Box
                    aria-hidden="true"
                    sx={{
                      width: 12,
                      height: 12,
                      borderRadius: '3px',
                      border: `${tokens.border} solid ${t.edge}`,
                      backgroundColor: color,
                    }}
                  />
                  {label}
                </Box>
              ))}
            </Box>
          </Box>
        </Tile>

        <Tile
          wide
          title="Your source is data, not instructions"
          copy="The judge reads your shader the way it reads anything a stranger wrote. Nothing in it can change the verdict."
        >
          <Box
            sx={{ display: 'grid', gap: 1.25, width: '100%', maxWidth: 520, justifyItems: 'start' }}
          >
            <Box
              component="pre"
              sx={{
                m: 0,
                width: '100%',
                font: `400 13px/1.65 ${tokens.font.mono}`,
                backgroundColor: t.previewBg,
                border: `${tokens.border} solid ${t.edge}`,
                borderRadius: tokens.radius.md,
                p: '12px 14px',
                overflowX: 'auto',
                color: t.textSoft,
                '& b': { color: t.blueUi, fontWeight: 400 },
              }}
            >
              <b>float</b> sphereSDF(<b>vec3</b> p, <b>float</b> r) {'{'} <b>return</b> length(p) -
              r; {'}'}
              {'\n\n'}
              <b>void</b> main() {'{'}
              {'\n'}
              {'  '}fragColor = <b>vec4</b>(color, 1.0);
              {'\n'}
              {'}'}
            </Box>
            <Box
              component="span"
              sx={{
                font: `600 13px/1 ${tokens.font.sans}`,
                px: 1.25,
                py: 0.875,
                borderRadius: tokens.radius.sm,
                border: `${tokens.border} solid ${t.edge}`,
                backgroundColor: t.surfaceRaised,
              }}
            >
              Read as untrusted input
            </Box>
          </Box>
        </Tile>

        <Tile
          title="Same shader, instant answer"
          copy="Results are cached per challenge and shader, so a resubmit doesn't wait."
        >
          <Box sx={{ display: 'grid', gap: 1.25, width: '100%', maxWidth: 230 }}>
            {[
              { status: 'Passed', color: t.pass, cached: false },
              { status: 'Instant', color: t.blueUi, cached: true },
            ].map((r) => (
              <Box
                key={r.status}
                sx={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  gap: 1.25,
                  backgroundColor: t.surfaceRaised,
                  border: `${tokens.border} solid ${t.edge}`,
                  borderRadius: tokens.radius.md,
                  p: '10px 12px',
                  boxShadow: tokens.shadow.sm,
                  fontSize: 14,
                  fontWeight: 600,
                  outline: r.cached ? `2px dashed ${t.blueUi}` : 'none',
                  outlineOffset: '3px',
                }}
              >
                <span>sphere.glsl</span>
                <Box component="span" sx={{ fontWeight: 800, color: r.color }}>
                  {r.status}
                </Box>
              </Box>
            ))}
          </Box>
        </Tile>
      </Box>

      <Box
        component={Link}
        to="/challenges/circle-sdf"
        sx={{
          display: 'inline-flex',
          alignItems: 'center',
          minHeight: 52,
          mt: { xs: 5, md: 7 },
          px: 3,
          font: `800 17px/1 ${tokens.font.sans}`,
          color: '#fff',
          textDecoration: 'none',
          backgroundColor: t.redUi,
          border: `${tokens.border} solid ${t.edge}`,
          borderRadius: tokens.radius.md,
          boxShadow: tokens.shadow.lg,
          transition: `transform ${tokens.motion.press} ${tokens.motion.pressEasing}, box-shadow ${tokens.motion.press} ${tokens.motion.pressEasing}`,
          '&:hover': { backgroundColor: '#b52f28' },
          '&:active': { transform: 'translate(5px, 5px)', boxShadow: '0 0 0 transparent' },
          '&:focus-visible': { outline: `3px solid ${t.text}`, outlineOffset: '5px' },
        }}
      >
        Try a challenge
      </Box>
    </Box>
  );
}
