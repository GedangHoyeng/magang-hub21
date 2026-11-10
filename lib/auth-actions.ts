'use server'

import { redirect } from 'next/navigation'
import { createClient } from '@/lib/supabase/server'
import type { UserRole } from '@/lib/auth'
import { userDefaultRoute } from '@/lib/auth'

export async function signInAction(
  _prevState: { error: string | null } | null,
  formData: FormData,
): Promise<{ error: string | null }> {
  const email = String(formData.get('email') ?? '').trim()
  const password = String(formData.get('password') ?? '')
  const supabase = await createClient()

  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error || !data.user) {
    return { error: error?.message ?? 'Gagal masuk. Periksa email dan kata sandi.' }
  }

  let role: UserRole = (data.user.user_metadata?.role as UserRole | undefined) ?? 'intern'
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', data.user.id)
    .maybeSingle()
  if (profile?.role) {
    role = profile.role as UserRole
  }

  redirect(userDefaultRoute(role))
}

export async function signOutAction(): Promise<void> {
  const supabase = await createClient()
  await supabase.auth.signOut()
  redirect('/login')
}
