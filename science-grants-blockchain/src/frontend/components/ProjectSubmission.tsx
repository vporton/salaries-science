import React, { useState } from 'react'
import { submitProject } from '../services/api'
import { SuccessNotification } from './SuccessNotification'

interface GitHubRepoData {
  name: string
  description: string
  html_url: string
  stargazers_count: number
  forks_count: number
  language: string
  topics: string[]
  created_at: string
  updated_at: string
  owner: {
    login: string
    avatar_url: string
  }
}

interface ProjectSubmissionProps {
  onSuccess: () => void
}

export const ProjectSubmission: React.FC<ProjectSubmissionProps> = ({ onSuccess }) => {
  const [githubUrl, setGithubUrl] = useState('')
  const [repoData, setRepoData] = useState<GitHubRepoData | null>(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [projectCategory, setProjectCategory] = useState<'science' | 'software'>('software')
  const [customDescription, setCustomDescription] = useState('')
  const [showSuccess, setShowSuccess] = useState(false)

  const extractRepoInfo = (url: string): { owner: string; repo: string } | null => {
    const githubRegex = /^https?:\/\/github\.com\/([^\/]+)\/([^\/]+)(?:\/.*)?$/
    const match = url.match(githubRegex)
    if (match) {
      return { owner: match[1], repo: match[2] }
    }
    return null
  }

  const fetchGitHubData = async () => {
    const repoInfo = extractRepoInfo(githubUrl)
    if (!repoInfo) {
      setError('Please enter a valid GitHub repository URL')
      return
    }

    setLoading(true)
    setError('')

    try {
      const response = await fetch(`https://api.github.com/repos/${repoInfo.owner}/${repoInfo.repo}`)
      if (!response.ok) {
        throw new Error('Repository not found or not accessible')
      }
      
      const data: GitHubRepoData = await response.json()
      setRepoData(data)
      setCustomDescription(data.description || '')
      
      // Auto-determine category based on topics and description
      const scienceKeywords = ['research', 'science', 'scientific', 'study', 'analysis', 'experiment', 'thesis', 'paper', 'academic', 'scholarly', 'mathematics', 'physics', 'chemistry', 'biology', 'medicine', 'medical', 'clinical', 'laboratory', 'lab']
      const description = (data.description || '').toLowerCase()
      const topics = data.topics.map(t => t.toLowerCase())
      
      const hasScienceContent = scienceKeywords.some(keyword => 
        description.includes(keyword) || topics.some(topic => topic.includes(keyword))
      )
      
      setProjectCategory(hasScienceContent ? 'science' : 'software')
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to fetch repository data')
    } finally {
      setLoading(false)
    }
  }

  const handleSubmit = async () => {
    if (!repoData) return

    setIsSubmitting(true)
    setError('')

    try {
      // Only send the GitHub URL to the backend
      const result = await submitProject(repoData.html_url)
      
      if (result.success) {
        // Reset form
        setGithubUrl('')
        setRepoData(null)
        setCustomDescription('')
        setProjectCategory('software')
        
        setShowSuccess(true)
        onSuccess()
      } else {
        setError('Failed to submit project. Please try again.')
      }
    } catch (err) {
      setError('Failed to submit project. Please try again.')
    } finally {
      setIsSubmitting(false)
    }
  }

  const handleReset = () => {
    setGithubUrl('')
    setRepoData(null)
    setError('')
    setCustomDescription('')
    setProjectCategory('software')
  }

  return (
    <div className="max-w-4xl mx-auto">
      <SuccessNotification
        message="Project submitted successfully! Redirecting to projects page..."
        isVisible={showSuccess}
        onClose={() => setShowSuccess(false)}
        autoHideDuration={3000}
      />
      <div className="card">
        <h2 className="text-2xl font-bold mb-6">Submit a Project</h2>
        
        {!repoData ? (
          // Step 1: Enter GitHub URL
          <div className="space-y-4">
            <div>
              <label htmlFor="github-url" className="block text-sm font-medium text-gray-700 mb-2">
                GitHub Repository URL
              </label>
              <div className="flex gap-2">
                <input
                  id="github-url"
                  type="url"
                  value={githubUrl}
                  onChange={(e) => setGithubUrl(e.target.value)}
                  placeholder="https://github.com/username/repository"
                  className="input-field flex-1"
                  disabled={loading}
                />
                <button
                  onClick={fetchGitHubData}
                  disabled={loading || !githubUrl}
                  className="btn-primary px-6"
                >
                  {loading ? (
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                  ) : (
                    'Fetch Data'
                  )}
                </button>
              </div>
            </div>
            
            {error && (
              <div className="text-red-600 text-sm">{error}</div>
            )}
          </div>
        ) : (
          // Step 2: Verify and submit
          <div className="space-y-6">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-semibold mb-4">Repository Information</h3>
              
              <div className="grid md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Repository Name
                  </label>
                  <p className="text-gray-900 font-medium">{repoData.name}</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Owner
                  </label>
                  <div className="flex items-center gap-2">
                    <img 
                      src={repoData.owner.avatar_url} 
                      alt={repoData.owner.login}
                      className="w-6 h-6 rounded-full"
                    />
                    <span className="text-gray-900">{repoData.owner.login}</span>
                  </div>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Language
                  </label>
                  <p className="text-gray-900">{repoData.language || 'Not specified'}</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Stars
                  </label>
                  <p className="text-gray-900">⭐ {repoData.stargazers_count.toLocaleString()}</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Forks
                  </label>
                  <p className="text-gray-900">🍴 {repoData.forks_count.toLocaleString()}</p>
                </div>
                
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-1">
                    Created
                  </label>
                  <p className="text-gray-900">
                    {new Date(repoData.created_at).toLocaleDateString()}
                  </p>
                </div>
              </div>
              
              {repoData.topics.length > 0 && (
                <div className="mt-4">
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Topics
                  </label>
                  <div className="flex flex-wrap gap-2">
                    {repoData.topics.map(topic => (
                      <span 
                        key={topic}
                        className="px-2 py-1 bg-blue-100 text-blue-800 text-xs rounded-full"
                      >
                        {topic}
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
            
            <div>
              <label htmlFor="category" className="block text-sm font-medium text-gray-700 mb-2">
                Project Category (Auto-detected)
              </label>
              <div className="input-field bg-gray-100 cursor-not-allowed">
                {projectCategory === 'science' ? '🔬 Science' : '💻 Software'}
              </div>
            </div>
            
            <div>
              <label htmlFor="description" className="block text-sm font-medium text-gray-700 mb-2">
                Description (From GitHub)
              </label>
              <div className="input-field bg-gray-100 cursor-not-allowed min-h-[6rem]">
                {customDescription || 'No description available'}
              </div>
            </div>
            
            {error && (
              <div className="text-red-600 text-sm">{error}</div>
            )}
            
            <div className="flex gap-4">
              <button
                onClick={handleSubmit}
                disabled={isSubmitting}
                className="btn-primary flex-1"
              >
                {isSubmitting ? (
                  <div className="flex items-center gap-2">
                    <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                    Submitting...
                  </div>
                ) : (
                  'Submit Project'
                )}
              </button>
              
              <button
                onClick={handleReset}
                disabled={isSubmitting}
                className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-50
                         transition-colors duration-200"
              >
                Start Over
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  )
} 