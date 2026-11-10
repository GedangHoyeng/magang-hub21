-- ============================================================================
-- Magang Hub database schema (Supabase)
-- Jalankan di Supabase Dashboard > SQL Editor. Idempoten (bisa diulang).
-- ============================================================================

-- Pastikan extension yang diperlukan tersedia
create extension if not exists pgcrypto;

-- ============================================================================
-- Enums (pakai DO block + EXCEPTION karena CREATE TYPE tidak mendukung IF NOT EXISTS)
-- ============================================================================
do $$ BEGIN
  CREATE TYPE public.user_role AS ENUM ('admin', 'mentor', 'intern');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ BEGIN
  CREATE TYPE public.attendance_status AS ENUM ('present', 'late', 'absent', 'leave', 'sick');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ BEGIN
  CREATE TYPE public.task_status AS ENUM ('backlog', 'todo', 'doing', 'in_review', 'done');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ BEGIN
  CREATE TYPE public.leave_type AS ENUM ('izin', 'sakit', 'lainnya');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ BEGIN
  CREATE TYPE public.leave_status AS ENUM ('pending', 'approved', 'rejected');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

do $$ BEGIN
  CREATE TYPE public.report_status AS ENUM ('draft', 'submitted', 'approved');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- Tabel: internship_periods (dibuat dulu karena dirujuk profiles)
-- ============================================================================
create table if not exists public.internship_periods (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  start_date date not null,
  end_date date not null,
  work_start_time time not null default '09:00',
  work_end_time time not null default '16:00',
  late_tolerance_minutes integer not null default 15,
  report_open_time time not null default '09:00',
  report_deadline_time time not null default '16:00',
  trello_board_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: profiles
-- ============================================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  role public.user_role not null default 'intern',
  school_or_campus text,
  phone text,
  avatar_url text,
  mentor_id uuid references public.profiles(id),
  period_id uuid references public.internship_periods(id),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: office_locations
-- ============================================================================
create table if not exists public.office_locations (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  address text not null,
  latitude double precision not null,
  longitude double precision not null,
  radius_meters integer not null default 100,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: attendance
-- ============================================================================
create table if not exists public.attendance (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  check_in_at timestamptz,
  check_out_at timestamptz,
  check_in_lat double precision,
  check_in_lng double precision,
  check_out_lat double precision,
  check_out_lng double precision,
  location_id uuid references public.office_locations(id),
  check_in_photo_url text,
  face_match_score real,
  status public.attendance_status not null default 'absent',
  flagged boolean not null default false,
  flag_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint attendance_user_date_key unique (user_id, date)
);

-- ============================================================================
-- Tabel: face_templates
-- ============================================================================
create table if not exists public.face_templates (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  descriptor jsonb not null,
  consent_at timestamptz not null default now(),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: leave_requests
-- ============================================================================
create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type public.leave_type not null,
  start_date date not null,
  end_date date not null,
  reason text not null,
  attachment_url text,
  status public.leave_status not null default 'pending',
  reviewed_by uuid references public.profiles(id),
  review_note text,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: tasks
-- ============================================================================
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  project_name text,
  assignee_id uuid not null references public.profiles(id),
  created_by uuid not null references public.profiles(id),
  status public.task_status not null default 'backlog',
  priority text,
  start_date date,
  due_date date,
  revision_note text,
  attachment_urls text[],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: task_history
-- ============================================================================
create table if not exists public.task_history (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  from_status public.task_status,
  to_status public.task_status not null,
  changed_by uuid references public.profiles(id),
  note text,
  changed_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: task_comments
-- ============================================================================
create table if not exists public.task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references public.tasks(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: daily_reports
-- ============================================================================
create table if not exists public.daily_reports (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  date date not null,
  photo_url text,
  trello_url text,
  project_description text,
  submitted_at timestamptz,
  status public.report_status not null default 'draft',
  mentor_comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint daily_reports_user_date_key unique (user_id, date)
);

-- ============================================================================
-- Tabel: evaluations
-- ============================================================================
create table if not exists public.evaluations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  evaluator_id uuid not null references public.profiles(id),
  week_label text not null,
  scores jsonb not null default '{}'::jsonb,
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: notifications
-- ============================================================================
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text,
  link text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

-- ============================================================================
-- Tabel: announcements
-- ============================================================================
create table if not exists public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================================
-- Trigger: updated_at otomatis
-- ============================================================================
create or replace function public.update_updated_at_column()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'profiles_updated_at'
  ) then
    create trigger profiles_updated_at
      before update on public.profiles
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'internship_periods_updated_at'
  ) then
    create trigger internship_periods_updated_at
      before update on public.internship_periods
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'office_locations_updated_at'
  ) then
    create trigger office_locations_updated_at
      before update on public.office_locations
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'attendance_updated_at'
  ) then
    create trigger attendance_updated_at
      before update on public.attendance
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'face_templates_updated_at'
  ) then
    create trigger face_templates_updated_at
      before update on public.face_templates
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'leave_requests_updated_at'
  ) then
    create trigger leave_requests_updated_at
      before update on public.leave_requests
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'tasks_updated_at'
  ) then
    create trigger tasks_updated_at
      before update on public.tasks
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'daily_reports_updated_at'
  ) then
    create trigger daily_reports_updated_at
      before update on public.daily_reports
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'evaluations_updated_at'
  ) then
    create trigger evaluations_updated_at
      before update on public.evaluations
      for each row execute function public.update_updated_at_column();
  end if;

  if not exists (
    select 1 from pg_trigger where tgname = 'announcements_updated_at'
  ) then
    create trigger announcements_updated_at
      before update on public.announcements
      for each row execute function public.update_updated_at_column();
  end if;
