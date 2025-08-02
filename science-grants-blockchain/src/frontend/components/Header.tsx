import React from 'react'
import { Link, useLocation } from 'react-router-dom'
import { useAuth } from '../contexts/AuthContext'

export const Header: React.FC = () => {
  const { isAuthenticated, login, logout, principal } = useAuth()
  const location = useLocation()

  const navItems = [
    { id: 'home', label: 'Home', icon: '🏠', path: '/' },
    { id: 'projects', label: 'Projects', icon: '📚', path: '/projects' },
    { id: 'donate', label: 'Donate', icon: '💝', path: '/donate' },
    { id: 'affiliate', label: 'Affiliate', icon: '🤝', path: '/affiliate' },
    { id: 'server', label: 'Server', icon: '🖥️', path: '/server' },
  ]

  const isActive = (path: string) => {
    if (path === '/') {
      return location.pathname === '/'
    }
    return location.pathname.startsWith(path)
  }

  const getCurrentPageName = () => {
    const currentItem = navItems.find(item => isActive(item.path))
    return currentItem ? currentItem.label : 'Unknown'
  }

  return (
    <header className="bg-white shadow-md sticky top-0 z-50">
      <div className="container mx-auto px-4">
        <div className="flex items-center justify-between h-16">
          <div className="flex items-center space-x-8">
            <Link 
              to="/"
              className="text-xl font-bold text-primary-700 cursor-pointer"
            >
              🔬 Science Grants
            </Link>
            <nav className="hidden md:flex space-x-4">
              {navItems.map(item => (
                <Link
                  key={item.id}
                  to={item.path}
                  className={`px-3 py-2 rounded-md text-sm font-medium transition-colors
                    ${isActive(item.path)
                      ? 'bg-primary-100 text-primary-700' 
                      : 'text-gray-700 hover:bg-gray-100'
                    }`}
                >
                  <span className="mr-1">{item.icon}</span>
                  {item.label}
                </Link>
              ))}
            </nav>
          </div>
          <div className="flex items-center space-x-4">
            {/* Current URL display */}
            <div className="hidden lg:block text-sm text-gray-500 bg-gray-100 px-3 py-1 rounded">
              📍 {getCurrentPageName()} | {location.pathname}
            </div>
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