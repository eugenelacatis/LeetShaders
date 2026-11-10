import { useLayoutEffect, useMemo, useRef, useState } from 'react';
import { Box, Typography, keyframes } from '@mui/material';
import { Link } from 'react-router-dom';
import { useChallenges } from '../backend/useChallenges';
import { ShaderCanvas } from '../components/ShaderCanvas';
import { PATH_ORDER } from '../challenges/path';
import { TRACKS } from '../judge/types';
import type { Challenge, Track } from '../judge/types';
import { tokens } from '../tokens';

const t = tokens.color;
const NARROW = '@media (max-width: 859.95px)';
const REDUCED = '@media (prefers-reduced-motion: reduce)';
const PRESS = `${tokens.motion.press} ${tokens.motion.pressEasing}`;
const ledPulse = keyframes`50% { opacity: 0.7; box-shadow: none; }`;

type Difficulty = Challenge['difficulty'];

const RANK: Record<Difficulty, number> = { beginner: 1, intermediate: 2, advanced: 3, expert: 4 };
const DIFFICULTY_LABEL: Record<Difficulty, string> = {
  beginner: 'Easy',
  intermediate: 'Medium',
  advanced: 'Hard',
  expert: 'Expert',
};

const TRACK_NAME: Record<Track, string> = {
  color: 'Color and coordinates',
  shapes: '2D shapes',
  combining: 'Combining shapes',
  patterns: 'Patterns and tiling',
  noise: 'Procedural noise',
  raymarching: '3D raymarching',
  capstone: 'Capstones',
};

// Derived shades. Each one mixes locked tokens, so no new raw colors enter the page.
const LED_OFF = `color-mix(in srgb, ${t.ground} 50%, ${t.edge})`;
const CAP_HOVER = `color-mix(in srgb, ${t.surfaceRaised} 90%, ${t.text})`;
const CAP_NEXT = `color-mix(in srgb, ${t.surfaceRaised} 85%, ${t.red})`;
const CAP_GOLD = `color-mix(in srgb, ${t.ground} 82%, ${t.gold})`;
const GLOW_PASS = `0 0 8px color-mix(in srgb, ${t.pass} 80%, transparent)`;
const GLOW_RED = `0 0 10px color-mix(in srgb, ${t.red} 90%, transparent)`;
const GLOW_GOLD = `0 0 10px color-mix(in srgb, ${t.gold} 80%, transparent)`;
const WIRE_DIM = `color-mix(in srgb, ${t.text} 14%, transparent)`;
const WIRE_DIM_GOLD = `color-mix(in srgb, ${t.gold} 35%, transparent)`;

const srOnly = {
  position: 'absolute',
  width: '1px',
  height: '1px',
  overflow: 'hidden',
  clip: 'rect(0 0 0 0)',
  whiteSpace: 'nowrap',
} as const;

function getSolvedSet(): Set<string> {
  const solved = new Set<string>();
  try {
    for (let i = 0; i < localStorage.length; i++) {
      const key = localStorage.key(i);
      if (key?.startsWith('ls_history_')) {
        const raw = localStorage.getItem(key);
        if (raw) {
          const history = JSON.parse(raw) as { passed: boolean }[];
          if (history.some((h) => h.passed)) {
            solved.add(key.replace('ls_history_', ''));
          }
        }
      }
    }
  } catch {
    // localStorage can throw (private mode, blocked storage); show nothing as solved.
  }
  return solved;
}

// Listed slugs follow PATH_ORDER; unlisted ones go after them, easiest first.
function pathIndex(c: Challenge): number {
  const i = PATH_ORDER.indexOf(c.slug);
  return i === -1 ? PATH_ORDER.length : i;
}

function byPath(a: Challenge, b: Challenge): number {
  return (
    pathIndex(a) - pathIndex(b) ||
    RANK[a.difficulty] - RANK[b.difficulty] ||
    a.title.localeCompare(b.title)
  );
}

function ProgressBar({ value, height = 10 }: { value: number; height?: number }) {
  return (
    <Box sx={{ height, borderRadius: '99px', backgroundColor: t.edge, overflow: 'hidden' }}>
      <Box
        sx={{
          height: '100%',
          width: `${value * 100}%`,
          borderRadius: '99px',
          backgroundColor: t.pass,
        }}
      />
    </Box>
  );
}

