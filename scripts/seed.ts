import "dotenv/config";
import { createClient } from "@supabase/supabase-js";

const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const serviceKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;

if (!url || !serviceKey) {
  throw new Error("Missing NEXT_PUBLIC_SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
}

const supabase = createClient(url, serviceKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

const PASSWORD = "Magang123!";

type SeedUser = {
  email: string;
  full_name: string;
  role: "admin" | "mentor" | "intern";
  school_or_campus?: string;
  phone?: string;
  mentor_id?: string | null;
  period_id?: string | null;
};

async function getOrCreateUser(email: string, full_name: string): Promise<string> {
  const { data: listData, error: listErr } = await supabase.auth.admin.listUsers({
    page: 1,
    perPage: 1000,
  });
  if (listErr) throw listErr;
  const existing = listData.users.find(
    (u) => (u.email || "").toLowerCase() === email.toLowerCase(),
  );
  if (existing) {
    console.log(`  exists: ${email} -> ${existing.id}`);
    return existing.id;
  }

  const { data, error } = await supabase.auth.admin.createUser({
    email,
    password: PASSWORD,
    email_confirm: true,
    user_metadata: { full_name },
  });
  if (error) throw error;
  console.log(`  created: ${email} -> ${data.user.id}`);
  return data.user.id;
}

async function upsertProfile(user: SeedUser & { id: string }) {
  const { error } = await supabase.from("profiles").upsert(
    {
      id: user.id,
      full_name: user.full_name,
      role: user.role,
      school_or_campus: user.school_or_campus ?? null,
      phone: user.phone ?? null,
      mentor_id: user.mentor_id ?? null,
      period_id: user.period_id ?? null,
      is_active: true,
    },
    { onConflict: "id" },
  );
  if (error) throw error;
}

async function getOrCreatePeriod() {
  const { data: existing } = await supabase
    .from("internship_periods")
    .select("id")
    .eq("name", "Periode Magang 2026")
    .maybeSingle();
  if (existing?.id) {
    console.log("Period exists:", existing.id);
    return existing.id as string;
  }

  const { data, error } = await supabase
    .from("internship_periods")
    .insert({
      name: "Periode Magang 2026",
      start_date: "2026-01-05",
      end_date: "2026-06-30",
      work_start_time: "09:00",
      work_end_time: "16:00",
      late_tolerance_minutes: 15,
      report_open_time: "09:00",
      report_deadline_time: "16:00",
      trello_board_url: "https://trello.com/b/example",
    })
    .select("id")
    .single();
  if (error) throw error;
  console.log("Period created:", data.id);
  return data.id as string;
}

async function getOrCreateOfficeLocation(name: string, payload: Record<string, unknown>) {
  const { data: existing } = await supabase
    .from("office_locations")
    .select("id")
    .eq("name", name)
    .maybeSingle();
  if (existing?.id) {
    console.log(`Office exists: ${name} -> ${existing.id}`);
    return existing.id as string;
  }
  const { data, error } = await supabase
    .from("office_locations")
    .insert({ name, ...payload })
    .select("id")
    .single();
  if (error) throw error;
  console.log(`Office created: ${name} -> ${data.id}`);
  return data.id as string;
}

function formatDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

async function seedDemoData(internIds: string[], mentorId: string, locationId: string) {
  if (internIds.length === 0) return;

  const demoTitles = [
    "Setup environment project",
    "Implementasi halaman dashboard",
    "Review dokumentasi API",
    "Bugfix form absensi",
    "Optimasi query laporan",
  ];

  // Bersihkan data demo lama agar idempoten
  const { data: oldTasks } = await supabase
    .from("tasks")
    .select("id")
    .in("title", demoTitles);
  const oldTaskIds = (oldTasks ?? []).map((t) => t.id as string);
  if (oldTaskIds.length > 0) {
    await supabase.from("task_history").delete().in("task_id", oldTaskIds);
    await supabase.from("task_comments").delete().in("task_id", oldTaskIds);
    await supabase.from("tasks").delete().in("id", oldTaskIds);
  }

  const today = new Date();
  const dates = [0, 1, 2].map((i) => {
    const d = new Date(today);
    d.setDate(d.getDate() - i);
    return formatDate(d);
  });

  await supabase.from("attendance").delete().in("date", dates).in("user_id", internIds);

  const statuses: Array<"backlog" | "todo" | "doing" | "in_review" | "done"> = [
    "backlog",
    "todo",
    "doing",
    "in_review",
    "done",
  ];

  for (let i = 0; i < demoTitles.length; i++) {
    const assignee = internIds[i % internIds.length];
    const { data: task, error } = await supabase
      .from("tasks")
      .insert({
        title: demoTitles[i],
        description: `Deskripsi contoh untuk ${demoTitles[i]}.`,
        project_name: "Magang Hub",
        assignee_id: assignee,
        created_by: mentorId,
        status: statuses[i],
        priority: i % 2 === 0 ? "medium" : "high",
        start_date: formatDate(today),
        due_date: formatDate(new Date(today.getTime() + 7 * 86400000)),
      })
      .select("id")
      .single();
    if (error) throw error;

    const { error: histErr } = await supabase.from("task_history").insert({
      task_id: task.id,
      from_status: null,
      to_status: statuses[i],
      changed_by: mentorId,
      note: "Seed: status awal",
      changed_at: new Date().toISOString(),
    });
    if (histErr) throw histErr;
  }

  for (let i = 0; i < internIds.length; i++) {
    const uid = internIds[i];
    for (let j = 0; j < dates.length; j++) {
      const status: "present" | "late" = j === 1 ? "late" : "present";
      const { error } = await supabase.from("attendance").insert({
        user_id: uid,
        date: dates[j],
        status,
        location_id: locationId,
        check_in_at: `${dates[j]}T02:05:00Z`,
        check_out_at: `${dates[j]}T09:00:00Z`,
        flagged: status === "late",
        flag_reason: status === "late" ? "Terlambat (contoh seed)" : null,
      });
      if (error) throw error;
    }
  }
}

async function main() {
  console.log("Seeding Magang Hub...");

  const periodId = await getOrCreatePeriod();

  console.log("Ensuring users...");
  const adminId = await getOrCreateUser("admin@magang.test", "Admin Magang");
  const mentorId = await getOrCreateUser("mentor@magang.test", "Mas Hanif");

  const internEmails = [
    "intern1@magang.test",
    "intern2@magang.test",
    "intern3@magang.test",
    "intern4@magang.test",
  ];
  const internNames = ["Intern Satu", "Intern Dua", "Intern Tiga", "Intern Empat"];
  const internIds: string[] = [];
  for (let i = 0; i < internEmails.length; i++) {
    const id = await getOrCreateUser(internEmails[i], internNames[i]);
    internIds.push(id);
  }

  console.log("Upserting profiles...");
  await upsertProfile({
    id: adminId,
    email: "admin@magang.test",
    full_name: "Admin Magang",
    role: "admin",
    period_id: periodId,
  });
  await upsertProfile({
    id: mentorId,
    email: "mentor@magang.test",
    full_name: "Mas Hanif",
    role: "mentor",
    period_id: periodId,
  });
  for (let i = 0; i < internIds.length; i++) {
    await upsertProfile({
      id: internIds[i],
      email: internEmails[i],
      full_name: internNames[i],
      role: "intern",
      school_or_campus: "Universitas Contoh",
      mentor_id: mentorId,
      period_id: periodId,
    });
  }

  console.log("Ensuring office locations...");
  const loc1 = await getOrCreateOfficeLocation("Kantor Pusat", {
    address: "Jl. Contoh No. 1, Jakarta",
    latitude: -6.2088,
    longitude: 106.8456,
    radius_meters: 100,
    is_active: true,
  });
  await getOrCreateOfficeLocation("Kantor Cabang", {
    address: "Jl. Contoh No. 2, Bandung",
    latitude: -6.9175,
    longitude: 107.6191,
    radius_meters: 120,
    is_active: true,
  });

  console.log("Seeding demo tasks & attendance...");
  await seedDemoData(internIds, mentorId, loc1);

  console.log("Seed selesai.");
  console.log("Akun (password semua: Magang123!):");
  console.log("  admin@magang.test (admin)");
  console.log("  mentor@magang.test (mentor, Mas Hanif)");
  for (const e of internEmails) console.log(`  ${e} (intern)`);
}

main().catch((e) => {
  console.error("Seed gagal:", e);
  process.exit(1);
});
