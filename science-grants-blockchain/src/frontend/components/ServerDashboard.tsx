import React, { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'

interface ServerStats {
  status: 'active' | 'inactive' | 'disqualified'
  stake: number
  challengesWon: number
  challengesLost: number
  rewardsEarned: number
  dependenciesWritten: number
}

interface Challenge {
  id: string
  type: 'incoming' | 'outgoing'
  opponent: string
  parentVersion: string
  status: 'pending' | 'resolved'
  timestamp: Date
}

export const ServerDashboard: React.FC = () => {
  const { isAuthenticated, principal } = useAuth()
  const [stats, setStats] = useState<ServerStats>({
    status: 'inactive',
    stake: 0,
    challengesWon: 0,
    challengesLost: 0,
    rewardsEarned: 0,
    dependenciesWritten: 0
  })
  const [challenges, setChallenges] = useState<Challenge[]>([])
  const [stakeAmount, setStakeAmount] = useState('')
  const [participateInRewards, setParticipateInRewards] = useState(true)

  useEffect(() => {
    if (isAuthenticated) {
      // Load server stats (mock data for now)
      setStats({
        status: 'active',
        stake: 10000,
        challengesWon: 5,
        challengesLost: 1,
        rewardsEarned: 2500,
        dependenciesWritten: 150
      })

      setChallenges([
        {
          id: '1',
          type: 'incoming',
          opponent: 'aaaaa-aa',
          parentVersion: 'abc123',
          status: 'pending',
          timestamp: new Date()
        }
      ])
    }
  }, [isAuthenticated])

  const handleStake = async () => {
    if (!stakeAmount || parseFloat(stakeAmount) <= 0) return
    
    // In real implementation, this would call the canister
    console.log('Staking:', stakeAmount, 'Participate:', participateInRewards)
  }

  if (!isAuthenticated) {
    return (
      <div className="card text-center">
        <p className="text-gray-600 mb-4">
          Connect your wallet to access the server dashboard
        </p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Server Status */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Server Status</h2>
        <div className="flex items-center justify-between">
          <div>
            <span className={`inline-flex items-center px-3 py-1 rounded-full text-sm font-medium
              ${stats.status === 'active' ? 'bg-green-100 text-green-800' : 
                stats.status === 'inactive' ? 'bg-gray-100 text-gray-800' :
                'bg-red-100 text-red-800'}`}>
              {stats.status.charAt(0).toUpperCase() + stats.status.slice(1)}
            </span>
          </div>
          <div className="text-right">
            <p className="text-sm text-gray-600">Current Stake</p>
            <p className="text-2xl font-bold">{stats.stake.toLocaleString()} ICP</p>
          </div>
        </div>
      </div>

      {/* Statistics Grid */}
      <div className="grid md:grid-cols-4 gap-4">
        <div className="card">
          <p className="text-sm text-gray-600">Dependencies Written</p>
          <p className="text-2xl font-bold text-primary-600">{stats.dependenciesWritten}</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-600">Rewards Earned</p>
          <p className="text-2xl font-bold text-green-600">{stats.rewardsEarned} ICP</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-600">Challenges Won</p>
          <p className="text-2xl font-bold text-blue-600">{stats.challengesWon}</p>
        </div>
        <div className="card">
          <p className="text-sm text-gray-600">Challenges Lost</p>
          <p className="text-2xl font-bold text-red-600">{stats.challengesLost}</p>
        </div>
      </div>

      {/* Stake Management */}
      {stats.status === 'inactive' && (
        <div className="card">
          <h2 className="text-xl font-semibold mb-4">Become a Server</h2>
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Stake Amount (ICP)
              </label>
              <input
                type="number"
                value={stakeAmount}
                onChange={(e) => setStakeAmount(e.target.value)}
                className="input-field"
                placeholder="Minimum: 100 ICP"
              />
            </div>
            <div>
              <label className="flex items-center">
                <input
                  type="checkbox"
                  checked={participateInRewards}
                  onChange={(e) => setParticipateInRewards(e.target.checked)}
                  className="mr-2"
                />
                <span className="text-sm text-gray-700">
                  Participate in reward distribution
                </span>
              </label>
              <p className="text-xs text-gray-500 mt-1">
                If unchecked, your stake contributes to the matching pool
              </p>
            </div>
            <button
              onClick={handleStake}
              className="btn-primary w-full"
            >
              Stake and Activate Server
            </button>
          </div>
        </div>
      )}

      {/* Active Challenges */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Active Challenges</h2>
        {challenges.length > 0 ? (
          <div className="space-y-3">
            {challenges.map(challenge => (
              <div key={challenge.id} className="border rounded-lg p-4">
                <div className="flex justify-between items-start mb-2">
                  <div>
                    <span className={`inline-block px-2 py-1 rounded text-xs font-medium mr-2
                      ${challenge.type === 'incoming' ? 'bg-yellow-100 text-yellow-800' : 
                        'bg-blue-100 text-blue-800'}`}>
                      {challenge.type === 'incoming' ? 'Incoming' : 'Outgoing'}
                    </span>
                    <span className="text-sm text-gray-600">
                      vs {challenge.opponent}
                    </span>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded
                    ${challenge.status === 'pending' ? 'bg-orange-100 text-orange-800' :
                      'bg-gray-100 text-gray-800'}`}>
                    {challenge.status}
                  </span>
                </div>
                <p className="text-sm text-gray-600">
                  Version: {challenge.parentVersion}
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  {challenge.timestamp.toLocaleString()}
                </p>
                {challenge.type === 'incoming' && challenge.status === 'pending' && (
                  <div className="flex gap-2 mt-3">
                    <button className="btn-primary text-sm py-1">
                      Vote Support
                    </button>
                    <button className="btn-secondary text-sm py-1">
                      Vote Against
                    </button>
                  </div>
                )}
              </div>
            ))}
          </div>
        ) : (
          <p className="text-gray-500 text-center py-4">No active challenges</p>
        )}
      </div>

      {/* Server Guidelines */}
      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Server Guidelines</h2>
        <ul className="space-y-2 text-sm text-gray-600">
          <li className="flex items-start">
            <span className="mr-2">•</span>
            Accurately report project dependencies to maintain network integrity
          </li>
          <li className="flex items-start">
            <span className="mr-2">•</span>
            Participate in consensus voting to resolve challenges fairly
          </li>
          <li className="flex items-start">
            <span className="mr-2">•</span>
            Write dependencies top-down to optimize gas costs
          </li>
          <li className="flex items-start">
            <span className="mr-2">•</span>
            Monitor your server status to avoid disqualification
          </li>
        </ul>
      </div>
    </div>
  )
}