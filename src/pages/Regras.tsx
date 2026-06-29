import { useCallback, useEffect, useMemo, useState } from 'react'
import { ChevronDown, ChevronRight, Plus } from 'lucide-react'
import { supabase } from '../lib/supabase'
import { Card, PageHeader, ErroBanner, Vazio, Modal, Button, Alert, inputCls } from '../components/ui'

// Regras de propagação — agrupadas POR VENDEDOR. Cada card é um vendedor; dentro,
// as condições (src/sck/xcode/afiliado) que classificam vendas pra ele + o grupo de cada uma.
// Mesma tabela origin_tracking_rules do /origem — aqui é só outra visão.

interface Grupo { id: string; nome: string }
interface SellerLite { id: string; name: string }
type MatchType = 'exact' | 'contains' | 'starts_with' | 'is_empty'
interface Regra { id: string; src_value: string | null; src_match: MatchType; sck_value: string | null; sck_match: MatchType; xcode_value: string | null; xcode_match: MatchType; afiliado_value: string | null; afiliado_match: MatchType; group_id: string | null; channel_id: string | null; seller_id: string | null }
interface NovaRegra { src_value: string; src_match: MatchType; sck_value: string; sck_match: MatchType; xcode_value: string; xcode_match: MatchType; afiliado_value: string; afiliado_match: MatchType; group_id: string; seller_id: string }

const MATCH_LABELS: Record<MatchType, string> = { exact: '=', contains: 'contém', starts_with: 'começa com', is_empty: 'é vazio' }
const REGRA_VAZIA: NovaRegra = { src_value: '', src_match: 'exact', sck_value: '', sck_match: 'exact', xcode_value: '', xcode_match: 'exact', afiliado_value: '', afiliado_match: 'exact', group_id: '', seller_id: '' }
const NOVO = '__novo__'
const SEM_VENDEDOR = '__sem__'

const condsDaRegra = (r: Regra) => [
  (r.src_value || r.src_match === 'is_empty') && `src ${MATCH_LABELS[r.src_match]} ${r.src_match === 'is_empty' ? '' : r.src_value}`.trim(),
  (r.sck_value || r.sck_match === 'is_empty') && `sck ${MATCH_LABELS[r.sck_match]} ${r.sck_match === 'is_empty' ? '' : r.sck_value}`.trim(),
  (r.xcode_value || r.xcode_match === 'is_empty') && `xcode ${MATCH_LABELS[r.xcode_match]} ${r.xcode_match === 'is_empty' ? '' : r.xcode_value}`.trim(),
  (r.afiliado_value || r.afiliado_match === 'is_empty') && `afiliado ${MATCH_LABELS[r.afiliado_match]} ${r.afiliado_match === 'is_empty' ? '' : r.afiliado_value}`.trim(),
].filter(Boolean) as string[]

