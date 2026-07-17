import { expect, test } from '@playwright/test'

test.use({ storageState: { cookies: [], origins: [] } })

test('rota protegida exibe o login sem sessão', async ({ page }) => {
  await page.goto('/dre')

  await expect(page).toHaveTitle('RB7 Financeiro')
  await expect(page.getByRole('heading', { name: 'RB7 Financeiro' })).toBeVisible()
  await expect(page.getByLabel('E-mail')).toBeVisible()
  await expect(page.getByLabel('Senha')).toBeVisible()
  await expect(page.getByRole('button', { name: 'Entrar' })).toBeEnabled()
})
