import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Error "mo:base/Error";
import Text "mo:base/Text";
import CA "mo:candb/CanisterActions";
import Utils "mo:candb/Utils";
import CanisterMap "mo:candb/CanisterMap";
import Buffer "mo:stable-buffer/StableBuffer";
import ServiceActor "ServiceActor";
import Principal "mo:base/Principal";

shared ({caller = owner}) actor class IndexCanister() = this {
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
      await createBuilderStorageCanister(pk, ?[owner, Principal.fromActor(this)]);
    } else {
      Debug.trap("error, called by non-controller=" # debug_show(caller));
    };
  };

  // Spins up a new HelloService canister with the provided pk and controllers
  func createBuilderStorageCanister(pk: Text, controllers: ?[Principal]): async Text {
    Debug.print("creating new hello service canister with pk=" # pk);
    // Pre-load 300 billion cycles for the creation of a new Hello Service canister
    // Note that canister creation costs 100 billion cycles, meaning there are 200 billion
    // left over for the new canister when it is created
    Cycles.add(300_000_000_000);
    let newHelloServiceCanister = await ServiceActor.ServiceActor({
      primaryKey = pk;
      scalingOptions = {
        autoScalingHook = autoScaleCanister;
        sizeLimit = #heapSize(475_000_000); // Scale out at 475MB
      };
      owners = controllers;
    });
    let newHelloServiceCanisterPrincipal = Principal.fromActor(newHelloServiceCanister);
    await CA.updateCanisterSettings({
      canisterId = newHelloServiceCanisterPrincipal;
      settings = {
        controllers = controllers;
        compute_allocation = ?0;
        memory_allocation = ?0;
        freezing_threshold = ?2592000;
      }
    });

    let newHelloServiceCanisterId = Principal.toText(newHelloServiceCanisterPrincipal);
    // After creating the new Hello Service canister, add it to the pkToCanisterMap
    pkToCanisterMap := CanisterMap.add(pkToCanisterMap, pk, newHelloServiceCanisterId);

    Debug.print("new hello service canisterId=" # newHelloServiceCanisterId);
    newHelloServiceCanisterId;
  };
}