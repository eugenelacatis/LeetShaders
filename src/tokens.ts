// Locked design tokens from the 2026 redesign rounds ("Match it" composition, teal-black palette).
// Every new screen uses only these values.

export const tokens = {
  color: {
    ground: '#162325',
    surface: '#1d2e31',
    // On dark, raised things get lighter instead of relying on shadows.
    surfaceRaised: '#24383c',
    text: '#f4f1ec',
    textSoft: 'rgba(244, 241, 236, 0.75)',
    edge: '#050b0c',
    edgeOnDark: '#f4f1ec',
    shadow: '#050b0c',
    // Red means act. Use redUi behind white text; red for large display type and paint.
    red: '#de443b',
    redUi: '#c9362e',
    // Blue means information and progress. Use blueUi for text and bars on the ground.
    blue: '#006bb4',
    blueUi: '#5aaeea',
    pass: '#8fe3b0',
    previewBg: '#05060c',
  },
  font: {
    sans: '"Schibsted Grotesk", Helvetica, Arial, sans-serif',
    // Picked in the code-font round: two-story g, clear 0/O and 1/l/I, no ligatures.
    mono: '"IBM Plex Mono", ui-monospace, Menlo, monospace',
  },
  type: {
    display: { size: 'clamp(44px, 6vw, 80px)', weight: 800, tracking: '-0.05em', leading: 0.9 },
    h2: { size: '28px', weight: 800, tracking: '-0.03em', leading: 1.1 },
    h3: { size: '22px', weight: 800, tracking: '-0.02em', leading: 1.15 },
    lede: { size: '18px', weight: 400, tracking: '0', leading: 1.5 },
    body: { size: '16px', weight: 400, tracking: '0', leading: 1.5 },
    label: { size: '15px', weight: 600, tracking: '0', leading: 1.3 },
    small: { size: '13px', weight: 600, tracking: '0', leading: 1.3 },
  },
  space: {
    1: '4px',
    2: '8px',
    3: '12px',
    4: '16px',
    5: '20px',
    6: '24px',
    8: '32px',
    11: '44px',
    14: '56px',
  },
  radius: { sm: '6px', md: '10px', lg: '14px', xl: '22px' },
  // Hard offset shadows, no blur. Pressing moves the element into its shadow.
  shadow: {
    sm: '3px 3px 0 #050b0c',
    md: '4px 4px 0 #050b0c',
    lg: '5px 5px 0 #050b0c',
    xl: '8px 8px 0 #050b0c',
  },
  border: '2px',
  motion: {
    press: '80ms',
    pressEasing: 'ease-out',
  },
  minTapTarget: '44px',
} as const;
