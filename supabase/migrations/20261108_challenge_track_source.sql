-- Add a track to every challenge and optional credits for adapted shaders.
-- Matches TRACKS and ChallengeSource in src/judge/types.ts.

alter table public.challenges
  add column if not exists track text
    check (track in ('color', 'shapes', 'combining', 'patterns', 'noise', 'raymarching')),
  add column if not exists source jsonb;

-- Backfill the existing nine so the column can be required.
update public.challenges set track = case slug
  when 'solid-color' then 'color'
  when 'uv-gradient' then 'color'
  when 'radial-gradient' then 'color'
  when 'hsv-color-wheel' then 'color'
  when 'circle-sdf' then 'shapes'
  when 'box-sdf' then 'shapes'
  when 'checkerboard' then 'patterns'
  when 'polar-pattern' then 'patterns'
  when 'raymarched-sphere' then 'raymarching'
end
where track is null;

alter table public.challenges alter column track set not null;
