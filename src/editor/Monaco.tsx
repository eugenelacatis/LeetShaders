import Editor, { type OnMount } from '@monaco-editor/react';
import { useCallback, useRef, useEffect } from 'react';
import type * as MonacoNs from 'monaco-editor';
import { registerGLSL } from './glsl-language';
import { LEETSHADERS_DARK_THEME, leetshadersDarkTheme } from './shaderTheme';
import type { PipelineError } from '../judge/types';
import { tokens } from '../tokens';

interface MonacoProps {
  value: string;
  onChange: (v: string) => void;
  readOnly?: boolean;
  errors?: PipelineError[];
  onJumpToLine?: React.MutableRefObject<((line: number) => void) | null>;
}

export default function Monaco({ value, onChange, readOnly = false, errors, onJumpToLine }: MonacoProps) {
  const editorRef = useRef<MonacoNs.editor.IStandaloneCodeEditor | null>(null);
  const monacoRef = useRef<typeof MonacoNs | null>(null);

  const onMount: OnMount = useCallback(
    (editor, monaco) => {
      registerGLSL(monaco);
      monaco.editor.defineTheme(LEETSHADERS_DARK_THEME, leetshadersDarkTheme);
      monaco.editor.setTheme(LEETSHADERS_DARK_THEME);
      editorRef.current = editor;
      monacoRef.current = monaco;
      // Monaco measures glyph widths at mount; re-measure once the web font has loaded.
      void document.fonts.ready.then(() => monaco.editor.remeasureFonts());

      if (onJumpToLine) {
        onJumpToLine.current = (line: number) => {
          editor.revealLineInCenter(line);
          editor.setPosition({ lineNumber: line, column: 1 });
          editor.focus();
        };
      }
    },
    [onJumpToLine],
  );

  useEffect(() => {
    const editor = editorRef.current;
    const monaco = monacoRef.current;
    if (!editor || !monaco) return;

    const model = editor.getModel();
    if (!model) return;

    const lineCount = model.getLineCount();
    const markers: MonacoNs.editor.IMarkerData[] = (errors ?? [])
      .filter((e) => e.kind === 'compile-error' && e.line != null && e.line > 0 && e.line <= lineCount)
      .map((e) => {
        const line = e.line!;
        let endCol: number;
        try { endCol = e.column != null ? e.column + 1 : model.getLineMaxColumn(line); } catch { endCol = 1; }
        return {
          severity: monaco.MarkerSeverity.Error,
          startLineNumber: line,
          startColumn: e.column ?? 1,
          endLineNumber: line,
          endColumn: endCol,
          message: e.message,
        };
      });

    monaco.editor.setModelMarkers(model, 'glsl', markers);
  }, [errors]);

  return (
    <Editor
      language="glsl"
      theme={LEETSHADERS_DARK_THEME}
      value={value}
      onChange={(v) => onChange(v ?? '')}
      onMount={onMount}
      options={{
        readOnly,
        fontSize: 14,
        fontFamily: tokens.font.mono,
        minimap: { enabled: false },
        scrollBeyondLastLine: false,
        tabSize: 2,
        wordWrap: 'on',
        accessibilitySupport: 'on',
      }}
    />
  );
}
