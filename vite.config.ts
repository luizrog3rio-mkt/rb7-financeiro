import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'

// versão do build: SHA curto do commit (Vercel) ou 'dev' no local
const versao = (process.env.VERCEL_GIT_COMMIT_SHA ?? '').slice(0, 7) || 'dev'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  define: {
    __APP_VERSION__: JSON.stringify(versao),
  },
  // testes: funções puras de matemática de dinheiro (parsers/sinal/datas) rodam em
  // 'node' sem jsdom. NÃO importar ./supabase em código testado aqui.
  test: {
    environment: 'node',
    include: ['src/**/*.test.ts'],
  },
  build: {
    rollupOptions: {
      output: {
        // framework + supabase num chunk cacheável: mudam pouco, então um deploy
        // novo (só código de app) não invalida o download deles no cliente.
        // recharts/xlsx seguem nos próprios chunks (lazy / import dinâmico).
        // Forma-função (o rolldown tipa manualChunks como função, não objeto).
        manualChunks(id) {
          if (!id.includes('node_modules')) return
          if (id.includes('@supabase')) return 'supabase'
          if (
            id.includes('/react/') ||
            id.includes('/react-dom/') ||
            id.includes('/react-router') ||
            id.includes('/scheduler/')
          )
            return 'react-vendor'
        },
      },
    },
  },
})
