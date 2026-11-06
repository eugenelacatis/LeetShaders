import { Box, Typography } from '@mui/material';
import { Link } from 'react-router-dom';
import { useEffect, useMemo, useState } from 'react';
import LivePreview from '../editor/LivePreview';
import { LOCAL_CHALLENGES } from '../backend/localChallenges';
import { compileAndRender, CANVAS_SIZE } from '../judge/pipeline';
import { computeMAEResult } from '../judge/mae';
import type { Challenge } from '../judge/types';
import { useColors } from '../hooks/useColors';
import { tokens } from '../tokens';

const t = tokens.color;
const HEADLINE = 'Match the reference.';
const SHELF_SLUGS = ['circle-sdf', 'hsv-color-wheel', 'polar-pattern', 'raymarched-sphere'];
const LEVEL: Record<Challenge['difficulty'], number> = {
  beginner: 1,
  intermediate: 2,
  advanced: 3,
};

// CSS stand-ins for each challenge's output, so the shelf costs no extra WebGL work.
const THUMB: Record<string, string> = {
  'circle-sdf': 'radial-gradient(circle, #fff 0 32%, #000 33.5%)',
  'hsv-color-wheel':
    'radial-gradient(circle, #05060c 0 30%, transparent 31% 47%, #05060c 48%), conic-gradient(red, yellow, lime, cyan, blue, magenta, red)',
  'polar-pattern':
    'radial-gradient(circle, transparent 0 18%, #12051d 72%), repeating-conic-gradient(#ff5fd2 0 12deg, #5b1bd1 12deg 24deg)',
  'raymarched-sphere':
    'radial-gradient(circle at 40% 36%, #fff 0 3%, #c9d6ff 9%, #4a68d8 30%, #0d1436 46.5%, #05060c 47.5%)',
};

// A near miss of the reference: the light sits a little lower and the highlight is softer.
function nearMiss(src: string): string {
  return src
    .replace('vec3(2.0, 4.0, 5.0)', 'vec3(4.0, 2.5, 4.0)')
    .replace('vec3(0.4, 0.6, 0.9)', 'vec3(0.5, 0.55, 0.95)')
    .replace('32.0', '16.0');
}

function useDemoScore(challenge: Challenge | undefined, yoursSrc: string): number | null {
  const [mae, setMae] = useState<number | null>(null);
  useEffect(() => {
    if (!challenge) return;
    const uniforms = { u_time: 0, u_resolution: [CANVAS_SIZE, CANVAS_SIZE] as [number, number] };
    const ref = compileAndRender(challenge.referenceShaderSrc, uniforms);
    if ('type' in ref) return;
    const refPixels = ref.pixels.slice();
    const yours = compileAndRender(yoursSrc, uniforms);
    if ('type' in yours) return;
    setMae(
      computeMAEResult(refPixels, yours.pixels, challenge.tolerance, challenge.useBlur).rawMae,
    );
  }, [challenge, yoursSrc]);
  return mae;
}

const pressable = {
  transition: `transform ${tokens.motion.press} ${tokens.motion.pressEasing}, box-shadow ${tokens.motion.press} ${tokens.motion.pressEasing}`,
  '&:focus-visible': { outline: `3px solid ${t.text}`, outlineOffset: '5px' },
};

function DifficultyBars({ level, label }: { level: number; label: string }) {
  return (
    <Box
      role="img"
      aria-label={label}
      sx={{ ml: 'auto', display: 'inline-flex', gap: '3px', flex: 'none' }}
    >
      {[1, 2, 3].map((i) => (
        <Box
          key={i}
          sx={{
            width: 6,
            height: 16,
            borderRadius: '2px',
            backgroundColor: i <= level ? t.text : 'rgba(244, 241, 236, 0.2)',
          }}
        />
      ))}
    </Box>
  );
}

function Tag({ side, children }: { side: 'left' | 'right'; children: string }) {
  return (
    <Box
      component="span"
      sx={{
        position: 'absolute',
        top: 12,
        [side]: 12,
        zIndex: 2,
        fontSize: tokens.type.small.size,
        fontWeight: 800,
        backgroundColor: t.surface,
        color: t.text,
        border: `${tokens.border} solid ${t.text}`,
        borderRadius: tokens.radius.sm,
        px: '9px',
        py: '3px',
        pointerEvents: 'none',
      }}
    >
      {children}
    </Box>
  );
}

