import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Time "mo:base/Time";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Text "mo:base/Text";
import Iter "mo:base/Iter";

actor Consensus {
    // Types
    public type Challenge = {
        challenger: Principal;
        challenged: Principal;
        parentVersion: Text;
        challengerChildVersion: Text;
        challengedChildVersion: Text;
        timestamp: Time.Time;
        resolved: Bool;
    };
    
    public type Vote = {
        voter: Principal;
        supportChallenge: Bool;
        stake: Nat;
    };
    
    public type ServerStatus = {
        #Active;
        #Disqualified;
        #Withdrawn;
    };
    
    public type ServerRecord = {
        address: Principal;
        stake: Nat;
        status: ServerStatus;
        rewardEligible: Bool;
        challengesWon: Nat;
        challengesLost: Nat;
    };
    
    public type DependencyType = {
        #PyPi;
        #CratesIO;
        #NPM;
        #GitHub;
        #Other: Text;
    };
    
    // State
    private var servers = HashMap.HashMap<Principal, ServerRecord>(50, Principal.equal, Principal.hash);
    private var challenges = Buffer.Buffer<Challenge>(100);
    private var votes = HashMap.HashMap<Nat, [Vote]>(100, Nat.equal, func(n: Nat) : Nat32 = Nat32.fromNat(n % 2147483647));
    private var rewardPool: Nat = 0;
    private var totalActiveStake: Nat = 0;
    
    // Register a server with stake
    public shared(msg) func registerServer(
        stake: Nat,
        eligibleForRewards: Bool
    ) : async Result.Result<Text, Text> {
        let serverRecord: ServerRecord = {
            address = msg.caller;
            stake = stake;
            status = #Active;
            rewardEligible = eligibleForRewards;
            challengesWon = 0;
            challengesLost = 0;
        };
        
        servers.put(msg.caller, serverRecord);
        totalActiveStake += stake;
        
        if (eligibleForRewards) {
            rewardPool += stake;
        };
        
        #ok("Server registered")
    };
    
    // Submit a challenge
    public shared(msg) func submitChallenge(
        challenged: Principal,
        parentVersion: Text,
        challengerChildVersion: Text,
        challengedChildVersion: Text
    ) : async Result.Result<Nat, Text> {
        // Verify challenger is an active server
        switch (servers.get(msg.caller)) {
            case null { return #err("Challenger is not a registered server") };
            case (?server) {
                switch (server.status) {
                    case (#Active) { /* OK */ };
                    case (_) { return #err("Challenger is not active") };
                };
            };
        };
        
        // Verify challenged is a server
        switch (servers.get(challenged)) {
            case null { return #err("Challenged is not a registered server") };
            case (?_) { /* OK */ };
        };
        
        let challenge: Challenge = {
            challenger = msg.caller;
            challenged = challenged;
            parentVersion = parentVersion;
            challengerChildVersion = challengerChildVersion;
            challengedChildVersion = challengedChildVersion;
            timestamp = Time.now();
            resolved = false;
        };
        
        challenges.add(challenge);
        let challengeId = challenges.size() - 1;
        
        #ok(challengeId)
    };
    
    // Vote on a challenge
    public shared(msg) func voteOnChallenge(
        challengeId: Nat,
        supportChallenge: Bool
    ) : async Result.Result<Text, Text> {
        // Verify voter is an active server
        let voterStake = switch (servers.get(msg.caller)) {
            case null { return #err("Voter is not a registered server") };
            case (?server) {
                switch (server.status) {
                    case (#Active) { server.stake };
                    case (_) { return #err("Voter is not active") };
                };
            };
        };
        
        // Verify challenge exists and is not resolved
        if (challengeId >= challenges.size()) {
            return #err("Invalid challenge ID");
        };
        
        let challenge = challenges.get(challengeId);
        if (challenge.resolved) {
            return #err("Challenge already resolved");
        };
        
        // Record vote
        let vote: Vote = {
            voter = msg.caller;
            supportChallenge = supportChallenge;
            stake = voterStake;
        };
        
        let currentVotes = switch (votes.get(challengeId)) {
            case null { [] };
            case (?v) { v };
        };
        
        votes.put(challengeId, Array.append(currentVotes, [vote]));
        
        #ok("Vote recorded")
    };
    
    // Resolve a challenge based on votes
    public shared func resolveChallenge(challengeId: Nat) : async Result.Result<Text, Text> {
        if (challengeId >= challenges.size()) {
            return #err("Invalid challenge ID");
        };
        
        var challenge = challenges.get(challengeId);
        if (challenge.resolved) {
            return #err("Challenge already resolved");
        };
        
        // Count votes weighted by stake
        let challengeVotes = switch (votes.get(challengeId)) {
            case null { return #err("No votes for this challenge") };
            case (?v) { v };
        };
        
        var supportStake: Nat = 0;
        var oppositionStake: Nat = 0;
        
        for (vote in challengeVotes.vals()) {
            if (vote.supportChallenge) {
                supportStake += vote.stake;
            } else {
                oppositionStake += vote.stake;
            };
        };
        
        // Determine outcome
        let challengeSucceeds = supportStake > oppositionStake;
        
        // Update server records
        if (challengeSucceeds) {
            // Disqualify the challenged server
            disqualifyServer(challenge.challenged);
            updateServerStats(challenge.challenger, true);
            updateServerStats(challenge.challenged, false);
            
            // Reward the challenger
            let fixedReward = rewardPool / getActiveServerCount();
            await rewardServer(challenge.challenger, fixedReward);
        } else {
            // Disqualify the challenger
            disqualifyServer(challenge.challenger);
            updateServerStats(challenge.challenger, false);
            updateServerStats(challenge.challenged, true);
        };
        
        // Mark challenge as resolved
        challenge := {
            challenger = challenge.challenger;
            challenged = challenge.challenged;
            parentVersion = challenge.parentVersion;
            challengerChildVersion = challenge.challengerChildVersion;
            challengedChildVersion = challenge.challengedChildVersion;
            timestamp = challenge.timestamp;
            resolved = true;
        };
        
        challenges.put(challengeId, challenge);
        
        #ok(if (challengeSucceeds) "Challenge succeeded" else "Challenge failed")
    };
    
    // Helper functions
    private func disqualifyServer(server: Principal) {
        switch (servers.get(server)) {
            case null { };
            case (?record) {
                let updated: ServerRecord = {
                    address = record.address;
                    stake = record.stake;
                    status = #Disqualified;
                    rewardEligible = record.rewardEligible;
                    challengesWon = record.challengesWon;
                    challengesLost = record.challengesLost;
                };
                servers.put(server, updated);
                
                // Update total active stake
                totalActiveStake -= record.stake;
                
                // Remove from reward pool if eligible
                if (record.rewardEligible) {
                    rewardPool -= record.stake;
                };
            };
        };
    };
    
    private func updateServerStats(server: Principal, won: Bool) {
        switch (servers.get(server)) {
            case null { };
            case (?record) {
                let updated: ServerRecord = {
                    address = record.address;
                    stake = record.stake;
                    status = record.status;
                    rewardEligible = record.rewardEligible;
                    challengesWon = if (won) record.challengesWon + 1 else record.challengesWon;
                    challengesLost = if (not won) record.challengesLost + 1 else record.challengesLost;
                };
                servers.put(server, updated);
            };
        };
    };
    
    private func getActiveServerCount() : Nat {
        var count = 0;
        for ((_, server) in servers.entries()) {
            switch (server.status) {
                case (#Active) { count += 1 };
                case (_) { };
            };
        };
        count
    };
    
    private func rewardServer(server: Principal, amount: Nat) : async () {
        // In real implementation, transfer tokens to server
        // For now, just track it internally
    };
    
    // Calculate consensus for dependency versions
    public func calculateVersionConsensus(
        projectId: Text,
        dependencyType: DependencyType
    ) : async Result.Result<Text, Text> {
        // Get all active servers' votes for this project version
        var versionVotes = HashMap.HashMap<Text, Nat>(10, Text.equal, Text.hash);
        
        for ((serverAddr, server) in servers.entries()) {
            switch (server.status) {
                case (#Active) {
                    // In real implementation, query each server for their version
                    // For now, we'll simulate this
                };
                case (_) { };
            };
        };
        
        // Find version with majority stake
        var maxStake: Nat = 0;
        var consensusVersion: Text = "";
        
        for ((version, stake) in versionVotes.entries()) {
            if (stake > maxStake) {
                maxStake := stake;
                consensusVersion := version;
            };
        };
        
        if (maxStake > totalActiveStake / 2) {
            #ok(consensusVersion)
        } else {
            #err("No majority consensus")
        }
    };
    
    // Query functions
    public query func getServerInfo(server: Principal) : async ?ServerRecord {
        servers.get(server)
    };
    
    public query func getChallenge(challengeId: Nat) : async ?Challenge {
        if (challengeId < challenges.size()) {
            ?challenges.get(challengeId)
        } else {
            null
        }
    };
    
    public query func getActiveServers() : async [Principal] {
        let activeServers = Buffer.Buffer<Principal>(servers.size());
        for ((addr, server) in servers.entries()) {
            switch (server.status) {
                case (#Active) { activeServers.add(addr) };
                case (_) { };
            };
        };
        Buffer.toArray(activeServers)
    };
    
    public query func getTotalActiveStake() : async Nat {
        totalActiveStake
    };
    
    public query func getRewardPool() : async Nat {
        rewardPool
    };
}