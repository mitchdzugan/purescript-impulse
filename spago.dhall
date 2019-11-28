{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "my-project"
, dependencies =
    [ "arrays"
    , "console"
    , "debug"
    , "dom-indexed"
    , "effect"
    , "psci-support"
    , "record"
    , "transformers"
    ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
, license = "MIT"
, repository = "git@github.com:mitchdzugan/purescript-impulse.git"
}
