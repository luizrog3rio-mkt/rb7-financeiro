import { useCallback, useEffect, useMemo, useState } from 'react'
import { supabase } from '../lib/supabase'
import { fmtBRL, fmtData } from '../lib/format'
import type { HotmartSale } from '../lib/types'
import { Card, PageHeader, ErroBanner, KPICard, KPIStrip, inputCls, Button, Vazio, Modal, Badge, type BadgeTom } from '../components/ui'
import DataTable, { type DataColumn } from '../components/DataTable'
import { useRealtimeRefetch } from '../hooks/useRealtimeRefetch'

// Origem v2 — modelo de 2 níveis (Grupo › Canal), TODO o mapeamento aqui.
//   • GRUPO (macro): Comercial / Orgânico / Tráfego Pago / Afiliado.
//   • CANAL (nomeado): "Meta Ads", "WhatsApp", "Raphaella" (vendedor)...
// Tudo derivado ao vivo pela view hotmart_sales_origin (migration origem_canais_v2):
// override(venda) > vendedor(sck) > afiliado > canal(src) > canal(sck) > a_classificar.

interface Canal {
  id: string; nome: string; grupo: string
  seller_id: string | null; seller_nome: string | null
  vendas: number; liquido: number
}
interface NaoMapeado {
  dimensao: string; valor: string; vendas: number; bruto: number; liquido: number
  sugestao: string | null; is_ruido: boolean
}
interface GrupoTotal { grupo: string; vendas: number; liquido: number }
interface SellerLite { id: string; name: string }

const GRUPOS = [
  { valor: 'comercial', rotulo: 'Comercial' },
  { valor: 'organico', rotulo: 'Orgânico' },
  { valor: 'trafego', rotulo: 'Tráfego Pago' },
  { valor: 'afiliado', rotulo: 'Afiliado' },
] as const

const GRUPO_META: Record<string, { rotulo: string; tom: BadgeTom }> = {
  comercial: { rotulo: 'Comercial', tom: 'brand' },
  organico: { rotulo: 'Orgânico', tom: 'revenue' },
  trafego: { rotulo: 'Tráfego Pago', tom: 'warning' },
  afiliado: { rotulo: 'Afiliado', tom: 'muted' },
  a_classificar: { rotulo: 'A classificar', tom: 'muted' },
}
function GrupoBadge({ grupo }: { grupo?: string }) {
  const m = GRUPO_META[grupo ?? 'a_classificar'] ?? GRUPO_META.a_classificar
  return <Badge tom={m.tom}>{m.rotulo}</Badge>
}

// Select de canal com optgroup por grupo (reusado no de-para e no override)
function CanalSelect({
  canais, value, onChange, autoLabel = '— sem canal —', className,
}: {
  canais: Canal[]; value: string | null; onChange: (id: string | null) => void
  autoLabel?: string; className?: string
}) {
  return (
    <select className={className ?? inputCls} value={value ?? ''} onChange={(e) => onChange(e.target.value || null)}>
      <option value="">{autoLabel}</option>
      {GRUPOS.map((g) => {
        const doGrupo = canais.filter((c) => c.grupo === g.valor)
        if (doGrupo.length === 0) return null
        return (
          <optgroup key={g.valor} label={g.rotulo}>
            {doGrupo.map((c) => <option key={c.id} value={c.id}>{c.nome}</option>)}
          </optgroup>
        )
      })}
    </select>
  )
}

