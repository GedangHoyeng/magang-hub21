-- ============================================================================
-- PATCH 01: perbaikan keamanan & bug (jalankan SETELAH schema.sql)
-- Idempoten. Jangan jalankan ulang schema.sql setelah patch ini.
-- ============================================================================

-- 1. Fungsi helper -> SECURITY DEFINER (memutus rekursi RLS) ------------------
create or replace function public.user_role()
returns public.user_role
language sql stable security definer set search_path = public
as $$ select role from public.profiles where id = auth.uid(); $$;

create or replace function public.is_mentor_of(target_user_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.profiles p
                 where p.id = target_user_id and p.mentor_id = auth.uid())
     and exists (select 1 from public.profiles m
                 where m.id = auth.uid() and m.role = 'mentor');
$$;

create or replace function public.my_mentor_id()
returns uuid
language sql stable security definer set search_path = public
as $$ select mentor_id from public.profiles where id = auth.uid(); $$;

-- 2. Profiles: kunci kolom sensitif + peserta boleh melihat pembimbingnya ------
create or replace function public.protect_profile_columns()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare v_role public.user_role;
begin
  if auth.uid() is null then return new; end if;  -- service role / SQL editor
  select role into v_role from public.profiles where id = auth.uid();
  if v_role = 'admin' then return new; end if;
  if new.role is distinct from old.role
     or new.mentor_id is distinct from old.mentor_id
     or new.period_id is distinct from old.period_id
     or new.is_active is distinct from old.is_active then
    raise exception 'Kolom role, mentor, periode, dan status aktif hanya bisa diubah admin.';
  end if;
  return new;
end $$;

drop trigger if exists profiles_protect_columns on public.profiles;
create trigger profiles_protect_columns
  before update on public.profiles
  for each row execute function public.protect_profile_columns();

drop policy if exists "intern_read_my_mentor" on public.profiles;
create policy "intern_read_my_mentor" on public.profiles
  for select to authenticated
  using (id = public.my_mentor_id());

-- 3. Jam server WIB yang benar -------------------------------------------------
drop function if exists public.server_time_wib();
create function public.server_time_wib()
returns timestamp
language sql stable
as $$ select (now() at time zone 'Asia/Jakarta'); $$;

create or replace function public.today_wib()
returns date
language sql stable
as $$ select (now() at time zone 'Asia/Jakarta')::date; $$;

-- 4. Trigger alur tugas: aturan per role + riwayat otomatis ---------------------
create or replace function public.enforce_task_flow_and_history()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  v_uid uuid := auth.uid();
  v_role public.user_role;
  v_forward boolean;
begin
  if v_uid is not null then
    select role into v_role from public.profiles where id = v_uid;
    if v_role is null then
      raise exception 'Profil pengguna tidak ditemukan.';
    end if;
  end if;

  if v_role = 'intern' then
    if new.assignee_id is distinct from old.assignee_id
       or new.created_by is distinct from old.created_by
       or new.revision_note is distinct from old.revision_note then
      raise exception 'Peserta tidak boleh mengubah penerima tugas, pembuat kartu, atau catatan revisi.';
    end if;
  end if;

  if new.status is distinct from old.status then
    if old.status = 'done' then
      raise exception 'Kartu yang sudah Done bersifat final dan tidak boleh dipindahkan lagi.';
    end if;

    v_forward :=
         (old.status = 'backlog' and new.status in ('todo', 'doing'))
      or (old.status = 'todo'    and new.status = 'doing')
      or (old.status = 'doing'   and new.status = 'in_review');

    if v_role = 'intern' then
      if not v_forward then
        raise exception 'Peserta hanya boleh memindahkan kartu maju (BackLog > ToDo > Doing > InReview). Revisi dan Done hanya oleh pembimbing.';
      end if;
    elsif v_role is not null then
      if not (v_forward or (old.status = 'in_review' and new.status in ('doing', 'done'))) then
        raise exception 'Perpindahan % -> % tidak diperbolehkan.', old.status, new.status;
      end if;
    end if;

    if old.status = 'in_review' and new.status = 'doing'
       and coalesce(trim(new.revision_note), '') = '' then
      raise exception 'Catatan revisi wajib diisi saat mengembalikan kartu dari InReview ke Doing.';
    end if;

    insert into public.task_history (task_id, from_status, to_status, changed_by, note, changed_at)
    values (old.id, old.status, new.status, v_uid,
            nullif(trim(new.revision_note), ''), now());
  end if;

  return new;
