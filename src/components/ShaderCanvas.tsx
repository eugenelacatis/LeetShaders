import { useEffect, useRef, useState } from 'react';
import {
  compileAndRender,
  compileShader,
  getContext,
  render,
  CANVAS_SIZE,
} from '../judge/pipeline';
import type { Uniforms } from '../judge/pipeline';

const BASE_UNIFORMS: Uniforms = { u_time: 0, u_resolution: [CANVAS_SIZE, CANVAS_SIZE] };

// readPixels returns rows bottom-up; canvas rows go top-down.
function drawPixels(canvas: HTMLCanvasElement, pixels: Uint8Array): void {
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  const img = ctx.createImageData(CANVAS_SIZE, CANVAS_SIZE);
  const row = CANVAS_SIZE * 4;
  for (let y = 0; y < CANVAS_SIZE; y++) {
    const src = (CANVAS_SIZE - 1 - y) * row;
    img.data.set(pixels.subarray(src, src + row), y * row);
  }
  ctx.putImageData(img, 0, 0);
}

function useInView(ref: React.RefObject<HTMLElement | null>): boolean {
  const [inView, setInView] = useState(false);
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const io = new IntersectionObserver(([e]) => setInView(e.isIntersecting), {
      rootMargin: '100px',
    });
    io.observe(el);
    return () => io.disconnect();
  }, [ref]);
  return inView;
}

const canvasStyle: React.CSSProperties = {
  display: 'block',
  width: '100%',
  height: '100%',
  backgroundColor: '#05060c',
};

interface ShaderCanvasProps {
  src: string;
  // Normalized 0 to 1; converted to pixels for u_mouse.
  mouse?: [number, number];
}

// One still render through the shared pipeline. It redraws only when it is in view and
// its source or mouse input changes, so a page full of these costs almost nothing.
export function ShaderCanvas({ src, mouse }: ShaderCanvasProps): React.JSX.Element {
  const ref = useRef<HTMLCanvasElement | null>(null);
  const inView = useInView(ref);
  const [program, setProgram] = useState<WebGLProgram | null>(null);
  const mx = mouse?.[0] ?? 0.5;
  const my = mouse?.[1] ?? 0.5;

  useEffect(() => {
    const p = compileShader(src);
    if ('type' in p) {
      setProgram(null);
      return;
    }
    setProgram(p);
    return () => {
      try {
        getContext().deleteProgram(p);
      } catch {
        // context lost; the program went with it
      }
    };
  }, [src]);

  useEffect(() => {
    if (!inView || !program || !ref.current) return;
    try {
      const pixels = render(program, {
        ...BASE_UNIFORMS,
        u_mouse: [mx * CANVAS_SIZE, my * CANVAS_SIZE],
      });
      drawPixels(ref.current, pixels);
    } catch {
      // render failed, keep the last frame
    }
  }, [inView, program, mx, my]);

  return <canvas ref={ref} width={CANVAS_SIZE} height={CANVAS_SIZE} style={canvasStyle} />;
}

// Dark teal where the renders match, through red, to pale yellow where they differ most.
const RAMP: [number, number, number][] = [
  [11, 26, 28],
  [222, 68, 59],
  [255, 228, 168],
];

function ramp(t: number): [number, number, number] {
  const k = t < 0.5 ? t * 2 : (t - 0.5) * 2;
  const [a, b] = t < 0.5 ? [RAMP[0], RAMP[1]] : [RAMP[1], RAMP[2]];
  return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k, a[2] + (b[2] - a[2]) * k];
}

interface DiffCanvasProps {
  refSrc: string;
  yoursSrc: string;
}

// The absolute per-pixel difference of two pipeline renders, normalized so the
// biggest difference is brightest.
export function DiffCanvas({ refSrc, yoursSrc }: DiffCanvasProps): React.JSX.Element {
  const ref = useRef<HTMLCanvasElement | null>(null);
  const inView = useInView(ref);
  const drawn = useRef('');

  useEffect(() => {
    const key = refSrc + yoursSrc;
    if (!inView || !ref.current || drawn.current === key) return;
    const a = compileAndRender(refSrc, BASE_UNIFORMS);
    const b = compileAndRender(yoursSrc, BASE_UNIFORMS);
    if ('type' in a || 'type' in b) return;

    const n = CANVAS_SIZE * CANVAS_SIZE;
    const diff = new Float32Array(n);
    let max = 1;
    for (let i = 0; i < n; i++) {
      const o = i * 4;
      const d =
        (Math.abs(a.pixels[o] - b.pixels[o]) +
          Math.abs(a.pixels[o + 1] - b.pixels[o + 1]) +
          Math.abs(a.pixels[o + 2] - b.pixels[o + 2])) /
        3;
      diff[i] = d;
      if (d > max) max = d;
    }
    const out = new Uint8Array(n * 4);
    for (let i = 0; i < n; i++) {
      const [r, g, bl] = ramp(diff[i] / max);
      out[i * 4] = r;
      out[i * 4 + 1] = g;
      out[i * 4 + 2] = bl;
      out[i * 4 + 3] = 255;
    }
    drawPixels(ref.current, out);
    drawn.current = key;
  }, [inView, refSrc, yoursSrc]);

  return <canvas ref={ref} width={CANVAS_SIZE} height={CANVAS_SIZE} style={canvasStyle} />;
}
