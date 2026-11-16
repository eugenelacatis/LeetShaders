import type { Challenge } from '../judge/types';

import solidColorJson from '../challenges/solid-color.json';
import solidColorGlsl from '../challenges/solid-color.glsl?raw';

import uvGradientJson from '../challenges/uv-gradient.json';
import uvGradientGlsl from '../challenges/uv-gradient.glsl?raw';

import checkerboardJson from '../challenges/checkerboard.json';
import checkerboardGlsl from '../challenges/checkerboard.glsl?raw';

import circleSdfJson from '../challenges/circle-sdf.json';
import circleSdfGlsl from '../challenges/circle-sdf.glsl?raw';

import radialGradientJson from '../challenges/radial-gradient.json';
import radialGradientGlsl from '../challenges/radial-gradient.glsl?raw';

import boxSdfJson from '../challenges/box-sdf.json';
import boxSdfGlsl from '../challenges/box-sdf.glsl?raw';

import hsvColorWheelJson from '../challenges/hsv-color-wheel.json';
import hsvColorWheelGlsl from '../challenges/hsv-color-wheel.glsl?raw';

import polarPatternJson from '../challenges/polar-pattern.json';
import polarPatternGlsl from '../challenges/polar-pattern.glsl?raw';

import raymarchedSphereJson from '../challenges/raymarched-sphere.json';
import raymarchedSphereGlsl from '../challenges/raymarched-sphere.glsl?raw';

import splitDecisionJson from '../challenges/split-decision.json';
import splitDecisionGlsl from '../challenges/split-decision.glsl?raw';

import slantJson from '../challenges/slant.json';
import slantGlsl from '../challenges/slant.glsl?raw';

import staircaseJson from '../challenges/staircase.json';
import staircaseGlsl from '../challenges/staircase.glsl?raw';

import vignetteJson from '../challenges/vignette.json';
import vignetteGlsl from '../challenges/vignette.glsl?raw';

import goldenHourJson from '../challenges/golden-hour.json';
import goldenHourGlsl from '../challenges/golden-hour.glsl?raw';

import ringJson from '../challenges/ring.json';
import ringGlsl from '../challenges/ring.glsl?raw';

import lineSegmentJson from '../challenges/line-segment.json';
import lineSegmentGlsl from '../challenges/line-segment.glsl?raw';

import triangleJson from '../challenges/triangle.json';
import triangleGlsl from '../challenges/triangle.glsl?raw';

import hexagonJson from '../challenges/hexagon.json';
import hexagonGlsl from '../challenges/hexagon.glsl?raw';

import starJson from '../challenges/star.json';
import starGlsl from '../challenges/star.glsl?raw';

import unionJson from '../challenges/union.json';
import unionGlsl from '../challenges/union.glsl?raw';

import intersectionJson from '../challenges/intersection.json';
import intersectionGlsl from '../challenges/intersection.glsl?raw';

import subtractionJson from '../challenges/subtraction.json';
import subtractionGlsl from '../challenges/subtraction.glsl?raw';

import smoothUnionJson from '../challenges/smooth-union.json';
import smoothUnionGlsl from '../challenges/smooth-union.glsl?raw';

import onionRingsJson from '../challenges/onion-rings.json';
import onionRingsGlsl from '../challenges/onion-rings.glsl?raw';

import glowJson from '../challenges/glow.json';
import glowGlsl from '../challenges/glow.glsl?raw';

import heartJson from '../challenges/heart.json';
import heartGlsl from '../challenges/heart.glsl?raw';

import crescentMoonJson from '../challenges/crescent-moon.json';
import crescentMoonGlsl from '../challenges/crescent-moon.glsl?raw';

import stripesJson from '../challenges/stripes.json';
import stripesGlsl from '../challenges/stripes.glsl?raw';

import polkaDotsJson from '../challenges/polka-dots.json';
import polkaDotsGlsl from '../challenges/polka-dots.glsl?raw';

import outlinedShapeJson from '../challenges/outlined-shape.json';
import outlinedShapeGlsl from '../challenges/outlined-shape.glsl?raw';

import dropShadowJson from '../challenges/drop-shadow.json';
import dropShadowGlsl from '../challenges/drop-shadow.glsl?raw';

