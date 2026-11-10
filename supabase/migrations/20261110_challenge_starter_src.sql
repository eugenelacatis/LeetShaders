-- Capstones ship their own starter scene. Matches Challenge.starterSrc in src/judge/types.ts.

alter table public.challenges add column if not exists starter_src text;