export default function Regras() {
  const [grupos, setGrupos] = useState<Grupo[]>([])
  const [sellers, setSellers] = useState<SellerLite[]>([])
  const [regras, setRegras] = useState<Regra[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)
  const [salvando, setSalvando] = useState(false)
  const [aplicando, setAplicando] = useState(false)
  const [resultado, setResultado] = useState<number | null>(null)
  const [expandido, setExpandido] = useState<Set<string>>(new Set())

  const [modalCriar, setModalCriar] = useState(false) // criar grupo
  const [nomeNovo, setNomeNovo] = useState('')

  const [modalRegra, setModalRegra] = useState<{ modo: 'criar' } | { modo: 'editar'; id: string } | null>(null)
  const [novaRegra, setNovaRegra] = useState<NovaRegra>(REGRA_VAZIA)

  const carregar = useCallback(async () => {
    setErro(null)
    const [r1, r2, r3] = await Promise.all([
      supabase.from('origin_groups').select('id,nome').order('nome'),
      supabase.from('sellers').select('id,name').order('name'),
      supabase.from('origin_tracking_rules').select('*').order('created_at'),
    ])
    if (r1.error) setErro('Erro ao carregar grupos: ' + r1.error.message); else setGrupos((r1.data as Grupo[]) ?? [])
    if (!r2.error) setSellers((r2.data as SellerLite[]) ?? [])
    if (r3.error) setErro('Erro ao carregar regras: ' + r3.error.message); else setRegras((r3.data as Regra[]) ?? [])
    setCarregando(false)
  }, [])

  useEffect(() => { carregar() }, [carregar])

  const nomeGrupo = (id: string | null) => grupos.find((g) => g.id === id)?.nome ?? null

  const porVendedor = useMemo(() => {
    const map = new Map<string, Regra[]>()
    for (const r of regras) {
      const k = r.seller_id ?? SEM_VENDEDOR
      if (!map.has(k)) map.set(k, [])
      map.get(k)!.push(r)
    }
    return map
  }, [regras])

  const cards = useMemo(() => {
    const lista = sellers.map((s) => ({ id: s.id, nome: s.name, regras: porVendedor.get(s.id) ?? [] }))
    const orfas = porVendedor.get(SEM_VENDEDOR) ?? []
    if (orfas.length) lista.push({ id: SEM_VENDEDOR, nome: 'Sem vendedor', regras: orfas })
    return lista
  }, [sellers, porVendedor])

  const toggle = (id: string) => setExpandido((prev) => {
    const n = new Set(prev)
    if (n.has(id)) n.delete(id); else n.add(id)
    return n
  })

  const adicionarCondicao = (sellerId: string) => {
    setNovaRegra({ ...REGRA_VAZIA, seller_id: sellerId === SEM_VENDEDOR ? '' : sellerId })
    setModalRegra({ modo: 'criar' })
  }

  const editarRegra = (r: Regra) => {
    setNovaRegra({ src_value: r.src_value ?? '', src_match: r.src_match, sck_value: r.sck_value ?? '', sck_match: r.sck_match, xcode_value: r.xcode_value ?? '', xcode_match: r.xcode_match, afiliado_value: r.afiliado_value ?? '', afiliado_match: r.afiliado_match, group_id: r.group_id ?? '', seller_id: r.seller_id ?? '' })
    setModalRegra({ modo: 'editar', id: r.id })
  }

  const regraValida = (r: NovaRegra) =>
    r.src_match === 'is_empty' || r.src_value.trim() ||
    r.sck_match === 'is_empty' || r.sck_value.trim() ||
    r.xcode_match === 'is_empty' || r.xcode_value.trim() ||
    r.afiliado_match === 'is_empty' || r.afiliado_value.trim()

  const salvarRegra = useCallback(async () => {
    if (!regraValida(novaRegra) || !modalRegra) return
    setSalvando(true)
    const payload = { src_value: novaRegra.src_value.trim() || null, src_match: novaRegra.src_match, sck_value: novaRegra.sck_value.trim() || null, sck_match: novaRegra.sck_match, xcode_value: novaRegra.xcode_value.trim() || null, xcode_match: novaRegra.xcode_match, afiliado_value: novaRegra.afiliado_value.trim() || null, afiliado_match: novaRegra.afiliado_match, group_id: novaRegra.group_id || null, seller_id: novaRegra.seller_id || null }
    if (modalRegra.modo === 'criar') {
      const { error } = await supabase.from('origin_tracking_rules').insert(payload)
      if (error) { setErro('Erro ao salvar regra: ' + error.message); setSalvando(false); return }
    } else {
      const { error } = await supabase.from('origin_tracking_rules').update(payload).eq('id', modalRegra.id)
      if (error) { setErro('Erro ao editar regra: ' + error.message); setSalvando(false); return }
    }
    const idEditado = modalRegra.modo === 'editar' ? modalRegra.id : null
    setModalRegra(null); setSalvando(false)
    if (idEditado) await supabase.rpc('force_apply_origin_rule', { p_rule_id: idEditado })
    else await supabase.rpc('apply_origin_rules')
    carregar()
  }, [novaRegra, modalRegra, carregar])

  const excluirRegra = async (id: string) => {
    const { error } = await supabase.from('origin_tracking_rules').delete().eq('id', id)
    if (error) { setErro('Erro ao excluir regra: ' + error.message); return }
    setRegras((prev) => prev.filter((r) => r.id !== id))
  }

  const aplicarRegras = useCallback(async () => {
    setAplicando(true); setResultado(null)
    const { data, error } = await supabase.rpc('apply_origin_rules')
    if (error) setErro('Erro ao aplicar regras: ' + error.message)
    else setResultado(Number(data) || 0)
    setAplicando(false)
    carregar()
  }, [carregar])

  const confirmarCriacaoGrupo = useCallback(async () => {
    if (!nomeNovo.trim()) return
    setSalvando(true)
    const { data, error } = await supabase.from('origin_groups').insert({ nome: nomeNovo.trim() }).select('id,nome').single()
    if (error) { setErro('Erro ao criar grupo: ' + error.message); setSalvando(false); return }
    const g = data as Grupo
    setGrupos((prev) => [...prev, g].sort((a, b) => a.nome.localeCompare(b.nome)))
    setNovaRegra((p) => ({ ...p, group_id: g.id }))
    setSalvando(false); setModalCriar(false); setNomeNovo('')
  }, [nomeNovo])

  return (
    <div className="space-y-6">
      <PageHeader
        titulo="Regras de propagação"
        subtitulo="Cada vendedor tem suas condições (src / sck / xcode / afiliado) que classificam vendas automaticamente. Abra um vendedor para ver e editar."
      />

      <ErroBanner mensagem={erro} />
      {resultado !== null && (
        <Alert tom="success">{resultado > 0 ? `${resultado} venda(s) classificada(s).` : 'Nenhuma venda nova classificada (todas já estavam classificadas).'}</Alert>
      )}

      <div className="flex justify-end gap-2">
        <Button variante="secondary" onClick={aplicarRegras} loading={aplicando} disabled={regras.length === 0}>Aplicar agora</Button>
      </div>

      {carregando ? (
        <Vazio mensagem="Carregando…" />
      ) : cards.length === 0 ? (
        <Vazio mensagem="Nenhum vendedor cadastrado. Cadastre vendedores na tela Vendedores." />
      ) : (
        <div className="space-y-3">
          {cards.map((c) => {
            const aberto = expandido.has(c.id)
            const gruposUnicos = [...new Set(c.regras.map((r) => r.group_id))]
            return (
              <Card key={c.id} className="overflow-hidden">
                <button
                  onClick={() => toggle(c.id)}
                  className="w-full flex items-center gap-3 px-5 py-3.5 hover:bg-surface-2 transition text-left"
                >
                  {aberto ? <ChevronDown size={18} className="text-fg-subtle shrink-0" /> : <ChevronRight size={18} className="text-fg-subtle shrink-0" />}
                  <span className="font-medium text-fg">{c.nome}</span>
                  <span className="text-xs text-fg-subtle tnum">{c.regras.length === 0 ? 'sem regras' : `${c.regras.length} ${c.regras.length === 1 ? 'condição' : 'condições'}`}</span>
                  <span className="ml-auto text-xs">
                    {gruposUnicos.length === 1 && nomeGrupo(gruposUnicos[0]) && (
                      <span className="bg-surface-2 border border-border rounded px-2 py-0.5 text-fg-muted">{nomeGrupo(gruposUnicos[0])}</span>
                    )}
                    {gruposUnicos.length > 1 && <span className="text-fg-subtle">vários grupos</span>}
                  </span>
                </button>

                {aberto && (
                  <div className="border-t border-border px-5 py-3 space-y-1.5">
                    {c.regras.map((r) => (
                      <div key={r.id} className="flex items-center gap-3 py-1.5 border-b border-border last:border-0">
                        <div className="flex flex-wrap gap-1 flex-1 min-w-0">
                          {condsDaRegra(r).map((cond) => (
                            <span key={cond} className="font-mono bg-surface-2 border border-border rounded px-1.5 py-0.5 text-[10px] text-fg-muted">{cond}</span>
                          ))}
                        </div>
                        <span className="text-xs text-fg-muted shrink-0 w-28 truncate">{nomeGrupo(r.group_id) ?? '— sem grupo —'}</span>
                        <div className="flex gap-3 shrink-0">
                          <button onClick={() => editarRegra(r)} className="text-brand hover:text-brand/70 text-xs transition">Editar</button>
                          <button onClick={() => excluirRegra(r.id)} className="text-expense hover:text-expense/70 text-xs transition">Excluir</button>
                        </div>
                      </div>
                    ))}
                    <button
                      onClick={() => adicionarCondicao(c.id)}
                      className="flex items-center gap-1.5 text-brand hover:text-brand/70 text-xs font-medium pt-2 transition"
                    >
                      <Plus size={14} /> adicionar condição
                    </button>
                  </div>
                )}
              </Card>
            )
          })}
        </div>
      )}

      {/* Modal criar/editar regra */}
      {modalRegra && (
        <Modal
          titulo={modalRegra.modo === 'criar' ? 'Nova condição' : 'Editar condição'}
          aberto={true}
          onFechar={() => setModalRegra(null)}
          largura="lg"
          footer={
            <div className="flex justify-end gap-2">
              <Button variante="secondary" onClick={() => setModalRegra(null)}>Cancelar</Button>
              <Button variante="primary" loading={salvando} disabled={!regraValida(novaRegra)} onClick={salvarRegra}>Salvar e aplicar</Button>
            </div>
          }
        >
          <div className="space-y-4">
            <div>
              <p className="text-xs text-fg-muted mb-2">Preencha ao menos um campo. A regra casa com vendas onde <strong>todos</strong> os campos preenchidos coincidem.</p>
              <div className="space-y-2">
                {([['SRC', 'src_value', 'src_match', 'ex: FB'], ['SCK', 'sck_value', 'sck_match', 'ex: raphaella_silva'], ['XCODE', 'xcode_value', 'xcode_match', 'ex: AF2024'], ['Afiliado', 'afiliado_value', 'afiliado_match', 'ex: Raphaela Silva']] as const).map(([label, valKey, matchKey, ph]) => (
                  <div key={valKey} className="flex items-center gap-2">
                    <span className="w-14 shrink-0 text-xs text-fg-muted font-mono">{label}</span>
                    <select
                      className="shrink-0 rounded-control border border-border bg-surface px-2 py-1 text-xs text-fg focus:outline-none focus:ring-1 focus:ring-brand"
                      value={novaRegra[matchKey]}
                      onChange={(e) => setNovaRegra((p) => ({ ...p, [matchKey]: e.target.value as MatchType }))}
                    >
                      <option value="exact">= exato</option>
                      <option value="contains">contém</option>
                      <option value="starts_with">começa com</option>
                      <option value="is_empty">é vazio</option>
                    </select>
                    {novaRegra[matchKey] !== 'is_empty' && (
                      <input
                        autoFocus={valKey === 'src_value'}
                        className={inputCls + ' flex-1'}
                        placeholder={ph}
                        value={novaRegra[valKey]}
                        onChange={(e) => setNovaRegra((p) => ({ ...p, [valKey]: e.target.value }))}
                      />
                    )}
                  </div>
                ))}
              </div>
            </div>
            <div>
              <label className="block text-xs text-fg-muted mb-1">Grupo</label>
              <select
                className={inputCls}
                value={novaRegra.group_id}
                onChange={(e) => e.target.value === NOVO ? (setNomeNovo(''), setModalCriar(true)) : setNovaRegra((p) => ({ ...p, group_id: e.target.value }))}
              >
                <option value="">— sem grupo —</option>
                {grupos.map((g) => <option key={g.id} value={g.id}>{g.nome}</option>)}
                <option value={NOVO}>+ Novo grupo...</option>
              </select>
            </div>
            <div>
              <label className="block text-xs text-fg-muted mb-1">Vendedor</label>
              <select
                className={inputCls}
                value={novaRegra.seller_id}
                onChange={(e) => setNovaRegra((p) => ({ ...p, seller_id: e.target.value }))}
              >
                <option value="">— sem vendedor —</option>
                {sellers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
              </select>
            </div>
          </div>
        </Modal>
      )}

      {/* Modal criar grupo — renderizado DEPOIS do modal de regra para ficar por cima (mesmo z-50) */}
      {modalCriar && (
        <Modal
          titulo="Novo grupo"
          aberto={true}
          onFechar={() => setModalCriar(false)}
          largura="lg"
          footer={
            <div className="flex justify-end gap-2">
              <Button variante="secondary" onClick={() => setModalCriar(false)}>Cancelar</Button>
              <Button variante="primary" loading={salvando} disabled={!nomeNovo.trim()} onClick={confirmarCriacaoGrupo}>Criar</Button>
            </div>
          }
        >
          <input
            autoFocus
            className={inputCls}
            placeholder="Nome do grupo"
            value={nomeNovo}
            onChange={(e) => setNomeNovo(e.target.value)}
            onKeyDown={(e) => { if (e.key === 'Enter') confirmarCriacaoGrupo() }}
          />
        </Modal>
      )}
    </div>
  )
}
