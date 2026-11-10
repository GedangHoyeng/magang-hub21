import { PlaceholderPage } from '@/components/PlaceholderPage'
import { PageHeader } from '@/components/PageHeader'
import { requireRole } from '@/lib/auth'

export default async function AdminPage() {
  await requireRole(['admin'])
  return (
    <>
      <PageHeader title="Admin" subtitle="Kelola pengguna dan periode magang" />
      <PlaceholderPage title="Admin" subtitle="Halaman admin akan diisi oleh tim terkait." />
    </>
  )
}
