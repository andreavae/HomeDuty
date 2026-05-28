-- 1. Estensioni
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 2. Tabelle (ordine corretto per le foreign keys)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT NOT NULL UNIQUE,
  display_name TEXT NOT NULL,
  total_xp INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.households (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.household_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member' CHECK (role IN ('owner', 'member')),
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (household_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.tasks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  household_id UUID NOT NULL REFERENCES public.households(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  xp INT NOT NULL CHECK (xp > 0),
  assigned_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
  due_date TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'todo' CHECK (status IN ('todo', 'in_progress', 'completed')),
  recurrence TEXT NOT NULL DEFAULT 'none' CHECK (recurrence IN ('none', 'daily', 'weekly')),
  created_by UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.task_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  completed_by UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  gained_xp INT NOT NULL CHECK (gained_xp > 0),
  completed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Funzioni e trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_tasks_updated_at ON public.tasks;
CREATE TRIGGER trg_tasks_updated_at
BEFORE UPDATE ON public.tasks
FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE OR REPLACE FUNCTION public.complete_task(p_task_id UUID, p_completed_by UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_task public.tasks%ROWTYPE;
  v_is_member BOOLEAN;
  v_next_due TIMESTAMPTZ;
BEGIN
  SELECT * INTO v_task
  FROM public.tasks
  WHERE id = p_task_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Task not found';
  END IF;

  SELECT EXISTS(
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = v_task.household_id
      AND hm.user_id = p_completed_by
  ) INTO v_is_member;

  IF NOT v_is_member THEN
    RAISE EXCEPTION 'User is not a member of the household';
  END IF;

  IF v_task.status = 'completed' THEN
    RETURN;
  END IF;

  UPDATE public.tasks
  SET status = 'completed'
  WHERE id = p_task_id;

  INSERT INTO public.task_completions(task_id, completed_by, gained_xp)
  VALUES (p_task_id, p_completed_by, v_task.xp);

  UPDATE public.users
  SET total_xp = total_xp + v_task.xp
  WHERE id = p_completed_by;

  IF v_task.recurrence = 'daily' THEN
    v_next_due := COALESCE(v_task.due_date, now()) + INTERVAL '1 day';
    UPDATE public.tasks
    SET status = 'todo',
        due_date = v_next_due
    WHERE id = p_task_id;
  ELSIF v_task.recurrence = 'weekly' THEN
    v_next_due := COALESCE(v_task.due_date, now()) + INTERVAL '7 day';
    UPDATE public.tasks
    SET status = 'todo',
        due_date = v_next_due
    WHERE id = p_task_id;
  END IF;
END;
$$;

-- 4. RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.households ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.household_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_completions ENABLE ROW LEVEL SECURITY;

-- Helper to check membership without triggering RLS recursion.
CREATE OR REPLACE FUNCTION public.is_household_member(p_household_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.household_members hm
    WHERE hm.household_id = p_household_id
      AND hm.user_id = auth.uid()
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_household_member(UUID) TO authenticated;

-- 5. Policy (senza IF NOT EXISTS)
DROP POLICY IF EXISTS users_select_self ON public.users;
CREATE POLICY users_select_self ON public.users FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS users_update_self ON public.users;
CREATE POLICY users_update_self ON public.users FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS users_insert_self ON public.users;
CREATE POLICY users_insert_self ON public.users FOR INSERT WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS household_members_select ON public.household_members;
CREATE POLICY household_members_select ON public.household_members FOR SELECT USING (
  user_id = auth.uid() OR public.is_household_member(household_id)
);

DROP POLICY IF EXISTS household_members_insert_self ON public.household_members;
CREATE POLICY household_members_insert_self ON public.household_members FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS households_select_member ON public.households;
CREATE POLICY households_select_member ON public.households FOR SELECT USING (
  owner_id = auth.uid()
  OR id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS households_insert_owner ON public.households;
CREATE POLICY households_insert_owner ON public.households FOR INSERT WITH CHECK (owner_id = auth.uid());

DROP POLICY IF EXISTS households_update_owner ON public.households;
CREATE POLICY households_update_owner ON public.households FOR UPDATE USING (owner_id = auth.uid());

DROP POLICY IF EXISTS tasks_select_member ON public.tasks;
CREATE POLICY tasks_select_member ON public.tasks FOR SELECT USING (
  household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS tasks_insert_member ON public.tasks;
CREATE POLICY tasks_insert_member ON public.tasks FOR INSERT WITH CHECK (
  household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS tasks_update_member ON public.tasks;
CREATE POLICY tasks_update_member ON public.tasks FOR UPDATE USING (
  household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS tasks_delete_member ON public.tasks;
CREATE POLICY tasks_delete_member ON public.tasks FOR DELETE USING (
  household_id IN (SELECT household_id FROM public.household_members WHERE user_id = auth.uid())
);

DROP POLICY IF EXISTS completions_select_member ON public.task_completions;
CREATE POLICY completions_select_member ON public.task_completions FOR SELECT USING (
  task_id IN (
    SELECT t.id FROM public.tasks t
    WHERE t.household_id IN (
      SELECT household_id FROM public.household_members WHERE user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS completions_insert_member ON public.task_completions;
CREATE POLICY completions_insert_member ON public.task_completions FOR INSERT WITH CHECK (completed_by = auth.uid());

-- 6. Grant
GRANT EXECUTE ON FUNCTION public.complete_task(UUID, UUID) TO authenticated;