import { createTheme, type Theme } from '@mui/material/styles';
import { tokens } from './tokens';

export interface ColorPalette {
  bg: string;
  surface: string;
  surfaceHover: string;
  border: string;
  borderHover: string;
  textPrimary: string;
  textSecondary: string;
  textTertiary: string;
  accent: string;
  accentHover: string;
  success: string;
  warning: string;
  danger: string;
}

const t = tokens.color;

// The redesign is dark only: teal-black ground, red for actions, blue for progress.
export const darkColors: ColorPalette = {
  bg: t.ground,
  surface: t.surface,
  surfaceHover: t.surfaceRaised,
  border: t.edge,
  borderHover: 'rgba(244, 241, 236, 0.35)',
  textPrimary: t.text,
  textSecondary: t.textSoft,
  textTertiary: 'rgba(244, 241, 236, 0.58)',
  accent: t.blueUi,
  accentHover: '#8cc8f2',
  success: t.pass,
  warning: '#f2c48d',
  // Lighter than tokens.color.red so small error text passes 4.5:1 on the ground.
  danger: '#f0756c',
};

const press = {
  transition: `transform ${tokens.motion.press} ${tokens.motion.pressEasing}, box-shadow ${tokens.motion.press} ${tokens.motion.pressEasing}, background-color ${tokens.motion.press} ${tokens.motion.pressEasing}`,
  '&:active': { transform: 'translate(3px, 3px)', boxShadow: '0 0 0 transparent' },
};

function buildTheme(c: ColorPalette): Theme {
  const heading = (size: { weight: number; tracking: string }) => ({
    fontFamily: tokens.font.sans,
    fontWeight: size.weight,
    letterSpacing: size.tracking,
  });

  return createTheme({
    palette: {
      mode: 'dark',
      primary: { main: c.accent },
      secondary: { main: t.redUi },
      background: {
        default: c.bg,
        paper: c.surface,
      },
      text: {
        primary: c.textPrimary,
        secondary: c.textSecondary,
      },
      success: { main: c.success },
      warning: { main: c.warning },
      error: { main: c.danger },
      divider: c.border,
    },
    typography: {
      fontFamily: tokens.font.sans,
      fontSize: 14,
      h1: heading(tokens.type.display),
      h2: heading(tokens.type.h2),
      h3: heading(tokens.type.h2),
      h4: heading(tokens.type.h2),
      h5: heading(tokens.type.h3),
      h6: heading(tokens.type.h3),
      button: { fontWeight: 600, textTransform: 'none' },
    },
    shape: { borderRadius: 10 },
    components: {
      MuiCssBaseline: {
        styleOverrides: {
          body: { backgroundColor: c.bg },
        },
      },
      MuiButton: {
        defaultProps: { disableRipple: true, disableElevation: true },
        styleOverrides: {
          root: {
            borderRadius: tokens.radius.md,
            fontWeight: 600,
            fontSize: '0.875rem',
            lineHeight: 1.4,
            minWidth: 0,
            '&:focus-visible': { outline: `3px solid ${c.textPrimary}`, outlineOffset: 3 },
          },
          sizeSmall: {
            padding: '5px 14px',
            fontSize: '0.8125rem',
          },
          contained: {
            ...press,
            backgroundColor: t.redUi,
            color: '#ffffff',
            border: `${tokens.border} solid ${t.edge}`,
            boxShadow: tokens.shadow.sm,
            '&:hover': { backgroundColor: '#b52f28', boxShadow: tokens.shadow.sm },
            '&.Mui-disabled': {
              backgroundColor: t.surfaceRaised,
              color: c.textTertiary,
              borderColor: t.edge,
              boxShadow: 'none',
            },
          },
          outlined: {
            ...press,
            backgroundColor: t.surface,
            border: `${tokens.border} solid ${c.textPrimary}`,
            color: c.textPrimary,
            boxShadow: tokens.shadow.sm,
            '&:hover': {
              backgroundColor: t.surfaceRaised,
              border: `${tokens.border} solid ${c.textPrimary}`,
            },
            '&.Mui-disabled': {
              border: `${tokens.border} solid ${c.borderHover}`,
              color: c.textTertiary,
              boxShadow: 'none',
            },
          },
          text: {
            color: c.textSecondary,
            '&:hover': { backgroundColor: c.surfaceHover, color: c.textPrimary },
          },
        },
      },
    },
  });
}

export const darkTheme = buildTheme(darkColors);

export const theme = darkTheme;
