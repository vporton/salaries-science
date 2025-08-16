import Principal "mo:core/Principal";
import Map "mo:core/Map";
import Text "mo:core/Text";
import Nat "mo:core/Nat";
import Array "mo:core/Array";
import List "mo:core/List";
import Time "mo:core/Time";
import Result "mo:core/Result";

module {
    // Types
    public type AffiliateRecord = {
        affiliate: Principal;
        projectId: Text;
        totalBrought: Nat; // Total donations brought by this affiliate
        joinedAt: Time.Time;
        isActive: Bool;
    };
    
    public type AffiliateReward = {
        affiliate: Principal;
        amount: Nat;
        timestamp: Time.Time;
        donationId: Text;
    };
    
    public type ProjectAffiliateData = {
        projectId: Text;
        activeAffiliates: [Principal];
        totalDonationsViaAffiliates: Nat;
        affiliateHistory: [AffiliateRecord];
    };
    
    // Calculate affiliate rewards based on the formula in the whitepaper
    public func calculateAffiliateRewards(
        donationAmount: Nat,
        currentAffiliate: ?Principal,
        previousAffiliates: [(Principal, Nat)], // (affiliate, their previous contribution)
        totalPreviousDonations: Nat,
        affiliatePercentageY: Nat, // Y% for current affiliate
        affiliatePercentageK: Nat  // K% for previous affiliates
    ) : {
        currentAffiliateReward: Nat;
        previousAffiliatesRewards: [(Principal, Nat)];
        remainingAmount: Nat;
    } {
        var remainingAmount = donationAmount;
        var currentAffiliateReward: Nat = 0;
        let previousRewards = List.empty<(Principal, Nat)>();
        
        // Calculate Y% for current affiliate if exists
        switch (currentAffiliate) {
            case null { };
            case (?affiliate) {
                currentAffiliateReward := (donationAmount * affiliatePercentageY) / 100;
                remainingAmount -= currentAffiliateReward;
            };
        };
        
        // Calculate K%*d*D/(D+d) for previous affiliates
        if (previousAffiliates.size() > 0 and totalPreviousDonations > 0) {
            let d = donationAmount;
            let D = totalPreviousDonations;
            let previousAffiliateTotal = (affiliatePercentageK * d * D) / (100 * (D + d));
            
            if (previousAffiliateTotal > 0) {
                remainingAmount -= previousAffiliateTotal;
                
                // Distribute proportionally among previous affiliates
                var totalPreviousContributions: Nat = 0;
                for ((_, contribution) in previousAffiliates.vals()) {
                    totalPreviousContributions += contribution;
                };
                
                if (totalPreviousContributions > 0) {
                    for ((affiliate, contribution) in previousAffiliates.vals()) {
                        let affiliateShare = (previousAffiliateTotal * contribution) / totalPreviousContributions;
                        List.add(previousRewards, (affiliate, affiliateShare));
                    };
                };
            };
        };
        
        {
            currentAffiliateReward = currentAffiliateReward;
            previousAffiliatesRewards = List.toArray(previousRewards);
            remainingAmount = remainingAmount;
        }
    };
    
    // Track affiliate performance
    public class AffiliateTracker() {
        // TODO: Use `List.List`:
        private var affiliateRecords = Map.empty<Text, [AffiliateRecord]>();
        private var affiliateRewards = Map.empty<Principal, [AffiliateReward]>();
        private var projectAffiliateData = Map.empty<Text, ProjectAffiliateData>();
        
        public func recordAffiliateDonation(
            projectId: Text,
            affiliate: Principal,
            donationAmount: Nat
        ) : Result.Result<Text, Text> {
            // Update affiliate record
            let record: AffiliateRecord = {
                affiliate = affiliate;
                projectId = projectId;
                totalBrought = donationAmount;
                joinedAt = Time.now();
                isActive = true;
            };
            
            let projectRecords = switch (Map.get(affiliateRecords, Text.compare, projectId)) {
                case null { [] };
                case (?existing) { existing };
            };
            
            // Check if affiliate already exists for this project
            var found = false;
            let updatedRecords = Array.map<AffiliateRecord, AffiliateRecord>(
                projectRecords,
                func(r) {
                    if (r.affiliate == affiliate) {
                        found := true;
                        {
                            affiliate = r.affiliate;
                            projectId = r.projectId;
                            totalBrought = r.totalBrought + donationAmount;
                            joinedAt = r.joinedAt;
                            isActive = r.isActive;
                        }
                    } else { r }
                }
            );
            
            if (not found) { // TODO: Check this code.
                ignore Map.insert(affiliateRecords, Text.compare, projectId, Array.concat(updatedRecords, [record]));
            } else {
                ignore Map.insert(affiliateRecords, Text.compare, projectId, updatedRecords);
            };
            
            // Update project affiliate data
            updateProjectAffiliateData(projectId, affiliate, donationAmount);
            
            #ok("Affiliate donation recorded")
        };
        
        public func recordAffiliateReward(
            affiliate: Principal,
            amount: Nat,
            donationId: Text
        ) {
            let reward: AffiliateReward = {
                affiliate = affiliate;
                amount = amount;
                timestamp = Time.now();
                donationId = donationId;
            };
            
            let rewards = switch (Map.get(affiliateRewards, Principal.compare, affiliate)) {
                case null { [] };
                case (?existing) { existing };
            };
            
            ignore Map.insert(affiliateRewards, Principal.compare, affiliate, Array.concat(rewards, [reward]));
        };
        
        public func getAffiliateStats(affiliate: Principal) : {
            totalEarned: Nat;
            projectsPromoted: Nat;
            totalDonationsBrought: Nat;
        } {
            var totalEarned: Nat = 0;
            var projectsPromoted: Nat = 0;
            var totalDonationsBrought: Nat = 0;
            
            // Calculate total earned
            switch (Map.get(affiliateRewards, Principal.compare, affiliate)) {
                case null { };
                case (?rewards) {
                    for (reward in rewards.vals()) {
                        totalEarned += reward.amount;
                    };
                };
            };
            
            // Calculate projects promoted and donations brought
            for ((projectId, records) in Map.entries(affiliateRecords)) {
                for (record in records.vals()) {
                    if (record.affiliate == affiliate) {
                        projectsPromoted += 1;
                        totalDonationsBrought += record.totalBrought;
                    };
                };
            };
            
            {
                totalEarned = totalEarned;
                projectsPromoted = projectsPromoted;
                totalDonationsBrought = totalDonationsBrought;
            }
        };
        
        public func getProjectAffiliates(projectId: Text) : [(Principal, Nat)] {
            switch (Map.get(affiliateRecords, Text.compare, projectId)) {
                case null { [] };
                case (?records) {
                    Array.map<AffiliateRecord, (Principal, Nat)>(
                        Array.filter<AffiliateRecord>(
                            records,
                            func(r) = r.isActive
                        ),
                        func(r) = (r.affiliate, r.totalBrought)
                    )
                };
            }
        };
        
        private func updateProjectAffiliateData(
            projectId: Text,
            affiliate: Principal,
            donationAmount: Nat
        ) {
            let data = switch (Map.get(projectAffiliateData, Text.compare, projectId)) {
                case null {
                    {
                        projectId = projectId;
                        activeAffiliates = [affiliate];
                        totalDonationsViaAffiliates = donationAmount;
                        affiliateHistory = [];
                    }
                };
                case (?existing) {
                    let activeAffiliates = if (Array.find<Principal>(
                        existing.activeAffiliates,
                        func(a) = a == affiliate
                    ) == null) {
                        Array.concat(existing.activeAffiliates, [affiliate])
                    } else {
                        existing.activeAffiliates
                    };
                    
                    {
                        projectId = existing.projectId;
                        activeAffiliates = activeAffiliates;
                        totalDonationsViaAffiliates = existing.totalDonationsViaAffiliates + donationAmount;
                        affiliateHistory = existing.affiliateHistory;
                    }
                };
            };
            
            ignore Map.insert(projectAffiliateData, Text.compare, projectId, data);
        };
    };
}