-- CalorieWizard Supabase schema
-- Run in the Supabase SQL Editor (Dashboard → SQL → New query).

-- Profiles (1:1 with auth.users)
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  first_name text not null default '',
  last_name text not null default '',
  email text not null default '',
  phone text not null default '',
  daily_calorie_goal double precision not null default 2000,
  daily_protein_goal double precision not null default 120,
  daily_carbs_goal double precision not null default 200,
  daily_fat_goal double precision not null default 65,
  daily_water_goal_ml double precision not null default 2500,
  updated_at timestamptz not null default now()
);

-- Meals
create table if not exists public.meals (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  food_name text not null default '',
  calories double precision not null default 0,
  protein_g double precision not null default 0,
  carbs_g double precision not null default 0,
  fats_g double precision not null default 0,
  insights text not null default '',
  created_at timestamptz not null default now(),
  image_file_name text not null default '',
  meal_kind text not null default 'analyzed'
);

create index if not exists meals_user_id_created_at_idx
  on public.meals (user_id, created_at desc);

-- Water logs
create table if not exists public.water_logs (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  amount_ml double precision not null default 0,
  created_at timestamptz not null default now(),
  note text not null default ''
);

create index if not exists water_logs_user_id_created_at_idx
  on public.water_logs (user_id, created_at desc);

-- Favorite recipes
create table if not exists public.favorite_recipes (
  id uuid primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null default '',
  body_text text not null default '',
  calories double precision not null default 0,
  protein_g double precision not null default 0,
  carbs_g double precision not null default 0,
  fats_g double precision not null default 0,
  meal_type text not null default '',
  dietary_preference text not null default '',
  ingredients text not null default '',
  created_at timestamptz not null default now()
);

create index if not exists favorite_recipes_user_id_created_at_idx
  on public.favorite_recipes (user_id, created_at desc);

-- Row Level Security: each user only sees/writes their own rows
alter table public.profiles enable row level security;
alter table public.meals enable row level security;
alter table public.water_logs enable row level security;
alter table public.favorite_recipes enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_insert_own" on public.profiles
  for insert with check (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id);
create policy "profiles_delete_own" on public.profiles
  for delete using (auth.uid() = id);

create policy "meals_select_own" on public.meals
  for select using (auth.uid() = user_id);
create policy "meals_insert_own" on public.meals
  for insert with check (auth.uid() = user_id);
create policy "meals_update_own" on public.meals
  for update using (auth.uid() = user_id);
create policy "meals_delete_own" on public.meals
  for delete using (auth.uid() = user_id);

create policy "water_select_own" on public.water_logs
  for select using (auth.uid() = user_id);
create policy "water_insert_own" on public.water_logs
  for insert with check (auth.uid() = user_id);
create policy "water_update_own" on public.water_logs
  for update using (auth.uid() = user_id);
create policy "water_delete_own" on public.water_logs
  for delete using (auth.uid() = user_id);

create policy "favorites_select_own" on public.favorite_recipes
  for select using (auth.uid() = user_id);
create policy "favorites_insert_own" on public.favorite_recipes
  for insert with check (auth.uid() = user_id);
create policy "favorites_update_own" on public.favorite_recipes
  for update using (auth.uid() = user_id);
create policy "favorites_delete_own" on public.favorite_recipes
  for delete using (auth.uid() = user_id);
