import { useEffect, useRef, useState } from 'react'
import { exportCSV, exportXLSX } from '../../lib/exportFatura'
import { S } from './estilos'

interface TxView {
  id: string
  date: string
  memo: string
  amount: number
  category: string | null
  auto: boolean
}

// Port 1:1 do ExportMenu original — distingue "filtrados (N)" vs "todos (N)";
// comportamento preservado (contrato #14): busca ativa + "exportar todos"
// ignora a busca, como no app antigo.
export default function ExportMenu({
  transactions,
  filtered,
  filter,
}: {
  transactions: TxView[]
  filtered: TxView[]
  filter: string
}) {
  const [open, setOpen] = useState(false)
  const ref = useRef<HTMLDivElement>(null)
  useEffect(() => {
    const h = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('mousedown', h)
    return () => document.removeEventListener('mousedown', h)
  }, [])

  const isFiltered = filter !== 'all'
  const exportTarget = isFiltered ? filtered : transactions
  const label = isFiltered ? `filtrados (${filtered.length})` : `todos (${transactions.length})`

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button
        onClick={() => setOpen((o) => !o)}
        disabled={transactions.length === 0}
        style={{ ...S.newBtn, background: '#0f172a', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', gap: 6, opacity: transactions.length === 0 ? 0.4 : 1, cursor: transactions.length === 0 ? 'not-allowed' : 'pointer' }}
      >
        <span>⬇ Exportar</span>
        <span style={{ fontSize: 9, opacity: 0.6 }}>▼</span>
      </button>
      {open && (
        <div style={{ position: 'absolute', top: 'calc(100% + 6px)', right: 0, background: '#fff', border: '1px solid #e2e8f0', borderRadius: 10, boxShadow: '0 8px 28px rgba(0,0,0,0.13)', minWidth: 230, zIndex: 9999, overflow: 'hidden' }}>
          <div style={{ padding: '10px 14px 6px', fontSize: 11, color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Exportar {label}</div>
          {[
            { icon: '📊', label: 'Excel (.xlsx)', sub: 'Abre direto no Excel', action: () => { exportXLSX(exportTarget); setOpen(false) } },
            { icon: '📄', label: 'CSV (.csv)', sub: 'Compatível com qualquer app', action: () => { exportCSV(exportTarget); setOpen(false) } },
          ].map(({ icon, label: l, sub, action }) => (
            <div
              key={l}
              onClick={action}
              style={{ padding: '10px 14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10 }}
              onMouseEnter={(e) => (e.currentTarget.style.background = '#f8fafc')}
              onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
            >
              <span style={{ fontSize: 20 }}>{icon}</span>
              <div>
                <div style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>{l}</div>
                <div style={{ fontSize: 11, color: '#94a3b8' }}>{sub}</div>
              </div>
            </div>
          ))}
          {isFiltered && (
            <>
              <div style={{ height: 1, background: '#f1f5f9', margin: '4px 0' }} />
              <div style={{ padding: '6px 14px 4px', fontSize: 11, color: '#94a3b8', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.06em' }}>Exportar todos ({transactions.length})</div>
              {[
                { icon: '📊', label: 'Excel (.xlsx)', action: () => { exportXLSX(transactions); setOpen(false) } },
                { icon: '📄', label: 'CSV (.csv)', action: () => { exportCSV(transactions); setOpen(false) } },
              ].map(({ icon, label: l, action }) => (
                <div
                  key={`all-${l}`}
                  onClick={action}
                  style={{ padding: '8px 14px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 10 }}
                  onMouseEnter={(e) => (e.currentTarget.style.background = '#f8fafc')}
                  onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                >
                  <span style={{ fontSize: 18 }}>{icon}</span>
                  <div style={{ fontWeight: 600, fontSize: 13, color: '#334155' }}>{l}</div>
                </div>
              ))}
            </>
          )}
        </div>
      )}
    </div>
  )
}

export type { TxView }
