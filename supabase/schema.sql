-- HomeDuty schema for Supabase
-- Run this file in Supabase SQL editor.

create extension if not exists pgcrypto;

create table if not exists public.users (
  id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  total_xp int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.households (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references public.users(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table if not exists public.household_members (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  role text not null default 'member' check (role in ('owner', 'member')),
  joined_at timestamptz not null default now(),
  unique (household_id, user_id)
);

create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  household_id uuid not null references public.households(id) on delete cascade,
  title text not null,
  description text not null default '',
  xp int not null check (xp > 0),
  assigned_user_id uuid references public.users(id) on delete set null,
  due_date timestamptz,
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'completed')),
  recurrence text not null default 'none' check (recurrence in ('none', 'daily', 'weekly')),
  created_by uuid not null references public.users(id) on delete restrict,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.task_completions (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  completed_by uuid not null references public.users(id) on delete cascade,
  gained_xp int not null check (gained_xp > 0),
  completed_at timestamptz not null default now()
);

create or replace function public.update_updated_at_column()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_tasks_updated_at on public.tasks;
create trigger trg_tasks_updated_at
before update on public.tasks
for each row execute function public.update_updated_at_column();

create or replace function public.complete_task(p_task_id uuid, p_completed_by uuid)
returns void
language plpgsql
security definer
as $$
declare
  v_task public.tasks%rowtype;
  v_is_member boolean;
  v_next_due timestamptz;
begin
  select * into v_task
  from public.tasks
  where id = p_task_id
  for update;

  if not found then
    raise exception 'Task not found';
  end if;

  select exists(
    select 1
    from public.household_members hm
    where hm.household_id = v_task.household_id
      and hm.user_id = p_completed_by
  ) into v_is_member;

  if not v_is_member then
    raise exception 'User is not a member of the household';
  end if;

  if v_task.status = 'completed' then
    return;
  end if;

  update public.tasks
  set status = 'completed'
  where id = p_task_id;

  insert into public.task_completions(task_id, completed_by, gained_xp)
  values (p_task_id, p_completed_by, v_task.xp);

  update public.users
  set total_xp = total_xp + v_task.xp
  where id = p_completed_by;

  if v_task.recurrence = 'daily' then
    v_next_due := coalesce(v_task.due_date, now()) + interval '1 day';
    update public.tasks
    set status = 'todo',
        due_date = v_next_due
    where id = p_task_id;
  elsif v_task.recurrence = 'weekly' then
    v_next_due := coalesce(v_task.due_date, now()) + interval '7 day';
    update public.tasks
    set status = 'todo',
        due_date = v_next_due
    where id = p_task_id;
  end if;
end;
$$;

alter table public.users enable row level security;
alter table public.households enable row level security;
alter table public.household_members enable row level security;
alter table public.tasks enable row level security;
alter table public.task_completions enable row level security;

-- users policies
create policy if not exists users_select_self on public.users
for select using (auth.uid() = id);

create policy if not exists users_update_self on public.users
for update using (auth.uid() = id);

create policy if not exists users_insert_self on public.users
for insert with check (auth.uid() = id);

-- household_members policies
create policy if not exists household_members_select on public.household_members
for select using (
  user_id = auth.uid()
  or household_id in (
    select household_id from public.household_members where user_id = auth.uid()
  )
);

create policy if not exists household_members_insert_self on public.household_members
for insert with check (user_id = auth.uid());

-- households policies
create policy if not exists households_select_member on public.households
for select using (
  id in (select household_id from public.household_members where user_id = auth.uid())
);

create policy if not exists households_insert_owner on public.households
for insert with check (owner_id = auth.uid());

create policy if not exists households_update_owner on public.households
for update using (owner_id = auth.uid());

-- tasks policies
create policy if not exists tasks_select_member on public.tasks
for select using (
  household_id in (select household_id from public.household_members where user_id = auth.uid())
);

create policy if not exists tasks_insert_member on public.tasks
for insert with check (
  household_id in (select household_id from public.household_members where user_id = auth.uid())
);

create policy if not exists tasks_update_member on public.tasks
for update using (
  household_id in (select household_id from public.household_members where user_id = auth.uid())
);

create policy if not exists tasks_delete_member on public.tasks
for delete using (
  household_id in (select household_id from public.household_members where user_id = auth.uid())
);

-- completions policies
create policy if not exists completions_select_member on public.task_completions
for select using (
  task_id in (
    select t.id
    from public.tasks t
    where t.household_id in (
      select household_id from public.household_members where user_id = auth.uid()
    )
  )
);

create policy if not exists completions_insert_member on public.task_completions
for insert with check (completed_by = auth.uid());

grant execute on function public.complete_task(uuid, uuid) to authenticated;
