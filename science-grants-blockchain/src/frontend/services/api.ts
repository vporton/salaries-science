import { HttpAgent } from '@dfinity/agent'
import { Principal } from '@dfinity/principal'

// Extend Window interface for mock storage
declare global {
  interface Window {
    mockProjects?: any[]
  }
}



// This would be generated from your canister's candid file
// For now, we'll define interfaces manually
interface GrantsSystem {
  donate: (args: any) => Promise<any>
  getProjectStats: (projectId: string) => Promise<any>
  getRoundConfig: () => Promise<any>
  submitProject: (githubUrl: string) => Promise<any>
  getProjects: () => Promise<any>
}

// Removed unused DependencyGraph interface

// Create agent and actors
let agent: HttpAgent | null = null
let grantsActor: GrantsSystem | null = null
// Removed unused _dependencyActor variable


export const initializeActors = async (identity?: any) => {
  // Initialize agent
  agent = new HttpAgent({
    host: import.meta.env.MODE === 'production' 
      ? 'https://ic0.app' 
      : 'http://localhost:8080',
    identity
  })

  // In development, fetch root key for local replica
  if (import.meta.env.MODE !== 'production') {
    await agent.fetchRootKey()
  }

  // Create mock actors for development
  if (import.meta.env.MODE !== 'production') {
    grantsActor = createMockGrantsActor()
    // _dependencyActor = createMockDependencyActor() // This line is removed
  } else {
    // Create real actors (you'll need to replace these with actual canister IDs)
    // grantsActor = Actor.createActor(grantsIdl, {
    //   agent,
    //   canisterId: 'your-grants-canister-id'
    // })

    // dependencyActor = Actor.createActor(dependencyIdl, {
    //   agent,
    //   canisterId: 'your-dependency-canister-id'
    // })
  }
}

// Mock actor for development
const createMockGrantsActor = (): GrantsSystem => ({
  donate: async (_args: any) => {
    await new Promise(resolve => setTimeout(resolve, 1000))
    return { success: true }
  },
  getProjectStats: async (_projectId: string) => {
    return {
      totalDonations: 0,
      donorCount: 0,
      matchingAmount: 0,
      affiliates: []
    }
  },
  getRoundConfig: async () => {
    return null
  },
  submitProject: async (githubUrl: string) => {
    await new Promise(resolve => setTimeout(resolve, 2000))
    
    // Extract repo info from URL
    const urlParts = githubUrl.split('/')
    const owner = urlParts[urlParts.length - 2]
    const repo = urlParts[urlParts.length - 1]
    
    // Create mock project data
    const mockProject = {
      id: `project-${Date.now()}`,
      githubUrl: githubUrl,
      name: repo,
      description: `Repository submitted to Science Grants: ${repo}`,
      category: 'software' as const,
      owner: owner,
      language: 'Unknown',
      stars: 0,
      forks: 0,
      topics: [],
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString()
    }
    
    // Store in mock storage
    if (!window.mockProjects) {
      window.mockProjects = []
    }
    window.mockProjects.push(mockProject)
    
    return { ok: mockProject.id }
  },
  getProjects: async () => {
    return window.mockProjects || []
  }
})

// Removed unused createMockDependencyActor function

// API functions
export const getProjects = async () => {
  if (!grantsActor) {
    throw new Error('Grants actor not initialized')
  }

  // Call the actor (mock or real)
  return await grantsActor.getProjects()
}

export const donate = async (params: {
  projectId: string
  amount: number
  dependencyPercentage: number
  affiliatePercentage: number
  affiliateAddress?: string
}) => {
  if (!grantsActor) {
    throw new Error('Grants actor not initialized')
  }

  // Convert parameters to the format expected by the canister
  const donationSpec = {
    projectId: params.projectId,
    amount: BigInt(Math.floor(params.amount * 1e8)), // Convert to e8s
    token: { ICP: null },
    dependencyPercentage: BigInt(params.dependencyPercentage),
    affiliatePercentage: BigInt(params.affiliatePercentage),
    affiliate: params.affiliateAddress 
      ? [Principal.fromText(params.affiliateAddress)]
      : [],
    timestamp: BigInt(Date.now() * 1000000) // nanoseconds
  }

  return await grantsActor.donate(donationSpec)
}

export const getProjectDependencies = async (_version: string) => {
  // In real implementation, this would call the canister
  // if (!dependencyActor) {
  //   throw new Error('Dependency actor not initialized')
  // }

  // return await dependencyActor.getAllDependencies(version)
  
  // Mock for now
  return []
}

export const getProjectStats = async (projectId: string) => {
  if (!grantsActor) {
    throw new Error('Grants actor not initialized')
  }

  // Call the actor (mock or real)
  const stats = await grantsActor.getProjectStats(projectId)
  
  // Return the stats if found, otherwise return default stats
  return stats || {
    totalDonations: 0,
    donorCount: 0,
    matchingAmount: 0,
    affiliates: []
  }
}

export const getRoundConfig = async () => {
  if (!grantsActor) {
    throw new Error('Grants actor not initialized')
  }

  return await grantsActor.getRoundConfig()
}

export const submitProject = async (githubUrl: string) => {
  if (!grantsActor) {
    throw new Error('Grants actor not initialized')
  }

  // Call the actor (mock or real) with just the GitHub URL
  const result = await grantsActor.submitProject(githubUrl)

  if ('ok' in result) {
    return { success: true, projectId: result.ok }
  } else {
    throw new Error(result.err)
  }
}