import { CAT_CHART_COLORS, TAG_COLORS, fmt, type CatUI, type TagColor } from '../../lib/fatura'
import type { TxView } from './ExportMenu'

// Port 1:1 do Dashboard por fatura do App.jsx (KPIs + ranking + donut com
// drill-down: clicar numa categoria filtra e leva pra aba Lançamentos).

interface EntryAgg {
  cat: string
  total: number
  count: number
  pct: number
  chartColor: string
  tagColor: TagColor
  start?: number
  end?: number
}

function DonutChart({ entries, grandTotal }: { entries: EntryAgg[]; grandTotal: number }) {
  const size = 150, cx = 75, cy = 75, r = 56, inner = 34
  if (!grandTotal) return null

  // cumulativo sem reassinalar variável durante o render (regra do React 19)
  const ends = entries.reduce<number[]>((acc, e) => [...acc, (acc[acc.length - 1] ?? 0) + e.pct / 100], [])
  const slices = entries.map((e, i) => ({ ...e, start: i === 0 ? 0 : ends[i - 1], end: ends[i] }))

  const pt = (pct: number, radius: number) => {
    const a = pct * 2 * Math.PI - Math.PI / 2
    return { x: cx + radius * Math.cos(a), y: cy + radius * Math.sin(a) }
  }

  return (
    <svg width={size} height={size} style={{ flexShrink: 0 }}>
      {slices.map((s, i) => {
        if (s.end - s.start < 0.001) return null
        const s1 = pt(s.start, r), s2 = pt(s.end, r)
        const i1 = pt(s.start, inner), i2 = pt(s.end, inner)
        const large = s.end - s.start > 0.5 ? 1 : 0
        const d = `M ${i1.x} ${i1.y} L ${s1.x} ${s1.y} A ${r} ${r} 0 ${large} 1 ${s2.x} ${s2.y} L ${i2.x} ${i2.y} A ${inner} ${inner} 0 ${large} 0 ${i1.x} ${i1.y} Z`
        return <path key={i} d={d} fill={s.chartColor} stroke="#fff" strokeWidth={1.5} />
      })}
      <text x={cx} y={cy - 7} textAnchor="middle" fontSize={9} fill="#94a3b8" fontWeight={700} letterSpacing="0.05em">TOTAL</text>
      <text x={cx} y={cy + 9} textAnchor="middle" fontSize={10} fill="#0f172a" fontWeight={800}>{fmt(grandTotal)}</text>
    </svg>
  )
}

