import { describe, it, expect } from 'vitest'
import { parseOfxExtrato } from './ofxExtrato'

// Gêmeo perigoso do parser de cartão: aqui o SINAL é PRESERVADO (débito negativo),
// data vira YYYY-MM-DD, e MEMO cai pra NAME. Roda pela 1ª vez direto em produção
// (bank_transactions está vazio), então o teste é a única rede que existe.
describe('parseOfxExtrato — extrato bancário', () => {
  const ofx = [
    '<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20260115<TRNAMT>-50.00<FITID>B1<MEMO>SAQUE CAIXA</STMTTRN>',
    '<STMTTRN><TRNTYPE>CREDIT<DTPOSTED>20260116<TRNAMT>100.00<FITID>B2<NAME>DEPOSITO PIX</STMTTRN>',
    '<STMTTRN><TRNTYPE>DEBIT<DTPOSTED>20260117<TRNAMT>-12.34<MEMO>SEM FITID</STMTTRN>',
    '<STMTTRN><TRNTYPE>DEBIT<TRNAMT>-9.99<MEMO>SEM DATA</STMTTRN>',
  ].join('\n')
  const txs = parseOfxExtrato(ofx)

  it('preserva o SINAL do valor (débito negativo, crédito positivo)', () => {
    expect(txs.map((t) => t.valor)).toEqual([-50, 100, -12.34])
  })
  it('DTPOSTED YYYYMMDD vira YYYY-MM-DD', () => {
    expect(txs[0].data).toBe('2026-01-15')
  })
  it('MEMO ausente cai pra NAME', () => {
    expect(txs[1].memo).toBe('DEPOSITO PIX')
  })
  it('FITID ausente vira string vazia (sintetizado depois no import)', () => {
    expect(txs[2].fitid).toBe('')
  })
  it('lançamento sem data é descartado (exige data + valor)', () => {
    // o 4º bloco não tem DTPOSTED → fora; sobram 3
    expect(txs).toHaveLength(3)
  })
  it('é case-insensitive e tolera tag sem fechamento', () => {
    const minus = '<stmttrn><trntype>debit<dtposted>20260201<trnamt>-7.00<memo>minusculo'
    expect(parseOfxExtrato(minus)).toEqual([{ fitid: '', data: '2026-02-01', valor: -7, memo: 'minusculo', tipo: 'debit' }])
  })
})
