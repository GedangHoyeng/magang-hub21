# Magang Hub

Sistem manajemen magang minimal berbasis **Next.js (App Router)** + **Supabase Auth**.

## Fitur (versi minimal)
- Login email + password (Supabase Auth) dan logout
- Proteksi route berbasis role via `proxy.ts` (Next.js 16)
  - `admin` → `/admin`
  - `mentor` → `/mentor`
  - `intern` → `/dashboard`
- App shell responsif: sidebar di desktop, bottom navigation di mobile
- Menu: Dashboard, Absensi, Izin, Tugas, Laporan Harian, Penilaian, Pengumuman (placeholder)
- Komponen bersama: `PageHeader`, `StatusBadge`, `EmptyState`, `ConfirmDialog`
- Helper auth: `getCurrentUser()`, `requireRole()` di `lib/auth.ts`

## Prasyarat
- Node.js 20+
- npm
- Project Supabase (database + Auth) dengan schema yang sudah diterapkan

## Cara clone
```bash
git clone <url-repo>
cd magang-hub21
```

## Konfigurasi `.env.local`
Salin template environment, lalu isi kredensial Supabase:

```bash
cp .env.example .env.local
```

Isi nilai berikut di `.env.local`:
```env
NEXT_PUBLIC_SUPABASE_URL=<url-project-supabase>
NEXT_PUBLIC_SUPABASE_ANON_KEY=<anon-key-supabase>
SUPABASE_SERVICE_ROLE_KEY=<service-role-key-supabase>  # diperlukan untuk seed
```

> `SUPABASE_SERVICE_ROLE_KEY` hanya dipakai untuk skrip seed/admin di server. Jangan diekspos ke klien.

## Instalasi & menjalankan
```bash
npm install
npm run dev
```

Buka [http://localhost:3000](http://localhost:3000). Pengguna yang belum login akan diarahkan ke `/login`.

## Seed data & akun uji
Jika database/schema sudah siap, jalankan seed untuk membuat periode, lokasi, akun, dan data demo:

```bash
npm run seed
```

Skrip seed: `scripts/seed.ts` (butuh `SUPABASE_SERVICE_ROLE_KEY` di `.env.local`).

### Daftar akun seed
Semua akun menggunakan kata sandi: **`Magang123!`**

| Role   | Email                 | Nama          | Catatan                          |
|--------|-----------------------|---------------|----------------------------------|
| Admin  | `admin@magang.test`   | Admin Magang  | Redirect ke `/admin` setelah login |
| Mentor | `mentor@magang.test`  | Mas Hanif     | Redirect ke `/mentor` setelah login |
| Intern | `intern1@magang.test` | Intern Satu   | Redirect ke `/dashboard` setelah login |
| Intern | `intern2@magang.test` | Intern Dua    | Dibimbing Mas Hanif               |
| Intern | `intern3@magang.test` | Intern Tiga   | Dibimbing Mas Hanif               |
| Intern | `intern4@magang.test` | Intern Empat  | Dibimbing Mas Hanif               |

## Skrip yang tersedia
- `npm run dev` — jalankan development server
- `npm run build` — build produksi
- `npm run start` — jalankan hasil build
- `npm run lint` — linting (ESLint)
- `npm run seed` — seed akun & data demo (`tsx --env-file=.env.local scripts/seed.ts`)

## Struktur penting
- `proxy.ts` — proteksi route & redirect berbasis role (pengganti middleware di Next.js 16)
- `lib/auth.ts` — `getCurrentUser()`, `requireRole()`, tipe `UserRole`
- `lib/auth-actions.ts` — Server Actions: `signInAction`, `signOutAction`
- `app/login/page.tsx` — halaman login
- `app/(app)/...` — halaman terproteksi dalam app shell (dashboard/menu)
- `components/AppShell.tsx` — sidebar (desktop) + bottom nav (mobile)
- `components/PageHeader.tsx`, `components/StatusBadge.tsx`, `components/EmptyState.tsx`, `components/ConfirmDialog.tsx` — komponen bersama

## Catatan
- Route role khusus: `/admin`, `/mentor`, `/dashboard` (masing-masing hanya untuk role terkait).
- Halaman menu selain landing role masih berupa placeholder dan akan dilanjutkan oleh tim terkait.

