import { useEffect, useRef, useState } from 'react';
import { Box } from '@mui/material';
import { compileShader, render, CANVAS_SIZE } from '../judge/pipeline';
import type { ShaderError, PipelineError } from '../judge/types';
import { shaderErrorToPipelineErrors } from '../judge/types';
import { tokens } from '../tokens';

export type Lens = 'yours' | 'reference' | 'difference';

interface RenderStageProps {
  userSrc: string;
  referenceSrc: string;
  lens: Lens;
  showThumb: boolean;
  timeRef: React.MutableRefObject<number>;
  onErrors?: (errors: PipelineError[]) => void;
  // A small canvas behind the page; it gets a low-res copy of your render each frame.
  backdropRef?: React.RefObject<HTMLCanvasElement | null>;
}

function hexToRgb(hex: string): [number, number, number] {
  const n = parseInt(hex.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

// Difference ramp: no difference reads as the edge color, then red, then near-white.
const RAMP = [hexToRgb(tokens.color.edge), hexToRgb(tokens.color.red), hexToRgb(tokens.color.text)];

// readPixels returns rows bottom-up; canvas rows go top-down.
function copyFlipped(src: Uint8Array, dst: Uint8ClampedArray): void {
  const row = CANVAS_SIZE * 4;
  for (let y = 0; y < CANVAS_SIZE; y++) {
    const from = (CANVAS_SIZE - 1 - y) * row;
    dst.set(src.subarray(from, from + row), y * row);
  }
}

function writeDifference(a: Uint8ClampedArray, b: Uint8ClampedArray, out: Uint8ClampedArray): void {
  for (let i = 0; i < a.length; i += 4) {
    const d =
      (Math.abs(a[i] - b[i]) + Math.abs(a[i + 1] - b[i + 1]) + Math.abs(a[i + 2] - b[i + 2])) / 765;
    const t = Math.min(1, d * 1.6) * 2;
    const s = Math.min(1, Math.floor(t));
    const f = t - s;
    const c0 = RAMP[s];
    const c1 = RAMP[s + 1];
    out[i] = c0[0] + (c1[0] - c0[0]) * f;
    out[i + 1] = c0[1] + (c1[1] - c0[1]) * f;
    out[i + 2] = c0[2] + (c1[2] - c0[2]) * f;
    out[i + 3] = 255;
  }
}

interface Pin {
  u: number;
  v: number;
}

interface Sample {
  yours: string;
  reference: string;
}

function hex(d: Uint8ClampedArray, i: number): string {
  return `#${[d[i], d[i + 1], d[i + 2]].map((c) => c.toString(16).padStart(2, '0')).join('')}`;
}

const canvasStyle: React.CSSProperties = {
  display: 'block',
  width: '100%',
  height: '100%',
  backgroundColor: tokens.color.previewBg,
};

// The challenge page's render: your shader, the reference, or the difference between them,
// all drawn through the shared pipeline. A compile error keeps the last working program.
export default function RenderStage({
  userSrc,
  referenceSrc,
  lens,
  showThumb,
  timeRef,
  onErrors,
  backdropRef,
}: RenderStageProps): React.JSX.Element {
  const mainRef = useRef<HTMLCanvasElement | null>(null);
  const thumbRef = useRef<HTMLCanvasElement | null>(null);
  const userProg = useRef<WebGLProgram | null>(null);
  const refProg = useRef<WebGLProgram | null>(null);
  const lensRef = useRef(lens);
  lensRef.current = lens;
  const showThumbRef = useRef(showThumb);
  showThumbRef.current = showThumb;
  const [pin, setPin] = useState<Pin | null>(null);
  const [sample, setSample] = useState<Sample | null>(null);
  const pinRef = useRef(pin);
  pinRef.current = pin;
  const lastSample = useRef('');
  const crosshairRef = useRef<HTMLDivElement | null>(null);
  const onErrorsRef = useRef(onErrors);
  onErrorsRef.current = onErrors;

  useEffect(() => {
    const result = compileShader(userSrc);
    if ('type' in result) {
      onErrorsRef.current?.(shaderErrorToPipelineErrors(result as ShaderError));
    } else {
      userProg.current = result;
      onErrorsRef.current?.([]);
    }
  }, [userSrc]);

  useEffect(() => {
    const result = compileShader(referenceSrc);
    refProg.current = 'type' in result ? null : result;
  }, [referenceSrc]);

  useEffect(() => {
    const main = mainRef.current?.getContext('2d');
    if (!main) return;

    const yours = main.createImageData(CANVAS_SIZE, CANVAS_SIZE);
    const ref = main.createImageData(CANVAS_SIZE, CANVAS_SIZE);
    const diff = main.createImageData(CANVAS_SIZE, CANVAS_SIZE);
    // Holds your frame as a drawable image so the backdrop can scale it down.
    const yoursBuf = document.createElement('canvas');
    yoursBuf.width = yoursBuf.height = CANVAS_SIZE;
    const yoursCtx = yoursBuf.getContext('2d');

    let raf = 0;
    function frame(): void {
      const uniforms = {
        u_time: timeRef.current,
        u_resolution: [CANVAS_SIZE, CANVAS_SIZE] as [number, number],
      };
      const current = lensRef.current;
      const needRef = current !== 'yours' || showThumbRef.current || pinRef.current !== null;
      try {
        if (userProg.current) copyFlipped(render(userProg.current, uniforms), yours.data);
        if (needRef && refProg.current) copyFlipped(render(refProg.current, uniforms), ref.data);
      } catch {
        // Render failed; keep the last frame.
      }

      const p = pinRef.current;
      if (p) {
        const i = (Math.min(CANVAS_SIZE - 1, Math.floor(p.v * CANVAS_SIZE)) * CANVAS_SIZE +
          Math.min(CANVAS_SIZE - 1, Math.floor(p.u * CANVAS_SIZE))) * 4;
        const next = { yours: hex(yours.data, i), reference: hex(ref.data, i) };
        const key = next.yours + next.reference;
        if (key !== lastSample.current) {
          lastSample.current = key;
          setSample(next);
        }
      }

      if (current === 'yours') main!.putImageData(yours, 0, 0);
      else if (current === 'reference') main!.putImageData(ref, 0, 0);
      else {
        writeDifference(yours.data, ref.data, diff.data);
        main!.putImageData(diff, 0, 0);
      }

      if (showThumbRef.current) thumbRef.current?.getContext('2d')?.putImageData(ref, 0, 0);

      const backdrop = backdropRef?.current?.getContext('2d');
      if (backdrop && yoursCtx) {
        yoursCtx.putImageData(yours, 0, 0);
        backdrop.drawImage(yoursBuf, 0, 0, backdrop.canvas.width, backdrop.canvas.height);
      }

      raf = requestAnimationFrame(frame);
    }
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [timeRef, backdropRef]);

  useEffect(() => {
    if (!pin) {
      lastSample.current = '';
      setSample(null);
      return;
    }
    const onKey = (e: KeyboardEvent): void => {
      if (e.key === 'Escape') setPin(null);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [pin]);

  function pointOf(e: React.PointerEvent<HTMLCanvasElement> | React.MouseEvent<HTMLCanvasElement>): Pin {
    const r = e.currentTarget.getBoundingClientRect();
    return {
      u: Math.min(1, Math.max(0, (e.clientX - r.left) / r.width)),
      v: Math.min(1, Math.max(0, (e.clientY - r.top) / r.height)),
    };
  }

  function moveCrosshair(e: React.PointerEvent<HTMLCanvasElement>): void {
    const el = crosshairRef.current;
    if (!el) return;
    const q = pointOf(e);
    el.style.setProperty('--x', `${q.u * 100}%`);
    el.style.setProperty('--y', `${q.v * 100}%`);
    el.style.opacity = '1';
  }

  // Click to pin a pixel; click near the pin again to clear it.
  function togglePin(e: React.MouseEvent<HTMLCanvasElement>): void {
    const q = pointOf(e);
    setPin((old) => (old && Math.hypot(old.u - q.u, old.v - q.v) < 0.03 ? null : q));
  }

  return (
    <>
      <canvas
        ref={mainRef}
        onPointerMove={moveCrosshair}
        onPointerLeave={() => {
          if (crosshairRef.current) crosshairRef.current.style.opacity = '0';
        }}
        onClick={togglePin}
        width={CANVAS_SIZE}
        height={CANVAS_SIZE}
        style={{ ...canvasStyle, cursor: 'crosshair' }}
        role="img"
        aria-label={
          lens === 'yours'
            ? 'Your render'
            : lens === 'reference'
              ? 'Reference render'
              : 'Difference between your render and the reference'
        }
      />
      <Box
        ref={crosshairRef}
        aria-hidden="true"
        sx={{
          position: 'absolute',
          inset: 0,
          pointerEvents: 'none',
          opacity: 0,
          mixBlendMode: 'difference',
          backgroundImage: `linear-gradient(${tokens.color.text}, ${tokens.color.text}), linear-gradient(${tokens.color.text}, ${tokens.color.text})`,
          backgroundSize: '1px 100%, 100% 1px',
          backgroundPosition: 'var(--x, 50%) 0, 0 var(--y, 50%)',
          backgroundRepeat: 'no-repeat',
        }}
      />
      {pin && (
        <Box
          aria-hidden="true"
          sx={{
            position: 'absolute',
            left: `${pin.u * 100}%`,
            top: `${pin.v * 100}%`,
            width: 16,
            height: 16,
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            pointerEvents: 'none',
            boxShadow: `0 0 0 2px ${tokens.color.text}, 0 0 0 4px ${tokens.color.edge}`,
          }}
        />
      )}
      {pin && sample && (
        <Box
          role="status"
          aria-label={`Pixel colors. Yours ${sample.yours}, reference ${sample.reference}`}
          sx={{
            position: 'absolute',
            left: '12px',
            bottom: '12px',
            display: 'flex',
            gap: '12px',
            p: '6px 10px',
            borderRadius: tokens.radius.md,
            pointerEvents: 'none',
            fontFamily: tokens.font.sans,
            fontSize: 12,
            fontWeight: 700,
            fontVariantNumeric: 'tabular-nums',
            color: tokens.color.text,
            background: `color-mix(in srgb, ${tokens.color.edge} 82%, transparent)`,
          }}
        >
          {([['Yours', sample.yours], ['Reference', sample.reference]] as const).map(([label, color]) => (
            <Box key={label} sx={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <Box
                component="span"
                sx={{ width: 14, height: 14, borderRadius: '3px', background: color, boxShadow: `0 0 0 1px ${tokens.color.text}` }}
              />
              {label} {color}
            </Box>
          ))}
        </Box>
      )}
      {showThumb && (
        <Box
          sx={{
            position: 'absolute',
            right: '12px',
            top: '12px',
            width: '26%',
            aspectRatio: '1',
            borderRadius: tokens.radius.md,
            overflow: 'clip',
            boxShadow: `0 0 0 2px color-mix(in srgb, ${tokens.color.text} 60%, transparent), 0 10px 24px color-mix(in srgb, ${tokens.color.edge} 50%, transparent)`,
            '@media (max-width: 859.95px)': { width: '30%' },
          }}
        >
          <canvas
            ref={thumbRef}
            width={CANVAS_SIZE}
            height={CANVAS_SIZE}
            style={canvasStyle}
            aria-hidden="true"
          />
          <Box
            component="span"
            sx={{
              position: 'absolute',
              left: '6px',
              bottom: '6px',
              fontSize: 12,
              fontWeight: 700,
              lineHeight: 1.4,
              color: tokens.color.text,
              background: `color-mix(in srgb, ${tokens.color.edge} 75%, transparent)`,
              padding: '1px 6px',
              borderRadius: '4px',
              // Too small to read past the shape on a phone.
              '@media (max-width: 859.95px)': { display: 'none' },
            }}
          >
            Reference
          </Box>
        </Box>
      )}
    </>
  );
}