function Pips({ difficulty }: { difficulty: Difficulty }) {
  const expert = difficulty === 'expert';
  const bars = expert ? [1, 2, 3, 4] : [1, 2, 3];
  return (
    <Box
      component="span"
      sx={{ display: 'inline-flex', gap: '3px', alignItems: 'flex-end', height: 15 }}
    >
      {bars.map((n) => (
        <Box
          key={n}
          component="span"
          sx={{
            width: 4,
            height: 3 + n * 3,
            borderRadius: '1px',
            backgroundColor:
              n <= RANK[difficulty]
                ? expert
                  ? t.gold
                  : t.text
                : `color-mix(in srgb, ${t.text} 22%, transparent)`,
          }}
        />
      ))}
    </Box>
  );
}

function TrackSquares({ mixes }: { mixes: Track[] }) {
  return (
    <Box component="span" sx={{ display: 'flex', gap: '6px', justifyContent: 'center' }}>
      {mixes.map((m) => (
        <Box
          key={m}
          component="span"
          title={TRACK_NAME[m]}
          sx={{
            width: 26,
            height: 26,
            borderRadius: tokens.radius.sm,
            backgroundColor: t.ground,
            border: `${tokens.border} solid ${t.edge}`,
            display: 'grid',
            placeItems: 'center',
            fontWeight: 800,
            fontSize: tokens.type.small.size,
            color: t.blueUi,
          }}
        >
          {TRACKS.indexOf(m) + 1}
        </Box>
      ))}
    </Box>
  );
}

interface KeyProps {
  challenge: Challenge;
  solved: boolean;
  next: boolean;
  boss: boolean;
  capstone: boolean;
  col: number;
  row: number;
}

function Key({ challenge, solved, next, boss, capstone, col, row }: KeyProps) {
  const gold = boss || capstone;
  const size = capstone
    ? { wide: 168, narrow: 140 }
    : boss
      ? { wide: 136, narrow: 96 }
      : { wide: 104, narrow: 84 };
  const ledColor = solved ? t.pass : next ? t.red : boss ? t.gold : LED_OFF;
  const ledGlow = solved ? GLOW_PASS : next ? GLOW_RED : boss ? GLOW_GOLD : 'none';
  const status = solved ? 'Solved' : next ? 'Up next' : null;

  return (
    <Box
      component="li"
      sx={{ gridColumn: col, gridRow: row, display: 'flex', justifyContent: 'center', zIndex: 1 }}
    >
      <Box
        component={Link}
        to={`/challenges/${challenge.slug}`}
        sx={{
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          gap: 1,
          textAlign: 'center',
          textDecoration: 'none',
          color: t.text,
          outline: 'none',
          '&:hover .cap': { backgroundColor: gold ? CAP_GOLD : CAP_HOVER },
          '&:active .cap': {
            transform: 'translateY(5px)',
            boxShadow: `0 1px 0 ${t.edge}${gold ? `, inset 0 0 0 3px ${t.gold}` : ''}`,
          },
          '&:focus-visible .cap': { outline: `3px solid ${t.blueUi}`, outlineOffset: '3px' },
        }}
      >
        <Box
          className="cap"
          data-cap
          sx={{
            position: 'relative',
            width: size.wide,
            height: size.wide,
            p: gold ? '10px' : 1,
            borderRadius: '16px',
            backgroundColor: gold ? CAP_GOLD : next ? CAP_NEXT : t.surfaceRaised,
            border: `${tokens.border} solid ${t.edge}`,
            boxShadow: `0 ${capstone ? 8 : boss ? 7 : 6}px 0 ${t.edge}${gold ? `, inset 0 0 0 3px ${t.gold}` : ''}`,
            transition: `transform ${PRESS}, box-shadow ${PRESS}`,
            [NARROW]: { width: size.narrow, height: size.narrow, p: '6px' },
            [REDUCED]: { transition: 'none' },
          }}
        >
          <Box
            sx={{
              width: '100%',
              height: '100%',
              borderRadius: '9px',
              overflow: 'hidden',
              border: `${tokens.border} solid ${t.edge}`,
              backgroundColor: t.previewBg,
            }}
          >
            <ShaderCanvas src={challenge.referenceShaderSrc} />
          </Box>
          <Box
            component="span"
            sx={{
              position: 'absolute',
              top: -6,
              right: -6,
              width: boss ? 18 : 16,
              height: boss ? 18 : 16,
              borderRadius: '50%',
              border: `${tokens.border} solid ${t.edge}`,
              backgroundColor: ledColor,
              boxShadow: ledGlow,
              ...(next && {
                animation: `${ledPulse} 2.4s ease-in-out infinite`,
                [REDUCED]: { animation: 'none' },
              }),
            }}
          />
          {boss && (
            <Box
              component="span"
              aria-hidden
              sx={{
                position: 'absolute',
                left: '50%',
                bottom: -12,
                transform: 'translateX(-50%)',
                px: '10px',
                py: '1px',
                borderRadius: tokens.radius.sm,
                border: `${tokens.border} solid ${t.edge}`,
                backgroundColor: t.gold,
                color: t.edge,
                fontSize: tokens.type.small.size,
                fontWeight: 800,
              }}
            >
              Boss
            </Box>
          )}
        </Box>
        <Box
          component="span"
          sx={{
            mt: boss ? '6px' : 0,
            maxWidth: 150,
            fontSize: tokens.type.label.size,
            fontWeight: tokens.type.label.weight,
            lineHeight: tokens.type.label.leading,
            [NARROW]: { fontSize: tokens.type.small.size },
          }}
        >
          {challenge.title}
        </Box>
        {capstone && challenge.mixes?.length ? (
          <TrackSquares mixes={challenge.mixes} />
        ) : (
          <Pips difficulty={challenge.difficulty} />
        )}
        <Box component="span" sx={srOnly}>
          {[boss && 'Boss key', DIFFICULTY_LABEL[challenge.difficulty], status]
            .filter(Boolean)
            .join(', ')}
        </Box>
      </Box>
    </Box>
  );
}

