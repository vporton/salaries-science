// Polyfills for DFINITY agent in browser environment
if (typeof global === 'undefined') {
  (window as any).global = window;
}

if (typeof process === 'undefined') {
  (window as any).process = { env: {} };
}

import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App'
import './index.css'

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)