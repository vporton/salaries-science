import React, { useState, useEffect } from 'react'
import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { ProjectList } from './components/ProjectList'
import { DonationForm } from './components/DonationForm'
import { AffiliatePanel } from './components/AffiliatePanel'
import { ServerDashboard } from './components/ServerDashboard'
import { AuthProvider } from './contexts/AuthContext'
import { Principal } from '@dfinity/principal'

type View = 'home' | 'projects' | 'donate' | 'affiliate' | 'server'

function App() {
  const [currentView, setCurrentView] = useState<View>('home')
  const [selectedProject, setSelectedProject] = useState<string | null>(null)

  const renderView = () => {
    switch (currentView) {
      case 'home':
        return (
          <>
            <Hero onGetStarted={() => setCurrentView('projects')} />
            <div className="container mx-auto px-4 py-16">
              <h2 className="text-3xl font-bold text-center mb-12">How It Works</h2>
              <div className="grid md:grid-cols-3 gap-8">
                <div className="card">
                  <div className="text-4xl mb-4">🔬</div>
                  <h3 className="text-xl font-semibold mb-2">Submit Projects</h3>
                  <p className="text-gray-600">
                    Scientists and developers submit their research papers or open-source projects
                    with dependency information.
                  </p>
                </div>
                <div className="card">
                  <div className="text-4xl mb-4">💰</div>
                  <h3 className="text-xl font-semibold mb-2">Quadratic Funding</h3>
                  <p className="text-gray-600">
                    Donations are matched using quadratic funding, amplifying the impact
                    of community support.
                  </p>
                </div>
                <div className="card">
                  <div className="text-4xl mb-4">🌐</div>
                  <h3 className="text-xl font-semibold mb-2">Decentralized</h3>
                  <p className="text-gray-600">
                    Built on DFINITY Internet Computer for transparent, secure, and 
                    censorship-resistant grants.
                  </p>
                </div>
              </div>
            </div>
          </>
        )
      case 'projects':
        return (
          <div className="container mx-auto px-4 py-8">
            <h1 className="text-3xl font-bold mb-8">Discover Projects</h1>
            <ProjectList 
              onSelectProject={(projectId) => {
                setSelectedProject(projectId)
                setCurrentView('donate')
              }}
            />
          </div>
        )
      case 'donate':
        return (
          <div className="container mx-auto px-4 py-8 max-w-2xl">
            <h1 className="text-3xl font-bold mb-8">Make a Donation</h1>
            {selectedProject ? (
              <DonationForm 
                projectId={selectedProject}
                onSuccess={() => {
                  setSelectedProject(null)
                  setCurrentView('projects')
                }}
              />
            ) : (
              <div className="text-center">
                <p className="text-gray-600 mb-4">Please select a project first</p>
                <button 
                  onClick={() => setCurrentView('projects')}
                  className="btn-primary"
                >
                  Browse Projects
                </button>
              </div>
            )}
          </div>
        )
      case 'affiliate':
        return (
          <div className="container mx-auto px-4 py-8">
            <h1 className="text-3xl font-bold mb-8">Affiliate Program</h1>
            <AffiliatePanel />
          </div>
        )
      case 'server':
        return (
          <div className="container mx-auto px-4 py-8">
            <h1 className="text-3xl font-bold mb-8">Server Dashboard</h1>
            <ServerDashboard />
          </div>
        )
      default:
        return null
    }
  }

  return (
    <AuthProvider>
      <div className="min-h-screen bg-gray-50">
        <Header 
          currentView={currentView} 
          onNavigate={setCurrentView}
        />
        <main>
          {renderView()}
        </main>
        <footer className="bg-gray-900 text-white py-8 mt-16">
          <div className="container mx-auto px-4 text-center">
            <p className="mb-2">
              Science Grants Blockchain - Financing Fundamental Science
            </p>
            <p className="text-sm text-gray-400">
              Built on DFINITY Internet Computer | By Victor Porton
            </p>
          </div>
        </footer>
      </div>
    </AuthProvider>
  )
}

export default App