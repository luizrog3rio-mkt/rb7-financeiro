import { expect, test } from '@playwright/test'

const authState = process.env.E2E_AUTH_STATE
const expectedRole = process.env.E2E_EXPECTED_ROLE

test.skip(!authState, 'Defina E2E_AUTH_STATE para executar o smoke autenticado.')

test('produção autenticada carrega os gráficos financeiros', async ({ page }) => {
  await page.goto('/')

  await expect(page.getByRole('heading', { name: 'Dashboard', exact: true })).toBeVisible({ timeout: 30_000 })
  await expect(page.getByRole('heading', { name: 'Fluxo de caixa por vencimento' })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Gasto por fatura' })).toBeVisible()
  await expect(page.locator('.recharts-responsive-container')).toHaveCount(2)
})

test('menu administrativo respeita o papel esperado', async ({ page }) => {
  test.skip(!expectedRole, 'Defina E2E_EXPECTED_ROLE como admin ou viewer para validar o menu.')
  await page.goto('/')

  const usuarios = page.getByRole('link', { name: 'Usuários' })
  if (expectedRole === 'admin') await expect(usuarios).toBeVisible()
  else if (expectedRole === 'viewer') await expect(usuarios).toHaveCount(0)
  else throw new Error('E2E_EXPECTED_ROLE deve ser admin ou viewer.')
})
