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

test :: DOM {} {} Unit
test = do
  -- sss <- DOM.s_use $ Sig.s_const 0
  -- DOM.upsertEnv p_clicks sss do
  s <- DOM.s_use $ Sig.s_from (FRP.timer 1000) 0
  s2 <- DOM.s_use $ Sig.s_from (FRP.timer 2000) 0
  DOM.e_collectAndReduce p_clicks (\agg _ -> agg + 1) 0 do
    DOM.createElement_ "section" (className "section") do
      DOM.createElement_ "div" (className "testClass") do
        DOM.s_bindDOM_ s $ \c -> DOM.s_bindDOM_ s2 \c2 -> do
          DOM.keyed (show c) do
            ul_ anil do
              stash <- d_stash do
                li_ anil $ text "out"
                li_ anil $ text "of"
                li_ anil $ text "order?"
              li_ anil $ text "You"
              li_ anil $ text "thought"
              li_ anil $ text "this"
              li_ anil $ text "was"
              d_apply stash
          DOM.text $ show c
          DOM.text " :: "
          DOM.text $ show c2
          d_button <- DOM.createElement "button" anil $ DOM.text "Click Me!"
          DOM.e_emit p_clicks $ DOM.onClick d_button
          pure unit
    s_clicks <- DOM.getEnv p_clicks
    DOM.s_bindDOM_ s_clicks \clicks -> do
      DOM.text "Clicks :: "
      DOM.text $ show clicks

ui :: Effect Unit
ui = do
  _ <- attach "test" {} test
  pure unit

type DOM a b c = DOM.DOM a b c

attach = DOM.attach

p_test = SProxy :: SProxy "test"
p_clicks = SProxy :: SProxy "clicks"

main :: Effect Unit
main = log "hi"

text = DOM.text
ul_ = DOM.createElement_ "ul"
li_ = DOM.createElement_ "li"
d_stash = DOM.d_stash
d_apply = DOM.d_apply
