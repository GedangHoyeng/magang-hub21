import { Badge } from '@/components/ui/badge'

export function StatusBadge({ variant }: { variant?: 'present' | 'late' | 'absent' | 'leave' | 'sick' | 'pending' | 'approved' | 'rejected' | 'default' }) {
  const map: Record<string, { variant: 'default' | 'secondary' | 'destructive' | 'outline'; label: string }> = {
    present: { variant: 'default', label: 'Hadir' },
    late: { variant: 'outline', label: 'Terlambat' },
    absent: { variant: 'destructive', label: 'Alpha' },
    leave: { variant: 'secondary', label: 'Izin' },
    sick: { variant: 'secondary', label: 'Sakit' },
    pending: { variant: 'secondary', label: 'Menunggu' },
    approved: { variant: 'default', label: 'Disetujui' },
    rejected: { variant: 'destructive', label: 'Ditolak' },
    default: { variant: 'default', label: '-' },
  }
  const item = map[variant ?? 'default']
  return (
    <Badge variant={item.variant} className="capitalize">
      {item.label}
    </Badge>
  )
}
