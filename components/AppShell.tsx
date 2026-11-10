'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import {
  LayoutDashboard,
  Clock,
  FileText,
  CheckSquare,
  ClipboardList,
  Award,
  Megaphone,
  LogOut,
} from 'lucide-react'
import { cn } from '@/lib/utils'
import { createClient } from '@/lib/supabase/browser'
import { useRouter } from 'next/navigation'
import type { UserRole } from '@/lib/auth'

export type MenuItem = {
  label: string
  href: string
  icon: React.ComponentType<{ className?: string }>
  roles: UserRole[]
}

export const menuItems: MenuItem[] = [
  { label: 'Dashboard', href: '/dashboard', icon: LayoutDashboard, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Absensi', href: '/attendance', icon: Clock, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Izin', href: '/leave', icon: FileText, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Tugas', href: '/tasks', icon: CheckSquare, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Laporan Harian', href: '/daily-reports', icon: ClipboardList, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Penilaian', href: '/evaluations', icon: Award, roles: ['admin', 'mentor', 'intern'] },
  { label: 'Pengumuman', href: '/announcements', icon: Megaphone, roles: ['admin', 'mentor', 'intern'] },
]

export function getMenuForRole(role: UserRole) {
  // All roles see all menu items as per spec; Penilaian visible to all in menu list given
  return menuItems.filter((item) => item.roles.includes(role))
}

export function AppShell({
  children,
  userName,
  userRole,
}: {
  children: React.ReactNode
  userName: string
  userRole: UserRole
}) {
  const pathname = usePathname()
  const router = useRouter()
  const items = getMenuForRole(userRole)

  async function handleLogout() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.replace('/login')
  }

  return (
    <div className="flex h-dvh flex-col md:flex-row bg-zinc-50 dark:bg-zinc-950">
      {/* Sidebar desktop */}
      <aside className="hidden md:flex md:w-64 md:flex-col border-r border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900">
        <div className="h-14 flex items-center px-4 border-b border-zinc-200 dark:border-zinc-800">
          <span className="font-bold text-lg">Magang Hub</span>
        </div>
        <nav className="flex-1 overflow-y-auto p-3 space-y-1">
          {items.map((item) => {
            const active = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href))
            const Icon = item.icon
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                  active
                    ? 'bg-zinc-900 text-white dark:bg-zinc-100 dark:text-zinc-900'
                    : 'text-zinc-700 hover:bg-zinc-100 dark:text-zinc-300 dark:hover:bg-zinc-800'
                )}
              >
                <Icon className="size-4" />
                {item.label}
              </Link>
            )
          })}
        </nav>
        <div className="p-3 border-t border-zinc-200 dark:border-zinc-800">
          <button
            onClick={handleLogout}
            className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium text-red-600 hover:bg-red-50 dark:hover:bg-red-950/30"
          >
            <LogOut className="size-4" />
            Keluar
          </button>
        </div>
      </aside>

      {/* Main content */}
      <div className="flex flex-1 flex-col min-w-0">
        <header className="h-14 flex items-center justify-between px-4 border-b border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900">
          <span className="font-semibold md:hidden">Magang Hub</span>
          <div className="ml-auto flex flex-col items-end">
            <span className="text-sm font-medium leading-tight">{userName}</span>
            <span className="text-xs text-zinc-500 capitalize">{userRole}</span>
          </div>
        </header>
        <main className="flex-1 overflow-y-auto p-4 md:p-6 pb-20 md:pb-6">
          {children}
        </main>
      </div>

      {/* Bottom nav mobile */}
      <nav className="md:hidden fixed bottom-0 inset-x-0 z-30 border-t border-zinc-200 dark:border-zinc-800 bg-white dark:bg-zinc-900">
        <div className="grid grid-cols-4 gap-1 p-1">
          {items.slice(0, 4).map((item) => {
            const active = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href))
            const Icon = item.icon
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex flex-col items-center justify-center gap-1 rounded-md py-2 text-[10px]',
                  active ? 'text-zinc-900 dark:text-white font-medium' : 'text-zinc-500'
                )}
              >
                <Icon className="size-5" />
                <span className="truncate max-w-full px-1">{item.label}</span>
              </Link>
            )
          })}
        </div>
        <div className="grid grid-cols-3 gap-1 p-1 pt-0">
          {items.slice(4).map((item) => {
            const active = pathname === item.href || (item.href !== '/dashboard' && pathname.startsWith(item.href))
            const Icon = item.icon
            return (
              <Link
                key={item.href}
                href={item.href}
                className={cn(
                  'flex flex-col items-center justify-center gap-1 rounded-md py-2 text-[10px]',
                  active ? 'text-zinc-900 dark:text-white font-medium' : 'text-zinc-500'
                )}
              >
                <Icon className="size-5" />
                <span className="truncate max-w-full px-1">{item.label}</span>
              </Link>
            )
          })}
          <button
            onClick={handleLogout}
            className="flex flex-col items-center justify-center gap-1 rounded-md py-2 text-[10px] text-red-600"
          >
            <LogOut className="size-5" />
            <span>Keluar</span>
          </button>
        </div>
      </nav>
    </div>
  )
}
