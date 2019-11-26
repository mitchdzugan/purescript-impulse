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

f_clickCounter = SProxy :: SProxy "clickCounter"

modScoreButton ::
  forall e rc.
  Int -> DOM e { clickCounter :: EventCollector Int | rc } Unit
modScoreButton num = do
  b <-
    button {} $ text $ "click me for "
      <> (if (num > 0) then "+" else "")
      <> (show num)
  emit f_clickCounter $ Event.fmap (\_ -> num) $ onClick b

scoreDisplay ::
  forall re c.
  String -> DOM { clickCounter :: Signal Int | re } c Unit
scoreDisplay preface = do
  s <- getEnv f_clickCounter
  s_bindDOM' s \c -> do
    label' {} $ text $ show c
    div' {} $ text $ preface <> (show c)

app :: DOM {} {} Unit
app = do
  div' {} do
    d_button <- button {} $ text "Click"
    s_clicks <- e_reduce (onClick d_button) (\agg _ -> agg + 1) 0
    e_2 <- eff $ flip Event.mapEff (onClick d_button)
               $ \e push -> do log "hello!!!!"
                               push { e, t: 2 }
    _ <- eff $ flip Event.consume e_2 $ \{ t } -> log $ show { t }
    s_clicksObj <- s_bind s_clicks \clicks -> { clicks }
    s_div3Obj <- s_dedup =<< s_bind s_clicksObj \({ clicks }) -> { div3: clicks / 3 }
    s_bindDOM' s_div3Obj \({ div3 }) -> div' {} do
      trace "rendering div3Val" \_ -> pure unit
      div' {} $ text $ "div3Val: " <> (show div3)
    s_div3 <- s_bind s_clicks \i -> i / 3
    s_sum <- s_bindAndFlatten s_clicks \clicks -> do
      s_bind s_div3 \div3 -> clicks + div3
    s_bindDOM' s_sum \sum -> do
      div' {} $ text $ show sum
    s_double <- s_bind s_clicks \clicks -> 2 * clicks
    s_bindDOM' s_double \double -> text $ "Test: " <> (show double)

attachApp :: Effect Unit
attachApp = do
  markup <- toMarkup {} app
  trace { markup } \_ -> pure unit
  attach "app" {} app
