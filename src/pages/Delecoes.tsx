import { useCallback, useEffect, useState } from 'react'
import { supabase } from '../lib/supabase'
import { Card, PageHeader, Vazio, ErroBanner } from '../components/ui'

// Log forense de deleções (deletions_log via RPC listar_delecoes). Read-only: o trigger
// BEFORE DELETE em entries/invoices captura quem/quando/snapshot; aqui só exibimos.
interface Delecao { id: string; quando: string; tabela: string; por: string; resumo: string }

const fmtQuando = (iso: string) =>
  new Date(iso).toLocaleString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })

const rotuloTabela = (t: string) => (t === 'entries' ? 'Lançamento' : t === 'invoices' ? 'Fatura' : t)

export default function Delecoes() {
  const [linhas, setLinhas] = useState<Delecao[]>([])
  const [carregando, setCarregando] = useState(true)
  const [erro, setErro] = useState<string | null>(null)

  const carregar = useCallback(async () => {
    setCarregando(true)
    const { data, error } = await supabase.rpc('listar_delecoes', { p_limit: 200 })
    if (error) setErro('Erro ao carregar o log: ' + error.message)
    setLinhas((data as Delecao[]) ?? [])
    setCarregando(false)
  }, [])

  useEffect(() => { carregar() }, [carregar])

  return (
    <div>
      <PageHeader
        titulo="Log de Deleções"
        subtitulo="Rastro forense de lançamentos e faturas excluídos — quem, quando e o conteúdo removido. Append-only (não editável)."
      />
      <ErroBanner mensagem={erro} />
      <Card>
        {carregando ? (
          <Vazio mensagem="Carregando…" />
        ) : linhas.length === 0 ? (
          <Vazio mensagem="Nenhuma deleção registrada. (O rastro começou a ser gravado em 30/06/2026.)" />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="text-left text-xs text-fg-subtle border-b border-border">
                  <th className="px-4 py-2.5 font-medium whitespace-nowrap">Quando</th>
                  <th className="px-4 py-2.5 font-medium">Tipo</th>
                  <th className="px-4 py-2.5 font-medium">O que foi excluído</th>
                  <th className="px-4 py-2.5 font-medium">Por quem</th>
                </tr>
              </thead>
              <tbody>
                {linhas.map((l) => (
                  <tr key={l.id} className="border-b border-border/60">
                    <td className="px-4 py-2 text-fg-muted whitespace-nowrap tnum">{fmtQuando(l.quando)}</td>
                    <td className="px-4 py-2">
                      <span className="text-xs px-2 py-0.5 rounded-control bg-surface-2 text-fg-muted">{rotuloTabela(l.tabela)}</span>
                    </td>
                    <td className="px-4 py-2 text-fg">{l.resumo}</td>
                    <td className="px-4 py-2 text-fg-subtle">{l.por}</td>
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
