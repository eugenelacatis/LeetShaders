import { Box } from '@mui/material';
import { keyframes } from '@mui/material/styles';
import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { tokens } from '../tokens';

// The verdict, as a sticker on the render's corner. No score, MAE, tolerance or latency.
export type Verdict =
  | { kind: 'matched'; next: { slug: string; title: string } | null }
  | { kind: 'not-yet'; reason: string }
  | { kind: 'not-judged' };

interface ResultPanelProps {
  verdict: Verdict;
  reducedMotion: boolean;
  onDismiss: () => void;
  onBackToRender: () => void;
  onSubmitAgain: () => void;
}

const t = tokens.color;
const NARROW = '@media (max-width: 859.95px)';
const SLAP_MS = 340;
const PEEL_MS = 260;

const slap = keyframes`
  from { transform: rotate(calc(var(--tilt) - 18deg)) scale(1.5); opacity: 0; }
`;
const peel = keyframes`
  to { transform: rotate(calc(var(--tilt) + 14deg)) translate(40%, -70%); opacity: 0; }
`;

interface Look {
  title: string;
  tilt: string;
  bg: string;
  ink: string;
  titleColor: string;
  titleSize: string;
}

const LOOK: Record<Verdict['kind'], Look> = {
  matched: {
    title: 'Matched',
    tilt: '-6deg',
    bg: t.pass,
    ink: `color-mix(in srgb, ${t.pass} 18%, ${t.edge})`,
    titleColor: `color-mix(in srgb, ${t.pass} 18%, ${t.edge})`,
    titleSize: '40px',
  },
  'not-yet': {
    title: 'Not yet',
    tilt: '3deg',
    bg: t.text,
    ink: t.edge,
    titleColor: t.redUi,
    titleSize: '32px',
  },
  'not-judged': {
    title: 'Not judged',
    tilt: '-2deg',
    bg: `color-mix(in srgb, ${t.blueUi} 22%, ${t.text})`,
    ink: `color-mix(in srgb, ${t.blue} 35%, ${t.edge})`,
    titleColor: `color-mix(in srgb, ${t.blue} 35%, ${t.edge})`,
    titleSize: '26px',
  },
};

function body(v: Verdict): string {
  if (v.kind === 'matched')
    return 'Your render matches the reference at every input the judge tried.';
  if (v.kind === 'not-yet') return v.reason;
  return "The judge couldn't reach a verdict this time. This try doesn't count.";
}

export default function ResultPanel({
  verdict,
  reducedMotion,
  onDismiss,
  onBackToRender,
  onSubmitAgain,
}: ResultPanelProps): React.JSX.Element {
  const look = LOOK[verdict.kind];
  const [peeling, setPeeling] = useState(false);

  useEffect(() => {
    if (!peeling) return;
    const id = setTimeout(onDismiss, PEEL_MS);
    return () => clearTimeout(id);
  }, [peeling, onDismiss]);

  const peelOff = (): void => {
    if (reducedMotion) onDismiss();
    else setPeeling(true);
  };

  const actionSx = {
    display: 'inline-flex',
    alignItems: 'center',
    justifySelf: 'start',
    minHeight: tokens.minTapTarget,
    mt: '6px',
    px: '18px',
    border: `${tokens.border} solid ${look.ink}`,
    borderRadius: tokens.radius.md,
    backgroundColor: look.ink,
    color: look.bg,
    fontFamily: tokens.font.sans,
    fontWeight: 800,
    fontSize: tokens.type.label.size,
    textAlign: 'left',
    textDecoration: 'none',
    cursor: 'pointer',
    transition: `transform ${tokens.motion.press} ${tokens.motion.pressEasing}`,
    '&:active': { transform: 'translate(2px, 2px)' },
    '&:focus-visible': { outline: `2px solid ${t.blueUi}`, outlineOffset: '2px' },
  } as const;

  let action: React.JSX.Element | null;
  if (verdict.kind === 'matched') {
    action = verdict.next ? (
      <Box component={Link} to={`/challenges/${verdict.next.slug}`} sx={actionSx}>
        Next: {verdict.next.title}
      </Box>
    ) : (
      <Box component={Link} to="/challenges" sx={actionSx}>
        Back to the board
      </Box>
    );
  } else if (verdict.kind === 'not-yet') {
    action = (
      <Box component="button" type="button" onClick={onBackToRender} sx={actionSx}>
        Back to my render
      </Box>
    );
  } else {
    action = (
      <Box component="button" type="button" onClick={onSubmitAgain} sx={actionSx}>
        Submit again
      </Box>
    );
  }

  return (
    <Box
      role="status"
      aria-live="polite"
      onKeyDown={(e: React.KeyboardEvent) => {
        if (e.key === 'Escape') peelOff();
      }}
      sx={{
        '--tilt': look.tilt,
        position: 'absolute',
        right: '18px',
        bottom: '18px',
        zIndex: 2,
        width: 'min(300px, calc(100% - 36px))',
        display: 'grid',
        gap: '6px',
        p: '18px 20px',
        borderRadius: '18px',
        backgroundColor: look.bg,
        color: look.ink,
        boxShadow: `0 0 0 6px ${t.text}, 0 24px 48px color-mix(in srgb, ${t.edge} 50%, transparent)`,
        transform: 'rotate(var(--tilt))',
        animation: reducedMotion
          ? 'none'
          : peeling
            ? `${peel} ${PEEL_MS}ms ease-in forwards`
            : `${slap} ${SLAP_MS}ms cubic-bezier(.2,1.4,.4,1) both`,
        [NARROW]: {
          left: '50%',
          right: 'auto',
          bottom: '10px',
          width: '240px',
          ml: '-120px',
          p: '12px 14px',
        },
      }}
    >
      <Box
        component="button"
        type="button"
        aria-label="Peel off"
        onClick={peelOff}
        sx={{
          position: 'absolute',
          right: '-2px',
          top: '-2px',
          width: tokens.minTapTarget,
          height: tokens.minTapTarget,
          p: 0,
          border: 0,
          borderTopRightRadius: '18px',
          background: `linear-gradient(225deg, ${t.ground} 50%, color-mix(in srgb, ${t.text} 85%, transparent) 50%)`,
          cursor: 'pointer',
          '&:hover': {
            background: `linear-gradient(225deg, ${t.ground} 56%, ${t.text} 56%)`,
          },
          '&:focus-visible': { outline: `2px solid ${t.blueUi}`, outlineOffset: '2px' },
        }}
      />
      <Box
        component="b"
        sx={{
          fontSize: look.titleSize,
          fontWeight: 800,
          letterSpacing: '-0.04em',
          lineHeight: 0.95,
          color: look.titleColor,
          pr: '28px',
          [NARROW]: { fontSize: '26px' },
        }}
      >
        {look.title}
      </Box>
      <Box
        component="p"
        sx={{
          m: 0,
          fontSize: tokens.type.label.size,
          fontWeight: 400,
          lineHeight: 1.4,
          // The phone sticker sits over a small render; only "Not yet" keeps its reason there.
          [NARROW]: verdict.kind === 'not-yet' ? { fontSize: '13px' } : { display: 'none' },
        }}
      >
        {body(verdict)}
      </Box>
      {action}
    </Box>
  );
}
