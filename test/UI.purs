module Test.UI where

import Data.Array
import Data.Maybe
import Debug.Trace
import Prelude hiding (div)
import Data.Symbol (class IsSymbol, SProxy(..))
import Effect (Effect)
import Effect.Class.Console (log)
import Record as Record
import Impulse.FRP.Event (Event, consume)
import Impulse.FRP.Event as Event
import Impulse.FRP.Signal (Signal)
import Impulse.FRP.Signal as Signal
import Impulse.DOM

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
  bindSignal' s \c -> do
    label' {} $ text $ show c
    div' {} $ text $ preface <> (show c)

app :: DOM {} {} Unit
app = do
  section' { className: "sectionHeader" } do
    d_div <- div {} $ text "Header"
    _ <- eff $ Event.consume (\e -> trace e \_ -> pure unit) $ onClick d_div
    s <- reduceEvent (onClick d_div) (\agg _ -> agg + 1) 0
    bindSignal' s \c -> div' {} $ text $ "Clicked it: " <> (show c)
    a' { href: "https://google.com" } $ text "link"
    listenAndReduce f_clickCounter (\agg curr -> agg + curr) 0 do
      b <- button {} $ text "click me for a point!"
      emit f_clickCounter $ Event.fmap (\_ -> 1) $ onClick b
      modScoreButton 2
      scoreDisplay "Your Score "
      modScoreButton 3
      modScoreButton (-1)
      div' {} $ text "Footer"

attachApp :: Effect Unit
attachApp = do
  attach "app" {} app