end $$;

-- ============================================================================
-- Trigger: atur alur tugas + isi task_history otomatis
-- Aturan:
--   1. Tidak boleh mengubah status tugas yang sudah 'done'.
--   2. Perubahan in_review -> doing WAJIB diisi revision_note.
--   3. Setiap perubahan status dicatat ke task_history.
-- changed_by diambil dari session variable app.current_user_id (nullable).
-- ============================================================================
create or replace function public.enforce_task_flow_and_history()
returns trigger as $$
declare
  v_old_status public.task_status;
  v_new_status public.task_status;
  v_changed_by uuid;
begin
  v_old_status := coalesce(old.status, 'backlog'::public.task_status);
  v_new_status := coalesce(new.status, 'backlog'::public.task_status);
  v_changed_by := nullif(current_setting('app.current_user_id', true), '')::uuid;

  -- Aturan 1: tidak boleh mengubah tugas yang sudah done
  if v_old_status = 'done'::public.task_status and v_new_status is distinct from v_old_status then
    raise exception 'Tugas dengan status done tidak dapat diubah kembali.';
  end if;

  -- Aturan 2: in_review -> doing wajib revision_note
  if v_old_status = 'in_review'::public.task_status
     and v_new_status = 'doing'::public.task_status
     and (new.revision_note is null or trim(new.revision_note) = '') then
    raise exception 'revision_note wajib diisi saat mengembalikan tugas dari in_review ke doing.';
  end if;

  -- Aturan 3: catat perubahan status ke task_history
  if v_new_status is distinct from v_old_status then
    insert into public.task_history (
      task_id, from_status, to_status, changed_by, note, changed_at
    ) values (
      old.id,
      v_old_status,
      v_new_status,
      v_changed_by,
      coalesce(nullif(trim(new.revision_note), ''), null),
      now()
    );
  end if;

  return new;
end;
$$ language plpgsql;

do $$
begin
  if not exists (
    select 1 from pg_trigger where tgname = 'tasks_enforce_flow_and_history'
  ) then
    create trigger tasks_enforce_flow_and_history
      before update on public.tasks
      for each row
      execute function public.enforce_task_flow_and_history();
  end if;
end $$;

-- ============================================================================
-- Fungsi SQL: jam server dalam WIB (Asia/Jakarta)
-- ============================================================================
create or replace function public.server_time_wib()
returns timestamptz as $$
  select now() at time zone 'Asia/Jakarta';
