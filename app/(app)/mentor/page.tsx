import { PlaceholderPage } from '@/components/PlaceholderPage'
import { PageHeader } from '@/components/PageHeader'
import { requireRole } from '@/lib/auth'

export default async function MentorPage() {
  await requireRole(['mentor', 'admin'])
  return (
    <>
      <PageHeader title="Mentor" subtitle="Manajemen magang bimbingan" />
      <PlaceholderPage title="Mentor" subtitle="Halaman mentor akan diisi oleh tim terkait." />
    </>
  )
}
