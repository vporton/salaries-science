import React, { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'
import { donate, getWalletBalance } from '../services/api'

interface DonationFormProps {
  projectId: string
  onSuccess: () => void
}

export const DonationForm: React.FC<DonationFormProps> = ({ projectId, onSuccess }) => {
  const { isAuthenticated } = useAuth()
  const [amount, setAmount] = useState('')
  const [dependencyPercentage, setDependencyPercentage] = useState(50)
  const [affiliatePercentage, setAffiliatePercentage] = useState(60)
  const [affiliateAddress, setAffiliateAddress] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [walletBalance, setWalletBalance] = useState<number>(0)
  const [balanceLoading, setBalanceLoading] = useState(false)

  const loadWalletBalance = async () => {
    if (!isAuthenticated) return
    
    try {
      setBalanceLoading(true)
      const result = await getWalletBalance()
      if (result.success && result.balance !== undefined) {
        setWalletBalance(result.balance)
      }
    } catch (err) {
      console.error('Failed to load wallet balance:', err)
    } finally {
      setBalanceLoading(false)
    }
  }

  useEffect(() => {
    if (isAuthenticated) {
      loadWalletBalance()
    }
  }, [isAuthenticated])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    
    if (!isAuthenticated) {
      setError('Please connect your wallet first')
      return
    }

    if (!amount || parseFloat(amount) <= 0) {
      setError('Please enter a valid donation amount')
      return
    }

    const donationAmount = parseFloat(amount)
    const donationAmountE8s = donationAmount * 100000000 // Convert to e8s

    if (donationAmountE8s > walletBalance) {
      setError('Insufficient wallet balance. Please fund your wallet first.')
      return
    }

    try {
      setLoading(true)
      setError('')
      
      // In real implementation, this would call the canister
      await donate({
        projectId,
        amount: donationAmount,
        dependencyPercentage,
        affiliatePercentage,
        affiliateAddress: affiliateAddress || undefined,
      })

      // Refresh wallet balance after donation
      await loadWalletBalance()
      onSuccess()
    } catch (err) {
      setError('Failed to process donation. Please try again.')
      console.error('Donation error:', err)
    } finally {
      setLoading(false)
    }
  }

  const calculateDistribution = () => {
    const total = parseFloat(amount) || 0
    const affiliateAmount = affiliateAddress ? (total * affiliatePercentage) / 100 : 0
    const remaining = total - affiliateAmount
    const dependenciesAmount = (remaining * dependencyPercentage) / 100
    const projectAmount = remaining - dependenciesAmount

    return {
      total,
      affiliateAmount,
      dependenciesAmount,
      projectAmount
    }
  }

  const distribution = calculateDistribution()

  return (
    <form onSubmit={handleSubmit} className="card space-y-6">
      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Donation Amount (ICP)
        </label>
        <div className="relative">
          <input
            type="number"
            step="0.01"
            min="0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            className="input-field"
            placeholder="Enter amount..."
            required
          />
          {isAuthenticated && (
            <div className="mt-2 text-sm text-gray-600">
              {balanceLoading ? (
                <span>Loading wallet balance...</span>
              ) : (
                <span>
                  Wallet Balance: {(walletBalance / 100000000).toFixed(8)} ICP
                </span>
              )}
            </div>
          )}
        </div>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Dependency Allocation: {dependencyPercentage}%
        </label>
        <input
          type="range"
          min="0"
          max="100"
          value={dependencyPercentage}
          onChange={(e) => setDependencyPercentage(parseInt(e.target.value))}
          className="w-full"
        />
        <p className="text-sm text-gray-500 mt-1">
          This percentage goes to project dependencies
        </p>
      </div>

      <div>
        <label className="block text-sm font-medium text-gray-700 mb-2">
          Affiliate Address (Optional)
        </label>
        <input
          type="text"
          value={affiliateAddress}
          onChange={(e) => setAffiliateAddress(e.target.value)}
          className="input-field"
          placeholder="Enter affiliate principal..."
        />
        {affiliateAddress && (
          <div className="mt-2">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Affiliate Commission: {affiliatePercentage}%
            </label>
            <input
              type="range"
              min="0"
              max="100"
              value={affiliatePercentage}
              onChange={(e) => setAffiliatePercentage(parseInt(e.target.value))}
              className="w-full"
            />
          </div>
        )}
      </div>

      {distribution.total > 0 && (
        <div className="bg-gray-50 rounded-lg p-4 space-y-2">
          <h3 className="font-semibold text-gray-700 mb-2">Donation Distribution</h3>
          {distribution.affiliateAmount > 0 && (
            <div className="flex justify-between text-sm">
              <span className="text-gray-600">Affiliate:</span>
              <span className="font-medium">{distribution.affiliateAmount.toFixed(2)} ICP</span>
            </div>
          )}
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Dependencies:</span>
            <span className="font-medium">{distribution.dependenciesAmount.toFixed(2)} ICP</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-gray-600">Main Project:</span>
            <span className="font-medium">{distribution.projectAmount.toFixed(2)} ICP</span>
          </div>
          <div className="border-t pt-2 flex justify-between font-semibold">
            <span>Total:</span>
            <span>{distribution.total.toFixed(2)} ICP</span>
          </div>
        </div>
      )}

      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-3">
          <p className="text-red-700 text-sm">{error}</p>
        </div>
      )}

      <button
        type="submit"
        disabled={loading || !isAuthenticated}
        className="btn-primary w-full"
      >
        {loading ? 'Processing...' : 'Donate Now'}
      </button>

      {!isAuthenticated && (
        <p className="text-center text-sm text-gray-500">
          Please connect your wallet to make a donation
        </p>
      )}
    </form>
  )
}