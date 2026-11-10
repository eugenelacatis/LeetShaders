import { Box, Typography } from '@mui/material';
import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Monaco from './Monaco';
import {
  cellLineOffsets,
  errorsForCell,
  joinCells,
  lockedText,
  parseCells,
  type Segment,
} from './cellParse';
import type { PipelineError } from '../judge/types';
import { tokens } from '../tokens';

const t = tokens.color;
const RULE = `color-mix(in srgb, ${t.text} 10%, transparent)`;
const LINE_PX = 19;

interface Props {
  /** The full shader. Cells edit their own lines and this stays in sync. */
  src: string;
  onChange: (src: string) => void;
  errors: PipelineError[];
  /** Set to a function that reveals a full-source line in the right cell. */
  onJumpToLine: React.MutableRefObject<((line: number) => void) | null>;
}

type CellSegment = Extract<Segment, { kind: 'cell' }>;

const linkBtn = {
  font: 'inherit',
  fontSize: tokens.type.small.size,
  fontWeight: 700,
  color: t.blueUi,
  background: 'none',
  border: 'none',
  p: 0,
  cursor: 'pointer',
  '&:hover': { textDecoration: 'underline' },
} as const;

function heightFor(lines: number): number {
  return Math.min(Math.max(lines, 3), 14) * LINE_PX + 16;
}

export default function CapstoneCells({ src, onChange, errors, onJumpToLine }: Props) {
  const segments = useMemo(() => parseCells(src), [src]);
  const cells = segments.filter((s): s is CellSegment => s.kind === 'cell');
  const offsets = useMemo(() => cellLineOffsets(segments), [segments]);
  const [numbersOpen, setNumbersOpen] = useState<Record<number, boolean>>({});
  const [lockedOpen, setLockedOpen] = useState(false);
  const jumpRefs = useRef<React.MutableRefObject<((line: number) => void) | null>[]>([]);
  const noop = useRef<((line: number) => void) | null>(null);

  const editCell = useCallback(
    (index: number, body: string) => {
      let seen = -1;
      const next = segments.map((s) => {
        if (s.kind !== 'cell') return s;
        seen++;
        return seen === index ? { ...s, body: body.split('\n') } : s;
      });
      onChange(joinCells(next));
    },
    [segments, onChange],
  );

  useEffect(() => {
    onJumpToLine.current = (line: number) => {
      const i = cells.findIndex((c, k) => line > offsets[k] && line <= offsets[k] + c.body.length);
      if (i >= 0) jumpRefs.current[i]?.current?.(line - offsets[i]);
    };
    return () => {
      onJumpToLine.current = null;
    };
  }, [cells, offsets, onJumpToLine]);

  return (
    <Box sx={{ flex: 1, minHeight: 0, overflowY: 'auto', p: '12px 16px', display: 'grid', gap: '14px', alignContent: 'start' }}>
      {cells.map((cell, i) => {
        jumpRefs.current[i] ??= { current: null };
        return (
          <Box key={i} sx={{ display: 'grid', gap: '6px' }}>
            <Box sx={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: '12px' }}>
              <Typography sx={{ fontSize: tokens.type.label.size, fontWeight: 700, color: t.text }}>
                {i + 1}. {cell.title}
              </Typography>
              {cell.numbers && (
                <Box
                  component="button"
                  type="button"
                  aria-expanded={!!numbersOpen[i]}
                  onClick={() => setNumbersOpen((o) => ({ ...o, [i]: !o[i] }))}
                  sx={linkBtn}
                >
                  {numbersOpen[i] ? 'Hide the numbers' : 'Stuck? Show the numbers'}
                </Box>
              )}
            </Box>
            {numbersOpen[i] && (
              <Typography
                sx={{
                  m: 0,
                  p: '10px 12px',
                  borderRadius: tokens.radius.md,
                  fontSize: tokens.type.label.size,
                  lineHeight: 1.5,
                  color: t.text,
                  backgroundColor: `color-mix(in srgb, ${t.blueUi} 12%, transparent)`,
                }}
              >
                {cell.numbers}
              </Typography>
            )}
            <Box sx={{ height: heightFor(cell.body.length), borderRadius: tokens.radius.md, overflow: 'hidden', border: `1px solid ${RULE}` }}>
              <Monaco
                value={cell.body.join('\n')}
                onChange={(v) => editCell(i, v)}
                errors={errorsForCell(errors, offsets[i], cell.body.length)}
                onJumpToLine={jumpRefs.current[i]}
              />
            </Box>
          </Box>
        );
      })}

      <Box sx={{ display: 'grid', gap: '6px' }}>
        <Box
          component="button"
          type="button"
          aria-expanded={lockedOpen}
          onClick={() => setLockedOpen((v) => !v)}
          sx={{ ...linkBtn, justifySelf: 'start' }}
        >
          {lockedOpen ? 'Hide the locked camera and march' : 'Show the locked camera and march'}
        </Box>
        {lockedOpen && (
          <Box sx={{ height: 280, borderRadius: tokens.radius.md, overflow: 'hidden', border: `1px solid ${RULE}` }}>
            <Monaco value={lockedText(segments)} onChange={() => undefined} readOnly onJumpToLine={noop} />
          </Box>
        )}
      </Box>
    </Box>
  );
}
