module Test.UI where

import Debug.Trace
import Data.Array
import Data.Maybe
import Prelude hiding (div)
import Control.Monad ((=<<))
import Data.Symbol (class IsSymbol, SProxy(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Record as Record
import Impulse.FRP.Event (Event, consume)
import Impulse.FRP.Event as Event
import Impulse.FRP.Signal (Signal)
import Impulse.FRP.Signal as Signal
import Impulse.DOM
import Impulse.DOM.Tags
import Impulse.DOM.Attrs
import Web.UIEvent.MouseEvent as ME

f_clickCounter = SProxy :: SProxy "clickCounter"

modScoreButton ::
  forall e rc.
  Int -> DOM e { clickCounter :: EventCollector Int | rc } Unit
modScoreButton num = do
  b <-
    button anil $ text $ "click me for "
      <> (if (num > 0) then "+" else "")
      <> (show num)
  emit f_clickCounter $ Event.fmap (\_ -> num) $ onClick b

scoreDisplay ::
  forall re c.
  String -> DOM { clickCounter :: Signal Int | re } c Unit
scoreDisplay preface = do
  s <- getEnv f_clickCounter
  s_bindDOM' s \c -> do
    label' anil $ text $ show c
    div' anil $ text $ preface <> (show c)

app :: DOM {} {} Unit
app = do
  div' (id "myApp") do
    d_button <- button anil $ text "Click"
    s_clicks <- e_reduce (onClick d_button) (\agg _ -> agg + 1) 0
    let e_2 = Event.makeFrom (onClick d_button)
                $ \e push -> do log "hello!!!!"
                                trace { sx: ME.screenX e } \_ -> pure unit
                                push { e, t: 2 }
    _ <- eff $ flip Event.consume e_2 $ \{ t } -> log $ show { t }
    s_clicksObj <- s_bind s_clicks \clicks -> { clicks }
    s_div3Obj <- s_dedup =<< s_bind s_clicksObj \({ clicks }) -> { div3: clicks / 3 }
    s_bindDOM' s_div3Obj \({ div3 }) -> div' anil do
      trace "rendering div3Val" \_ -> dnil
      div' (do classNames do cn "test"
                             whenM (pure false) $ cn "wontBeOn"
                             whenM (pure true) $ cn "willBeOn"
                             cn "_div3Val"
               id "yellow"
               styles do style "color" "red"
                         style "background" "blue"
           )
        do text $ "div3Val: " <> (show div3)
    s_div3 <- s_bind s_clicks \i -> i / 3
    s_sum <- s_bindAndFlatten s_clicks \clicks -> do
      s_bind s_div3 \div3 -> clicks + div3
    s_bindDOM' s_sum \sum -> do
      div' anil $ text $ show sum
    s_double <- s_bind s_clicks \clicks -> 2 * clicks
    s_bindDOM' s_double \double -> text $ "Test: " <> (show double)
    d_a <- a (href "https://google.com") $ text "google"
    let e_a = withPreventDefault $ onClick d_a
    _ <- eff $ Event.consume (\v -> trace { v } \_ -> pure unit) e_a
    pure unit

attachApp :: Effect Unit
attachApp = do
  markup <- toMarkup {} app
  trace { markup } \_ -> pure unit
  attach "app" {} app
