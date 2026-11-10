-- Boss keys and the capstone board: a fourth difficulty, a seventh track, and
-- the tracks a capstone mixes. Matches Challenge in src/judge/types.ts.

alter table public.challenges drop constraint if exists challenges_difficulty_check;
alter table public.challenges add constraint challenges_difficulty_check
  check (difficulty in ('beginner', 'intermediate', 'advanced', 'expert'));

alter table public.challenges drop constraint if exists challenges_track_check;
alter table public.challenges add constraint challenges_track_check
  check (track in ('color', 'shapes', 'combining', 'patterns', 'noise', 'raymarching', 'capstone'));

alter table public.challenges add column if not exists mixes text[];
