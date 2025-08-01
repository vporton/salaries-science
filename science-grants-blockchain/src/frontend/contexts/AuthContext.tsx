import React, { createContext, useContext, useState, useEffect } from 'react'
import { AuthClient } from '@dfinity/auth-client'
import { Principal } from '@dfinity/principal'

interface AuthContextType {
  isAuthenticated: boolean
  principal: Principal | null
  login: () => Promise<void>
  logout: () => Promise<void>
  authClient: AuthClient | null
}

const AuthContext = createContext<AuthContextType>({
  isAuthenticated: false,
  principal: null,
  login: async () => {},
  logout: async () => {},
  authClient: null,
})

export const useAuth = () => useContext(AuthContext)

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false)
  const [principal, setPrincipal] = useState<Principal | null>(null)
  const [authClient, setAuthClient] = useState<AuthClient | null>(null)

  useEffect(() => {
    initAuth()
  }, [])

  const initAuth = async () => {
    const client = await AuthClient.create()
    setAuthClient(client)

    const isAuthenticated = await client.isAuthenticated()
    setIsAuthenticated(isAuthenticated)

    if (isAuthenticated) {
      const identity = client.getIdentity()
      setPrincipal(identity.getPrincipal())
    }
  }

  const login = async () => {
    if (!authClient) return

    await authClient.login({
      identityProvider: process.env.NODE_ENV === 'production' 
        ? 'https://identity.ic0.app'
        : `http://localhost:8000?canisterId=${process.env.INTERNET_IDENTITY_CANISTER_ID}`,
      onSuccess: () => {
        setIsAuthenticated(true)
        const identity = authClient.getIdentity()
        setPrincipal(identity.getPrincipal())
      },
    })
  }

  const logout = async () => {
    if (!authClient) return

    await authClient.logout()
    setIsAuthenticated(false)
    setPrincipal(null)
  }

  return (
    <AuthContext.Provider value={{
      isAuthenticated,
      principal,
      login,
      logout,
      authClient,
    }}>
      {children}
    </AuthContext.Provider>
  )
}