interface ProfilePermission {
  id: string
  role: unknown
}

/**
 * A interface só libera escrita quando o perfil administrativo carregado
 * pertence exatamente ao usuário autenticado. A RLS continua sendo a
 * autoridade final no banco.
 */
export function isAdminProfileForUser(
  profile: ProfilePermission | null | undefined,
  authenticatedUserId: string | null | undefined,
): boolean {
  return Boolean(
    authenticatedUserId
    && profile?.id === authenticatedUserId
    && profile.role === 'admin',
  )
}
