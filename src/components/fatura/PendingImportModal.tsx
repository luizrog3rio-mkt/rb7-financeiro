import { useState } from 'react'
import { fmt, formatMonth } from '../../lib/fatura'
import type { PurchaseItem } from '../../lib/types'

// Port 1:1 do PendingImportModal do App.jsx (contrato #7): abre automaticamente
// após importar fatura com pendentes existentes, todos pré-selecionados,
// agrupados por mês desc; "Pular" mantém pendentes; confirmar atrela à fatura.
export default function PendingImportModal({
  items,
  onConfirm,
  onCancel,
}: {
  items: PurchaseItem[]
  onConfirm: (ids: string[]) => void
  onCancel: () => void
}) {
  const [selected, setSelected] = useState<Set<string>>(() => new Set(items.map((i) => i.id)))

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  const grouped = items.reduce((acc, it) => {
    const k = it.month || ''
    ;(acc[k] = acc[k] || []).push(it)
    return acc
  }, {} as Record<string, PurchaseItem[]>)
  const groupKeys = Object.keys(grouped).sort((a, b) => b.localeCompare(a))

  const toggleGroup = (gk: string) => {
    const ids = grouped[gk].map((i) => i.id)
    const allSelected = ids.every((id) => selected.has(id))
    setSelected((prev) => {
      const next = new Set(prev)
      if (allSelected) ids.forEach((id) => next.delete(id))
      else ids.forEach((id) => next.add(id))
      return next
    })
  }

  return (
    <div style={{ position: 'fixed', inset: 0, background: 'rgba(15,23,42,0.5)', zIndex: 10000, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 20 }}>
      <div style={{ background: '#fff', borderRadius: 14, maxWidth: 640, width: '100%', maxHeight: '85vh', display: 'flex', flexDirection: 'column', boxShadow: '0 24px 60px rgba(0,0,0,0.25)' }}>
        <div style={{ padding: '20px 24px', borderBottom: '1px solid #e2e8f0' }}>
          <h2 style={{ margin: '0 0 4px', fontSize: 18, fontWeight: 800, color: '#0f172a' }}>🛒 Importar compras pendentes</h2>
          <p style={{ margin: 0, fontSize: 13, color: '#64748b' }}>
            Selecione quais itens incluir nesta fatura. Os não selecionados continuam pendentes.
          </p>
        </div>

        <div style={{ overflowY: 'auto', padding: '12px 24px', flex: 1 }}>
          {groupKeys.map((gk) => {
            const groupItems = grouped[gk]
            const allSelected = groupItems.every((i) => selected.has(i.id))
            return (
              <div key={gk || 'single'} style={{ marginBottom: 16 }}>
                <div onClick={() => toggleGroup(gk)} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 0', cursor: 'pointer', borderBottom: '1px solid #f1f5f9', marginBottom: 4 }}>
                  <input type="checkbox" checked={allSelected} readOnly style={{ cursor: 'pointer' }} />
                  <span style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>📅 {formatMonth(gk || null)}</span>
                  <span style={{ fontSize: 11, color: '#94a3b8' }}>({groupItems.length})</span>
                </div>
                {groupItems.map((it) => (
                  <label
                    key={it.id}
                    style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 6px', cursor: 'pointer', borderRadius: 6 }}
                    onMouseEnter={(e) => (e.currentTarget.style.background = '#f8fafc')}
                    onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}
                  >
                    <input type="checkbox" checked={selected.has(it.id)} onChange={() => toggle(it.id)} style={{ cursor: 'pointer' }} />
                    {it.purchase_date && (
                      <span style={{ fontSize: 11, color: '#94a3b8', fontVariantNumeric: 'tabular-nums', minWidth: 70 }}>
                        {it.purchase_date.split('-').reverse().join('/')}
                      </span>
                    )}
                    <span style={{ flex: 1, fontSize: 13, color: '#1e293b' }}>{it.description}</span>
                    {it.payment_method && <span style={{ fontSize: 11, color: '#64748b' }}>{it.payment_method}</span>}
                    {it.category && (
                      <span style={{ fontSize: 11, color: '#64748b', background: '#f1f5f9', padding: '2px 8px', borderRadius: 12 }}>{it.category}</span>
                    )}
                    {it.amount != null && (
                      <span style={{ fontSize: 12, fontWeight: 700, color: '#0f172a', fontVariantNumeric: 'tabular-nums' }}>{fmt(Number(it.amount))}</span>
                    )}
                  </label>
                ))}
              </div>
            )
          })}
        </div>

        <div style={{ padding: '16px 24px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: 12, color: '#64748b' }}>{selected.size} de {items.length} selecionados</span>
          <div style={{ display: 'flex', gap: 8 }}>
            <button onClick={onCancel} style={{ background: 'transparent', border: '1px solid #e2e8f0', borderRadius: 8, padding: '8px 16px', fontWeight: 600, fontSize: 13, color: '#64748b', cursor: 'pointer' }}>
              Pular
            </button>
            <button onClick={() => onConfirm([...selected])} style={{ background: '#3b82f6', color: '#fff', border: 'none', borderRadius: 8, padding: '8px 18px', fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>
              Importar selecionados
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
