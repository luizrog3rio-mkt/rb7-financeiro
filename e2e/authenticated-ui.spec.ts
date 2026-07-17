import { expect, test } from '@playwright/test'
import { mockAuthenticatedSupabase } from './support/mockSupabase'

test.use({ storageState: { cookies: [], origins: [] } })

test('admin vê dashboard, gráficos e menu administrativo', async ({ page }) => {
  await mockAuthenticatedSupabase(page, 'admin')
  await page.goto('/')

  await expect(page.getByRole('heading', { name: 'Dashboard', exact: true })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Fluxo de caixa por vencimento' })).toBeVisible()
  await expect(page.getByRole('heading', { name: 'Gasto por fatura' })).toBeVisible()
  await expect(page.locator('.recharts-responsive-container')).toHaveCount(2)
  expect(await page.locator('svg.recharts-surface').count()).toBeGreaterThanOrEqual(2)
  await expect(page.getByRole('link', { name: 'Usuários' })).toBeVisible()
})

test('viewer vê os relatórios sem receber controles administrativos', async ({ page }) => {
  await mockAuthenticatedSupabase(page, 'viewer')
  await page.goto('/')

  await expect(page.getByRole('heading', { name: 'Dashboard', exact: true })).toBeVisible()
  await expect(page.locator('.recharts-responsive-container')).toHaveCount(2)
  await expect(page.getByRole('link', { name: 'Usuários' })).toHaveCount(0)
})
