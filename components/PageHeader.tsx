'use client'

import { useRouter } from 'next/navigation'
import { LogOut } from 'lucide-react'
import { createClient } from '@/lib/supabase/browser'
import { Button } from '@/components/ui/button'

interface PageHeaderProps {
  title: string
  subtitle?: string
  userName?: string | null
  userRole?: string | null
}

export function PageHeader({ title, subtitle, userName, userRole }: PageHeaderProps) {
  const router = useRouter()

  async function handleLogout() {
    const supabase = createClient()
    await supabase.auth.signOut()
    router.replace('/login')
  }

  return (
    <header className="flex flex-col md:flex-row md:items-center justify-between gap-4 px-4 py-3 border-b border-zinc-200 dark:border-zinc-800 bg-background sticky top-0 z-20">
      <div className="flex flex-col gap-1 md:gap-0">
        <h1 className="text-lg font-semibold text-foreground">{title}</h1>
        {subtitle && <p className="text-sm text-muted-foreground">{subtitle}</p>}
      </div>
      <div className="flex items-center gap-3">
        {(userName || userRole) && (
          <div className="flex flex-col text-right">
            <span className="text-sm font-medium">{userName ?? '-'}</span>
            <span className="text-xs text-muted-foreground">{userRole ?? ''}</span>
          </div>
        )}
        <Button variant="outline" size="sm" onClick={handleLogout}>
          <LogOut className="mr-2 h-4 w-4" />
          Keluar
        </Button>
      </div>
    </header>
  )
}
