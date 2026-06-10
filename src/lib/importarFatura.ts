import { supabase } from './supabase'
import { parseOFXCartao, type RegraUI } from './fatura'
import type { Invoice, PurchaseItem } from './types'

// Fluxo de import de fatura de cartão — port do handleFile do App.jsx, com
// duas evoluções conscientes: grava invoices.account_id (Fase 1c) e CHECA
// erros (o app antigo engolia). Sem dedupe de reimport (contrato #14:
// comportamento preservado — reimportar cria fatura duplicada).
export interface ResultadoImport {
  invoice: Invoice
  pendentes: PurchaseItem[]
}

export async function importarFaturaOFX(
  file: File,
  regras: RegraUI[],
  userId: string,
  accountId: string | null
): Promise<{ ok: ResultadoImport | null; erro: string | null }> {
  const text = await file.text()
  const txs = parseOFXCartao(text, regras)
  const total = txs.reduce((s, t) => s + t.amount, 0)

  const { data: inv, error: e1 } = await supabase
    .from('invoices')
    .insert({
      user_id: userId,
      name: file.name.replace(/\.ofx$/i, ''),
      total,
      transaction_count: txs.length,
      account_id: accountId,
    })
    .select()
    .single()
  if (e1 || !inv) return { ok: null, erro: 'Erro ao criar a fatura: ' + (e1?.message ?? 'sem retorno') }

  if (txs.length > 0) {
    const rows = txs.map((t) => ({
      user_id: userId,
      invoice_id: inv.id,
      fit_id: t.fit_id,
      memo: t.memo,
      amount: t.amount,
      date: t.date,
      category: t.category,
      auto_categorized: t.auto,
    }))
    const { error: e2 } = await supabase.from('transactions').insert(rows)
    if (e2) return { ok: null, erro: 'Fatura criada, mas falhou ao inserir lançamentos: ' + e2.message }
  }

  // pendentes pra oferecer no modal (contrato #7)
  const { data: pendentes } = await supabase
    .from('purchase_items')
    .select('*')
    .is('invoice_id', null)
    .order('month', { ascending: false })
    .order('created_at')

  return { ok: { invoice: inv, pendentes: pendentes ?? [] }, erro: null }
}
