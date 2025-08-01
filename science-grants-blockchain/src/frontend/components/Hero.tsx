import React from 'react'

interface HeroProps {
  onGetStarted: () => void
}

export const Hero: React.FC<HeroProps> = ({ onGetStarted }) => {
  return (
    <div className="bg-gradient-to-br from-primary-600 to-secondary-600 text-white">
      <div className="container mx-auto px-4 py-24">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-5xl md:text-6xl font-bold mb-6">
            Financing Fundamental Science & Software
          </h1>
          <p className="text-xl md:text-2xl mb-8 opacity-90">
            A decentralized grant system that rewards scientific discoveries and 
            open-source software development through blockchain technology
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <button 
              onClick={onGetStarted}
              className="bg-white text-primary-700 px-8 py-3 rounded-lg font-semibold
                       hover:bg-gray-100 transition-colors duration-200 shadow-lg"
            >
              Explore Projects
            </button>
            <a 
              href="https://github.com/vporton/science-grants-blockchain"
              target="_blank"
              rel="noopener noreferrer"
              className="bg-transparent border-2 border-white text-white px-8 py-3 
                       rounded-lg font-semibold hover:bg-white hover:text-primary-700
                       transition-all duration-200"
            >
              View on GitHub
            </a>
          </div>
          <div className="mt-12 grid grid-cols-3 gap-8 text-center">
            <div>
              <div className="text-3xl font-bold">$0M+</div>
              <div className="text-sm opacity-75">Total Funding</div>
            </div>
            <div>
              <div className="text-3xl font-bold">0</div>
              <div className="text-sm opacity-75">Projects Funded</div>
            </div>
            <div>
              <div className="text-3xl font-bold">0</div>
              <div className="text-sm opacity-75">Active Donors</div>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}