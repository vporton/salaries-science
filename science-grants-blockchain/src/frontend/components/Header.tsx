import React from 'react'
import { useAuth } from '../contexts/AuthContext'

interface HeaderProps {
  currentView: string
  onNavigate: (view: any) => void
}

export const Header: React.FC<HeaderProps> = ({ currentView, onNavigate }) => {
  const { isAuthenticated, login, logout, principal } = useAuth()

  const navItems = [
    { id: 'home', label: 'Home', icon: '🏠' },
    { id: 'projects', label: 'Projects', icon: '📚' },
    { id: 'donate', label: 'Donate', icon: '💝' },
    { id: 'affiliate', label: 'Affiliate', icon: '🤝' },
    { id: 'server', label: 'Server', icon: '🖥️' },
  ]

  return (
    <header className="bg-white shadow-md sticky top-0 z-50">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <h1 
              className="text-xl font-bold text-primary-700 cursor-pointer"
              onClick={() => onNavigate('home')}
            >
              🔬 Science Grants
            </h1>
            <nav className="hidden md:flex space-x-4">
              {navItems.map(item => (
                <button
                  key={item.id}
                  onClick={() => onNavigate(item.id)}
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-colors
                    ${currentView === item.id 
                      ? 'bg-primary-100 text-primary-700' 
                      : 'text-gray-700 hover:bg-gray-100'
                    }`}
                >
                  <span className="mr-1">{item.icon}</span>
                  {item.label}
                </button>
              ))}
            </nav>
          </div>
          <div className="flex items-center space-x-4">
            {isAuthenticated ? (
              <>
                <span className="text-sm text-gray-600">
                  {principal?.toString().slice(0, 10)}...
                </span>
                <button onClick={logout} className="btn-secondary text-sm">
                  Disconnect
                </button>
              </>
            ) : (
              <button onClick={login} className="btn-primary text-sm">
                Connect Wallet
              </button>
            )}
          </div>
        </div>
      </div>
    </header>
  )
}