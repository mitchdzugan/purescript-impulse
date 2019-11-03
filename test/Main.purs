module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Class.Console (log)
import Test.UI as UI

main :: Effect Unit
main = do
  log "🍝"
  log "You should add some tests!"

ui :: Effect Unit
ui = UI.attachApp
