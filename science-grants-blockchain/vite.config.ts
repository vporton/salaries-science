import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import environment from 'vite-plugin-environment';

export default defineConfig({
  root: './src/frontend',
  build: {
    outDir: '../../dist',
    emptyOutDir: true,
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      }
    }
  },
  plugins: [
    react(),
    // nodePolyfills(),
    environment("all", { prefix: "CANISTER_", defineOn: 'process.env' }),
    environment("all", { prefix: "DFX_", defineOn: 'process.env' }),
    environment("all", { prefix: "II_", defineOn: 'process.env' }),
  ],
  define: {
    'process.env.II_URL': JSON.stringify(process.env.II_URL || 'http://localhost:4943'),
  },
})