import bricksJson from '../challenges/bricks.json';
import bricksGlsl from '../challenges/bricks.glsl?raw';

import hexGridJson from '../challenges/hex-grid.json';
import hexGridGlsl from '../challenges/hex-grid.glsl?raw';

import truchetJson from '../challenges/truchet.json';
import truchetGlsl from '../challenges/truchet.glsl?raw';

import zigzagJson from '../challenges/zigzag.json';
import zigzagGlsl from '../challenges/zigzag.glsl?raw';

import concentricRingsJson from '../challenges/concentric-rings.json';
import concentricRingsGlsl from '../challenges/concentric-rings.glsl?raw';

import spiralJson from '../challenges/spiral.json';
import spiralGlsl from '../challenges/spiral.glsl?raw';

import kaleidoscopeJson from '../challenges/kaleidoscope.json';
import kaleidoscopeGlsl from '../challenges/kaleidoscope.glsl?raw';

import whiteNoiseJson from '../challenges/white-noise.json';
import whiteNoiseGlsl from '../challenges/white-noise.glsl?raw';

// Optional per-challenge starters: `<slug>.starter.glsl` next to the challenge files.
const starters = import.meta.glob('../challenges/*.starter.glsl', {
  query: '?raw',
  import: 'default',
  eager: true,
}) as Record<string, string>;

interface ChallengeFile {
  meta: Record<string, unknown>;
  glsl: string;
}

const files: ChallengeFile[] = [
  { meta: solidColorJson, glsl: solidColorGlsl },
  { meta: uvGradientJson, glsl: uvGradientGlsl },
  { meta: checkerboardJson, glsl: checkerboardGlsl },
  { meta: circleSdfJson, glsl: circleSdfGlsl },
  { meta: boxSdfJson, glsl: boxSdfGlsl },
  { meta: radialGradientJson, glsl: radialGradientGlsl },
  { meta: hsvColorWheelJson, glsl: hsvColorWheelGlsl },
  { meta: polarPatternJson, glsl: polarPatternGlsl },
  { meta: raymarchedSphereJson, glsl: raymarchedSphereGlsl },
  { meta: splitDecisionJson, glsl: splitDecisionGlsl },
  { meta: slantJson, glsl: slantGlsl },
  { meta: staircaseJson, glsl: staircaseGlsl },
  { meta: vignetteJson, glsl: vignetteGlsl },
  { meta: goldenHourJson, glsl: goldenHourGlsl },
  { meta: ringJson, glsl: ringGlsl },
  { meta: lineSegmentJson, glsl: lineSegmentGlsl },
  { meta: triangleJson, glsl: triangleGlsl },
  { meta: hexagonJson, glsl: hexagonGlsl },
  { meta: starJson, glsl: starGlsl },
  { meta: unionJson, glsl: unionGlsl },
  { meta: intersectionJson, glsl: intersectionGlsl },
  { meta: subtractionJson, glsl: subtractionGlsl },
  { meta: smoothUnionJson, glsl: smoothUnionGlsl },
  { meta: onionRingsJson, glsl: onionRingsGlsl },
  { meta: glowJson, glsl: glowGlsl },
  { meta: heartJson, glsl: heartGlsl },
  { meta: crescentMoonJson, glsl: crescentMoonGlsl },
  { meta: stripesJson, glsl: stripesGlsl },
  { meta: polkaDotsJson, glsl: polkaDotsGlsl },
  { meta: outlinedShapeJson, glsl: outlinedShapeGlsl },
  { meta: dropShadowJson, glsl: dropShadowGlsl },
  { meta: bricksJson, glsl: bricksGlsl },
  { meta: hexGridJson, glsl: hexGridGlsl },
  { meta: truchetJson, glsl: truchetGlsl },
  { meta: zigzagJson, glsl: zigzagGlsl },
  { meta: concentricRingsJson, glsl: concentricRingsGlsl },
  { meta: spiralJson, glsl: spiralGlsl },
  { meta: kaleidoscopeJson, glsl: kaleidoscopeGlsl },
  { meta: whiteNoiseJson, glsl: whiteNoiseGlsl },
];

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

export const LOCAL_CHALLENGES: Challenge[] = files.map((f) => toChallenge(f.meta, f.glsl));
