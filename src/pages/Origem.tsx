import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { fmtBRL, fmtData } from '../lib/format'
import type { HotmartSale } from '../lib/types'
import { Card, PageHeader, ErroBanner, KPICard, Vazio } from '../components/ui'
import { useRealtimeRefetch } from '../hooks/useRealtimeRefetch'

// Origem das vendas — VISÃO read-only das vendas classificadas. A classificação é
// feita pelas regras de propagação na tela /regras (agrupadas por vendedor).

interface Grupo { id: string; nome: string }
interface SellerLite { id: string; name: string }
interface GrupoTotal { grupo: string; vendas: number; liquido: number }
type Filtro = 'a_classificar' | 'classificadas' | 'todas'

export default function Origem() {
  const [grupos, setGrupos] = useState<Grupo[]>([])
  const [sellers, setSellers] = useState<SellerLite[]>([])
  const [vendas, setVendas] = useState<HotmartSale[]>([])
  const [totais, setTotais] = useState<GrupoTotal[]>([])
  const [filtro, setFiltro] = useState<Filtro>('a_classificar')
  const [busca, setBusca] = useState('')
  const [buscaDebounced, setBuscaDebounced] = useState('')
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)

  useEffect(() => {
    const t = setTimeout(() => setBuscaDebounced(busca), 400)
    return () => clearTimeout(t)
  }, [busca])

  const carregar = useCallback(async () => {
    setErro(null)
    let vendasQ = supabase.from('hotmart_sales_origin').select('*').order('sale_date', { ascending: false }).limit(1000)
    if (filtro === 'a_classificar') vendasQ = vendasQ.eq('origem', 'a_classificar')
    else if (filtro === 'classificadas') vendasQ = vendasQ.neq('origem', 'a_classificar')
    if (buscaDebounced.trim()) {
      const q = buscaDebounced.trim()
      vendasQ = vendasQ.or(`product.ilike.%${q}%,src.ilike.%${q}%,sck.ilike.%${q}%,xcod.ilike.%${q}%,affiliate.ilike.%${q}%,origem.ilike.%${q}%,vendedor.ilike.%${q}%`)
    }
    const [r1, r2, r3, r4] = await Promise.all([
      supabase.from('origin_groups').select('id,nome').order('nome'),
      supabase.from('sellers').select('id,name').order('name'),
      vendasQ,
      supabase.rpc('hotmart_by_group', { p_company: null, p_start: null, p_end: null }),
    ])
    if (r1.error) setErro('Erro ao carregar grupos: ' + r1.error.message); else setGrupos((r1.data as Grupo[]) ?? [])
    if (!r2.error) setSellers((r2.data as SellerLite[]) ?? [])
    if (r3.error) setErro('Erro ao carregar vendas: ' + r3.error.message); else setVendas((r3.data as HotmartSale[]) ?? [])
    if (!r4.error) setTotais(((r4.data as GrupoTotal[]) ?? []).map((g) => ({ grupo: g.grupo, vendas: Number(g.vendas), liquido: Number(g.liquido) })))
    setCarregando(false)
  }, [filtro, buscaDebounced])

  useEffect(() => { carregar() }, [carregar])
  useRealtimeRefetch('hotmart_sales', carregar)

  const nomeGrupo = (id: string | null | undefined) => grupos.find((g) => g.id === id)?.nome ?? '—'
  const nomeSeller = (id: string | null | undefined) => sellers.find((s) => s.id === id)?.name ?? '—'

  return (
    <div className="space-y-6">
      <PageHeader
        titulo="Origem das vendas"
        subtitulo="Visão das vendas classificadas. A classificação automática é definida nas Regras de propagação."
      />

      <ErroBanner mensagem={erro} />

      {/* KPIs por grupo */}
      {totais.length > 0 && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          {totais.map((g) => (
            <KPICard
              key={g.grupo}
              label={g.grupo === 'a_classificar' ? 'A classificar' : g.grupo}
              valor={`${g.vendas} · ${fmtBRL(g.liquido)}`}
              tom={g.grupo === 'a_classificar' ? 'warning' : 'neutro'}
            />
          ))}
        </div>
      )}

      {/* Card de vendas */}
      <Card>
        <div className="px-5 pt-5 pb-3 border-b border-border flex items-center justify-between gap-4">
          <div>
            <h2 className="text-sm font-semibold text-fg">Vendas</h2>
            <p className="text-xs text-fg-subtle mt-0.5">
              {filtro === 'a_classificar' && `${vendas.length === 1000 ? 'Primeiras 1000' : vendas.length} sem classificação.`}
              {filtro === 'classificadas' && `${vendas.length === 1000 ? 'Primeiras 1000' : vendas.length} já classificadas.`}
              {filtro === 'todas' && `${vendas.length === 1000 ? 'Primeiras 1000' : vendas.length} mais recentes.`}
            </p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <input
              className="rounded-control border border-border bg-surface px-3 py-1 text-xs text-fg placeholder:text-fg-subtle focus:outline-none focus:ring-1 focus:ring-brand w-48"
              placeholder="Pesquisar..."
              value={busca}
              onChange={(e) => setBusca(e.target.value)}
            />
            <div className="flex gap-1 shrink-0">
              {(['a_classificar', 'classificadas', 'todas'] as Filtro[]).map((f) => (
                <button
                  key={f}
                  onClick={() => setFiltro(f)}
                  className={`px-3 py-1 rounded-control text-xs font-medium transition ${filtro === f ? 'bg-brand text-white' : 'bg-surface-2 text-fg-muted hover:bg-border'}`}
                >
                  {f === 'a_classificar' ? 'A classificar' : f === 'classificadas' ? 'Classificadas' : 'Todas'}
                </button>
              ))}
            </div>
          </div>
        </div>
        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : vendas.length === 0 ? (
          <Vazio mensagem={buscaDebounced.trim() ? 'Nenhuma venda encontrada para essa pesquisa.' : 'Nenhuma venda encontrada.'} />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-[11px]">
              <thead>
                <tr className="border-b border-border text-xs text-fg-subtle uppercase tracking-wide">
                  <th className="text-left px-3 h-10 font-medium">Data</th>
                  <th className="text-left px-3 h-10 font-medium">Produto</th>
                  <th className="text-left px-3 h-10 font-medium">src</th>
                  <th className="text-left px-3 h-10 font-medium">sck</th>
                  <th className="text-left px-3 h-10 font-medium">xcode</th>
                  <th className="text-left px-3 h-10 font-medium">Afiliado</th>
                  <th className="text-left px-3 h-10 font-medium">Grupo</th>
                  <th className="text-left px-3 h-10 font-medium">Vendedor</th>
                  <th className="text-right px-3 h-10 font-medium">Líquido</th>
                </tr>
              </thead>
              <tbody>
                {vendas.map((v) => (
                  <tr key={v.id} className="border-b border-border last:border-0 hover:bg-surface-2 align-top">
                    <td className="px-3 py-2 whitespace-nowrap text-fg-muted tnum">{fmtData(v.sale_date)}</td>
                    <td className="px-3 py-2 text-fg max-w-[200px] truncate" title={v.product}>{v.product}</td>
                    <td className="px-3 py-2 text-fg-subtle break-all max-w-[160px]">{v.src || '—'}</td>
                    <td className="px-3 py-2 text-fg-subtle break-all max-w-[160px]">{v.sck || '—'}</td>
                    <td className="px-3 py-2 text-fg-subtle break-all max-w-[120px]">{v.xcod || '—'}</td>
                    <td className="px-3 py-2 text-fg-muted max-w-[140px] truncate" title={v.affiliate ?? ''}>{v.affiliate || '—'}</td>
                    <td className="px-3 py-2 text-fg-muted">{nomeGrupo(v.group_id)}</td>
                    <td className="px-3 py-2 text-fg-muted">{nomeSeller(v.seller_id)}</td>
                    <td className="px-3 py-2 text-right font-medium text-revenue tnum whitespace-nowrap">{fmtBRL(Number(v.net_amount))}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  )
}
