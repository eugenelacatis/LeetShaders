import { Box } from '@mui/material';
import type { PipelineError } from '../judge/types';
import { tokens } from '../tokens';
import { plainCompileError } from './compileHint';

interface ErrorConsoleProps {
  errors: PipelineError[];
  onJumpToLine?: (line: number) => void;
}

const t = tokens.color;
const MAX_RAW = 3;

function plainLine(err: PipelineError): string {
  if (err.kind === 'compile-error') return plainCompileError(err.message, err.line);
  if (err.kind === 'link-error')
    return "The shader compiled but couldn't link. The raw error is below.";
  if (err.kind === 'timeout')
    return 'The shader took too long to draw. Look for a loop that never ends.';
  return 'The graphics context dropped. Try again in a moment.';
}

function rawLine(err: PipelineError): string {
  return err.line ? `${err.line}: ${err.message}` : err.message;
}

// Compile-error toast inside the code sheet: one plain-language line, the raw errors under it.
export default function ErrorConsole({
  errors,
  onJumpToLine,
}: ErrorConsoleProps): React.JSX.Element | null {
  if (errors.length === 0) return null;
  const first = errors[0];
  const jumpLine = first.kind === 'compile-error' && first.line ? first.line : null;
  const extra = errors.length - MAX_RAW;

  return (
    <Box
      role="alert"
      sx={{
        mx: '12px',
        mb: '12px',
        p: '10px 12px',
        borderRadius: '12px',
        backgroundColor: `color-mix(in srgb, ${t.red} 20%, color-mix(in srgb, ${t.ground} 90%, transparent))`,
        border: `1px solid color-mix(in srgb, ${t.red} 50%, transparent)`,
        fontSize: tokens.type.label.size,
        lineHeight: 1.4,
        flexShrink: 0,
        maxHeight: '30%',
        overflow: 'auto',
      }}
    >
      {jumpLine !== null && onJumpToLine ? (
        <Box
          component="button"
          type="button"
          onClick={() => onJumpToLine(jumpLine)}
          sx={{
            display: 'block',
            p: 0,
            border: 0,
            background: 'none',
            color: t.text,
            font: 'inherit',
            fontWeight: 600,
            textAlign: 'left',
            cursor: 'pointer',
            '&:hover': { textDecoration: 'underline' },
            '&:focus-visible': { outline: `2px solid ${t.blueUi}`, outlineOffset: '2px' },
          }}
        >
          {plainLine(first)}
        </Box>
      ) : (
        <Box sx={{ fontWeight: 600 }}>{plainLine(first)}</Box>
      )}
      {errors.slice(0, MAX_RAW).map((err, i) => (
        <Box
          key={i}
          component="code"
          sx={{
            display: 'block',
            mt: '2px',
            fontFamily: tokens.font.mono,
            fontSize: '12.5px',
            color: `color-mix(in srgb, ${t.text} 55%, transparent)`,
            overflowWrap: 'anywhere',
          }}
        >
          {rawLine(err)}
        </Box>
      ))}
      {extra > 0 && (
        <Box sx={{ mt: '2px', fontSize: tokens.type.small.size, color: t.textSoft }}>
          and {extra} more
        </Box>
      )}
    </Box>
  );
}
