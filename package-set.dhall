let upstream = https://github.com/dfinity/vessel-package-set/releases/download/mo-0.8.8-20230505/package-set.dhall sha256:a080991699e6d96dd2213e81085ec4ade973c94df85238de88bc7644a542de5d
let Package =
    { name : Text, version : Text, repo : Text, dependencies : List Text }

let
  -- This is where you can add your own packages to the package-set
  additions =
    [
      { name = "stable-rbtree"
      , repo = "https://github.com/canscale/StableRBTree"
      , version = "v0.6.1"
      , dependencies = [ "base" ]
      },
      { name = "stable-buffer"
      , repo = "https://github.com/canscale/StableBuffer"
      , version = "v0.2.0"
      , dependencies = [ "base" ]
      },
      { name = "btree"
      , repo = "https://github.com/canscale/StableHeapBTreeMap"
      , version = "v0.3.1"
      , dependencies = [ "base" ]
      },
      { name = "candb"
      , repo = "git@github.com:canscale/CanDB.git"
      , version = "beta"
      , dependencies = [ "base" ]
      },
    ] : List Package

let
  {- This is where you can override existing packages in the package-set

     For example, if you wanted to use version `v2.0.0` of the foo library:
     let overrides = [
         { name = "foo"
         , version = "v2.0.0"
         , repo = "https://github.com/bar/foo"
         , dependencies = [] : List Text
         }
     ]
  -}
  overrides =
    [] : List Package

in  upstream # additions # overrides
