import React, { useState, useEffect } from 'react'
import { useAuth } from '../contexts/AuthContext'

interface AffiliateStats {
  totalEarned: number
  projectsPromoted: number
  totalDonationsBrought: number
}

export const AffiliatePanel: React.FC = () => {
  const { isAuthenticated, principal } = useAuth()
  const [stats, setStats] = useState<AffiliateStats>({
    totalEarned: 0,
    projectsPromoted: 0,
    totalDonationsBrought: 0
  })
  const [affiliateLink, setAffiliateLink] = useState('')

  useEffect(() => {
    if (isAuthenticated && principal) {
      // Generate affiliate link
      const baseUrl = window.location.origin
      setAffiliateLink(`${baseUrl}?ref=${principal.toString()}`)
      
      // Load affiliate stats (mock data for now)
      setStats({
        totalEarned: 1250,
        projectsPromoted: 3,
        totalDonationsBrought: 15000
      })
    }
  }, [isAuthenticated, principal])

  if (!isAuthenticated) {
    return (
      <div className="card text-center">
        <p className="text-gray-600 mb-4">
          Connect your wallet to access the affiliate program
        </p>
      </div>
    )
  }

  const copyToClipboard = () => {
    navigator.clipboard.writeText(affiliateLink)
  }

  return (
    <div className="space-y-6">
      <div className="grid md:grid-cols-3 gap-6">
        <div className="card">
          <div className="text-3xl font-bold text-primary-600 mb-2">
            ${stats.totalEarned.toLocaleString()}
          </div>
          <p className="text-gray-600">Total Earned</p>
        </div>
        <div className="card">
          <div className="text-3xl font-bold text-secondary-600 mb-2">
            {stats.projectsPromoted}
          </div>
          <p className="text-gray-600">Projects Promoted</p>
        </div>
        <div className="card">
          <div className="text-3xl font-bold text-green-600 mb-2">
            ${stats.totalDonationsBrought.toLocaleString()}
          </div>
          <p className="text-gray-600">Donations Generated</p>
        </div>
      </div>

      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Your Affiliate Link</h2>
        <div className="flex gap-2">
          <input
            type="text"
            value={affiliateLink}
            readOnly
            className="input-field flex-1"
          />
          <button
            onClick={copyToClipboard}
            className="btn-primary"
          >
            Copy
          </button>
        </div>
        <p className="text-sm text-gray-600 mt-2">
          Share this link to earn {60}% commission on donations you bring
        </p>
      </div>

      <div className="card">
        <h2 className="text-xl font-semibold mb-4">How It Works</h2>
        <div className="space-y-4">
          <div className="flex gap-4">
            <div className="text-2xl">1️⃣</div>
            <div>
              <h3 className="font-semibold">Share Your Link</h3>
              <p className="text-gray-600">
                Share your unique affiliate link with your network
              </p>
            </div>
          </div>
          <div className="flex gap-4">
            <div className="text-2xl">2️⃣</div>
            <div>
              <h3 className="font-semibold">Drive Donations</h3>
              <p className="text-gray-600">
                When someone donates through your link, you earn commission
              </p>
            </div>
          </div>
          <div className="flex gap-4">
            <div className="text-2xl">3️⃣</div>
            <div>
              <h3 className="font-semibold">Earn Rewards</h3>
              <p className="text-gray-600">
                Receive up to 60% commission on donations you generate
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="card">
        <h2 className="text-xl font-semibold mb-4">Marketing Tips</h2>
        <ul className="space-y-2 text-gray-600">
          <li className="flex items-start">
            <span className="mr-2">✓</span>
            Focus on projects aligned with your audience's interests
          </li>
          <li className="flex items-start">
            <span className="mr-2">✓</span>
            Share the scientific or technical impact of projects
          </li>
          <li className="flex items-start">
            <span className="mr-2">✓</span>
            Highlight the quadratic funding multiplier effect
          </li>
          <li className="flex items-start">
            <span className="mr-2">✓</span>
            Create content explaining how the project benefits society
          </li>
        </ul>
      </div>
    </div>
  )
}