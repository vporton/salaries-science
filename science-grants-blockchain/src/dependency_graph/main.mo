import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Array "mo:core/Array";
import Result "mo:core/Result";
import Time "mo:core/Time";
import List "mo:core/List";
import Option "mo:core/Option";

persistent actor DependencyGraph {
    // Types
    public type ServerAddress = Principal;
    public type Version = Text; // Git commit hash or version tag
    public type ProjectID = Text; // e.g., "github.com/user/repo"
    public type DonationAddress = Text; // Blockchain address for donations
    
    public type VersionStatus = {
        #Unfinished;
        #Finished;
        #Dead;
    };
    
    public type Node = {
        server: ServerAddress;
        version: Version;
        status: VersionStatus;
        dependencies: [Version];
        writtenAt: Time.Time;
        writtenBy: ServerAddress;
    };
    
    public type ProjectInfo = {
        projectId: ProjectID;
        version: Version;
        donationAddress: ?DonationAddress;
        server: ServerAddress;
    };
    
    // Storage
    private stable var dependencyGraph = Map.empty<Version, Node>();
    private stable var projectRegistry = Map.empty<ProjectID, ProjectInfo>();
    private stable var serverTrust = Map.empty<ServerAddress, List.List<ServerAddress>>();
    
    // Add a new node to the dependency graph
    public shared(msg) func addNode(
        version: Version,
        status: VersionStatus,
        dependencies: [Version]
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        // Check if all parent dependencies exist and are finished
        for (dep in dependencies.vals()) {
            switch (Map.get(dependencyGraph, Text.compare, dep)) {
                case null { return #err("Parent dependency " # dep # " not found") };
                case (?node) {
                    switch (node.status) {
                        case (#Finished) { /* OK */ };
                        case (_) { return #err("Parent dependency " # dep # " is not finished") };
                    };
                };
            };
        };
        
        // Check if node already exists
        switch (Map.get(dependencyGraph, Text.compare, version)) {
            case (?existing) { return #err("Version already exists") };
            case null { /* OK to add */ };
        };
        
        let node: Node = {
            server = caller;
            version = version;
            status = status;
            dependencies = dependencies;
            writtenAt = Time.now();
            writtenBy = caller;
        };
        
        ignore Map.insert(dependencyGraph, Text.compare, version, node);
        #ok("Node added successfully")
    };
    
    // Update node status (e.g., mark as finished)
    public shared(msg) func updateNodeStatus(
        version: Version,
        newStatus: VersionStatus
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (Map.get(dependencyGraph, Text.compare, version)) {
            case null { return #err("Version not found") };
            case (?node) {
                if (node.server != caller) {
                    return #err("Only the server that created the node can update it");
                };
                
                let updatedNode: Node = {
                    server = node.server;
                    version = node.version;
                    status = newStatus;
                    dependencies = node.dependencies;
                    writtenAt = node.writtenAt;
                    writtenBy = node.writtenBy;
                };
                
                ignore Map.insert(dependencyGraph, Text.compare, version, updatedNode);
                #ok("Status updated successfully")
            };
        };
    };
    
    // Register a top-level project
    public shared(msg) func registerProject(
        projectId: ProjectID,
        version: Version,
        donationAddress: ?DonationAddress
    ) : async Result.Result<Text, Text> {
        let projectInfo: ProjectInfo = {
            projectId = projectId;
            version = version;
            donationAddress = donationAddress;
            server = msg.caller;
        };
        
        ignore Map.insert(projectRegistry, Text.compare, projectId, projectInfo);
        #ok("Project registered successfully")
    };
    
    // Get all dependencies for a version (recursive)
    public query func getAllDependencies(version: Version) : async [Version] {
        let visited = Map.empty<Version, Bool>();
        let result = List.empty<Version>();
        
        func traverse(v: Version) {
            switch (Map.get(visited, Text.compare, v)) {
                case (?true) { return };
                case _ {
                    ignore Map.insert(visited, Text.compare, v, true);
                    switch (Map.get(dependencyGraph, Text.compare, v)) {
                        case null { };
                        case (?node) {
                            List.add(result, v);
                            for (dep in node.dependencies.vals()) {
                                traverse(dep);
                            };
                        };
                    };
                };
            };
        };
        
        traverse(version);
        List.toArray(result)
    };
    
    // Get node information
    public query func getNode(version: Version) : async ?Node {
        Map.get(dependencyGraph, Text.compare, version)
    };
    
    // Get project information
    public query func getProject(projectId: ProjectID) : async ?ProjectInfo {
        Map.get(projectRegistry, Text.compare, projectId)
    };
    
    // Add trust relationship between servers
    public shared(msg) func addTrust(trustedServer: ServerAddress) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (Map.get(serverTrust, Principal.compare, caller)) {
            case null {
                ignore Map.insert<ServerAddress, List.List<ServerAddress>>(
                    serverTrust, Principal.compare, caller, List.singleton(trustedServer)
                );
            };
            case (?trusted) {
                List.add(trusted, trustedServer);
            };
        };
        
        #ok("Trust relationship added")
    };
    
    // Get trusted servers for a given server
    public query func getTrustedServers(server: ServerAddress) : async [ServerAddress] {
        switch (Map.get(serverTrust, Principal.compare, server)) {
            case null { [] };
            case (?trusted) { List.toArray(trusted) };
        }
    };
    
    // Validate dependency tree integrity
    public query func validateDependencyTree(version: Version) : async Bool {
        func checkNode(v: Version) : Bool {
            switch (Map.get(dependencyGraph, Text.compare, v)) {
                case null { false };
                case (?node) {
                    // Check all dependencies exist
                    for (dep in node.dependencies.vals()) {
                        if (not checkNode(dep)) {
                            return false;
                        };
                    };
                    true
                };
            };
        };
        
        checkNode(version)
    };
}