import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

actor DependencyGraph {
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
    private var dependencyGraph = HashMap.HashMap<Version, Node>(100, Text.equal, Text.hash);
    private var projectRegistry = HashMap.HashMap<ProjectID, ProjectInfo>(100, Text.equal, Text.hash);
    private var serverTrust = HashMap.HashMap<ServerAddress, [ServerAddress]>(50, Principal.equal, Principal.hash);
    
    // Add a new node to the dependency graph
    public shared(msg) func addNode(
        version: Version,
        status: VersionStatus,
        dependencies: [Version]
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        // Check if all parent dependencies exist and are finished
        for (dep in dependencies.vals()) {
            switch (dependencyGraph.get(dep)) {
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
        switch (dependencyGraph.get(version)) {
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
        
        dependencyGraph.put(version, node);
        #ok("Node added successfully")
    };
    
    // Update node status (e.g., mark as finished)
    public shared(msg) func updateNodeStatus(
        version: Version,
        newStatus: VersionStatus
    ) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (dependencyGraph.get(version)) {
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
                
                dependencyGraph.put(version, updatedNode);
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
        
        projectRegistry.put(projectId, projectInfo);
        #ok("Project registered successfully")
    };
    
    // Get all dependencies for a version (recursive)
    public query func getAllDependencies(version: Version) : async [Version] {
        let visited = HashMap.HashMap<Version, Bool>(100, Text.equal, Text.hash);
        let result = Buffer.Buffer<Version>(50);
        
        func traverse(v: Version) {
            switch (visited.get(v)) {
                case (?true) { return };
                case _ {
                    visited.put(v, true);
                    switch (dependencyGraph.get(v)) {
                        case null { };
                        case (?node) {
                            result.add(v);
                            for (dep in node.dependencies.vals()) {
                                traverse(dep);
                            };
                        };
                    };
                };
            };
        };
        
        traverse(version);
        Buffer.toArray(result)
    };
    
    // Get node information
    public query func getNode(version: Version) : async ?Node {
        dependencyGraph.get(version)
    };
    
    // Get project information
    public query func getProject(projectId: ProjectID) : async ?ProjectInfo {
        projectRegistry.get(projectId)
    };
    
    // Add trust relationship between servers
    public shared(msg) func addTrust(trustedServer: ServerAddress) : async Result.Result<Text, Text> {
        let caller = msg.caller;
        
        switch (serverTrust.get(caller)) {
            case null {
                serverTrust.put(caller, [trustedServer]);
            };
            case (?trusted) {
                let buffer = Buffer.fromArray<ServerAddress>(trusted);
                buffer.add(trustedServer);
                serverTrust.put(caller, Buffer.toArray(buffer));
            };
        };
        
        #ok("Trust relationship added")
    };
    
    // Get trusted servers for a given server
    public query func getTrustedServers(server: ServerAddress) : async [ServerAddress] {
        switch (serverTrust.get(server)) {
            case null { [] };
            case (?trusted) { trusted };
        }
    };
    
    // Validate dependency tree integrity
    public query func validateDependencyTree(version: Version) : async Bool {
        func checkNode(v: Version) : Bool {
            switch (dependencyGraph.get(v)) {
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