$$ language sql stable;

-- ============================================================================
-- Indeks yang wajar
-- ============================================================================
create index if not exists idx_profiles_role on public.profiles(role);
create index if not exists idx_profiles_mentor_id on public.profiles(mentor_id);
create index if not exists idx_profiles_period_id on public.profiles(period_id);

create index if not exists idx_attendance_user_id on public.attendance(user_id);
create index if not exists idx_attendance_date on public.attendance(date);
create index if not exists idx_attendance_location_id on public.attendance(location_id);

create index if not exists idx_face_templates_user_id on public.face_templates(user_id);

create index if not exists idx_leave_requests_user_id on public.leave_requests(user_id);
create index if not exists idx_leave_requests_status on public.leave_requests(status);

create index if not exists idx_tasks_assignee_id on public.tasks(assignee_id);
create index if not exists idx_tasks_created_by on public.tasks(created_by);
create index if not exists idx_tasks_status on public.tasks(status);

create index if not exists idx_task_history_task_id on public.task_history(task_id);

create index if not exists idx_task_comments_task_id on public.task_comments(task_id);
create index if not exists idx_task_comments_user_id on public.task_comments(user_id);

create index if not exists idx_daily_reports_user_id on public.daily_reports(user_id);
create index if not exists idx_daily_reports_date on public.daily_reports(date);

create index if not exists idx_evaluations_user_id on public.evaluations(user_id);
create index if not exists idx_evaluations_evaluator_id on public.evaluations(evaluator_id);

create index if not exists idx_notifications_user_id on public.notifications(user_id);
create index if not exists idx_notifications_is_read on public.notifications(is_read);

-- ============================================================================
-- RLS: enable pada semua tabel
-- ============================================================================
alter table public.profiles enable row level security;
alter table public.internship_periods enable row level security;
alter table public.office_locations enable row level security;
alter table public.attendance enable row level security;
alter table public.face_templates enable row level security;
alter table public.leave_requests enable row level security;
alter table public.tasks enable row level security;
alter table public.task_history enable row level security;
alter table public.task_comments enable row level security;
alter table public.daily_reports enable row level security;
alter table public.evaluations enable row level security;
alter table public.notifications enable row level security;
alter table public.announcements enable row level security;

-- Helper: cek role pengguna dari auth.uid()
create or replace function public.user_role()
returns public.user_role as $$
  select role from public.profiles where id = auth.uid();
$$ language sql stable;

-- Helper: apakah auth.uid() adalah mentor dari user_id tertentu
create or replace function public.is_mentor_of(target_user_id uuid)
returns boolean as $$
  select exists (
    select 1 from public.profiles p
    where p.id = target_user_id and p.mentor_id = auth.uid()
  ) and public.user_role() = 'mentor';
$$ language sql stable;

-- ============================================================================
-- Policies: profiles
-- ============================================================================
drop policy if exists "admin_all_profiles" on public.profiles;
create policy "admin_all_profiles" on public.profiles
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_read_all_profiles" on public.profiles;
create policy "mentor_read_all_profiles" on public.profiles
  for select to authenticated
  using (public.user_role() = 'mentor');

drop policy if exists "mentor_update_own_profile" on public.profiles;
create policy "mentor_update_own_profile" on public.profiles
  for update to authenticated
  using (auth.uid() = id and public.user_role() = 'mentor')
  with check (auth.uid() = id and public.user_role() = 'mentor');

drop policy if exists "intern_read_own_profile" on public.profiles;
create policy "intern_read_own_profile" on public.profiles
  for select to authenticated
  using (auth.uid() = id);

drop policy if exists "intern_update_own_profile" on public.profiles;
create policy "intern_update_own_profile" on public.profiles
  for update to authenticated
  using (auth.uid() = id)
  with check (
    auth.uid() = id
    and public.user_role() = 'intern'
    and id = auth.uid()
  );

