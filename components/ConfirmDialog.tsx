'use client'

import * as React from 'react'
import { Button } from '@/components/ui/button'

interface ConfirmDialogProps {
  open: boolean
  onOpenChange: (open: boolean) => void
  title?: string
  description?: string
  confirmLabel?: string
  cancelLabel?: string
  onConfirm: () => void
  destructive?: boolean
}

export function ConfirmDialog({
  open,
  onOpenChange,
  title = 'Konfirmasi',
  description,
  confirmLabel = 'Ya, Hapus',
  cancelLabel = 'Batal',
  onConfirm,
  destructive = false,
}: ConfirmDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
          {description ? <DialogDescription>{description}</DialogDescription> : null}
        </DialogHeader>
        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            {cancelLabel}
          </Button>
          <Button
            variant={destructive ? 'destructive' : 'default'}
            onClick={() => {
              onConfirm()
              onOpenChange(false)
            }}
          >
            {confirmLabel}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  )
}

// --- Simple dialog primitives (local, minimal) ---
function Dialog({
  open,
  onOpenChange,
  children,
}: {
  open: boolean
  onOpenChange: (open: boolean) => void
  children?: React.ReactNode
}) {
  if (!open) return null
  return (
    <>
      <Backdrop onPointerDown={() => onOpenChange(false)} />
      <Container>{children}</Container>
    </>
  )
}

function Backdrop({ onPointerDown }: { onPointerDown: () => void }) {
  return (
    <div
      className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm"
      onPointerDown={onPointerDown}
    />
  )
}

function Container({ children }: { children?: React.ReactNode }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="bg-background p-6 rounded-lg border border-zinc-200 dark:border-zinc-800 shadow-xl w-full max-w-md">
        {children}
      </div>
    </div>
  )
}

function DialogContent({ children }: { children?: React.ReactNode }) {
  return <>{children}</>
}

function DialogHeader({ children }: { children?: React.ReactNode }) {
  return <div className="flex flex-col space-y-1 text-center sm:text-left">{children}</div>
}

function DialogTitle({ children }: { children?: React.ReactNode }) {
  return <h2 className="text-lg font-semibold text-foreground">{children}</h2>
}

function DialogDescription({ children }: { children?: React.ReactNode }) {
  return <p className="text-sm text-muted-foreground">{children}</p>
}

function DialogFooter({ children }: { children?: React.ReactNode }) {
  return <div className="mt-4 flex flex-row-reverse gap-2">{children}</div>
}
