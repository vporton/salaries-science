import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Time "mo:base/Time";
import Result "mo:base/Result";

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
        let previousRewards = Buffer.Buffer<(Principal, Nat)>(previousAffiliates.size());
        
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
                        previousRewards.add((affiliate, affiliateShare));
                    };
                };
            };
        };
        
        {
            currentAffiliateReward = currentAffiliateReward;
            previousAffiliatesRewards = Buffer.toArray(previousRewards);
            remainingAmount = remainingAmount;
        }
    };
    
    // Track affiliate performance
    public class AffiliateTracker() {
        private var affiliateRecords = HashMap.HashMap<Text, [AffiliateRecord]>(100, Text.equal, Text.hash);
        private var affiliateRewards = HashMap.HashMap<Principal, [AffiliateReward]>(100, Principal.equal, Principal.hash);
        private var projectAffiliateData = HashMap.HashMap<Text, ProjectAffiliateData>(100, Text.equal, Text.hash);
        
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
            
            let projectRecords = switch (affiliateRecords.get(projectId)) {
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
            
            if (not found) {
                affiliateRecords.put(projectId, Array.append(updatedRecords, [record]));
            } else {
                affiliateRecords.put(projectId, updatedRecords);
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
            
            let rewards = switch (affiliateRewards.get(affiliate)) {
                case null { [] };
                case (?existing) { existing };
            };
            
            affiliateRewards.put(affiliate, Array.append(rewards, [reward]));
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
            switch (affiliateRewards.get(affiliate)) {
                case null { };
                case (?rewards) {
                    for (reward in rewards.vals()) {
                        totalEarned += reward.amount;
                    };
                };
            };
            
            // Calculate projects promoted and donations brought
            for ((projectId, records) in affiliateRecords.entries()) {
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
            switch (affiliateRecords.get(projectId)) {
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
            let data = switch (projectAffiliateData.get(projectId)) {
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
                        Array.append(existing.activeAffiliates, [affiliate])
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
            
            projectAffiliateData.put(projectId, data);
        };
    };
}