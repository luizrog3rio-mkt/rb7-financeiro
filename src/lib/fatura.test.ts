import { describe, it, expect } from 'vitest'
import { parseOFXCartao, valorComSinal, formatMonth } from './fatura'

// Coração do "mundo fatura": o sinal contábil e a classificação de cada lançamento.
// Esta é a classe de bug que JÁ inflou o total das faturas antes de 2026-06-22.

describe('valorComSinal — fonte única do sinal contábil', () => {
  it('débito (despesa) soma positivo', () => {
    expect(valorComSinal({ amount: 100, kind: 'debit' })).toBe(100)
  })
  it('crédito (estorno/desconto) abate (negativo)', () => {
    expect(valorComSinal({ amount: 100, kind: 'credit' })).toBe(-100)
  })
  it('total de uma fatura = soma com sinal (débitos − créditos)', () => {
    const txs = [
      { amount: 50, kind: 'debit' as const },
      { amount: 20, kind: 'credit' as const },
      { amount: 12.34, kind: 'debit' as const },
    ]
    expect(txs.reduce((s, t) => s + valorComSinal(t), 0)).toBeCloseTo(42.34, 2)
  })
})

describe('parseOFXCartao — parser OFX da fatura de cartão', () => {
  const ofx = [
    '<OFX>',
    '<STMTTRN><TRNTYPE>PAYMENT<DTPOSTED>20260115120000<TRNAMT>-50.00<FITID>A1<MEMO>COMPRA MERCADO</STMTTRN>',
    '<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20260116<TRNAMT>20.00<FITID>A2<MEMO>ESTORNO LOJA</STMTTRN>',
    '<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20260117<TRNAMT>1000.00<FITID>A3<MEMO>PAGAMENTO FATURA ANTERIOR</STMTTRN>',
    '<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20260118<TRNAMT>900.00<FITID>A4<MEMO>BOLETO BANCARIO</STMTTRN>',
    '<STMTTRN><TRNTYPE>PAYMENT<DTPOSTED>20260119<TRNAMT>-12.34<FITID>A5<MEMO>CAFE &amp; CIA</STMTTRN>',
    '<STMTTRN><TRNTYPE>PAYMENT<DTPOSTED>20260120<FITID>A6<MEMO>SEM VALOR</STMTTRN>',
    '</OFX>',
  ].join('\n')
  const txs = parseOFXCartao(ofx)

  it('descarta o pagamento da fatura anterior (CREDIT + /PAGAMENTO|BOLETO/) e a linha sem valor', () => {
    // A1 (despesa) + A2 (estorno) + A5 (despesa) entram; A3/A4 (pagamento) e A6 (sem TRNAMT) saem
    expect(txs.map((t) => t.fit_id)).toEqual(['A1', 'A2', 'A5'])
  })
  it('despesa (PAYMENT) vira kind=debit com amount em magnitude positiva', () => {
    expect(txs[0]).toMatchObject({ kind: 'debit', amount: 50, date: '15/01/2026', memo: 'COMPRA MERCADO' })
  })
  it('estorno (CREDIT que não é pagamento) vira kind=credit', () => {
    expect(txs[1]).toMatchObject({ kind: 'credit', amount: 20, memo: 'ESTORNO LOJA' })
  })
  it('DTPOSTED YYYYMMDD[HHMMSS] vira DD/MM/YYYY e &amp; vira &', () => {
    expect(txs[2]).toMatchObject({ date: '19/01/2026', memo: 'CAFE & CIA', amount: 12.34 })
  })
  it('o total da fatura via valorComSinal abate o estorno', () => {
    expect(txs.reduce((s, t) => s + valorComSinal(t), 0)).toBeCloseTo(42.34, 2)
  })
  it('OFX vazio/sem STMTTRN retorna lista vazia', () => {
    expect(parseOFXCartao('')).toEqual([])
    expect(parseOFXCartao('<OFX></OFX>')).toEqual([])
  })
})

describe('formatMonth', () => {
  it('YYYY-MM vira Mmm/YYYY', () => {
    expect(formatMonth('2026-01')).toBe('Jan/2026')
    expect(formatMonth('2026-12')).toBe('Dez/2026')
  })
  it('null vira "Sem mês"', () => {
    expect(formatMonth(null)).toBe('Sem mês')
  })
})
