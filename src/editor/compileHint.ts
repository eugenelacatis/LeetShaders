// Turns a raw GLSL compile error into one plain-language line.
// Unknown names get a "Did you mean ...?" from an edit-distance match.

// GLSL ES 3.00 built-in functions, types and variables, plus this editor's uniforms and output.
const KNOWN_NAMES: readonly string[] = [
  // angle and trig
  'radians',
  'degrees',
  'sin',
  'cos',
  'tan',
  'asin',
  'acos',
  'atan',
  'sinh',
  'cosh',
  'tanh',
  'asinh',
  'acosh',
  'atanh',
  // exponential
  'pow',
  'exp',
  'log',
  'exp2',
  'log2',
  'sqrt',
  'inversesqrt',
  // common
  'abs',
  'sign',
  'floor',
  'trunc',
  'round',
  'roundEven',
  'ceil',
  'fract',
  'mod',
  'modf',
  'min',
  'max',
  'clamp',
  'mix',
  'step',
  'smoothstep',
  'isnan',
  'isinf',
  'floatBitsToInt',
  'floatBitsToUint',
  'intBitsToFloat',
  'uintBitsToFloat',
  'packSnorm2x16',
  'unpackSnorm2x16',
  'packUnorm2x16',
  'unpackUnorm2x16',
  'packHalf2x16',
  'unpackHalf2x16',
  // geometric
  'length',
  'distance',
  'dot',
  'cross',
  'normalize',
  'faceforward',
  'reflect',
  'refract',
  // matrix and vector
  'matrixCompMult',
  'outerProduct',
  'transpose',
  'determinant',
  'inverse',
  'lessThan',
  'lessThanEqual',
  'greaterThan',
  'greaterThanEqual',
  'equal',
  'notEqual',
  'any',
  'all',
  'not',
  // texture and derivatives
  'texture',
  'textureSize',
  'texelFetch',
  'textureLod',
  'dFdx',
  'dFdy',
  'fwidth',
  // types
  'void',
  'bool',
  'int',
  'uint',
  'float',
  'vec2',
  'vec3',
  'vec4',
  'bvec2',
  'bvec3',
  'bvec4',
  'ivec2',
  'ivec3',
  'ivec4',
  'uvec2',
  'uvec3',
  'uvec4',
  'mat2',
  'mat3',
  'mat4',
  'sampler2D',
  // variables
  'gl_FragCoord',
  'gl_FrontFacing',
  'gl_PointCoord',
  'u_time',
  'u_resolution',
  'u_mouse',
  'fragColor',
];

export function editDistance(a: string, b: string): number {
  const prev = Array.from({ length: b.length + 1 }, (_, j) => j);
  for (let i = 1; i <= a.length; i++) {
    let diag = prev[0];
    prev[0] = i;
    for (let j = 1; j <= b.length; j++) {
      const up = prev[j];
      prev[j] = Math.min(prev[j] + 1, prev[j - 1] + 1, diag + (a[i - 1] === b[j - 1] ? 0 : 1));
      diag = up;
    }
  }
  return prev[b.length];
}

/** The closest known GLSL name, if it is a likely typo of `name`. */
export function closestName(name: string): string | null {
  let best: string | null = null;
  let bestD = Infinity;
  for (const k of KNOWN_NAMES) {
    if (k === name) return null;
    const d = editDistance(name.toLowerCase(), k.toLowerCase());
    if (d < bestD) {
      bestD = d;
      best = k;
    }
  }
  const limit = name.length <= 4 ? 1 : 2;
  return bestD <= limit ? best : null;
}

function quoted(message: string): string | null {
  const m = message.match(/'([^']+)'/);
  return m ? m[1] : null;
}

/** One plain-language sentence for a compile error. `line` 0 or undefined means no line. */
export function plainCompileError(message: string, line?: number): string {
  const at = line ? `Line ${line}: ` : '';
  const name = quoted(message);
  const lower = message.toLowerCase();

  if (name === 'gl_FragColor') {
    return `${at}gl_FragColor is from WebGL 1. Write your color to fragColor instead.`;
  }
  if (name && lower.includes('no matching overloaded function')) {
    const guess = closestName(name);
    if (guess) return `${at}there is no function called ${name}. Did you mean ${guess}?`;
    if (KNOWN_NAMES.includes(name)) {
      return `${at}${name} doesn't take these arguments. Check how many you pass and their types.`;
    }
    return `${at}there is no function called ${name}. Define it above main, or check the spelling.`;
  }
  if (name && lower.includes('undeclared identifier')) {
    const guess = closestName(name);
    if (guess) return `${at}${name} isn't defined. Did you mean ${guess}?`;
    return `${at}${name} isn't defined. Declare it before you use it.`;
  }
  if (lower.includes('syntax error')) {
    return `${at}GLSL couldn't read this line. Look for a missing semicolon or bracket just before it.`;
  }
  if (lower.includes('cannot convert') || lower.includes('wrong operand types')) {
    return `${at}the types don't match. Write whole numbers as 1.0, not 1, when you mix them with floats.`;
  }
  if (lower.includes('not enough data provided for construction')) {
    return `${at}this constructor needs more values.`;
  }
  if (lower.includes('too many arguments')) {
    return `${at}this call has too many values.`;
  }
  if (lower.includes('must return a value') || lower.includes('not return a value')) {
    return `${at}this function needs a return statement.`;
  }
  if (lower.includes('redefinition') || lower.includes('already has a body')) {
    return `${at}${name ?? 'this name'} is defined twice.`;
  }
  if (lower.includes('l-value required')) {
    return `${at}you can't assign to ${name ?? 'this'}. Uniforms and inputs are read-only.`;
  }
  return `${at}the shader didn't compile. The raw error is below.`;
}
