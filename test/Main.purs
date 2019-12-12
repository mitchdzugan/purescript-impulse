module Test.Main where

import Prelude

import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Impulse.Native.FRP as FRP
import Impulse.Native.FRP.Signal as Sig
import Impulse.Native.BetterDOM as DOM
import Impulse.Native.DOM.Attrs
import Debug.Trace
import Data.Symbol (class IsSymbol, SProxy(..))

p_test = SProxy :: SProxy "test"

main :: Effect Unit
main = log "hi"

test :: DOM.DOM {} {} Unit
test = do
  DOM.keyed "abc" $ DOM.createElement_ "section" (className "section") do
    DOM.keyed "123" $ DOM.createElement_ "div" (className "testClass") do
      DOM.text "Hello world!! :: "
  {-}
  liftEffect $ log "1"
  s <- liftEffect $ Sig.mkSignal (FRP.timer 1000) 0
  s2 <- liftEffect $ Sig.mkSignal (FRP.timer 5000) 0
  -- _ <- liftEffect $ Sig.sub (log <<< show) s2
  liftEffect $ log "2"
  DOM.createElement_ "section" (className "section") do
    DOM.createElement_ "div" (className "testClass") do
      DOM.text "Hello world!! :: "
      DOM.s_bindDOM_ s \c -> do
        DOM.text $ show c
      DOM.text " :: "
      DOM.s_bindDOM_ s \c -> do
        DOM.text $ show c
        DOM.text " :: "
        DOM.s_bindDOM_ s2 \c2 -> do
          DOM.text $ show c2
  -}

ui :: Effect Unit
ui = do
  _ <- DOM.attach "test" {} test
  pure unit
