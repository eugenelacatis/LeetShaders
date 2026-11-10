import Editor, { type OnMount } from '@monaco-editor/react';
import { useCallback, useRef, useEffect } from 'react';
import type * as MonacoNs from 'monaco-editor';
import { registerGLSL } from './glsl-language';
import { LEETSHADERS_DARK_THEME, leetshadersDarkTheme } from './shaderTheme';
import type { PipelineError } from '../judge/types';
import { tokens } from '../tokens';

const NUMBER_RE = /(?<![A-Za-z_0-9.])\d+\.?\d*(?:e[+-]?\d+)?|(?<![A-Za-z_0-9.])\.\d+/gi;
const PX_PER_STEP = 4;

interface ScrubTarget {
  line: number;
  startCol: number;
  endCol: number;
  value: number;
  decimals: number;
  signed: boolean;
}

// Finds the number literal under a column. A leading minus counts only when it is unary.
function numberAt(text: string, column: number): ScrubTarget | null {
  const idx = column - 1;
  for (const m of text.matchAll(NUMBER_RE)) {
    const start = m.index ?? 0;
    const end = start + m[0].length;
    if (idx < start || idx > end) continue;
    const before = text.slice(0, start);
    const unary = /(^|[(,=*/+<>?:-]\s*)-$/.test(before) && !/--$/.test(before);
    const frac = m[0].split(/e/i)[0].split('.')[1];
    const value = parseFloat(m[0]);
    return {
      line: 0,
      startCol: (unary ? start - 1 : start) + 1,
      endCol: end + 1,
      value: unary ? -value : value,
      decimals: frac ? frac.length : 0,
      signed: unary,
    };
  }
  return null;
}

interface MonacoProps {
  value: string;
  onChange: (v: string) => void;
  readOnly?: boolean;
  errors?: PipelineError[];
  onJumpToLine?: React.MutableRefObject<((line: number) => void) | null>;
}

export default function Monaco({
  value,
  onChange,
  readOnly = false,
  errors,
  onJumpToLine,
}: MonacoProps) {
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

      // Option/Alt-drag on a number scrubs it. Alt is free once multi-cursor uses Cmd/Ctrl.
      editor.onMouseDown((e) => {
        if (
          !e.event.altKey ||
          !e.target.position ||
          editor.getOption(monaco.editor.EditorOption.readOnly)
        )
          return;
        const model = editor.getModel();
        if (!model) return;
        const line = e.target.position.lineNumber;
        const hit = numberAt(model.getLineContent(line), e.target.position.column);
        if (!hit) return;
        e.event.preventDefault();
        const startX = e.event.posx;
        const places =
          hit.decimals > 0 || /\./.test(String(hit.value)) ? Math.max(hit.decimals, 2) : 0;
        const step = places === 0 ? 1 : Math.pow(10, -places);
        let endCol = hit.endCol;
        editor.pushUndoStop();
        document.body.style.cursor = 'ew-resize';

        const onMove = (ev: MouseEvent): void => {
          let next = hit.value + Math.round((ev.clientX - startX) / PX_PER_STEP) * step;
          // A binary minus can't flip sign without changing the expression.
          if (!hit.signed) next = Math.max(0, next);
          const text = next.toFixed(places);
          editor.executeEdits('scrub', [
            { range: new monaco.Range(line, hit.startCol, line, endCol), text },
          ]);
          endCol = hit.startCol + text.length;
        };
        const onUp = (): void => {
          window.removeEventListener('mousemove', onMove);
          window.removeEventListener('mouseup', onUp);
          document.body.style.cursor = '';
          editor.pushUndoStop();
        };
        window.addEventListener('mousemove', onMove);
        window.addEventListener('mouseup', onUp);
      });

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
      .filter(
        (e) => e.kind === 'compile-error' && e.line != null && e.line > 0 && e.line <= lineCount,
      )
      .map((e) => {
        const line = e.line!;
        let endCol: number;
        try {
          endCol = e.column != null ? e.column + 1 : model.getLineMaxColumn(line);
        } catch {
          endCol = 1;
        }
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
        multiCursorModifier: 'ctrlCmd',
        accessibilitySupport: 'on',
      }}
    />
  );
}