export default function FaturaDashboard({
  transactions,
  categories,
  onFilterClick,
}: {
  transactions: TxView[]
  categories: CatUI[]
  onFilterClick: (cat: string) => void
}) {
  const grandTotal = transactions.reduce((s, t) => s + t.amount, 0)
  const semCat = transactions.filter((t) => !t.category).length
  const ticket = transactions.length > 0 ? grandTotal / transactions.length : 0

  const byCategory: Record<string, { total: number; count: number }> = {}
  transactions.forEach((t) => {
    const key = t.category || 'Sem categoria'
    if (!byCategory[key]) byCategory[key] = { total: 0, count: 0 }
    byCategory[key].total += t.amount
    byCategory[key].count += 1
  })

  const entries: EntryAgg[] = Object.entries(byCategory)
    .map(([cat, d]) => {
      const colorIdx = categories.findIndex((c) => c.name === cat)
      const tagColor = colorIdx >= 0 ? categories[colorIdx].color : TAG_COLORS[9]
      const chartColor = CAT_CHART_COLORS[colorIdx >= 0 ? colorIdx % CAT_CHART_COLORS.length : 8]
      return { cat, total: d.total, count: d.count, pct: grandTotal > 0 ? (d.total / grandTotal) * 100 : 0, chartColor, tagColor }
    })
    .sort((a, b) => b.total - a.total)

  const maxVal = entries[0]?.total || 1

  if (transactions.length === 0) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: '64px 24px', color: '#94a3b8' }}>
        <div style={{ fontSize: 40, marginBottom: 12 }}>📊</div>
        <p style={{ margin: 0, fontSize: 15 }}>Importe uma fatura para ver o dashboard</p>
      </div>
    )
  }

  return (
    <div style={{ padding: '20px' }}>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(140px, 1fr))', gap: 10, marginBottom: 20 }}>
        {[
          { label: 'Total gasto', value: fmt(grandTotal), sub: `${transactions.length} lançamentos` },
          { label: 'Maior categoria', value: entries[0] ? fmt(entries[0].total) : '—', sub: `${entries[0]?.cat || '—'} · ${entries[0]?.pct.toFixed(1) || 0}%` },
          { label: 'Ticket médio', value: fmt(ticket), sub: 'por lançamento' },
          { label: 'Sem categoria', value: String(semCat), sub: semCat === 0 ? 'tudo categorizado ✓' : `de ${transactions.length} lançamentos` },
        ].map(({ label, value, sub }) => (
          <div key={label} style={{ background: '#f8fafc', borderRadius: 10, padding: '14px 16px', border: '1px solid #f1f5f9' }}>
            <p style={{ margin: '0 0 4px', fontSize: 11, color: '#64748b', fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.05em' }}>{label}</p>
            <p style={{ margin: '0 0 2px', fontSize: 20, fontWeight: 800, color: '#0f172a', lineHeight: 1.2 }}>{value}</p>
            <p style={{ margin: 0, fontSize: 11, color: '#94a3b8' }}>{sub}</p>
          </div>
        ))}
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 20, alignItems: 'start' }}>
        <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 12, overflow: 'hidden' }}>
          <div style={{ padding: '14px 18px 10px', borderBottom: '1px solid #f1f5f9', display: 'flex', alignItems: 'baseline', gap: 8 }}>
            <span style={{ fontWeight: 700, fontSize: 13, color: '#0f172a' }}>Ranking por categoria</span>
            <span style={{ fontSize: 11, color: '#94a3b8' }}>clique para ver os lançamentos</span>
          </div>
          {entries.map((e, i) => (
            <div
              key={e.cat}
              onClick={() => onFilterClick(e.cat)}
              style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '10px 18px', borderBottom: i < entries.length - 1 ? '1px solid #f8fafc' : 'none', cursor: 'pointer' }}
              onMouseEnter={(ev) => (ev.currentTarget.style.background = '#f8fafc')}
              onMouseLeave={(ev) => (ev.currentTarget.style.background = 'transparent')}
            >
              <span style={{ fontSize: 11, color: '#cbd5e1', width: 16, textAlign: 'right', flexShrink: 0 }}>{i + 1}</span>
              <span style={{ display: 'inline-block', padding: '3px 10px', borderRadius: 20, background: e.tagColor.bg, color: e.tagColor.text, border: `1px solid ${e.tagColor.border}`, fontSize: 11, fontWeight: 700, width: 116, textAlign: 'center', flexShrink: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.cat}</span>
              <div style={{ flex: 1, height: 7, background: '#f1f5f9', borderRadius: 4, overflow: 'hidden' }}>
                <div style={{ height: '100%', borderRadius: 4, background: e.chartColor, width: `${(e.total / maxVal) * 100}%`, transition: 'width 0.5s ease' }} />
              </div>
              <span style={{ fontSize: 11, color: '#94a3b8', width: 40, textAlign: 'right', flexShrink: 0 }}>{e.pct.toFixed(1)}%</span>
              <span style={{ fontSize: 13, fontWeight: 700, color: '#0f172a', width: 110, textAlign: 'right', flexShrink: 0 }}>{fmt(e.total)}</span>
              <span style={{ fontSize: 11, color: '#cbd5e1', width: 50, textAlign: 'right', flexShrink: 0 }}>{e.count} lanç.</span>
            </div>
          ))}
        </div>

        <div style={{ background: '#fff', border: '1px solid #e2e8f0', borderRadius: 12, padding: '16px 18px', minWidth: 220 }}>
          <div style={{ fontWeight: 700, fontSize: 13, color: '#0f172a', marginBottom: 14 }}>Distribuição</div>
          <div style={{ display: 'flex', justifyContent: 'center', marginBottom: 16 }}>
            <DonutChart entries={entries} grandTotal={grandTotal} />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            {entries.map((e) => (
              <div
                key={e.cat}
                style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'pointer' }}
                onClick={() => onFilterClick(e.cat)}
                onMouseEnter={(ev) => (ev.currentTarget.style.opacity = '0.7')}
                onMouseLeave={(ev) => (ev.currentTarget.style.opacity = '1')}
              >
                <div style={{ width: 10, height: 10, borderRadius: 2, background: e.chartColor, flexShrink: 0 }} />
                <span style={{ fontSize: 12, color: '#334155', flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.cat}</span>
                <span style={{ fontSize: 12, color: '#94a3b8', fontWeight: 600, flexShrink: 0 }}>{e.pct.toFixed(1)}%</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
