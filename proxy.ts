import { createServerClient } from '@supabase/ssr'
import { NextResponse, type NextRequest } from 'next/server'

type Role = 'admin' | 'mentor' | 'intern'

const PUBLIC_PATHS = ['/login']
const DASHBOARD_ROUTE: Record<Role, string> = {
  admin: '/admin',
  mentor: '/mentor',
  intern: '/dashboard',
}

function isPublicPath(pathname: string) {
  return PUBLIC_PATHS.some((p) => pathname === p || pathname.startsWith(p + '/'))
}

export async function proxy(request: NextRequest) {
  let supabaseResponse = NextResponse.next({ request })

  const supabase = createServerClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      cookies: {
        getAll() {
          return request.cookies.getAll()
        },
        setAll(cookiesToSet) {
          cookiesToSet.forEach(({ name, value }) => request.cookies.set(name, value))
          supabaseResponse = NextResponse.next({ request })
          cookiesToSet.forEach(({ name, value, options }) =>
            supabaseResponse.cookies.set(name, value, options),
          )
        },
      },
    },
  )

  // Refresh session
  const {
    data: { user },
  } = await supabase.auth.getUser()

  const pathname = request.nextUrl.pathname

  if (!user) {
    if (!isPublicPath(pathname) && pathname !== '/') {
      const url = request.nextUrl.clone()
      url.pathname = '/login'
      return NextResponse.redirect(url)
    }
    if (pathname === '/') {
      const url = request.nextUrl.clone()
      url.pathname = '/login'
      return NextResponse.redirect(url)
    }
    return supabaseResponse
  }

  // Resolve role from profile, fallback to user_metadata
  let role: Role = (user.user_metadata?.role as Role | undefined) ?? 'intern'
  const { data: profile } = await supabase
    .from('profiles')
    .select('role')
    .eq('id', user.id)
    .maybeSingle()
  if (profile?.role) role = profile.role as Role

  const home = DASHBOARD_ROUTE[role]

  if (isPublicPath(pathname) || pathname === '/') {
    const url = request.nextUrl.clone()
    url.pathname = home
    return NextResponse.redirect(url)
  }

  // Role-gated routes
  if (pathname === '/admin' || pathname.startsWith('/admin/')) {
    if (role !== 'admin') {
      const url = request.nextUrl.clone()
      url.pathname = home
      return NextResponse.redirect(url)
    }
  }
  if (pathname === '/mentor' || pathname.startsWith('/mentor/')) {
    if (role !== 'mentor') {
      const url = request.nextUrl.clone()
      url.pathname = home
      return NextResponse.redirect(url)
    }
  }
  if (pathname === '/dashboard' || pathname.startsWith('/dashboard/')) {
    if (role !== 'intern') {
      const url = request.nextUrl.clone()
      url.pathname = home
      return NextResponse.redirect(url)
    }
  }

  return supabaseResponse
}

export const config = {
  matcher: [
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
}
