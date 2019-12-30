module Test.Main where

import Debug.Trace
import Impulse.DOM.Attrs
import Prelude

import Data.Symbol (class IsSymbol, SProxy(..))
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console (log)
import Impulse.DOM as DOM
import Impulse.FRP as FRP

test :: DOM {} {} Unit
test = do
  s <- DOM.s_use $ FRP.s_from (FRP.timer 1000) 0
  s2 <- DOM.s_use $ FRP.s_from (FRP.timer 2000) 0
  DOM.e_collectAndReduce p_clicks (\agg _ -> agg + 1) 0 do
    DOM.createElement_ "section" (className "section") do
      DOM.createElement_ "div" (className "testClass") do
        DOM.keyed "ayyy lmao" $ DOM.s_bindDOM_ s $ \c -> DOM.s_bindDOM_ s2 \c2 -> do
          DOM.d_memo 1 $ const do
            text $ " ::[memo c, bound c2]:: [" <> (show c)
            DOM.s_bindDOM_ s2 \c2 -> do
              text $ ",  " <> (show c2) <> "]"
          DOM.keyed (show c) do
            ul_ anil do
              stash <- d_stash do
                li_ anil $ text "out"
                li_ anil $ text "of"
                li_ anil $ text "order!?!"
              li_ (className "1" *> id "1") $ text "You"
              d_li <- li (id "2" *> className "2") $ text "thought"
              DOM.e_emit p_clicks $ DOM.onClick d_li
              li_ (className "3") $ text "this"
              li_ (id "3") $ text "was"
              d_apply stash
            DOM.text $ show c
            DOM.text " :: "
            DOM.text $ show c2
            d_button <- DOM.createElement "button" anil $ DOM.text "Click Me!"
            DOM.e_emit p_clicks $ DOM.onClick d_button <#> \val -> trace { val } \_ -> val
            pure unit
    s_clicks <- DOM.getEnv p_clicks
    DOM.s_bindDOM_ s_clicks \clicks -> do
      DOM.text "Clicks :: "
      DOM.text $ show clicks

ui :: Effect Unit
ui = do
  -- ssr <- DOM.toMarkup {} test
  -- DOM.ssr_then ssr $ \markup res -> do
    -- trace { markup, res } \_ -> pure unit
    -- pure unit
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
li = DOM.createElement "li"
d_stash = DOM.d_stash
d_apply = DOM.d_apply
