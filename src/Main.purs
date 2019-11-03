module Main where

import Prelude

import Effect (Effect)
import Effect.Console (log)
import Impulse.FRP.Event as Event

main :: Effect Unit
main = do
  e <- Event.makeEvent $ pure $ pure unit
  off <- Event.consume log e
  Event.push "1" e
  off
