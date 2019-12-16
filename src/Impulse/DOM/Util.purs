module Impulse.DOM.Util
       ( getEnv
       , withEnv
       , upsertEnv
       , e_collectAndReduce
       , d_clone
       , s_extract
       , s_extract_
       , d_read
       , d_readAs
       , s_bindKeyedDOM
       , s_bindKeyedDOM_
       ) where

import Prelude
import Control.Monad.Reader
import Data.Symbol (class IsSymbol, SProxy(..))
import Prim.Row (class Cons, class Lacks, class Union)
import Record as R
import Impulse.FRP as FRP
import Impulse.DOM.API (DOM, Collector, ImpulseStash)
import Impulse.DOM.API as API


-- | `getEnv p`
-- |
-- | pulls the value at `p` out of the current environment
-- | ```
-- |   p_test = (SProxy :: SProxy "test")
-- |
-- |   displayFromEnv :: forall e c. DOM { test :: String | e } c Unit
-- |   displayFromEnv = do
-- |     test <- getEnv p_test    --  <-- Usage here
-- |     div_ anil $ text test
-- |
-- |   test :: forall e c. DOM e c Unit
-- |   test = do
-- |     upsertEnv p_test "Hello World!" do
-- |       displayFromEnv
-- | ```
-- | results in
-- | ```
-- |   <div>Hello World!</div>
-- | ```
getEnv ::
  forall c a r1 r2 l.
  IsSymbol l =>
  Cons l a r1 r2 =>
  SProxy l ->
  DOM (Record r2) c a
getEnv proxy = API.env <#> R.get proxy

withEnv :: forall r1 r2 e a. r2 -> DOM r2 e a -> DOM r1 e a
withEnv newEnv = API.withAlteredEnv (const newEnv)

-- | `upsertEnv p value inner`
-- |
-- | runs `inner` with `value` added to the environment at `p`
-- | ```
-- |   p_test = (SProxy :: SProxy "test")
-- |
-- |   displayFromEnv :: forall e c. DOM { test :: String | e } c Unit
-- |   displayFromEnv = do
-- |     test <- getEnv p_test
-- |     div_ anil $ text test
-- |
-- |   test :: forall e c. DOM e c Unit
-- |   test = do
-- |     upsertEnv p_test "Hello World!" do     --  <-- Usage here
-- |       displayFromEnv
-- | ```
-- | results in
-- | ```
-- |   <div>Hello World!</div>
-- | ```
upsertEnv ::
  forall res a sym rI rSym rO rOSymless c.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym a () rSym =>
  Cons sym a rOSymless rO =>
  Union rSym rI rO =>
  SProxy sym ->
  a ->
  DOM (Record rO) c res ->
  DOM (Record rI) c res
upsertEnv p v = API.withAlteredEnv $ R.union $ R.insert p v {}

d_readAs ::
  forall sym e e' c a b res.
  IsSymbol sym =>
  Cons sym a e' e =>
  SProxy sym ->
  (a -> b) ->
  Reader b res ->
  DOM { | e } { | c } res
d_readAs sym f r = getEnv sym >>= f >>> runReader r >>> pure

d_read ::
  forall sym e e' c a res.
  IsSymbol sym =>
  Cons sym a e' e =>
  SProxy sym ->
  Reader a res ->
  DOM { | e } { | c } res
d_read sym = d_readAs sym identity

-- | `e_collectAndReduce p reducer init inner`
-- |
-- | Creates a signal from the supplied `reducer` and `init`ial value.
-- | `inner` is then run with the created signal injected into the
-- | environment at `p`. The event used to drive the `reducer` is the
-- | combination of all events `e_emit`ed to `p` while running `inner`.
-- | ```
-- |    p_score = (SProxy :: SProxy "score")
-- |
-- |    scoreButton ::
-- |      forall e c.
-- |      Int ->
-- |      String ->
-- |      DOM e { score :: Collector Int | c } Unit
-- |    scoreButton change message = do
-- |      d_button <- button anil $ text message
-- |      e_emit p_score $ onClick d_button <#> const change
-- |
-- |    displayScore ::
-- |      forall e c.
-- |      DOM { score :: Signal Int | e } c Unit
-- |    displayScore = do
-- |      s_score <- getEnv p_score
-- |      s_bindDOM_ s_score \score -> do
-- |        span_ anil $ text $ "Score: " <> show score
-- |
-- |    test :: forall e c. DOM e c Unit
-- |    test = do
-- |      e_collectAndReduce p_score (\agg change -> agg + change) 0 do
-- |        scoreButton (-1) "Decrement Score"
-- |        displayScore
-- |        scoreButton (1) "Increment Score"
-- | ```
-- | results in
-- | ```
-- |   <button>Decrement Score</button>
-- |   <span>Score: 0</span>
-- |   <button>Increment Score</button>
-- | ```
-- | with the score text changing as expected
e_collectAndReduce ::
  forall res a b sym eI eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (Collector a) () cSym =>
  Cons sym (Collector a) cOSymless cO =>
  Union cSym cI cO =>
  Cons sym (FRP.Signal b) () eSym =>
  Cons sym (FRP.Signal b) eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  (b -> a -> b) ->
  b ->
  DOM { | eO } { | cO } res ->
  DOM { | eI } { | cI } res
e_collectAndReduce proxy reducer init inner = do
  API.e_collect proxy go
  where go e_raw = do
          let e = FRP.reduce reducer init e_raw
          s <- API.s_use $ FRP.s_from e init
          upsertEnv proxy s inner

d_clone :: forall e c a. ImpulseStash a -> DOM e c (ImpulseStash a)
d_clone = API.d_apply >>> API.d_stash

s_extract :: forall e c a. FRP.Signal (ImpulseStash a) -> DOM e c (ImpulseStash (FRP.Signal a))
s_extract = flip API.s_bindDOM API.d_apply >>> API.d_stash

s_extract_ :: forall e c a. FRP.Signal (ImpulseStash a) -> DOM e c (ImpulseStash Unit)
s_extract_ = flip API.s_bindDOM_ API.d_apply_ >>> API.d_stash

s_bindKeyedDOM :: forall e c a b. (Show a) => FRP.Signal a -> (a -> DOM e c b) -> DOM e c (FRP.Signal b)
s_bindKeyedDOM signal inner = do
  API.s_bindDOM signal \val -> API.keyed (show val) $ inner val

s_bindKeyedDOM_ :: forall e c a b. (Show a) => FRP.Signal a -> (a -> DOM e c b) -> DOM e c Unit
s_bindKeyedDOM_ signal inner = do
  API.s_bindDOM_ signal \val -> API.keyed (show val) $ inner val
