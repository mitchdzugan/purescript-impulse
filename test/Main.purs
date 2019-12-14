module Test.Main where

import Debug.Trace
import Impulse.Native.DOM.Attrs
import Prelude

import Data.Symbol (class IsSymbol, SProxy(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Impulse.Native.BetterDOM as DOM
import Impulse.Native.FRP as FRP
import Impulse.Native.FRP.Signal as Sig

p_test = SProxy :: SProxy "test"
p_clicks = SProxy :: SProxy "clicks"

main :: Effect Unit
main = log "hi"

test :: DOM.DOM {} {} Unit
test = do
  s <- DOM.s_use $ Sig.s_make (FRP.timer 1000) 0
  s2 <- DOM.s_use $ Sig.s_make (FRP.timer 5000) 0
  DOM.e_collectAndReduce p_clicks (\agg _ -> agg + 1) 0 do
    d_section <- DOM.createElement "section" (className "section") do
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
    DOM.e_emit p_clicks $ DOM.onClick d_section
    s_clicks <- DOM.getEnv p_clicks
    DOM.s_bindDOM_ s_clicks \clicks -> do
      DOM.createElement_ "div" anil do
        DOM.text "Clicks :: "
        DOM.text $ show clicks

ui :: Effect Unit
ui = do
  _ <- DOM.attach "test" {} test
  pure unit
