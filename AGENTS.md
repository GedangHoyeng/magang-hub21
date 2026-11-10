<!-- BEGIN:nextjs-agent-rules -->

## This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` (resolved from this file's directory; in monorepos the `next` package may not be visible from the repo root) before writing any code. Heed deprecation notices.

This block is written and re-added by `next dev` — verify at `node_modules/next/dist/server/lib/generate-agent-files.js`. Removing it from a diff only re-creates the uncommitted change; committing it with your work keeps the tree clean.

<!-- END:nextjs-agent-rules -->

KEAMANAN DATA (WAJIB):
- Peserta HANYA BOLEH MEMBACA tabel attendance, daily_reports, dan face_templates (RLS menolak tulis langsung).
- Semua penulisan ke tabel itu dilakukan di Server Action / Route Handler dengan urutan: (1) supabase.auth.getUser() untuk identitas, (2) validasi aturan bisnis (GPS, jam server, wajah, batas jam laporan), (3) tulis memakai client service-role dari lib/supabase/admin.ts.
- user_id SELALU diambil dari getUser(), tidak pernah dari input form.
- lib/supabase/admin.ts tidak boleh di-import dari file "use client" atau komponen klien.
- Menulis notifications untuk user lain (pembimbing -> peserta dan sebaliknya) juga lewat client service-role di server.
- Jam server: pakai public.server_time_wib() (timestamp tanpa zona, sudah WIB) dan public.today_wib().
- Kartu tugas: aturan perpindahan ditegakkan trigger di DB; UI hanya menampilkan pesan error-nya, jangan menduplikasi aturannya dengan cara lain.