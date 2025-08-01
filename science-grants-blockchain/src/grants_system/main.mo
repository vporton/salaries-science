import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Time "mo:base/Time";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Iter "mo:base/Iter";
import Order "mo:base/Order";

actor GrantsSystem {
    // Types
    public type TokenType = {
        #ICP;
        #IS20: Text; // Token canister ID
    };
    
    public type DonationSpec = {
        projectId: Text;
        amount: Nat;
        token: TokenType;
        dependencyPercentage: Nat; // X% for dependencies
        affiliatePercentage: Nat; // Y% for affiliate
        affiliate: ?Principal;
        timestamp: Time.Time;
    };
    
    public type ServerInfo = {
        address: Principal;
        pledge: Nat;
        participatesInRewards: Bool;
        errors: Nat;
    };
    
    public type RoundConfig = {
        startTime: Time.Time;
        endTime: Time.Time;
        challengeEndTime: Time.Time;
        worldScienceDAOTax: Nat; // Percentage
        serverRewardPercentage: Nat; // Percentage
        minDonationAmount: Nat;
        affiliateKPercentage: Nat; // K% for previous affiliates
        serverRewardZ: Nat; // Fixed reward per dependency write
    };
    
    public type ProjectStats = {
        totalDonations: Nat;
        donorCount: Nat;
        matchingAmount: Nat;
        affiliates: [(Principal, Nat)]; // Affiliate and their contribution
    };
    
    public type GitCoinPassport = {
        address: Text;
        score: Float;
        timestamp: Time.Time;
    };
    
    // State
    private stable var currentRound: ?RoundConfig = null;
    private var donations = HashMap.HashMap<Text, [DonationSpec]>(100, Text.equal, Text.hash);
    private var matchingPool = HashMap.HashMap<TokenType, Nat>(10, func(a, b) = a == b, func(t) = 0);
    private var servers = HashMap.HashMap<Principal, ServerInfo>(50, Principal.equal, Principal.hash);
    private var projectStats = HashMap.HashMap<Text, ProjectStats>(100, Text.equal, Text.hash);
    private var passportScores = HashMap.HashMap<Text, [GitCoinPassport]>(1000, Text.equal, Text.hash);
    private var withdrawals = HashMap.HashMap<Text, [(TokenType, Nat)]>(100, Text.equal, Text.hash);
    
    // Start a new funding round
    public shared(msg) func startRound(config: RoundConfig) : async Result.Result<Text, Text> {
        switch (currentRound) {
            case (?_) { #err("A round is already active") };
            case null {
                currentRound := ?config;
                #ok("Round started successfully")
            };
        }
    };
    
    // Add to matching pool
    public shared(msg) func contributeToMatchingPool(
        token: TokenType,
        amount: Nat
    ) : async Result.Result<Text, Text> {
        switch (currentRound) {
            case null { #err("No active round") };
            case (?round) {
                if (Time.now() > round.startTime) {
                    return #err("Cannot contribute to matching pool after round starts");
                };
                
                let current = switch (matchingPool.get(token)) {
                    case null { 0 };
                    case (?amt) { amt };
                };
                
                matchingPool.put(token, current + amount);
                #ok("Added to matching pool")
            };
        }
    };
    
    // Server pledge
    public shared(msg) func serverPledge(
        amount: Nat,
        participateInRewards: Bool
    ) : async Result.Result<Text, Text> {
        switch (currentRound) {
            case null { #err("No active round") };
            case (?round) {
                if (Time.now() > round.startTime) {
                    return #err("Cannot pledge after round starts");
                };
                
                let serverInfo: ServerInfo = {
                    address = msg.caller;
                    pledge = amount;
                    participatesInRewards = participateInRewards;
                    errors = 0;
                };
                
                servers.put(msg.caller, serverInfo);
                
                // Add to matching pool
                let current = switch (matchingPool.get(#ICP)) {
                    case null { 0 };
                    case (?amt) { amt };
                };
                matchingPool.put(#ICP, current + amount);
                
                #ok("Server pledged successfully")
            };
        }
    };
    
    // Make a donation
    public shared(msg) func donate(spec: DonationSpec) : async Result.Result<Text, Text> {
        switch (currentRound) {
            case null { #err("No active round") };
            case (?round) {
                let now = Time.now();
                if (now < round.startTime or now > round.endTime) {
                    return #err("Not in donation period");
                };
                
                if (spec.amount < round.minDonationAmount) {
                    return #err("Donation below minimum amount");
                };
                
                // Record donation
                let projectDonations = switch (donations.get(spec.projectId)) {
                    case null { [] };
                    case (?existing) { existing };
                };
                
                let newDonations = Array.append(projectDonations, [spec]);
                donations.put(spec.projectId, newDonations);
                
                // Update project stats
                updateProjectStats(spec);
                
                #ok("Donation recorded")
            };
        }
    };
    
    // Submit GitCoin passport score
    public shared(msg) func submitPassportScore(
        address: Text,
        score: Float
    ) : async Result.Result<Text, Text> {
        let passport: GitCoinPassport = {
            address = address;
            score = score;
            timestamp = Time.now();
        };
        
        let scores = switch (passportScores.get(address)) {
            case null { [] };
            case (?existing) { existing };
        };
        
        passportScores.put(address, Array.append(scores, [passport]));
        #ok("Passport score submitted")
    };
    
    // Calculate quadratic matching
    public func calculateMatching(projectId: Text) : async Nat {
        switch (currentRound) {
            case null { 0 };
            case (?round) {
                let projectDonations = switch (donations.get(projectId)) {
                    case null { return 0 };
                    case (?d) { d };
                };
                
                // Group donations by donor and calculate square roots
                let donorTotals = HashMap.HashMap<Principal, Float>(100, Principal.equal, Principal.hash);
                
                for (donation in projectDonations.vals()) {
                    let donor = Principal.fromText(donation.projectId); // This should be donor address
                    let current = switch (donorTotals.get(donor)) {
                        case null { 0.0 };
                        case (?amt) { amt };
                    };
                    
                    // Get passport score
                    let score = getMedianPassportScore(Principal.toText(donor));
                    donorTotals.put(donor, current + Float.fromInt(donation.amount) * score);
                };
                
                // Calculate sum of square roots
                var sumOfSqrts = 0.0;
                for ((_, amount) in donorTotals.entries()) {
                    sumOfSqrts += Float.sqrt(amount);
                };
                
                // Square the sum
                let matchingAmount = sumOfSqrts ** 2;
                
                // Get total matching pool for token type
                let totalPool = switch (matchingPool.get(#ICP)) {
                    case null { 0.0 };
                    case (?amt) { Float.fromInt(amt) };
                };
                
                // Calculate this project's share
                let allProjectsSumSqrts = calculateAllProjectsSumOfSquares();
                let projectShare = if (allProjectsSumSqrts > 0) {
                    matchingAmount / allProjectsSumSqrts
                } else { 0.0 };
                
                Int.abs(Float.toInt(projectShare * totalPool))
            };
        }
    };
    
    // Calculate distribution after round ends
    public shared func calculateDistributions() : async Result.Result<Text, Text> {
        switch (currentRound) {
            case null { #err("No active round") };
            case (?round) {
                if (Time.now() < round.endTime) {
                    return #err("Round has not ended yet");
                };
                
                // Calculate distributions for each project
                for ((projectId, _) in donations.entries()) {
                    let matching = await calculateMatching(projectId);
                    let stats = switch (projectStats.get(projectId)) {
                        case null { continue };
                        case (?s) { s };
                    };
                    
                    // Calculate after tax and affiliate fees
                    let totalAmount = stats.totalDonations + matching;
                    let afterTax = totalAmount * (100 - round.worldScienceDAOTax) / 100;
                    
                    // Store withdrawal allowance
                    let current = switch (withdrawals.get(projectId)) {
                        case null { [] };
                        case (?w) { w };
                    };
                    
                    withdrawals.put(projectId, Array.append(current, [(#ICP, afterTax)]));
                };
                
                #ok("Distributions calculated")
            };
        }
    };
    
    // Withdraw funds
    public shared(msg) func withdraw(projectId: Text) : async Result.Result<Nat, Text> {
        switch (withdrawals.get(projectId)) {
            case null { #err("No funds to withdraw") };
            case (?funds) {
                var total = 0;
                for ((_, amount) in funds.vals()) {
                    total += amount;
                };
                
                // Clear withdrawals
                withdrawals.delete(projectId);
                
                // In real implementation, transfer funds here
                #ok(total)
            };
        }
    };
    
    // Helper functions
    private func updateProjectStats(donation: DonationSpec) {
        let stats = switch (projectStats.get(donation.projectId)) {
            case null {
                {
                    totalDonations = 0;
                    donorCount = 0;
                    matchingAmount = 0;
                    affiliates = [];
                }
            };
            case (?existing) { existing };
        };
        
        let updatedStats: ProjectStats = {
            totalDonations = stats.totalDonations + donation.amount;
            donorCount = stats.donorCount + 1;
            matchingAmount = stats.matchingAmount;
            affiliates = switch (donation.affiliate) {
                case null { stats.affiliates };
                case (?aff) {
                    // Update affiliate contributions
                    var found = false;
                    let updated = Array.map<(Principal, Nat), (Principal, Nat)>(
                        stats.affiliates,
                        func((p, amt)) {
                            if (p == aff) {
                                found := true;
                                (p, amt + donation.amount)
                            } else {
                                (p, amt)
                            }
                        }
                    );
                    
                    if (not found) {
                        Array.append(updated, [(aff, donation.amount)])
                    } else {
                        updated
                    }
                }
            };
        };
        
        projectStats.put(donation.projectId, updatedStats);
    };
    
    private func getMedianPassportScore(address: Text) : Float {
        switch (passportScores.get(address)) {
            case null { 1.0 }; // Default score
            case (?scores) {
                if (scores.size() == 0) { return 1.0 };
                
                // Sort scores
                let sorted = Array.sort<GitCoinPassport>(
                    scores,
                    func(a, b) = Float.compare(a.score, b.score)
                );
                
                // Get median
                let mid = sorted.size() / 2;
                if (sorted.size() % 2 == 0 and sorted.size() > 1) {
                    (sorted[mid - 1].score + sorted[mid].score) / 2.0
                } else {
                    sorted[mid].score
                }
            };
        }
    };
    
    private func calculateAllProjectsSumOfSquares() : Float {
        var total = 0.0;
        // This would calculate for all projects
        // Simplified for now
        total
    };
    
    // Query functions
    public query func getRoundConfig() : async ?RoundConfig {
        currentRound
    };
    
    public query func getProjectStats(projectId: Text) : async ?ProjectStats {
        projectStats.get(projectId)
    };
    
    public query func getMatchingPool(token: TokenType) : async Nat {
        switch (matchingPool.get(token)) {
            case null { 0 };
            case (?amount) { amount };
        }
    };
}