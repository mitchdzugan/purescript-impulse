module Test.UI where

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
  s_bind' s \c -> do
    label' {} $ text $ show c
    div' {} $ text $ preface <> (show c)

app :: DOM {} {} Unit
app = do
  div' {} do
    d_button <- button {} $ text "Click"
    s_clicks <- e_reduce (onClick d_button) (\agg _ -> agg + 1) 0
    s_clicksObj <- s_bind s_clicks \clicks -> pure { clicks }
    s_div3Obj <- s_dedup =<< s_bind s_clicksObj \({ clicks }) -> pure $ { div3: clicks / 3 }
    s_bind' s_div3Obj \({ div3 }) -> div' {} do
      div' {} $ text $ "div3Val: " <> (show div3)
    s_div3 <- s_bind s_clicks \i -> pure $ i / 3
    s_sum <- s_flatten =<< s_bind s_clicks \clicks -> do
      s_bind s_div3 \div3 -> do
        pure $ clicks + div3
    s_bind' s_sum \sum -> do
      div' {} $ text $ show sum
    s_double <- s_bind s_clicks \clicks -> pure $ 2 * clicks
    s_bind' s_double \double -> text $ "Test: " <> (show double)

attachApp :: Effect Unit
attachApp = do
  attach "app" {} app
