import { describe, it, expect } from 'vitest'
import { parseValor, parseData, vendaAprovada, parseHotmartCSV } from './hotmart'

// parseValor define o BRUTO de ~13k vendas. Mistura formato BR (1.234,56) e US
// (1,234.56) + milhar sem decimais — a math que já foi corrigida em auditoria.
describe('parseValor — BR, US, milhar e lixo', () => {
  it('formato BR com decimais', () => {
    expect(parseValor('1.234,56')).toBe(1234.56)
    expect(parseValor('R$ 1.234,56')).toBe(1234.56)
    expect(parseValor('123,5')).toBe(123.5)
    expect(parseValor('-50,00')).toBe(-50)
  })
  it('milhar BR sem decimais (dinheiro nunca tem 3 casas)', () => {
    expect(parseValor('1.234')).toBe(1234)
    expect(parseValor('12.345.678')).toBe(12345678)
  })
  it('formato US (vírgula de milhar, ponto decimal)', () => {
    expect(parseValor('1,234.56')).toBe(1234.56)
  })
  it('vazio/undefined/lixo vira 0 (nunca NaN)', () => {
    expect(parseValor('')).toBe(0)
    expect(parseValor(undefined)).toBe(0)
    expect(parseValor('abc')).toBe(0)
  })
})

describe('parseData — ISO, BR e lixo', () => {
  it('ISO passa direto', () => {
    expect(parseData('2026-01-15')).toBe('2026-01-15')
    expect(parseData('2026-01-15 10:00')).toBe('2026-01-15')
  })
  it('BR DD/MM/YYYY vira ISO', () => {
    expect(parseData('15/01/2026')).toBe('2026-01-15')
  })
  it('vazio/lixo vira null', () => {
    expect(parseData(undefined)).toBeNull()
    expect(parseData('')).toBeNull()
    expect(parseData('xx/yy/zzzz')).toBeNull()
  })
})

describe('vendaAprovada — allowlist de receita (PT+EN)', () => {
  it('aprovados contam', () => {
    for (const s of ['APPROVED', 'COMPLETE', 'aprovada', 'Concluída', 'COMPLETED'])
      expect(vendaAprovada(s)).toBe(true)
  })
  it('não-aprovados NÃO contam', () => {
    for (const s of ['REFUNDED', 'WAITING_PAYMENT', 'BILLET_PRINTED', 'EXPIRED', 'CHARGEBACK', 'CANCELED'])
      expect(vendaAprovada(s)).toBe(false)
  })
})

describe('parseHotmartCSV — detecção de coluna + parse de linha', () => {
  const csv = [
    'Código da transação;Produto;Data da venda;Valor total;Status',
    'HP123;Curso X;15/01/2026;R$ 297,00;APPROVED',
    ';Sem código;15/01/2026;R$ 10,00;APPROVED', // sem código → erro, ignorada
  ].join('\n')
  const { vendas, erros } = parseHotmartCSV(csv)

  it('parseia a venda válida com código, data ISO e total', () => {
    expect(vendas).toHaveLength(1)
    expect(vendas[0]).toMatchObject({
      transaction_code: 'HP123', product: 'Curso X', sale_date: '2026-01-15',
      total_amount: 297, status: 'APPROVED',
    })
  })
  it('reporta a linha sem código como erro', () => {
    expect(erros.length).toBe(1)
  })
})
