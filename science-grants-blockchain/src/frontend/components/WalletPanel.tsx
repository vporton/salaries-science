import React, { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { getWalletBalance, createUserWallet, getWalletAccountId } from '../services/api'

interface WalletPanelProps {
  onBalanceUpdate?: (balance: number) => void
}

export const WalletPanel: React.FC<WalletPanelProps> = ({ onBalanceUpdate }) => {
  const { isAuthenticated } = useAuth()
  const [balance, setBalance] = useState<number>(0)
  const [accountId, setAccountId] = useState<string>('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const loadWalletInfo = async () => {
    if (!isAuthenticated) return

    try {
      setLoading(true)
      setError('')

      // Try to get wallet balance
      const balanceResult = await getWalletBalance()
      if (balanceResult.success && balanceResult.balance !== undefined) {
        setBalance(balanceResult.balance)
        onBalanceUpdate?.(balanceResult.balance)
      } else {
        // Wallet doesn't exist, create it
        const createResult = await createUserWallet()
        if (createResult.success) {
          // Try to get balance again
          const newBalanceResult = await getWalletBalance()
          if (newBalanceResult.success && newBalanceResult.balance !== undefined) {
            setBalance(newBalanceResult.balance)
            onBalanceUpdate?.(newBalanceResult.balance)
          }
        } else {
          setError('Failed to create wallet')
        }
      }

      // Get account ID for deposits
      const accountResult = await getWalletAccountId()
      if (accountResult.success && accountResult.accountId) {
        setAccountId(accountResult.accountId)
      }
    } catch (err) {
      setError('Failed to load wallet information')
      console.error('Wallet error:', err)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (isAuthenticated) {
      loadWalletInfo()
    }
  }, [isAuthenticated])

  const formatBalance = (balance: number) => {
    return (balance / 100000000).toFixed(8) // Convert from e8s to ICP
  }

  const copyAccountId = async () => {
    if (accountId) {
      try {
        await navigator.clipboard.writeText(accountId)
        // You could add a toast notification here
      } catch (err) {
        console.error('Failed to copy account ID:', err)
      }
    }
  }

  if (!isAuthenticated) {
    return (
      <div className="card">
        <h3 className="text-lg font-semibold mb-4">Wallet</h3>
        <p className="text-gray-600 text-center py-4">
          Please connect your wallet to view your balance
        </p>
      </div>
    )
  }

  return (
    <div className="card">
      <h3 className="text-lg font-semibold mb-4">Your Wallet</h3>
      
      {loading ? (
        <div className="text-center py-4">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
          <p className="text-gray-600 mt-2">Loading wallet...</p>
        </div>
      ) : error ? (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3 mb-4">
          <p className="text-red-700 text-sm">{error}</p>
          <button
            onClick={loadWalletInfo}
            className="text-red-600 hover:text-red-800 text-sm mt-2"
          >
            Try again
          </button>
        </div>
      ) : (
        <div className="space-y-4">
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <div className="flex justify-between items-center">
              <span className="text-blue-700 font-medium">Balance</span>
              <span className="text-blue-900 font-bold text-lg">
                {formatBalance(balance)} ICP
              </span>
            </div>
          </div>

          {accountId && (
            <div className="bg-gray-50 border border-gray-200 rounded-lg p-4">
              <div className="flex justify-between items-center mb-2">
                <span className="text-gray-700 font-medium">Account ID</span>
                <button
                  onClick={copyAccountId}
                  className="text-blue-600 hover:text-blue-800 text-sm"
                >
                  Copy
                </button>
              </div>
              <div className="bg-white border border-gray-300 rounded p-2">
                <code className="text-xs text-gray-600 break-all">
                  {accountId}
                </code>
              </div>
              <p className="text-xs text-gray-500 mt-2">
                Use this account ID to deposit ICP into your wallet
              </p>
            </div>
          )}

          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-3">
            <p className="text-yellow-800 text-sm">
              💡 <strong>Tip:</strong> Transfer ICP to your account ID above to fund your wallet for donations.
            </p>
          </div>

          <button
            onClick={loadWalletInfo}
            disabled={loading}
            className="btn-secondary w-full"
          >
            {loading ? 'Refreshing...' : 'Refresh Balance'}
          </button>
        </div>
      )}
    </div>
  )
}
