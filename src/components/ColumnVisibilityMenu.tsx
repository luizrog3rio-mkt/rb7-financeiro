import { useState } from 'react'
import { SlidersHorizontal } from 'lucide-react'

// Menu "Colunas" standalone (só esconder/mostrar) pra tabela de Compras do
// mundo fatura — onde a edição é inline e não cabe no DataTable. O estado de
// visibilidade vem do useColumnPrefs (persiste por usuário). Visual alinhado ao
// menu de colunas do DataTable.

export interface ColMeta {
  id: string
  label: string
}

export default function ColumnVisibilityMenu({
  columns,
  isVisible,
  onToggle,
  onReset,
}: {
  columns: ColMeta[]
  isVisible: (id: string) => boolean
  onToggle: (id: string) => void
  onReset: () => void
}) {
  const [aberto, setAberto] = useState(false)
  return (
    <div className="relative">
      <button
        onClick={() => setAberto((a) => !a)}
        title="Mostrar ou esconder colunas"
        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 px-2.5 py-1.5 text-xs font-medium text-slate-500 hover:text-slate-700 hover:bg-slate-50"
      >
        <SlidersHorizontal size={14} /> Colunas
      </button>
      {aberto && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setAberto(false)} />
          <div className="absolute right-0 mt-1 z-20 w-60 rounded-lg border border-slate-200 bg-white p-2 shadow-lg">
            <p className="px-2 py-1 text-xs text-slate-400">Mostrar colunas</p>
            {columns.map((c) => (
              <label key={c.id} className="flex cursor-pointer items-center gap-2 rounded px-2 py-1.5 text-sm hover:bg-slate-50">
                <input type="checkbox" checked={isVisible(c.id)} onChange={() => onToggle(c.id)} />
                <span className="truncate">{c.label}</span>
              </label>
            ))}
            <button
              onClick={() => { onReset(); setAberto(false) }}
              className="mt-1 w-full border-t border-slate-100 px-2 py-1.5 text-left text-xs text-slate-500 hover:text-indigo-600"
            >
              Restaurar padrão
            </button>
          </div>
        </>
      )}
    </div>
  )
}
