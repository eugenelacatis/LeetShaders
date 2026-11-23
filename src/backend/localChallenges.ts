import type { Challenge } from '../judge/types';

// Challenge files are picked up by glob: `<slug>.json`, `<slug>.glsl`, and an
// optional `<slug>.starter.glsl`, all in `src/challenges/`.
const metas = import.meta.glob<Record<string, unknown>>('../challenges/*.json', {
  import: 'default',
  eager: true,
});

const references = import.meta.glob(['../challenges/*.glsl', '!../challenges/*.starter.glsl'], {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

const starters = import.meta.glob('../challenges/*.starter.glsl', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

function toChallenge(meta: Record<string, unknown>, glsl: string): Challenge {
  return {
    id: meta.id as string,
    slug: meta.slug as string,
    title: meta.title as string,
    description: meta.description as string,
    difficulty: meta.difficulty as Challenge['difficulty'],
    track: meta.track as Challenge['track'],
    referenceShaderSrc: glsl,
    starterSrc: starters[`../challenges/${meta.slug as string}.starter.glsl`],
    tolerance: meta.tolerance as number,
    useBlur: meta.useBlur as boolean,
    hintText: (meta.hintText as string) ?? undefined,
    source: (meta.source as Challenge['source']) ?? undefined,
    mixes: (meta.mixes as Challenge['mixes']) ?? undefined,
  };
}

export const LOCAL_CHALLENGES: Challenge[] = Object.entries(metas).map(([jsonPath, meta]) => {
  const glsl = references[jsonPath.replace(/\.json$/, '.glsl')];
  if (glsl === undefined) throw new Error(`No .glsl file for ${jsonPath}`);
  return toChallenge(meta, glsl);
});
