import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { getCurrentUser } from '@/lib/auth'
import { AppShell } from '@/components/AppShell'

export default function AppLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <Suspense fallback={<div className="h-screen flex items-center justify-center">Memuat…</div>}>
      <AppLayoutInner>{children}</AppLayoutInner>
    </Suspense>
  )
}

async function AppLayoutInner({ children }: { children: React.ReactNode }) {
  const currentUser = await getCurrentUser()
  if (!currentUser) redirect('/login')

  return (
    <AppShell
      userName={currentUser.full_name ?? currentUser.email ?? 'User'}
      userRole={currentUser.role}
    >
      {children}
    </AppShell>
  )
}

