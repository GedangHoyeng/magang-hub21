import { cache } from 'react'
import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'

export type UserRole = 'admin' | 'mentor' | 'intern'

export interface CurrentUser {
  id: string
  email: string | null
  full_name: string | null
  role: UserRole
  mentor_id: string | null
  period_id: string | null
  is_active: boolean
}

export function userDefaultRoute(role: UserRole): string {
  switch (role) {
    case 'admin': return '/admin'
    case 'mentor': return '/mentor'
    case 'intern': return '/dashboard'
    default: return '/dashboard'
  }
}

export const getCurrentUser = cache(async (): Promise<CurrentUser | null> => {
  const supabase = await createClient()

  const { data: { user }, error } = await supabase.auth.getUser()
  if (error || !user) return null

  const { data: profile } = await supabase
    .from('profiles')
    .select('full_name, role, mentor_id, period_id, is_active')
    .eq('id', user.id)
    .maybeSingle()

  if (!profile) return null

  return {
    id: user.id,
    email: user.email ?? null,
    full_name: (profile.full_name as string | null) ?? null,
    role: profile.role as UserRole,
    mentor_id: (profile.mentor_id as string | null) ?? null,
    period_id: (profile.period_id as string | null) ?? null,
    is_active: (profile.is_active as boolean) ?? true,
  }
})

export async function requireRole(allowedRoles: UserRole[]): Promise<CurrentUser> {
  const user = await getCurrentUser()
  if (!user) {
    redirect('/login')
  }
  if (!allowedRoles.includes(user.role)) {
    redirect(userDefaultRoute(user.role))
  }
  return user
}
