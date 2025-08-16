import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Array "mo:core/Array";
import List "mo:core/List";
import Result "mo:core/Result";
import Time "mo:core/Time";
import Nat "mo:core/Nat";
import Int "mo:core/Int";
import Float "mo:core/Float";
import Text "mo:core/Text";
import Iter "mo:core/Iter";
import Nat32 "mo:core/Nat32";
import Error "mo:core/Error";

persistent actor Consensus {
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
    private var servers = Map.empty<Principal, ServerRecord>();
    private var challenges = List.empty<Challenge>();
    private var votes = Map.empty<Nat, List.List<Vote>>();
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
        
        ignore Map.insert(servers, Principal.compare, msg.caller, serverRecord);
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
        switch (Map.get(servers, Principal.compare, msg.caller)) {
            case null { return #err("Challenger is not a registered server") };
            case (?server) {
                switch (server.status) {
                    case (#Active) { /* OK */ };
                    case (_) { return #err("Challenger is not active") };
                };
            };
        };
        
        // Verify challenged is a server
        switch (Map.get(servers, Principal.compare, challenged)) {
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
        
        List.add(challenges, challenge);
        let challengeId = List.size(challenges) - 1;
        
        #ok(challengeId)
    };
    
    // Vote on a challenge
    public shared(msg) func voteOnChallenge(
        challengeId: Nat,
        supportChallenge: Bool
    ) : async Result.Result<Text, Text> {
        // Verify voter is an active server
        let voterStake = switch (Map.get(servers, Principal.compare, msg.caller)) {
            case null { return #err("Voter is not a registered server") };
            case (?server) {
                switch (server.status) {
                    case (#Active) { server.stake };
                    case (_) { return #err("Voter is not active") };
                };
            };
        };
        
        // Verify challenge exists and is not resolved
        if (challengeId >= List.size(challenges)) {
            return #err("Invalid challenge ID");
        };
        
        let ?challenge = List.get(challenges, challengeId) else {
            throw Error.reject("programmer error: challenge not found");
        };
        if (challenge.resolved) {
            return #err("Challenge already resolved");
        };
        
        // Record vote
        let vote: Vote = {
            voter = msg.caller;
            supportChallenge = supportChallenge;
            stake = voterStake;
        };
        
        let l = Map.get(votes, Nat.compare, challengeId);
        switch (l) {
            case null {
                ignore Map.insert<Nat, List.List<Vote>>(votes, Nat.compare, challengeId, List.singleton(vote));
            };
            case (?l) {
                List.add(l, vote);
            };
        };
        
        #ok("Vote recorded")
    };
    
    // Resolve a challenge based on votes
    public shared func resolveChallenge(challengeId: Nat) : async Result.Result<Text, Text> {
        if (challengeId >= List.size(challenges)) {
            return #err("Invalid challenge ID");
        };
        
        let ?challenge0 = List.get(challenges, challengeId) else {
            throw Error.reject("programmer error: challenge not found");
        };
        var challenge = challenge0;
        if (challenge.resolved) {
            return #err("Challenge already resolved");
        };
        
        // Count votes weighted by stake
        let challengeVotes = switch (Map.get(votes, Nat.compare, challengeId)) {
            case null { return #err("No votes for this challenge") };
            case (?v) { v };
        };
        
        var supportStake: Nat = 0;
        var oppositionStake: Nat = 0;
        
        for (vote in List.values(challengeVotes)) {
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
        
        List.add(challenges, challenge);
        
        #ok(if (challengeSucceeds) "Challenge succeeded" else "Challenge failed")
    };
    
    // Helper functions
    private func disqualifyServer(server: Principal) {
        switch (Map.get(servers, Principal.compare, server)) {
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
                ignore Map.insert(servers, Principal.compare, server, updated);
                
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
        switch (Map.get(servers, Principal.compare, server)) {
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
                ignore Map.insert(servers, Principal.compare, server, updated);
            };
        };
    };
    
    private func getActiveServerCount() : Nat {
        var count = 0;
        for ((_, server) in Map.entries(servers)) {
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
        var versionVotes = Map.empty<Text, Nat>();
        
        for ((serverAddr, server) in Map.entries(servers)) {
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
        
        for ((version, stake) in Map.entries(versionVotes)) {
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
        Map.get(servers, Principal.compare, server)
    };
    
    public query func getChallenge(challengeId: Nat) : async ?Challenge {
        if (challengeId < List.size(challenges)) {
            List.get(challenges, challengeId)
        } else {
            null
        }
    };
    
    public query func getActiveServers() : async [Principal] {
        let activeServers = List.empty<Principal>();
        for ((addr, server) in Map.entries(servers)) {
            switch (server.status) {
                case (#Active) { List.add(activeServers, addr) };
                case (_) { };
            };
        };
        List.toArray(activeServers)
    };
    
    public query func getTotalActiveStake() : async Nat {
        totalActiveStake
    };
    
    public query func getRewardPool() : async Nat {
        rewardPool
    };
}