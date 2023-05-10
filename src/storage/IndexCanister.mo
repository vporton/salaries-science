import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Text "mo:base/Text";
import TrieSet "mo:base/TrieSet";
import CA "mo:candb/CanisterActions";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stable-buffer/StableBuffer";
import DBPartition "DBPartition";
import Principal "mo:base/Principal";

shared actor class IndexCanister(owner: Principal) = this {
  stable var allowedCallers: TrieSet.Set<Principal> = TrieSet.empty<Principal>();

  public shared({caller = caller}) func addAllowedCaller(allowed: Principal) {
    if (Principal.equal(owner, caller)) {
      allowedCallers.put(allowed);
    } else {
      Debug.trap("only owner can add allowed callers")
    };
  };

  /// @required stable variable (Do not delete or change)
  ///
  /// Holds the CanisterMap of PK -> CanisterIdList
  stable var pkToCanisterMap = CanisterMap.init();

  /// @required API (Do not delete or change)
  ///
  /// Get all canisters for an specific PK
  ///
  /// This method is called often by the candb-client query & update methods. 
  public shared query({caller = caller}) func getCanistersByPK(pk: Text): async [Text] {
    getCanisterIdsIfExists(pk);
  };

  /// @required function (Do not delete or change)
  ///
  /// Helper method acting as an interface for returning an empty array if no canisters
  /// exist for the given PK
  func getCanisterIdsIfExists(pk: Text): [Text] {
    switch(CanisterMap.get(pkToCanisterMap, pk)) {
      case null { [] };
      case (?canisterIdsBuffer) { Buffer.toArray(canisterIdsBuffer) } 
    }
  };

  public shared({caller = caller}) func autoScaleCanister(pk: Text): async Text {
    if (Utils.callingCanisterOwnsPK(caller, pkToCanisterMap, pk)) {
      await createSalariesStorageCanister(pk, ?[owner, Principal.fromActor(this)]);
    } else {
      Debug.trap("error, called by non-controller=" # debug_show(caller));
    };
  };

  // FIXME
  public shared({caller = creator}) func createHelloServiceCanisterByGroup(group: Text): async ?Text {
    let pk = "group#" # group;
    let canisterIds = getCanisterIdsIfExists(pk);
    if (canisterIds == []) {
      ?(await createSalariesStorageCanister(pk, ?[owner, Principal.fromActor(this)]));
    // the partition already exists, so don't create a new canister
    } else {
      Debug.print(pk # " already exists");
      null 
    };
  };

  // FIXME: We need big single canister for storing dependencies.
  // Spins up a new HelloService canister with the provided pk and controllers
  func createSalariesStorageCanister(pk: Text, controllers: ?[Principal]): async Text {
    Debug.print("creating new storage canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new storage canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000); // TODO: Choose the number.
    let newStorageCanister = await DBPartition.DBPartition({
      primaryKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = #heapSize(475_000_000); // Scale out at 475MB
      };
      owners = controllers;
    });
    let newStorageCanisterPrincipal = Principal.fromActor(newStorageCanister);
    await CA.updateCanisterSettings({
      canisterId = newStorageCanisterPrincipal;
      settings = {
        controllers = controllers;
        compute_allocation = ?0;
        memory_allocation = ?0;
        freezing_threshold = ?2592000;
      }
    });

    let newStorageCanisterId = Principal.toText(newStorageCanisterPrincipal);
    // After creating the new Hello Service canister, add it to the pkToCanisterMap
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newStorageCanisterId);

    Debug.print("new storage canisterId=" # newStorageCanisterId);
    newStorageCanisterId;
  };
}