-- ============================================================================
-- Policies: internship_periods
-- ============================================================================
drop policy if exists "admin_all_periods" on public.internship_periods;
create policy "admin_all_periods" on public.internship_periods
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "read_periods" on public.internship_periods;
create policy "read_periods" on public.internship_periods
  for select to authenticated
  using (true);

-- ============================================================================
-- Policies: office_locations
-- ============================================================================
drop policy if exists "admin_all_office_locations" on public.office_locations;
create policy "admin_all_office_locations" on public.office_locations
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "read_office_locations" on public.office_locations;
create policy "read_office_locations" on public.office_locations
  for select to authenticated
  using (true);

-- ============================================================================
-- Policies: attendance
-- ============================================================================
drop policy if exists "admin_all_attendance" on public.attendance;
create policy "admin_all_attendance" on public.attendance
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_manage_intern_attendance" on public.attendance;
create policy "mentor_manage_intern_attendance" on public.attendance
  for all to authenticated
  using (public.user_role() = 'mentor' and public.is_mentor_of(user_id))
  with check (public.user_role() = 'mentor' and public.is_mentor_of(user_id));

drop policy if exists "intern_own_attendance" on public.attendance;
create policy "intern_own_attendance" on public.attendance
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Policies: face_templates
-- ============================================================================
drop policy if exists "admin_all_face_templates" on public.face_templates;
create policy "admin_all_face_templates" on public.face_templates
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_read_intern_face_templates" on public.face_templates;
create policy "mentor_read_intern_face_templates" on public.face_templates
  for select to authenticated
  using (public.user_role() = 'mentor' and public.is_mentor_of(user_id));

drop policy if exists "intern_own_face_templates" on public.face_templates;
create policy "intern_own_face_templates" on public.face_templates
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Policies: leave_requests
-- ============================================================================
drop policy if exists "admin_all_leave_requests" on public.leave_requests;
create policy "admin_all_leave_requests" on public.leave_requests
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_manage_intern_leave" on public.leave_requests;
create policy "mentor_manage_intern_leave" on public.leave_requests
  for all to authenticated
  using (public.user_role() = 'mentor' and public.is_mentor_of(user_id))
  with check (public.user_role() = 'mentor' and public.is_mentor_of(user_id));

drop policy if exists "intern_own_leave_requests" on public.leave_requests;
create policy "intern_own_leave_requests" on public.leave_requests
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Policies: tasks
-- ============================================================================
drop policy if exists "admin_all_tasks" on public.tasks;
create policy "admin_all_tasks" on public.tasks
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_tasks" on public.tasks;
create policy "mentor_tasks" on public.tasks
  for all to authenticated
  using (
    public.user_role() = 'mentor'
    and (created_by = auth.uid() or assignee_id in (
      select id from public.profiles where mentor_id = auth.uid()
    ))
  )
  with check (
    public.user_role() = 'mentor'
    and created_by = auth.uid()
  );

drop policy if exists "intern_tasks" on public.tasks;
create policy "intern_tasks" on public.tasks
  for select to authenticated
  using (
    public.user_role() = 'intern'
    and (assignee_id = auth.uid() or created_by = auth.uid())
  );

drop policy if exists "intern_update_own_task_status" on public.tasks;
create policy "intern_update_own_task_status" on public.tasks
  for update to authenticated
  using (
    public.user_role() = 'intern'
    and assignee_id = auth.uid()
    and status <> 'done'::public.task_status
  )
  with check (
    public.user_role() = 'intern'
    and assignee_id = auth.uid()
    and status <> 'done'::public.task_status
  );

-- ============================================================================
-- Policies: task_history
-- ============================================================================
drop policy if exists "admin_all_task_history" on public.task_history;
create policy "admin_all_task_history" on public.task_history
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "read_related_task_history" on public.task_history;
create policy "read_related_task_history" on public.task_history
  for select to authenticated
  using (
    exists (
      select 1 from public.tasks t where t.id = task_id
      and (t.created_by = auth.uid() or t.assignee_id = auth.uid())
    )
    or public.user_role() = 'mentor'
  );