// Snake order: odd rows run right to left, so the path reads as one wire.
function gridSpot(i: number, cols: number): { col: number; row: number } {
  const row = Math.floor(i / cols);
  const c = i % cols;
  return { row: row + 1, col: row % 2 ? cols - c : c + 1 };
}

interface Wires {
  w: number;
  h: number;
  lit: string;
  dim: string;
}

interface BoardProps {
  number: number;
  track: Track;
  items: Challenge[];
  solvedSet: Set<string>;
}

function Board({ number, track, items, solvedSet }: BoardProps) {
  const capstone = track === 'capstone';
  const wrapRef = useRef<HTMLDivElement | null>(null);
  const [width, setWidth] = useState(0);
  const [wires, setWires] = useState<Wires | null>(null);

  const cols = capstone ? (width < 640 ? 2 : 4) : width < 420 ? 3 : width < 700 ? 4 : 6;
  const solvedCount = items.filter((c) => solvedSet.has(c.id)).length;
  const next = items.find((c) => !solvedSet.has(c.id));

  useLayoutEffect(() => {
    const el = wrapRef.current;
    if (!el) return;
    const ro = new ResizeObserver(([e]) => setWidth(e.contentRect.width));
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  // Measure each cap after layout and draw the trace between them.
  useLayoutEffect(() => {
    const el = wrapRef.current;
    if (!el || width === 0) return;
    const box = el.getBoundingClientRect();
    const caps = [...el.querySelectorAll<HTMLElement>('[data-cap]')];
    const pts = caps.map((c) => {
      const r = c.getBoundingClientRect();
      return [r.left + r.width / 2 - box.left, r.top + r.height / 2 - box.top] as const;
    });
    const solved = (i: number) => solvedSet.has(items[i].id);
    const isNext = (i: number) => items[i] === next;
    // A wire lights when it joins two solved keys, or a solved key and the next one.
    const litWire = (i: number) =>
      (solved(i) && (solved(i + 1) || isNext(i + 1))) || (isNext(i) && solved(i + 1));
    const seg = (a: number) => {
      const [x1, y1] = pts[a];
      const [x2, y2] = pts[a + 1];
      // Same row: run straight at the smaller key's center, which still meets the taller boss cap.
      if (gridSpot(a, cols).row === gridSpot(a + 1, cols).row) {
        const y = Math.min(y1, y2);
        return `M${x1},${y} H${x2}`;
      }
      // Turn outside the row, half a column past the last key.
      const out = gridSpot(a, cols).col === 1 ? -1 : 1;
      const x = x1 + (out * box.width) / cols / 2;
      return `M${x1},${y1} H${x} V${y2} H${x2}`;
    };
    let lit = '';
    let dim = '';
    for (let i = 0; i < pts.length - 1; i++) {
      if (litWire(i)) lit += seg(i);
      else dim += seg(i);
    }
    setWires({ w: box.width, h: box.height, lit, dim });
  }, [width, cols, items, solvedSet, next]);

  return (
    <Box
      component="section"
      aria-labelledby={`board-${track}`}
      sx={{
        position: 'relative',
        mb: 3.5,
        p: '24px 28px 28px',
        borderRadius: tokens.radius.xl,
        border: `${tokens.border} solid ${t.edge}`,
        backgroundColor: capstone ? `color-mix(in srgb, ${t.ground} 80%, ${t.edge})` : t.surface,
        backgroundImage: `radial-gradient(color-mix(in srgb, ${t.text} 6%, transparent) 1px, transparent 1.4px)`,
        backgroundSize: '16px 16px',
        boxShadow: capstone ? tokens.shadow.xl : tokens.shadow.lg,
        [NARROW]: { p: '18px 14px 22px' },
      }}
    >
      <Box
        component="header"
        sx={{ display: 'flex', alignItems: 'center', gap: 1.75, mb: 2.5, flexWrap: 'wrap' }}
      >
        <Typography
          component="h2"
          id={`board-${track}`}
          sx={{
            fontSize: tokens.type.h3.size,
            fontWeight: tokens.type.h3.weight,
            letterSpacing: tokens.type.h3.tracking,
            lineHeight: tokens.type.h3.leading,
            px: 1.75,
            py: 0.5,
            borderRadius: tokens.radius.sm,
            border: `${tokens.border} solid ${t.edge}`,
            backgroundColor: capstone ? t.gold : t.ground,
            color: capstone ? t.edge : t.text,
            boxShadow: capstone ? 'none' : `inset 2px 2px 0 ${t.edge}`,
          }}
        >
          <Box component="b" sx={{ color: capstone ? t.edge : t.blueUi, mr: 1 }}>
            {number}
          </Box>
          {TRACK_NAME[track]}
        </Typography>
        {items.length > 0 && (
          <Box
            sx={{
              display: 'flex',
              alignItems: 'center',
              gap: 1.25,
              color: t.textSoft,
              fontSize: tokens.type.label.size,
              fontWeight: 600,
            }}
          >
            <Box component="span" aria-hidden sx={{ display: 'inline-flex', gap: '4px' }}>
              {items.map((c) => (
                <Box
                  key={c.id}
                  component="span"
                  sx={{
                    width: 8,
                    height: 8,
                    borderRadius: '50%',
                    border: `1px solid ${t.edge}`,
                    backgroundColor: solvedSet.has(c.id)
                      ? t.pass
                      : c.difficulty === 'expert'
                        ? CAP_GOLD
                        : LED_OFF,
                    boxShadow: solvedSet.has(c.id) ? GLOW_PASS : 'none',
                  }}
                />
              ))}
            </Box>
            {solvedCount} of {items.length} solved
          </Box>
        )}
        {capstone && (
          <Typography sx={{ color: t.textSoft, flex: '1 1 260px' }}>
            Each one mixes two tracks. The squares under a key name the tracks it draws on.
          </Typography>
        )}
      </Box>

      {items.length === 0 ? (
        <Box
          sx={{
            p: 3,
            borderRadius: tokens.radius.lg,
            border: `${tokens.border} dashed color-mix(in srgb, ${t.text} 25%, transparent)`,
            color: t.textSoft,
          }}
        >
          The first challenges for this board are on the way.
        </Box>
      ) : (
        <Box ref={wrapRef} sx={{ position: 'relative' }}>
          {wires && (
            <svg
              aria-hidden
              width={wires.w}
              height={wires.h}
              viewBox={`0 0 ${wires.w} ${wires.h}`}
              style={{ position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'visible' }}
            >
              <path
                d={wires.dim}
                fill="none"
                stroke={t.edge}
                strokeWidth={10}
                strokeLinejoin="round"
              />
              <path
                d={wires.dim}
                fill="none"
                style={{ stroke: capstone ? WIRE_DIM_GOLD : WIRE_DIM }}
                strokeWidth={4}
                strokeLinejoin="round"
                strokeLinecap="round"
                strokeDasharray="2 8"
              />
              <path
                d={wires.lit}
                fill="none"
                stroke={t.edge}
                strokeWidth={10}
                strokeLinejoin="round"
              />
              <path
                d={wires.lit}
                fill="none"
                stroke={t.pass}
                strokeWidth={4}
                strokeLinejoin="round"
              />
            </svg>
          )}
          <Box
            component="ol"
            sx={{
              position: 'relative',
              listStyle: 'none',
              m: 0,
              p: 0,
              display: 'grid',
              gridTemplateColumns: `repeat(${cols}, 1fr)`,
              rowGap: 3.5,
              columnGap: 1.5,
              alignItems: 'start',
            }}
          >
            {items.map((c, i) => {
              const { col, row } = gridSpot(i, cols);
              return (
                <Key
                  key={c.id}
                  challenge={c}
                  solved={solvedSet.has(c.id)}
                  next={c === next}
                  boss={!capstone && c.difficulty === 'expert'}
                  capstone={capstone}
                  col={col}
                  row={row}
                />
              );
            })}
          </Box>
        </Box>
      )}
    </Box>
  );
}

function LoadingBoard({ number }: { number: number }) {
  return (
    <Box
      aria-hidden
      sx={{
        mb: 3.5,
        p: '24px 28px 28px',
        borderRadius: tokens.radius.xl,
        border: `${tokens.border} solid ${t.edge}`,
        backgroundColor: t.surface,
        boxShadow: tokens.shadow.lg,
        [NARROW]: { p: '18px 14px 22px' },
      }}
    >
      <Box
        sx={{
          width: 220,
          height: 36,
          mb: 2.5,
          borderRadius: tokens.radius.sm,
          backgroundColor: t.ground,
        }}
      >
        <Box
          component="b"
          sx={{
            display: 'inline-block',
            p: '4px 14px',
            color: t.blueUi,
            fontSize: tokens.type.h3.size,
            fontWeight: 800,
          }}
        >
          {number}
        </Box>
      </Box>
      <Box sx={{ display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
        {[0, 1, 2, 3].map((i) => (
          <Box
            key={i}
            sx={{
              width: 104,
              height: 104,
              borderRadius: '16px',
              border: `${tokens.border} solid ${t.edge}`,
              backgroundColor: t.surfaceRaised,
              boxShadow: `0 6px 0 ${t.edge}`,
              [NARROW]: { width: 84, height: 84 },
            }}
          />
        ))}
      </Box>
    </Box>
  );
}

export default function ChallengeList() {
  const { data, loading, error } = useChallenges();
  const solvedSet = useMemo(() => getSolvedSet(), []);

  const boards = useMemo(() => {
    const all = data ?? [];
    return (
      TRACKS.map((track) => ({ track, items: all.filter((c) => c.track === track).sort(byPath) }))
        // The capstone board appears once it has challenges; the six tracks always show, so the numbering holds.
        .filter((b) => b.track !== 'capstone' || b.items.length > 0)
    );
  }, [data]);

  const total = data?.length ?? 0;
  const solved = data?.filter((c) => solvedSet.has(c.id)).length ?? 0;

  return (
    <Box sx={{ maxWidth: 1280, mx: 'auto', px: 4, pt: 4, pb: 10, [NARROW]: { px: 2 } }}>
      <Box
        sx={{
          display: 'flex',
          alignItems: 'flex-end',
          justifyContent: 'space-between',
          gap: 3,
          flexWrap: 'wrap',
          mb: 3.5,
        }}
      >
        <Typography
          component="h1"
          sx={{
            fontSize: tokens.type.display.size,
            fontWeight: tokens.type.display.weight,
            letterSpacing: tokens.type.display.tracking,
            lineHeight: tokens.type.display.leading,
            color: t.text,
          }}
        >
          Challenges
        </Typography>
        {total > 0 && (
          <Box sx={{ minWidth: 240 }}>
            <Typography
              sx={{ fontSize: '22px', fontWeight: 800, letterSpacing: '-0.02em', color: t.text }}
            >
              {solved} solved
              <Box
                component="span"
                sx={{
                  ml: 0.5,
                  color: t.textSoft,
                  fontWeight: 600,
                  fontSize: tokens.type.label.size,
                }}
              >
                of {total}
              </Box>
            </Typography>
            <Box sx={{ mt: 0.75 }}>
              <ProgressBar value={solved / total} />
            </Box>
          </Box>
        )}
      </Box>

      {error && (
        <Typography role="alert" sx={{ color: t.red, mb: 2 }}>
          {error.message}
        </Typography>
      )}

      {loading ? (
        <>
          <LoadingBoard number={1} />
          <LoadingBoard number={2} />
        </>
      ) : (
        boards.map((b) => (
          <Board
            key={b.track}
            number={TRACKS.indexOf(b.track) + 1}
            track={b.track}
            items={b.items}
            solvedSet={solvedSet}
          />
        ))
      )}
    </Box>
  );
}