export default function Landing() {
  const colors = useColors();
  const [split, setSplit] = useState(50);

  const sphere = useMemo(() => LOCAL_CHALLENGES.find((c) => c.slug === 'raymarched-sphere'), []);
  const yoursSrc = useMemo(() => (sphere ? nearMiss(sphere.referenceShaderSrc) : ''), [sphere]);
  const mae = useDemoScore(sphere, yoursSrc);
  const shelf = useMemo(
    () =>
      SHELF_SLUGS.map((s) => LOCAL_CHALLENGES.find((c) => c.slug === s)).filter(
        (c): c is Challenge => !!c,
      ),
    [],
  );

  const within = sphere && mae !== null ? mae <= sphere.tolerance : null;
  const fill = sphere && mae !== null ? Math.min(100, (mae / sphere.tolerance) * 100) : 0;

  return (
    <Box sx={{ maxWidth: 1240, mx: 'auto', px: { xs: 2, md: 4 }, pb: { xs: 5, md: 7 } }}>
      <Box
        component="section"
        sx={{
          display: 'grid',
          gridTemplateColumns: { xs: 'minmax(0, 1fr)', md: 'minmax(0, 5fr) minmax(0, 7fr)' },
          gap: { xs: 4, md: 5.5 },
          alignItems: 'center',
          pt: { xs: 4, md: 7 },
          pb: { xs: 4, md: 6 },
        }}
      >
        <Box>
          <Typography
            component="h1"
            sx={{
              fontSize: tokens.type.display.size,
              fontWeight: tokens.type.display.weight,
              letterSpacing: tokens.type.display.tracking,
              lineHeight: tokens.type.display.leading,
              color: colors.textPrimary,
              m: 0,
              mb: 2.25,
            }}
          >
            {HEADLINE}
          </Typography>
          <Typography
            sx={{
              fontSize: tokens.type.lede.size,
              color: colors.textSecondary,
              maxWidth: '34ch',
              mb: 4,
            }}
          >
            Write a GLSL fragment shader. Drag the line to see how close you got. You pass when the
            difference drops under the limit.
          </Typography>
          <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap', alignItems: 'center' }}>
            <Box
              component={Link}
              to="/challenges/circle-sdf"
              sx={{
                ...pressable,
                display: 'inline-flex',
                alignItems: 'center',
                minHeight: 52,
                px: 3,
                font: `800 17px/1 ${tokens.font.sans}`,
                color: '#fff',
                textDecoration: 'none',
                backgroundColor: t.redUi,
                border: `${tokens.border} solid ${t.edge}`,
                borderRadius: tokens.radius.md,
                boxShadow: tokens.shadow.lg,
                '&:hover': { backgroundColor: '#b52f28' },
                '&:active': { transform: 'translate(5px, 5px)', boxShadow: '0 0 0 transparent' },
              }}
            >
              Start with Zen Dot
            </Box>
            <Box
              component={Link}
              to="/challenges"
              sx={{
                ...pressable,
                display: 'inline-flex',
                alignItems: 'center',
                minHeight: 52,
                px: 2.5,
                fontWeight: 600,
                fontSize: tokens.type.label.size,
                color: t.text,
                textDecoration: 'none',
                backgroundColor: t.surface,
                border: `${tokens.border} solid ${t.text}`,
                borderRadius: tokens.radius.md,
                boxShadow: tokens.shadow.md,
                '&:hover': { backgroundColor: t.surfaceRaised },
                '&:active': { transform: 'translate(4px, 4px)', boxShadow: '0 0 0 transparent' },
              }}
            >
              See all challenges
            </Box>
          </Box>
        </Box>

        <Box sx={{ width: '100%', maxWidth: 560, justifySelf: { md: 'end' } }}>
          <Box
            sx={{
              position: 'relative',
              aspectRatio: '1',
              border: `${tokens.border} solid ${t.edge}`,
              borderRadius: tokens.radius.lg,
              boxShadow: tokens.shadow.xl,
              backgroundColor: t.previewBg,
              overflow: 'hidden',
            }}
          >
            {sphere && (
              <>
                <Box
                  sx={{ position: 'absolute', inset: 0 }}
                  aria-label="Reference render"
                  role="img"
                >
                  <LivePreview shaderSrc={sphere.referenceShaderSrc} />
                </Box>
                <Box
                  sx={{ position: 'absolute', inset: 0, clipPath: `inset(0 0 0 ${split}%)` }}
                  aria-label="Your render"
                  role="img"
                >
                  <LivePreview shaderSrc={yoursSrc} />
                </Box>
              </>
            )}
            <Tag side="left">Reference</Tag>
            <Tag side="right">Yours</Tag>
            <Box
              aria-hidden="true"
              sx={{
                position: 'absolute',
                top: 0,
                bottom: 0,
                left: `${split}%`,
                width: 3,
                transform: 'translateX(-1.5px)',
                backgroundColor: t.red,
                zIndex: 3,
                pointerEvents: 'none',
                '&::after': {
                  content: '"\\21C6"',
                  position: 'absolute',
                  top: '50%',
                  left: '50%',
                  transform: 'translate(-50%, -50%)',
                  width: 44,
                  height: 44,
                  borderRadius: '50%',
                  backgroundColor: t.redUi,
                  border: `${tokens.border} solid ${t.edge}`,
                  color: '#fff',
                  display: 'grid',
                  placeItems: 'center',
                  fontWeight: 800,
                  fontSize: 18,
                },
              }}
            />
            <Box
              component="input"
              type="range"
              min={0}
              max={100}
              value={split}
              onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
                setSplit(Number(e.target.value))
              }
              aria-label="Compare the reference with your render"
              sx={{
                position: 'absolute',
                inset: 0,
                width: '100%',
                height: '100%',
                m: 0,
                opacity: 0,
                cursor: 'ew-resize',
                zIndex: 4,
              }}
            />
          </Box>

          <Box
            sx={{
              display: 'grid',
              gridTemplateColumns: 'auto minmax(0, 1fr) auto',
              gap: 1.75,
              alignItems: 'center',
              mt: 2.75,
              minHeight: 40,
            }}
          >
            <Typography
              sx={{
                fontSize: tokens.type.h2.size,
                fontWeight: 800,
                letterSpacing: tokens.type.h2.tracking,
                color: within === false ? colors.danger : t.pass,
              }}
            >
              {within === null ? 'Judging' : within ? 'Passed' : 'Too far'}
            </Typography>
            <Box
              sx={{
                height: 14,
                border: `${tokens.border} solid ${t.text}`,
                borderRadius: '4px',
                backgroundColor: t.surface,
                position: 'relative',
                overflow: 'hidden',
              }}
            >
              <Box
                sx={{
                  position: 'absolute',
                  inset: '0 auto 0 0',
                  width: `${fill}%`,
                  backgroundColor: t.blueUi,
                  transition: 'width 600ms ease-out',
                }}
              />
            </Box>
            <Typography
              sx={{
                fontSize: 14,
                fontWeight: 600,
                whiteSpace: 'nowrap',
                color: colors.textPrimary,
              }}
            >
              {mae !== null && sphere ? `${mae.toFixed(1)} of ${sphere.tolerance} allowed` : ' '}
            </Typography>
          </Box>
        </Box>
      </Box>

      <Box
        component="section"
        aria-label="Challenges"
        sx={{
          display: 'grid',
          gridTemplateColumns: {
            xs: 'minmax(0, 1fr)',
            sm: 'repeat(2, minmax(0, 1fr))',
            md: 'repeat(4, minmax(0, 1fr))',
          },
          gap: 1.75,
        }}
      >
        {shelf.map((c) => (
          <Box
            key={c.slug}
            component={Link}
            to={`/challenges/${c.slug}`}
            sx={{
              ...pressable,
              display: 'flex',
              alignItems: 'center',
              gap: 1.5,
              minWidth: 0,
              p: 1,
              textDecoration: 'none',
              color: t.text,
              backgroundColor: t.surface,
              border: `${tokens.border} solid ${t.edge}`,
              borderRadius: tokens.radius.md,
              boxShadow: tokens.shadow.md,
              '&:hover': { backgroundColor: t.surfaceRaised },
              '&:active': { transform: 'translate(4px, 4px)', boxShadow: '0 0 0 transparent' },
            }}
          >
            <Box
              aria-hidden="true"
              sx={{
                width: 44,
                height: 44,
                flex: 'none',
                borderRadius: tokens.radius.sm,
                border: `${tokens.border} solid rgba(244, 241, 236, 0.25)`,
                background: THUMB[c.slug],
              }}
            />
            <Typography sx={{ fontSize: tokens.type.label.size, fontWeight: 800, minWidth: 0 }}>
              {c.title}
            </Typography>
            <DifficultyBars level={LEVEL[c.difficulty]} label={c.difficulty} />
          </Box>
        ))}
      </Box>
    </Box>
  );
}
