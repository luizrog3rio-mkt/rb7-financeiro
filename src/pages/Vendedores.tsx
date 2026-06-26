import { useCallback, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { fmtBRL } from '../lib/format'
import type { Seller } from '../lib/types'
import { Card, PageHeader, ErroBanner, KPICard, KPIStrip, inputCls, Button, Vazio } from '../components/ui'

// De-para sck → vendedor. O sck (purchase.tracking.source_sck) atribui a venda a
// um vendedor DIRETO (não-afiliado). O valor é ruidoso: visitor-ids (`<ts>_<id>`)
// e UTMs (`a|b|c`) se misturam aos códigos fixos de vendedor (ex.: raphaella_silva)
// — o filtro "esconder ruído" usa o is_ruido vindo da RPC. Espelha ProdutosHotmart.

interface SckRow {
  sck: string
  vendas: number
  bruto: number
  liquido: number
  seller_id: string | null
  is_ruido: boolean
}

// Afiliado (nome canônico da Hotmart) → mesmo vendedor (pessoa) do sck
interface AfiRow {
  affiliate: string
  vendas: number
  comissao: number
  liquido: number
  seller_id: string | null
}

export default function Vendedores() {
  const [scks, setScks] = useState<SckRow[]>([])
  const [afiliados, setAfiliados] = useState<AfiRow[]>([])
  const [sellers, setSellers] = useState<Seller[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)
  const [novoNome, setNovoNome] = useState('')
  const [salvandoSeller, setSalvandoSeller] = useState(false)
  const [soNaoMapeados, setSoNaoMapeados] = useState(false)
  const [esconderRuido, setEsconderRuido] = useState(false)

  const carregar = useCallback(async () => {
    setCarregando(true)
    setErro(null)
    const [r1, r2, r3] = await Promise.all([
      supabase.rpc('hotmart_scks'),
      supabase.from('sellers').select('*').order('name'),
      supabase.rpc('hotmart_affiliates'),
    ])
    if (r1.error) setErro('Erro ao carregar os sck: ' + r1.error.message)
    else setScks(((r1.data as SckRow[]) ?? []).map((s) => ({
      ...s, vendas: Number(s.vendas), bruto: Number(s.bruto), liquido: Number(s.liquido),
    })))
    setSellers((r2.data as Seller[]) ?? [])
    if (r3.error) setErro('Erro ao carregar os afiliados: ' + r3.error.message)
    else setAfiliados(((r3.data as AfiRow[]) ?? []).map((a) => ({
      ...a, vendas: Number(a.vendas), comissao: Number(a.comissao), liquido: Number(a.liquido),
    })))
    setCarregando(false)
  }, [])

  useEffect(() => { carregar() }, [carregar])

  const addSeller = async () => {
    const nome = novoNome.trim()
    if (!nome) return
    setSalvandoSeller(true)
    const { error } = await supabase.from('sellers').insert({ name: nome })
    setSalvandoSeller(false)
    if (error) { setErro('Erro ao cadastrar vendedor: ' + error.message); return }
    setNovoNome('')
    carregar()
  }

  const toggleSeller = async (s: Seller) => {
    const { error } = await supabase.from('sellers').update({ active: !s.active }).eq('id', s.id)
    if (error) { setErro('Erro ao atualizar vendedor: ' + error.message); return }
    setSellers((prev) => prev.map((x) => (x.id === s.id ? { ...x, active: !x.active } : x)))
  }

  // upsert por sck (mesma estratégia do setProduto em ProdutosHotmart)
  const setVendedor = async (sck: string, sellerId: string | null) => {
    setScks((prev) => prev.map((r) => (r.sck === sck ? { ...r, seller_id: sellerId } : r)))
    const { error } = await supabase
      .from('hotmart_sck_map')
      .upsert({ sck, seller_id: sellerId, updated_at: new Date().toISOString() }, { onConflict: 'sck' })
    if (error) { setErro('Erro ao salvar o mapeamento: ' + error.message); carregar() }
  }

  const setAfiliadoVendedor = async (affiliate: string, sellerId: string | null) => {
    setAfiliados((prev) => prev.map((r) => (r.affiliate === affiliate ? { ...r, seller_id: sellerId } : r)))
    const { error } = await supabase
      .from('hotmart_affiliate_map')
      .upsert({ affiliate, seller_id: sellerId, updated_at: new Date().toISOString() }, { onConflict: 'affiliate' })
    if (error) { setErro('Erro ao salvar o afiliado: ' + error.message); carregar() }
  }

  // KPIs sobre os CANDIDATOS (sem ruído) — onde mora o trabalho real
  const resumo = useMemo(() => {
    const cand = scks.filter((r) => !r.is_ruido)
    const naoMap = cand.filter((r) => !r.seller_id)
    return {
      candidatos: cand.length,
      mapeados: cand.length - naoMap.length,
      aMapear: naoMap.length,
      liquidoAMapear: naoMap.reduce((s, r) => s + r.liquido, 0),
    }
  }, [scks])

  // nº de sck mapeados por vendedor (badge no cadastro)
  const porVendedor = useMemo(() => {
    const m = new Map<string, number>()
    scks.forEach((r) => { if (r.seller_id) m.set(r.seller_id, (m.get(r.seller_id) ?? 0) + 1) })
    return m
  }, [scks])

  const exibidos = useMemo(() => {
    let l = scks
    if (esconderRuido) l = l.filter((r) => !r.is_ruido)
    if (soNaoMapeados) l = l.filter((r) => !r.seller_id)
    return l
  }, [scks, esconderRuido, soNaoMapeados])

  return (
    <div className="space-y-6">
      <PageHeader
        titulo="Vendedores"
        subtitulo="Cadastre vendedores e associe cada código de tracking (sck) do checkout ao vendedor — atribui as vendas diretas, não-afiliadas"
      />

      <ErroBanner mensagem={erro} />

      {/* cadastro de vendedores */}
      <Card className="p-5">
        <div className="flex items-end gap-3 flex-wrap">
          <div className="flex-1 min-w-60">
            <label className="block text-sm font-medium mb-1">Novo vendedor</label>
            <input
              className={inputCls}
              placeholder="Nome do vendedor"
              value={novoNome}
              onChange={(e) => setNovoNome(e.target.value)}
              onKeyDown={(e) => { if (e.key === 'Enter') addSeller() }}
            />
          </div>
          <Button onClick={addSeller} loading={salvandoSeller} disabled={!novoNome.trim()}>Adicionar</Button>
        </div>
        {sellers.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-2">
            {sellers.map((s) => (
              <span
                key={s.id}
                className={`inline-flex items-center gap-2 rounded-full border border-border px-3 py-1 text-sm ${s.active ? 'text-fg' : 'text-fg-subtle line-through'}`}
              >
                {s.name}
                <span className="text-xs text-fg-subtle tnum">{porVendedor.get(s.id) ?? 0} sck</span>
                <button
                  onClick={() => toggleSeller(s)}
                  className="text-xs text-fg-subtle hover:text-fg-muted"
                  title={s.active ? 'Desativar' : 'Reativar'}
                >
                  {s.active ? 'desativar' : 'reativar'}
                </button>
              </span>
            ))}
          </div>
        )}
      </Card>

      {/* KPIs (sobre os candidatos, sem ruído) */}
      <KPIStrip cols={4}>
        <KPICard bare label="Códigos (sem ruído)" valor={resumo.candidatos} />
        <KPICard bare label="Mapeados" valor={resumo.mapeados} tom="revenue" />
        <KPICard bare label="A mapear" valor={resumo.aMapear} tom={resumo.aMapear > 0 ? 'warning' : 'revenue'} />
        <KPICard bare label="Líquido a mapear" valor={fmtBRL(resumo.liquidoAMapear)} tom={resumo.aMapear > 0 ? 'warning' : 'neutro'} />
      </KPIStrip>

      {/* de-para sck → vendedor */}
      <Card>
        <div className="flex items-center justify-between gap-3 p-3 border-b border-border flex-wrap">
          <p className="text-sm text-fg-muted">{exibidos.length} código{exibidos.length !== 1 ? 's' : ''} de sck</p>
          <div className="flex items-center gap-4">
            <label className="flex items-center gap-2 text-sm text-fg-muted cursor-pointer">
              <input type="checkbox" className="accent-brand" checked={esconderRuido} onChange={(e) => setEsconderRuido(e.target.checked)} />
              Esconder ruído (visitor-id/UTM)
            </label>
            <label className="flex items-center gap-2 text-sm text-fg-muted cursor-pointer">
              <input type="checkbox" className="accent-brand" checked={soNaoMapeados} onChange={(e) => setSoNaoMapeados(e.target.checked)} />
              Só os a mapear
            </label>
          </div>
        </div>

        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : exibidos.length === 0 ? (
          <Vazio mensagem="Nenhum código de sck. As vendas com tracking aparecem aqui conforme o sync preenche o histórico." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm tnum">
              <thead>
                <tr className="border-b border-border text-xs text-fg-subtle uppercase tracking-wide">
                  <th className="text-left px-4 h-10 font-medium">Código (sck)</th>
                  <th className="text-right px-4 h-10 font-medium">Vendas</th>
                  <th className="text-right px-4 h-10 font-medium">Líquido</th>
                  <th className="text-left px-4 h-10 font-medium w-64">Vendedor</th>
                </tr>
              </thead>
              <tbody>
                {exibidos.map((r) => (
                  <tr
                    key={r.sck}
                    className={`border-b border-border last:border-0 hover:bg-surface-2 ${!r.seller_id && !r.is_ruido ? 'bg-warning-bg/40' : ''}`}
                  >
                    <td className="px-4 py-2 text-fg">
                      <span className="break-all">{r.sck}</span>
                      {r.is_ruido && <span className="ml-2 text-[10px] text-fg-subtle uppercase tracking-wide">ruído</span>}
                    </td>
                    <td className="px-4 py-2 text-right text-fg-muted">{r.vendas}</td>
                    <td className="px-4 py-2 text-right font-medium text-fg">{fmtBRL(r.liquido)}</td>
                    <td className="px-4 py-2">
                      <select
                        className={inputCls + (!r.seller_id && !r.is_ruido ? ' border-warning' : '')}
                        value={r.seller_id ?? ''}
                        onChange={(e) => setVendedor(r.sck, e.target.value || null)}
                      >
                        <option value="">— sem vendedor —</option>
                        {sellers.map((s) => (
                          <option key={s.id} value={s.id}>{s.name}</option>
                        ))}
                      </select>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* de-para afiliado → vendedor (mesma pessoa do sck) */}
      <Card>
        <div className="px-4 py-3 border-b border-border">
          <p className="text-sm font-medium text-fg">Afiliados → vendedor <span className="text-fg-subtle font-normal">({afiliados.length})</span></p>
          <p className="text-xs text-fg-subtle mt-0.5">Mesma pessoa do sck — o nome vem da Hotmart (canônico). Mapeie pra unificar o total por pessoa nos dois canais.</p>
        </div>
        {afiliados.length === 0 ? (
          <Vazio mensagem="Nenhum afiliado nas vendas. Os afiliados aparecem conforme o sync de comissões preenche." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm tnum">
              <thead>
                <tr className="border-b border-border text-xs text-fg-subtle uppercase tracking-wide">
                  <th className="text-left px-4 h-10 font-medium">Afiliado</th>
                  <th className="text-right px-4 h-10 font-medium">Vendas</th>
                  <th className="text-right px-4 h-10 font-medium">Comissão</th>
                  <th className="text-right px-4 h-10 font-medium">Líquido</th>
                  <th className="text-left px-4 h-10 font-medium w-64">Vendedor</th>
                </tr>
              </thead>
              <tbody>
                {afiliados.map((r) => (
                  <tr
                    key={r.affiliate}
                    className={`border-b border-border last:border-0 hover:bg-surface-2 ${!r.seller_id ? 'bg-warning-bg/40' : ''}`}
                  >
                    <td className="px-4 py-2 text-fg"><span className="break-all">{r.affiliate}</span></td>
                    <td className="px-4 py-2 text-right text-fg-muted">{r.vendas}</td>
                    <td className="px-4 py-2 text-right text-warning">{fmtBRL(r.comissao)}</td>
                    <td className="px-4 py-2 text-right font-medium text-fg">{fmtBRL(r.liquido)}</td>
                    <td className="px-4 py-2">
                      <select
                        className={inputCls + (!r.seller_id ? ' border-warning' : '')}
                        value={r.seller_id ?? ''}
                        onChange={(e) => setAfiliadoVendedor(r.affiliate, e.target.value || null)}
                      >
                        <option value="">— sem vendedor —</option>
                        {sellers.map((s) => (
                          <option key={s.id} value={s.id}>{s.name}</option>
                        ))}
                      </select>
                    </td>
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
