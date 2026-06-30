import { describe, it, expect, vi, afterEach } from 'vitest'
import { fmtData, hoje, primeiroDiaMes, ultimoDiaMes } from './format'

describe('fmtData — ISO YYYY-MM-DD para DD/MM/YYYY', () => {
  it('formata data simples', () => {
    expect(fmtData('2026-01-15')).toBe('15/01/2026')
  })
  it('aceita timestamp e corta no dia', () => {
    expect(fmtData('2026-01-15T10:00:00Z')).toBe('15/01/2026')
  })
  it('null/undefined vira travessão', () => {
    expect(fmtData(null)).toBe('—')
    expect(fmtData(undefined)).toBe('—')
  })
})

describe('datas locais (NÃO UTC — isoLocal evita o off-by-one perto da meia-noite)', () => {
  afterEach(() => vi.useRealTimers())

  it('hoje() usa os componentes LOCAIS da data', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 0, 15, 12, 0, 0)) // 15/jan/2026 meio-dia local
    expect(hoje()).toBe('2026-01-15')
  })
  it('primeiroDiaMes e ultimoDiaMes do mês corrente', () => {
    vi.useFakeTimers()
    vi.setSystemTime(new Date(2026, 0, 15, 12, 0, 0)) // janeiro
    expect(primeiroDiaMes()).toBe('2026-01-01')
    expect(ultimoDiaMes()).toBe('2026-01-31')
  })
  it('ultimoDiaMes respeita ano bissexto em fevereiro', () => {
    expect(ultimoDiaMes(new Date(2024, 1, 10))).toBe('2024-02-29') // 2024 bissexto
    expect(ultimoDiaMes(new Date(2026, 1, 10))).toBe('2026-02-28') // 2026 não
  })
})
