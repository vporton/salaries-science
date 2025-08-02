import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig(({ mode }) => {
  // Load env file based on `mode` in the current working directory.
  const env = loadEnv(mode, process.cwd(), '')
  
  // Create define object for environment variables
  const defineEnv = {}
  
  // Add CANISTER_ prefixed variables
  Object.keys(env).forEach(key => {
    if (key.startsWith('CANISTER_')) {
      defineEnv[`import.meta.env.${key}`] = JSON.stringify(env[key])
    }
  })
  
  // Add DFX_ prefixed variables
  Object.keys(env).forEach(key => {
    if (key.startsWith('DFX_')) {
      defineEnv[`import.meta.env.${key}`] = JSON.stringify(env[key])
    }
  })
  
  // Add II_ prefixed variables
  Object.keys(env).forEach(key => {
    if (key.startsWith('II_')) {
      defineEnv[`import.meta.env.${key}`] = JSON.stringify(env[key])
    }
  })

  return {
    root: './src/frontend',
    build: {
      outDir: '../../dist',
      emptyOutDir: true,
    },
    server: {
      proxy: {
        '/api': {
          target: 'http://localhost:8080',
          changeOrigin: true,
        }
      }
    },
    plugins: [
      react(),
      // nodePolyfills(),
    ],
    define: defineEnv,
  }
})