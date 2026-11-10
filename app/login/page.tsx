'use client'

import { useActionState } from 'react'
import { signInAction } from '@/lib/auth-actions'
import { Button } from '@/components/ui/button'
import { Mail, Lock, AlertCircle } from 'lucide-react'

export default function LoginPage() {
  const [state, formAction, isPending] = useActionState(signInAction, { error: null } as { error: string | null } | null)

  return (
    <div className="min-h-screen flex items-center justify-center bg-zinc-100 dark:bg-zinc-900 px-4">
      <div className="w-full max-w-md bg-background border border-zinc-200 dark:border-zinc-800 rounded-xl shadow-sm p-6 sm:p-8">
        <div className="mb-6 flex items-center gap-2">
          <div className="w-8 h-8 rounded bg-primary text-primary-foreground flex items-center justify-center text-lg">
            M
          </div>
          <span className="text-xl font-bold tracking-tight">Magang Hub</span>
        </div>

        <h2 className="mb-6 text-lg font-semibold">Masuk</h2>

        {state?.error && (
          <div className="mb-4 rounded-md bg-red-50 dark:bg-red-500/10 p-3 text-sm text-red-600 dark:text-red-400 border border-red-100 dark:border-red-500/30 flex items-center gap-2">
            <AlertCircle size={16} />
            {state.error}
          </div>
        )}

        <form action={formAction} className="space-y-4">
          <div className="space-y-2">
            <label htmlFor="email" className="text-sm font-medium text-foreground">
              Email
            </label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground size-4" />
              <input
                id="email"
                name="email"
                type="email"
                autoComplete="email"
                required
                disabled={isPending}
                className="w-full h-10 pl-10 pr-4 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-background text-foreground placeholder:text-zinc-500 dark:placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 disabled:opacity-70 disabled:cursor-not-allowed"
                placeholder="email@magang.test"
              />
            </div>
          </div>

          <div className="space-y-2">
            <label htmlFor="password" className="text-sm font-medium text-foreground">
              Kata Sandi
            </label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground size-4" />
              <input
                id="password"
                name="password"
                type="password"
                autoComplete="current-password"
                required
                disabled={isPending}
                className="w-full h-10 pl-10 pr-4 rounded-lg border border-zinc-300 dark:border-zinc-700 bg-background text-foreground placeholder:text-zinc-500 dark:placeholder:text-zinc-500 focus:outline-none focus:ring-2 focus:ring-zinc-900 dark:focus:ring-zinc-100 disabled:opacity-70 disabled:cursor-not-allowed"
              />
            </div>
          </div>

          <Button type="submit" disabled={isPending} className="w-full h-11">
            {isPending ? 'Memproses…' : 'Masuk'}
          </Button>
        </form>

        <div className="mt-6 rounded-md bg-zinc-50 dark:bg-zinc-800/50 p-3 text-xs text-zinc-600 dark:text-zinc-400">
          <p className="font-medium mb-1">
            Akun seed (kata sandi: <code className="font-mono">Magang123!</code>)
          </p>
          <ul className="space-y-0.5">
            <li>admin@magang.test — Admin</li>
            <li>mentor@magang.test — Mentor</li>
            <li>intern1@magang.test — Intern</li>
          </ul>
        </div>
      </div>
    </div>
  )
}
