import { useEffect, useRef } from 'react'
import { supabase } from '../lib/supabase'

interface Options {
  /** Filtro Realtime no formato PostgREST, ex.: `company_id=eq.<uuid>`.
   *  Omitido = ouve todas as linhas da tabela (ex.: modo consolidado). */
  filter?: string
  /** Janela de coalescência de rajadas (ms). Default 600. */
  debounceMs?: number
  /** Pausa a assinatura (ex.: enquanto sessão/empresa não carregou). Default true. */
  enabled?: boolean
}

/**
 * Assina `postgres_changes` de `table` e dispara `onChange` (debounced) a cada
 * INSERT/UPDATE/DELETE. Pensado pra "refetch on change": quando os dados vêm de
 * RPCs agregadas (KPIs), re-buscar tudo é mais simples e correto que merge
 * incremental no cliente. Em uso na tela Hotmart, onde o webhook hotmart-webhook
 * grava/atualiza hotmart_sales e a página precisa refletir sem reload.
 *
 * `onChange` é lido via ref → a assinatura NÃO recria quando o callback muda (ex.:
 * quando o filtro de datas reescreve o carregar()). Só recria quando muda
 * table/filter/enabled, evitando re-subscribe do WebSocket a cada ajuste de UI.
 *
 * Canal PÚBLICO de propósito: postgres_changes autoriza via RLS do banco contra o
 * JWT do socket — NÃO usar private channel (isso é pra Broadcast/Presence). Com a
 * policy de equipe `using(true)` pra authenticated, o usuário logado recebe; anon
 * (publishable key sozinha) não recebe nada.
 */
export function useRealtimeRefetch(
  table: string,
  onChange: () => void,
  { filter, debounceMs = 600, enabled = true }: Options = {},
) {
  // mantém o callback atual sem torná-lo dependência da assinatura
  const onChangeRef = useRef(onChange)
  useEffect(() => {
    onChangeRef.current = onChange
  })

  const timer = useRef<ReturnType<typeof setTimeout> | undefined>(undefined)

  useEffect(() => {
    if (!enabled) return

    // event:'*' = INSERT|UPDATE|DELETE; o webhook faz upsert (INSERT/UPDATE).
    const cfg: { event: '*'; schema: string; table: string; filter?: string } = {
      event: '*',
      schema: 'public',
      table,
    }
    if (filter) cfg.filter = filter

    const ch = supabase
      .channel(`rt:${table}:${filter ?? 'all'}`)
      .on('postgres_changes', cfg, () => {
        if (timer.current) clearTimeout(timer.current)
        timer.current = setTimeout(() => onChangeRef.current(), debounceMs)
      })
      .subscribe()

    return () => {
      if (timer.current) clearTimeout(timer.current)
      timer.current = undefined
      supabase.removeChannel(ch)
    }
  }, [table, filter, debounceMs, enabled])
}