end $$;

-- 5. Policy tugas ---------------------------------------------------------------
drop policy if exists "mentor_tasks" on public.tasks;
create policy "mentor_tasks" on public.tasks
  for all to authenticated
  using (public.user_role() = 'mentor'
         and (created_by = auth.uid() or public.is_mentor_of(assignee_id)))
  with check (public.user_role() = 'mentor'
         and (created_by = auth.uid() or public.is_mentor_of(assignee_id)));

drop policy if exists "intern_insert_own_backlog" on public.tasks;
create policy "intern_insert_own_backlog" on public.tasks
  for insert to authenticated
  with check (public.user_role() = 'intern'
              and assignee_id = auth.uid()
              and created_by = auth.uid()
              and status = 'backlog');

-- 6. Izin: peserta tidak boleh menyetujui izinnya sendiri ------------------------
drop policy if exists "intern_own_leave_requests" on public.leave_requests;
drop policy if exists "intern_read_own_leave" on public.leave_requests;
drop policy if exists "intern_insert_own_leave" on public.leave_requests;
drop policy if exists "intern_edit_pending_leave" on public.leave_requests;
drop policy if exists "intern_cancel_pending_leave" on public.leave_requests;

create policy "intern_read_own_leave" on public.leave_requests
  for select to authenticated using (auth.uid() = user_id);

create policy "intern_insert_own_leave" on public.leave_requests
  for insert to authenticated
  with check (auth.uid() = user_id and status = 'pending'
              and reviewed_by is null and reviewed_at is null and review_note is null);

create policy "intern_edit_pending_leave" on public.leave_requests
  for update to authenticated
  using (auth.uid() = user_id and status = 'pending')
  with check (auth.uid() = user_id and status = 'pending'
              and reviewed_by is null and reviewed_at is null and review_note is null);

create policy "intern_cancel_pending_leave" on public.leave_requests
  for delete to authenticated
  using (auth.uid() = user_id and status = 'pending');

-- 7. Absensi, laporan harian, template wajah: peserta hanya BACA ----------------
-- (penulisan dilakukan server dengan service-role setelah validasi)
drop policy if exists "intern_own_attendance" on public.attendance;
drop policy if exists "intern_read_own_attendance" on public.attendance;
create policy "intern_read_own_attendance" on public.attendance
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "intern_own_daily_reports" on public.daily_reports;
drop policy if exists "intern_read_own_daily_reports" on public.daily_reports;
create policy "intern_read_own_daily_reports" on public.daily_reports
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists "intern_own_face_templates" on public.face_templates;
drop policy if exists "intern_read_own_face_templates" on public.face_templates;
create policy "intern_read_own_face_templates" on public.face_templates
  for select to authenticated using (auth.uid() = user_id);

-- 8. Storage: pembimbing/admin bisa melihat file, file tugas bisa dibaca semua ---
drop policy if exists "staff_read_all_files" on storage.objects;
create policy "staff_read_all_files" on storage.objects
  for select to authenticated
  using (bucket_id in ('attendance-photos','report-photos','task-files','leave-attachments')
         and public.user_role() in ('admin', 'mentor'));

drop policy if exists "authenticated_read_task_files" on storage.objects;
create policy "authenticated_read_task_files" on storage.objects
  for select to authenticated
  using (bucket_id = 'task-files');