import React, { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { getProjects, getProjectStats } from '../services/api'

interface Project {
  id: string
  name: string
  description: string
  category: 'science' | 'software'
  totalDonations: number
  matchingAmount: number
  donationAddress?: string
  dependencies: number
  github?: string
  owner?: string
  language?: string
  stars?: number
  forks?: number
  topics?: string[]
  createdAt?: string
  updatedAt?: string
}

interface ProjectListProps {
  onSelectProject: (projectId: string) => void
}

export const ProjectList: React.FC<ProjectListProps> = ({ onSelectProject }) => {
  const [projects, setProjects] = useState<Project[]>([])
  const [loading, setLoading] = useState(true)
  const [filter, setFilter] = useState<'all' | 'science' | 'software'>('all')
  const [searchTerm, setSearchTerm] = useState('')

  useEffect(() => {
    loadProjects()
  }, [])

  const loadProjects = async () => {
    try {
      setLoading(true)
      
      // Fetch projects from the API
      const apiProjects = await getProjects()
      
      // Transform API projects to match our interface and fetch stats for each
      const transformedProjects: Project[] = await Promise.all(
        (apiProjects || []).map(async (apiProject: any) => {
          // Fetch project stats
          const stats = await getProjectStats(apiProject.id)
          
          return {
            id: apiProject.id,
            name: apiProject.name,
            description: apiProject.description,
            category: apiProject.category === 'science' ? 'science' : 'software',
            totalDonations: stats?.totalDonations || 0,
            matchingAmount: stats?.matchingAmount || 0,
            donationAddress: undefined, // Not available in current API
            dependencies: 0, // Not available in current API
            github: apiProject.githubUrl,
            owner: apiProject.owner,
            language: apiProject.language,
            stars: apiProject.stars,
            forks: apiProject.forks,
            topics: apiProject.topics,
            createdAt: apiProject.createdAt,
            updatedAt: apiProject.updatedAt
          }
        })
      )
      
      setProjects(transformedProjects)
    } catch (error) {
      console.error('Failed to load projects:', error)
      // Fallback to empty array if API fails
      setProjects([])
    } finally {
      setLoading(false)
    }
  }

  const filteredProjects = projects.filter(project => {
    const matchesFilter = filter === 'all' || project.category === filter
    const matchesSearch = project.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         project.description.toLowerCase().includes(searchTerm.toLowerCase())
    return matchesFilter && matchesSearch
  })

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
      </div>
    )
  }

  return (
    <div>
      <div className="mb-8 space-y-4">
        <input
          type="text"
          placeholder="Search projects..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="input-field"
        />
        <div className="flex gap-2">
          {(['all', 'science', 'software'] as const).map(filterType => (
            <button
              key={filterType}
              onClick={() => setFilter(filterType)}
              className={`px-4 py-2 rounded-lg font-medium transition-colors
                ${filter === filterType 
                  ? 'bg-primary-600 text-white' 
                  : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
            >
              {filterType.charAt(0).toUpperCase() + filterType.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredProjects.map(project => (
          <div key={project.id} className="card hover:shadow-xl transition-shadow">
            <div className="flex justify-between items-start mb-4">
              <span className={`px-3 py-1 rounded-full text-xs font-semibold
                ${project.category === 'science' 
                  ? 'bg-blue-100 text-blue-800' 
                  : 'bg-green-100 text-green-800'
                }`}>
                {project.category === 'science' ? '🔬 Science' : '💻 Software'}
              </span>
              {project.dependencies > 0 && (
                <span className="text-sm text-gray-500">
                  {project.dependencies} deps
                </span>
              )}
            </div>
            
            <h3 className="text-xl font-semibold mb-2">{project.name}</h3>
            <p className="text-gray-600 mb-4 line-clamp-3">{project.description}</p>
            
            {/* Additional project info */}
            <div className="space-y-2 mb-4 text-sm text-gray-500">
              {project.owner && (
                <div className="flex items-center gap-1">
                  <span>👤 {project.owner}</span>
                </div>
              )}
              {project.language && (
                <div className="flex items-center gap-1">
                  <span>💻 {project.language}</span>
                </div>
              )}
              {project.stars && (
                <div className="flex items-center gap-1">
                  <span>⭐ {project.stars.toLocaleString()} stars</span>
                </div>
              )}
              {project.forks && (
                <div className="flex items-center gap-1">
                  <span>🍴 {project.forks.toLocaleString()} forks</span>
                </div>
              )}
            </div>
            
            <div className="space-y-2 mb-4">
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Total Donations:</span>
                <span className="font-semibold">${project.totalDonations.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-500">Matching Funds:</span>
                <span className="font-semibold text-primary-600">
                  +${project.matchingAmount.toLocaleString()}
                </span>
              </div>
            </div>

            <div className="flex gap-2">
              <button
                onClick={() => onSelectProject(project.id)}
                className="btn-primary flex-1"
              >
                Donate
              </button>
              {project.github && (
                <a
                  href={project.github}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50
                           transition-colors duration-200"
                >
                  <span className="sr-only">View on GitHub</span>
                  <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                    <path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/>
                  </svg>
                </a>
              )}
            </div>
          </div>
        ))}
      </div>

      {filteredProjects.length === 0 && (
        <div className="text-center py-12">
          <p className="text-gray-500 mb-4">No projects found matching your criteria</p>
          <Link to="/submit" className="btn-primary">
            Submit Your First Project
          </Link>
        </div>
      )}
    </div>
  )
}