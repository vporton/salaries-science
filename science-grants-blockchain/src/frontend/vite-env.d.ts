/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_INTERNET_IDENTITY_CANISTER_ID: string
  readonly MODE: string
  // more env variables...
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}