import { defineConfig } from 'vite'
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
})
