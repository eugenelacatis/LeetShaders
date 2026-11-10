// A fail reason a learner can act on, read from where the two renders differ.
// It names a place and a direction (brighter, darker, colors), never a number.

const DIFF_THRESHOLD = 0.12; // per-pixel mean channel difference, 0 to 1
const EDGE_THRESHOLD = 0.08; // reference luminance step that counts as an edge
const EDGE_RADIUS = 3; // pixels either side of an edge that count as "along the edge"
const MIN_SHARE = 0.003; // below this share of differing pixels, the frame counts as a match

function lum(p: Uint8Array, i: number): number {
  return (0.2126 * p[i] + 0.7152 * p[i + 1] + 0.0722 * p[i + 2]) / 255;
}

function region(cx: number, cy: number, spread: number): string {
  if (spread > 0.3) return 'all over the image';
  const v = cy < 0.36 ? 'top' : cy > 0.64 ? 'bottom' : '';
  const h = cx < 0.36 ? 'left' : cx > 0.64 ? 'right' : '';
  if (!v && !h) return 'near the center';
  return `toward the ${v && h ? `${v}-${h}` : v || h}`;
}

/**
 * Describe where `yours` differs from `ref`. Both are square RGBA buffers as
 * `readPixels` returns them (rows bottom-up). Returns null when this frame matches.
 */
export function describeDifference(
  yours: Uint8Array,
  ref: Uint8Array,
  size: number,
): string | null {
  const n = size * size;
  const diff = new Uint8Array(n);
  const edge = new Uint8Array(n);
  let count = 0;
  let sx = 0;
  let sy = 0;
  let sxx = 0;
  let syy = 0;
  let lumDelta = 0;
  let colorOnly = 0;
  // Bright-area masks, for "your shape is smaller / larger".
  let areaYours = 0;
  let areaRef = 0;
  let onlyYours = 0;
  let onlyRef = 0;
  let midtones = 0;

  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      const k = y * size + x;
      const i = k * 4;
      const d =
        (Math.abs(yours[i] - ref[i]) +
          Math.abs(yours[i + 1] - ref[i + 1]) +
          Math.abs(yours[i + 2] - ref[i + 2])) /
        765;
      const lr = lum(ref, i);
      const ly = lum(yours, i);
      const by = ly > 0.5;
      const br = lr > 0.5;
      if (by) areaYours++;
      if (br) areaRef++;
      if (by && !br) onlyYours++;
      if (br && !by) onlyRef++;
      if (lr > 0.15 && lr < 0.85) midtones++;
      if (x + 1 < size && Math.abs(lum(ref, i + 4) - lr) > EDGE_THRESHOLD) edge[k] = 1;
      if (y + 1 < size && Math.abs(lum(ref, i + size * 4) - lr) > EDGE_THRESHOLD) edge[k] = 1;
      if (d <= DIFF_THRESHOLD) continue;
      diff[k] = 1;
      count++;
      // Image coordinates: flip y so 0 is the top row.
      const fx = x / size;
      const fy = 1 - y / size;
      sx += fx;
      sy += fy;
      sxx += fx * fx;
      syy += fy * fy;
      const dl = ly - lr;
      lumDelta += dl;
      if (Math.abs(dl) < d * 0.5) colorOnly++;
    }
  }

  const share = count / n;
  if (share < MIN_SHARE) return null;

  // Only for crisp shapes on a background: in a gradient, the bright area moves with brightness.
  if (midtones / n < 0.1 && areaRef > 0 && areaYours > 0) {
    if (areaYours < areaRef * 0.92 && onlyYours < onlyRef * 0.1) {
      return 'Your shape comes out smaller than the reference. Check its size.';
    }
    if (areaYours > areaRef * 1.08 && onlyRef < onlyYours * 0.1) {
      return 'Your shape comes out larger than the reference. Check its size.';
    }
  }

  let nearEdge = 0;
  for (let y = 0; y < size; y++) {
    for (let x = 0; x < size; x++) {
      if (!diff[y * size + x]) continue;
      let hit = false;
      for (let dy = -EDGE_RADIUS; dy <= EDGE_RADIUS && !hit; dy++) {
        const yy = y + dy;
        if (yy < 0 || yy >= size) continue;
        for (let dx = -EDGE_RADIUS; dx <= EDGE_RADIUS; dx++) {
          const xx = x + dx;
          if (xx >= 0 && xx < size && edge[yy * size + xx]) {
            hit = true;
            break;
          }
        }
      }
      if (hit) nearEdge++;
    }
  }

  let where: string;
  if (share > 0.4) where = 'Most of the image is different.';
  else if (nearEdge / count > 0.6)
    where = 'Most of the difference sits along the edges of the shapes.';
  else {
    const cx = sx / count;
    const cy = sy / count;
    const spread = Math.sqrt(
      Math.max(0, sxx / count - cx * cx) + Math.max(0, syy / count - cy * cy),
    );
    where = `Most of the difference sits ${region(cx, cy, spread)}.`;
  }

  let how: string;
  if (colorOnly / count > 0.6) how = 'The brightness lines up there, but the colors are off.';
  else if (lumDelta / count < 0) how = 'Yours is darker there.';
  else how = 'Yours is brighter there.';

  return `${where} ${how}`;
}