-- ============================================================================
-- Policies: task_comments
-- ============================================================================
drop policy if exists "admin_all_task_comments" on public.task_comments;
create policy "admin_all_task_comments" on public.task_comments
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "manage_related_task_comments" on public.task_comments;
create policy "manage_related_task_comments" on public.task_comments
  for all to authenticated
  using (
    exists (
      select 1 from public.tasks t where t.id = task_id
      and (t.created_by = auth.uid() or t.assignee_id = auth.uid())
    )
  )
  with check (
    auth.uid() = user_id
    and exists (
      select 1 from public.tasks t where t.id = task_id
      and (t.created_by = auth.uid() or t.assignee_id = auth.uid())
    )
  );

-- ============================================================================
-- Policies: daily_reports
-- ============================================================================
drop policy if exists "admin_all_daily_reports" on public.daily_reports;
create policy "admin_all_daily_reports" on public.daily_reports
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_manage_intern_daily_reports" on public.daily_reports;
create policy "mentor_manage_intern_daily_reports" on public.daily_reports
  for all to authenticated
  using (public.user_role() = 'mentor' and public.is_mentor_of(user_id))
  with check (public.user_role() = 'mentor' and public.is_mentor_of(user_id));

drop policy if exists "intern_own_daily_reports" on public.daily_reports;
create policy "intern_own_daily_reports" on public.daily_reports
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Policies: evaluations
-- ============================================================================
drop policy if exists "admin_all_evaluations" on public.evaluations;
create policy "admin_all_evaluations" on public.evaluations
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "mentor_manage_own_evaluations" on public.evaluations;
create policy "mentor_manage_own_evaluations" on public.evaluations
  for all to authenticated
  using (public.user_role() = 'mentor' and evaluator_id = auth.uid())
  with check (public.user_role() = 'mentor' and evaluator_id = auth.uid());

drop policy if exists "intern_read_own_evaluations" on public.evaluations;
create policy "intern_read_own_evaluations" on public.evaluations
  for select to authenticated
  using (public.user_role() = 'intern' and user_id = auth.uid());

-- ============================================================================
-- Policies: notifications
-- ============================================================================
drop policy if exists "admin_all_notifications" on public.notifications;
create policy "admin_all_notifications" on public.notifications
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "own_notifications" on public.notifications;
create policy "own_notifications" on public.notifications
  for all to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ============================================================================
-- Policies: announcements
-- ============================================================================
drop policy if exists "admin_all_announcements" on public.announcements;
create policy "admin_all_announcements" on public.announcements
  for all to authenticated
  using (public.user_role() = 'admin')
  with check (public.user_role() = 'admin');

drop policy if exists "read_announcements" on public.announcements;
create policy "read_announcements" on public.announcements
  for select to authenticated
  using (true);

-- ============================================================================
-- Storage: bucket privat + policy per user (prefix user_id/)
-- ============================================================================
insert into storage.buckets (id, name, public)
values ('attendance-photos', 'attendance-photos', false),
       ('report-photos', 'report-photos', false),
       ('task-files', 'task-files', false),
       ('leave-attachments', 'leave-attachments', false)
on conflict (id) do nothing;

do $$
declare b record;
begin
  for b in select id from storage.buckets where id in (
    'attendance-photos','report-photos','task-files','leave-attachments'
  ) loop
    execute format(
      $f$
      drop policy if exists %I on storage.objects;
      create policy %I on storage.objects
        for all to authenticated
        using (bucket_id = %L and auth.uid()::text = (storage.foldername(name))[1])
        with check (bucket_id = %L and auth.uid()::text = (storage.foldername(name))[1]);
      $f$,
      'user_' || b.id || '_own',
      'user_' || b.id || '_own',
      b.id, b.id
    );
  end loop;
end $$;

-- Komentar dokumentasi
comment on function public.server_time_wib() is 'Mengembalikan jam server saat ini dalam zona waktu WIB (Asia/Jakarta).';
comment on trigger tasks_enforce_flow_and_history on public.tasks is 'Menegakkan atur alur tugas (tolak ubah done, wajib revision_note in_review->doing) dan mengisi task_history otomatis.';