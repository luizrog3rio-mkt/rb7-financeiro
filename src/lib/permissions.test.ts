import { describe, expect, it } from 'vitest'
import { isAdminProfileForUser } from './permissions'

describe('isAdminProfileForUser', () => {
  it('libera somente o admin da sessão atual', () => {
    expect(isAdminProfileForUser({ id: 'user-1', role: 'admin' }, 'user-1')).toBe(true)
  })

  it('mantém viewer em modo somente leitura', () => {
    expect(isAdminProfileForUser({ id: 'user-1', role: 'viewer' }, 'user-1')).toBe(false)
  })

  it('falha fechado enquanto sessão ou perfil não carregaram', () => {
    expect(isAdminProfileForUser(null, 'user-1')).toBe(false)
    expect(isAdminProfileForUser({ id: 'user-1', role: 'admin' }, null)).toBe(false)
  })

  it('não reaproveita perfil admin de uma sessão anterior', () => {
    expect(isAdminProfileForUser({ id: 'admin-antigo', role: 'admin' }, 'user-atual')).toBe(false)
  })

  it('falha fechado para um papel inesperado vindo do banco', () => {
    expect(isAdminProfileForUser({ id: 'user-1', role: 'owner' }, 'user-1')).toBe(false)
  })
})
