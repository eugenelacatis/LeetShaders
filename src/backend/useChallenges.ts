import { useEffect, useState } from 'react';
import type { Challenge, JudgeResult } from '../judge/types';
import { supabase } from './supabase';
import { LOCAL_CHALLENGES } from './localChallenges';

const SUPABASE_CONFIGURED =
  import.meta.env.VITE_SUPABASE_URL &&
  !import.meta.env.VITE_SUPABASE_URL.includes('placeholder');

interface UseChallengesResult {
  data: Challenge[] | null;
  loading: boolean;
  error: Error | null;
}

export function useChallenges(): UseChallengesResult {
  const [data, setData] = useState<Challenge[] | null>(null);
  const [loading, setLoading] = useState(true);
  const [error] = useState<Error | null>(null);

  useEffect(() => {
    let cancelled = false;

    async function fetchFromSupabase() {
      const { data: rows, error: err } = await supabase
        .from('challenges')
        .select('*')
        .order('difficulty', { ascending: true });

      if (cancelled) return;

      if (err || !rows || rows.length === 0) {
        setData(LOCAL_CHALLENGES);
        setLoading(false);
        return;
      }

      const challenges: Challenge[] = rows.map((r: Record<string, unknown>) => ({
        id: r.id as string,
        slug: r.slug as string,
        title: r.title as string,
        description: r.description as string,
        difficulty: r.difficulty as Challenge['difficulty'],
        track: r.track as Challenge['track'],
        referenceShaderSrc: r.reference_shader_src as string,
        tolerance: r.tolerance as number,
        useBlur: r.use_blur as boolean,
        hintText: (r.hint_text as string) ?? undefined,
        source: (r.source as Challenge['source']) ?? undefined,
      }));

      setData(challenges);
      setLoading(false);
    }

    if (SUPABASE_CONFIGURED) {
      fetchFromSupabase();
    } else {
      setData(LOCAL_CHALLENGES);
      setLoading(false);
    }

    return () => { cancelled = true; };
  }, []);

  return { data, loading, error };
}

interface UseChallengeResult {
  data: Challenge | null;
  loading: boolean;
}

export function useChallenge(slug: string): UseChallengeResult {
  const [data, setData] = useState<Challenge | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function fetchFromSupabase() {
      const { data: row, error: err } = await supabase
        .from('challenges')
        .select('*')
        .eq('slug', slug)
        .single();

      if (cancelled) return;

      if (err || !row) {
        const local = LOCAL_CHALLENGES.find((c) => c.slug === slug) ?? null;
        setData(local);
        setLoading(false);
        return;
      }

      setData({
        id: row.id as string,
        slug: row.slug as string,
        title: row.title as string,
        description: row.description as string,
        difficulty: row.difficulty as Challenge['difficulty'],
        track: row.track as Challenge['track'],
        referenceShaderSrc: row.reference_shader_src as string,
        tolerance: row.tolerance as number,
        useBlur: row.use_blur as boolean,
        hintText: (row.hint_text as string) ?? undefined,
        source: (row.source as Challenge['source']) ?? undefined,
      });
      setLoading(false);
    }

    if (SUPABASE_CONFIGURED) {
      fetchFromSupabase();
    } else {
      const local = LOCAL_CHALLENGES.find((c) => c.slug === slug) ?? null;
      setData(local);
      setLoading(false);
    }

    return () => { cancelled = true; };
  }, [slug]);

  return { data, loading };
}

export type SolveSaveStatus = 'saved' | 'signed-out' | 'not-configured';

/**
 * Records a passing submission in `solves` (see supabase/migrations). RLS
 * only accepts rows for the signed-in user, so a signed-out user is a
 * normal outcome, not an error. Throws only when the insert itself fails.
 */
export async function submitSolve(
  challengeId: string,
  result: JudgeResult,
  shaderSrc: string,
): Promise<SolveSaveStatus> {
  if (!SUPABASE_CONFIGURED) return 'not-configured';
  const { data: auth } = await supabase.auth.getUser();
  if (!auth.user) return 'signed-out';

  const { error } = await supabase.from('solves').insert({
    user_id: auth.user.id,
    challenge_id: challengeId,
    final_score: result.finalScore,
    mae_score: result.maeScore,
    llm_score: result.llmScore,
    submitted_shader_src: shaderSrc,
    passed: result.passed,
  });
  if (error) throw new Error(error.message);
  return 'saved';
}
