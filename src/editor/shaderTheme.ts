import type { editor } from 'monaco-editor';
import { tokens } from '../tokens';

export const LEETSHADERS_DARK_THEME = 'leetshaders-dark';

const bg = tokens.color.ground.slice(1);
const fg = tokens.color.text.slice(1);

// Syntax colors from the code-font round: blue keywords and types, mint built-ins, sand numbers.
export const leetshadersDarkTheme: editor.IStandaloneThemeData = {
  base: 'vs-dark',
  inherit: false,
  rules: [
    { token: '', foreground: fg, background: bg },
    { token: 'comment', foreground: '9aa3a0' },
    { token: 'keyword', foreground: '5aaeea' },
    { token: 'type', foreground: '9fd0f3' },
    { token: 'identifier', foreground: fg },
    { token: 'number', foreground: 'f2c48d' },
    { token: 'number.float', foreground: 'f2c48d' },
    { token: 'function', foreground: '8fe3b0' },
    { token: 'variable', foreground: 'f2c48d' },
    { token: 'operator', foreground: 'b8bfbc' },
    { token: 'delimiter', foreground: 'b8bfbc' },
    { token: 'delimiter.bracket', foreground: 'b8bfbc' },
    { token: 'preprocessor', foreground: '5aaeea' },
  ],
  colors: {
    'editor.background': tokens.color.ground,
    'editor.foreground': tokens.color.text,
    'editor.lineHighlightBackground': tokens.color.surface,
    'editor.selectionBackground': '#5aaeea40',
    'editor.inactiveSelectionBackground': '#5aaeea20',
    'editorCursor.foreground': tokens.color.text,
    'editorLineNumber.foreground': '#f4f1ec55',
    'editorLineNumber.activeForeground': tokens.color.text,
    'editorIndentGuide.background': tokens.color.surfaceRaised,
    'editorIndentGuide.activeBackground': '#f4f1ec40',
    'editorBracketMatch.background': '#5aaeea20',
    'editorBracketMatch.border': '#5aaeea80',
    'editorError.foreground': tokens.color.red,
    'scrollbarSlider.background': '#f4f1ec20',
    'scrollbarSlider.hoverBackground': '#f4f1ec35',
    'scrollbarSlider.activeBackground': '#f4f1ec50',
    'editorWidget.background': tokens.color.surface,
    'editorWidget.border': tokens.color.edge,
    'editorGutter.background': tokens.color.ground,
  },
};
