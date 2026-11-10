import { Suspense } from 'react'
import { redirect } from 'next/navigation'
import { getCurrentUser, userDefaultRoute } from '@/lib/auth'

function Loading() {
  return <div className="h-screen flex items-center justify-center">Memuat…</div>
}

export default function AppIndexPage() {
  return (
    <Suspense fallback={<Loading />}>
      <AppIndexInner />
    </Suspense>
  )
}

async function AppIndexInner() {
  const user = await getCurrentUser()
  if (!user) redirect('/login')
  redirect(userDefaultRoute(user.role))
  return null
}