export default function Origem() {
  const [canais, setCanais] = useState<Canal[]>([])
  const [naoMapeados, setNaoMapeados] = useState<NaoMapeado[]>([])
  const [grupos, setGrupos] = useState<GrupoTotal[]>([])
  const [vendas, setVendas] = useState<HotmartSale[]>([])
  const [sellers, setSellers] = useState<SellerLite[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)
  const [esconderRuido, setEsconderRuido] = useState(true)
  // modal criar/editar canal
  const [modalAberto, setModalAberto] = useState(false)
  const [editando, setEditando] = useState<Canal | null>(null)
  const [novoNome, setNovoNome] = useState('')
  const [novoGrupo, setNovoGrupo] = useState<string>('comercial')
  const [novoSeller, setNovoSeller] = useState<string>('')
  const [salvando, setSalvando] = useState(false)

  const carregar = useCallback(async () => {
    setErro(null)
    const [r1, r2, r3, r4, r5] = await Promise.all([
      supabase.rpc('origin_channels_list'),
      supabase.rpc('origin_tracking_unmapped'),
      supabase.rpc('hotmart_by_group', { p_company: null, p_start: null, p_end: null }),
      supabase.from('hotmart_sales_origin').select('*').order('sale_date', { ascending: false }).limit(300),
      supabase.from('sellers').select('id,name').eq('active', true).order('name'),
    ])
    if (r1.error) setErro('Erro ao carregar canais: ' + r1.error.message)
    else setCanais(((r1.data as Canal[]) ?? []).map((c) => ({ ...c, vendas: Number(c.vendas), liquido: Number(c.liquido) })))
    if (r2.error) setErro('Erro ao carregar não-mapeados: ' + r2.error.message)
    else setNaoMapeados(((r2.data as NaoMapeado[]) ?? []).map((n) => ({ ...n, vendas: Number(n.vendas), bruto: Number(n.bruto), liquido: Number(n.liquido) })))
    if (r3.error) setErro('Erro ao carregar totais: ' + r3.error.message)
    else setGrupos(((r3.data as GrupoTotal[]) ?? []).map((g) => ({ grupo: g.grupo, vendas: Number(g.vendas), liquido: Number(g.liquido) })))
    if (r4.error) setErro('Erro ao carregar vendas: ' + r4.error.message)
    else setVendas((r4.data as HotmartSale[]) ?? [])
    if (!r5.error) setSellers((r5.data as SellerLite[]) ?? [])
    setCarregando(false)
  }, [])

  useEffect(() => { carregar() }, [carregar])
  useRealtimeRefetch('hotmart_sales', carregar)

  const kpi = (g: string) => {
    const t = grupos.find((x) => x.grupo === g)
    return t ? `${t.vendas} · ${fmtBRL(t.liquido)}` : '0 · —'
  }

  const abrirNovo = () => {
    setEditando(null); setNovoNome(''); setNovoGrupo('comercial'); setNovoSeller(''); setModalAberto(true)
  }
  const abrirEditar = (c: Canal) => {
    setEditando(c); setNovoNome(c.nome); setNovoGrupo(c.grupo); setNovoSeller(c.seller_id ?? ''); setModalAberto(true)
  }
  const salvarCanal = async () => {
    const nome = novoNome.trim()
    if (!nome) return
    setSalvando(true)
    const payload = { nome, grupo: novoGrupo, seller_id: novoSeller || null }
    const { error } = editando
      ? await supabase.from('origin_channels').update(payload).eq('id', editando.id)
      : await supabase.from('origin_channels').insert(payload)
    setSalvando(false)
    if (error) { setErro('Erro ao salvar canal: ' + error.message); return }
    setModalAberto(false); setEditando(null); setNovoNome(''); setNovoGrupo('comercial'); setNovoSeller('')
    carregar()
  }
  const excluirCanal = async (c: Canal) => {
    if (!window.confirm(`Excluir o canal "${c.nome}"? Os mapeamentos de tracking e os overrides que apontam pra ele serão removidos — as vendas voltam a classificar pelas demais regras. O cadastro do vendedor (se houver) NÃO é afetado.`)) return
    const { error } = await supabase.from('origin_channels').delete().eq('id', c.id)
    if (error) { setErro('Erro ao excluir canal: ' + error.message); return }
    carregar()
  }

  // de-para: mapeia/desmapeia um valor de tracking a um canal
  const mapear = async (dimensao: string, valor: string, channelId: string | null) => {
    const { error } = channelId
      ? await supabase.from('origin_tracking_map').upsert({ dimensao, valor, channel_id: channelId }, { onConflict: 'dimensao,valor' })
      : await supabase.from('origin_tracking_map').delete().eq('dimensao', dimensao).eq('valor', valor)
    if (error) setErro('Erro ao mapear: ' + error.message)
    carregar()
  }

  // override por venda (channelId vazio = volta ao automático)
  const overrideVenda = useCallback(async (transactionCode: string, channelId: string | null) => {
    const { error } = channelId
      ? await supabase.from('origin_sale_override').upsert({ transaction_code: transactionCode, channel_id: channelId, updated_at: new Date().toISOString() }, { onConflict: 'transaction_code' })
      : await supabase.from('origin_sale_override').delete().eq('transaction_code', transactionCode)
    if (error) setErro('Erro no override: ' + error.message)
    carregar()
  }, [carregar])

  const naoMapeadosExibidos = useMemo(
    () => (esconderRuido ? naoMapeados.filter((n) => !n.is_ruido) : naoMapeados),
    [naoMapeados, esconderRuido],
  )

  const colunas = useMemo<DataColumn<HotmartSale>[]>(() => [
    { id: 'sale_date', header: 'Data', size: 100, cell: (v) => <span className="whitespace-nowrap text-fg-muted tnum">{fmtData(v.sale_date)}</span> },
    { id: 'product', header: 'Produto', size: 200, align: 'left', grow: true, cell: (v) => <span className="text-fg">{v.product}</span> },
    { id: 'src', header: 'src', size: 140, cell: (v) => <span className="text-xs text-fg-subtle break-all">{v.src || '—'}</span> },
    { id: 'sck', header: 'sck', size: 140, cell: (v) => <span className="text-xs text-fg-subtle break-all">{v.sck || '—'}</span> },
    { id: 'xcod', header: 'xcode', size: 110, cell: (v) => <span className="text-xs text-fg-subtle break-all">{v.xcod || '—'}</span> },
    { id: 'affiliate', header: 'Afiliado', size: 140, align: 'left', cell: (v) => <span className="text-fg-muted">{v.affiliate || '—'}</span> },
    { id: 'grupo', header: 'Grupo', size: 110, cell: (v) => <GrupoBadge grupo={v.origem} /> },
    { id: 'canal', header: 'Canal', size: 130, cell: (v) => <span className="text-fg-muted">{v.canal || '—'}</span> },
    { id: 'override', header: 'Reclassificar', size: 180, enableHiding: true, cell: (v) => (
      <CanalSelect
        canais={canais}
        value={v.channel_id ?? null}
        autoLabel="— automático —"
        onChange={(id) => overrideVenda(v.transaction_code, id)}
        className="w-full rounded-control border border-border bg-surface px-2 py-1 text-xs text-fg focus:outline-none focus:ring-2 focus:ring-brand"
      />
    ) },
  ], [canais, overrideVenda])

  return (
    <div className="space-y-6">
      <PageHeader
        titulo="Origem das vendas"
        subtitulo="Todo o mapeamento de origem num lugar só: classifique cada canal de tracking (src/sck) e afiliado em um Canal, e cada Canal pertence a um Grupo (Comercial, Orgânico, Tráfego Pago, Afiliado)"
        acao={<Button onClick={abrirNovo}>Novo canal</Button>}
      />

      <ErroBanner mensagem={erro} />

      {/* KPIs por grupo (derivado ao vivo) */}
      <KPIStrip cols={5}>
        <KPICard bare label="Comercial" valor={kpi('comercial')} tom="brand" />
        <KPICard bare label="Orgânico" valor={kpi('organico')} tom="revenue" />
        <KPICard bare label="Tráfego Pago" valor={kpi('trafego')} tom="warning" />
        <KPICard bare label="Afiliado" valor={kpi('afiliado')} tom="neutro" />
        <KPICard bare label="A classificar" valor={kpi('a_classificar')} tom={grupos.find((g) => g.grupo === 'a_classificar') ? 'warning' : 'neutro'} />
      </KPIStrip>

      {/* Bloco 1 — Canais cadastrados */}
      <Card>
        <div className="px-5 pt-5 pb-3 border-b border-border">
          <h2 className="text-sm font-semibold text-fg">Canais de origem</h2>
          <p className="text-xs text-fg-subtle mt-0.5">Cada canal pertence a um grupo. Vendedores são canais Comercial vinculados a um cadastro (em Vendedores).</p>
        </div>
        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : canais.length === 0 ? (
          <Vazio mensagem="Nenhum canal ainda. Clique em “Novo canal”." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm tnum">
              <thead>
                <tr className="border-b border-border text-xs text-fg-subtle uppercase tracking-wide">
                  <th className="text-left px-4 h-10 font-medium">Canal</th>
                  <th className="text-left px-4 h-10 font-medium">Grupo</th>
                  <th className="text-left px-4 h-10 font-medium">Vendedor</th>
                  <th className="text-right px-4 h-10 font-medium">Vendas</th>
                  <th className="text-right px-4 h-10 font-medium">Líquido</th>
                  <th className="px-4 h-10 font-medium text-right">Ações</th>
                </tr>
              </thead>
              <tbody>
                {canais.map((c) => (
                  <tr key={c.id} className="border-b border-border last:border-0 hover:bg-surface-2">
                    <td className="px-4 py-2 text-fg">{c.nome}</td>
                    <td className="px-4 py-2"><GrupoBadge grupo={c.grupo} /></td>
                    <td className="px-4 py-2 text-fg-muted">{c.seller_nome || '—'}</td>
                    <td className="px-4 py-2 text-right text-fg-muted">{c.vendas}</td>
                    <td className="px-4 py-2 text-right font-medium text-fg">{fmtBRL(c.liquido)}</td>
                    <td className="px-4 py-2 text-right whitespace-nowrap">
                      <button onClick={() => abrirEditar(c)} className="text-xs text-brand hover:underline mr-3">Editar</button>
                      <button onClick={() => excluirCanal(c)} className="text-xs text-expense hover:underline">Excluir</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Bloco 2 — De-para: valores de tracking ainda sem canal */}
      <Card>
        <div className="flex items-center justify-between gap-3 px-5 pt-5 pb-3 border-b border-border flex-wrap">
          <div>
            <h2 className="text-sm font-semibold text-fg">A classificar — tracking sem canal</h2>
            <p className="text-xs text-fg-subtle mt-0.5">{naoMapeadosExibidos.length} valor{naoMapeadosExibidos.length !== 1 ? 'es' : ''} de src/sck/afiliado esperando um canal.</p>
          </div>
          <label className="flex items-center gap-2 text-sm text-fg-muted cursor-pointer">
            <input type="checkbox" className="accent-brand" checked={esconderRuido} onChange={(e) => setEsconderRuido(e.target.checked)} />
            Esconder ruído
          </label>
        </div>
        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : naoMapeadosExibidos.length === 0 ? (
          <Vazio mensagem="Tudo classificado por aqui 🎉" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm tnum">
              <thead>
                <tr className="border-b border-border text-xs text-fg-subtle uppercase tracking-wide">
                  <th className="text-left px-4 h-10 font-medium">Valor</th>
                  <th className="text-left px-4 h-10 font-medium">Tipo</th>
                  <th className="text-right px-4 h-10 font-medium">Vendas</th>
                  <th className="text-right px-4 h-10 font-medium">Líquido</th>
                  <th className="text-left px-4 h-10 font-medium w-64">Canal</th>
                </tr>
              </thead>
              <tbody>
                {naoMapeadosExibidos.map((n) => (
                  <tr key={`${n.dimensao}:${n.valor}`} className={`border-b border-border last:border-0 hover:bg-surface-2 ${!n.is_ruido ? 'bg-warning-bg/40' : ''}`}>
                    <td className="px-4 py-2 text-fg">
                      <span className="break-all">{n.valor}</span>
                      {n.is_ruido && <span className="ml-2 text-[10px] text-fg-subtle uppercase tracking-wide">ruído</span>}
                      {n.sugestao && <span className="ml-2 text-[10px] text-brand uppercase tracking-wide">sugestão: {n.sugestao}</span>}
                    </td>
                    <td className="px-4 py-2 text-xs text-fg-subtle">{n.dimensao === 'afiliado' ? 'afiliado' : 'canal (src/sck)'}</td>
                    <td className="px-4 py-2 text-right text-fg-muted">{n.vendas}</td>
                    <td className="px-4 py-2 text-right font-medium text-fg">{fmtBRL(n.liquido)}</td>
                    <td className="px-4 py-2">
                      <CanalSelect canais={canais} value={null} autoLabel="— escolher canal —" onChange={(id) => mapear(n.dimensao, n.valor, id)} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* Bloco 3 — Vendas (com src/sck/xcode + reclassificar manual) */}
      <Card>
        <div className="px-5 pt-5 pb-3 border-b border-border">
          <h2 className="text-sm font-semibold text-fg">Vendas</h2>
          <p className="text-xs text-fg-subtle mt-0.5">300 vendas mais recentes. Use “Reclassificar” pra sobrepor a origem de uma venda específica (vence o mapeamento automático).</p>
        </div>
        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : vendas.length === 0 ? (
          <Vazio mensagem="Nenhuma venda. As vendas aparecem aqui conforme o sync/webHook preenche o histórico." />
        ) : (
          <DataTable tableKey="origem-sales" columns={colunas} data={vendas} getRowId={(v) => v.id} />
        )}
      </Card>

      <Modal
        titulo={editando ? 'Editar canal de origem' : 'Novo canal de origem'}
        aberto={modalAberto}
        onFechar={() => setModalAberto(false)}
        footer={
          <div className="flex justify-end gap-2">
            <Button variante="secondary" onClick={() => setModalAberto(false)}>Cancelar</Button>
            <Button onClick={salvarCanal} loading={salvando} disabled={!novoNome.trim()}>{editando ? 'Salvar' : 'Criar'}</Button>
          </div>
        }
      >
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium mb-1">Nome do canal</label>
            <input className={inputCls} value={novoNome} onChange={(e) => setNovoNome(e.target.value)} placeholder="Ex.: Meta Ads, WhatsApp, Busca Google…" autoFocus />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Grupo</label>
            <select className={inputCls} value={novoGrupo} onChange={(e) => setNovoGrupo(e.target.value)}>
              {GRUPOS.map((g) => <option key={g.valor} value={g.valor}>{g.rotulo}</option>)}
            </select>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Vendedor <span className="text-fg-subtle font-normal">(opcional — vincula o canal a um cadastro)</span></label>
            <select className={inputCls} value={novoSeller} onChange={(e) => setNovoSeller(e.target.value)}>
              <option value="">— nenhum —</option>
              {sellers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
        </div>
      </Modal>
    </div>
  )
}
