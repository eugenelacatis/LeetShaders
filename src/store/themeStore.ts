import { create } from 'zustand';
import { darkColors, darkTheme, type ColorPalette } from '../theme';
import type { Theme } from '@mui/material/styles';

interface ThemeState {
  colors: ColorPalette;
  muiTheme: Theme;
}

// The redesign is dark only, so the store holds one fixed palette.
export const useThemeStore = create<ThemeState>(() => ({
  colors: darkColors,
  muiTheme: darkTheme,
}));
