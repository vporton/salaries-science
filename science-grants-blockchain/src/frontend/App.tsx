import { BrowserRouter as Router, Routes, Route, Navigate, useParams, Link, useNavigate } from 'react-router-dom'

import { Header } from './components/Header'
import { Hero } from './components/Hero'
import { ProjectList } from './components/ProjectList'
import { ProjectSubmission } from './components/ProjectSubmission'
import { DonationForm } from './components/DonationForm'
import { AffiliatePanel } from './components/AffiliatePanel'
import { ServerDashboard } from './components/ServerDashboard'
import { WalletPanel } from './components/WalletPanel'
import { AuthProvider } from './contexts/AuthContext'

// Home component
const Home = () => (
  <>
    <Hero />
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

// Projects component
const Projects = () => {
  const navigate = useNavigate()
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="flex justify-between items-center mb-8">
        <h1 className="text-3xl font-bold">Discover Projects</h1>
        <Link to="/submit" className="btn-primary">
          Submit Project
        </Link>
      </div>
      <ProjectList 
        onSelectProject={(projectId) => {
          navigate(`/donate/${projectId}`)
        }}
      />
    </div>
  )
}

// Submit Project component
const SubmitProject = () => {
  const navigate = useNavigate()
  
  return (
    <div className="container mx-auto px-4 py-8">
      <ProjectSubmission 
        onSuccess={() => {
          navigate('/projects')
        }}
      />
    </div>
  )
}

// Donate component with URL parameter
const DonateWithParams = () => {
  const { projectId } = useParams<{ projectId: string }>()
  return <Donate projectId={projectId} />
}

// Donate component
const Donate = ({ projectId }: { projectId?: string }) => {
  const navigate = useNavigate()
  
  return (
    <div className="container mx-auto px-4 py-8">
      <div className="max-w-6xl mx-auto">
        <h1 className="text-3xl font-bold mb-8">Make a Donation</h1>
        
        <div className="grid lg:grid-cols-3 gap-8">
          {/* Main donation form */}
          <div className="lg:col-span-2">
            {projectId ? (
              <DonationForm 
                projectId={projectId}
                onSuccess={() => {
                  navigate('/projects')
                }}
              />
            ) : (
              <div className="card text-center">
                <p className="text-gray-600 mb-4">Please select a project first</p>
                <Link to="/projects" className="btn-primary">
                  Browse Projects
                </Link>
              </div>
            )}
          </div>
          
          {/* Wallet panel */}
          <div className="lg:col-span-1">
            <WalletPanel />
          </div>
        </div>
      </div>
    </div>
  )
}

// Affiliate component
const Affiliate = () => (
  <div className="container mx-auto px-4 py-8">
    <h1 className="text-3xl font-bold mb-8">Affiliate Program</h1>
    <AffiliatePanel />
  </div>
)

// Server component
const Server = () => (
  <div className="container mx-auto px-4 py-8">
    <h1 className="text-3xl font-bold mb-8">Server Dashboard</h1>
    <ServerDashboard />
  </div>
)

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="min-h-screen bg-gray-50">
          <Header />
          <main>
            <Routes>
              <Route path="/" element={<Home />} />
              <Route path="/projects" element={<Projects />} />
              <Route path="/submit" element={<SubmitProject />} />
              <Route path="/donate" element={<Donate />} />
              <Route path="/donate/:projectId" element={<DonateWithParams />} />
              <Route path="/affiliate" element={<Affiliate />} />
              <Route path="/server" element={<Server />} />
              <Route path="*" element={<Navigate to="/" replace />} />
            </Routes>
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
      </Router>
    </AuthProvider>
  )
}

export default App