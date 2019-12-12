module Impulse.Native.BetterDOM
       ( DOM
       -- env
       , getEnv
       , upsertEnv
       -- creating DOM elements
       , createElement
       , createElement_
       , text
       -- signals
       , s_use
       , s_bindDOM
       , s_bindDOM_
       -- events
       , e_collect
       , e_collectAndReduce
       , e_emit
       -- misc
       , d_memo
       , d_stash
       , d_apply
       , d_apply_
       -- vdom keys
       , keyed
       -- types
       , Collector
       , ImpulseAttachment
       , ImpulseStash
       , ImpulseEl
       -- for dealing types
       , elRes
       -- putting to use
       , attach
       -- proxy reader
       , d_read
       , d_readAs
       -- -- core API but not mostly made useless by better wrappers --
       -- env
       , env
       , withAlteredEnv
       , withEnv
       -- types required to be exported but should remain unused
       , DOMClass
       ) where

import Prelude
import Debug.Trace
import Control.Monad.State.Trans as StateT
import Control.Monad.Reader
import DOM.HTML.Indexed as HTML
import Data.Array as A
import Data.HashMap as HM
import Data.Hashable as H
import Data.List as L
import Data.Maybe as M
import Data.Symbol (class IsSymbol, SProxy(..))
import Data.Traversable as TRV
import Data.Tuple as T
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Effect.Ref as Ref
import Impulse.Native.DOM.Attrs
import Impulse.Native.FRP as FRP
import Impulse.Native.FRP.Signal as Sig
import Impulse.Util.EffState as EffState
import Prim.Row (class Cons, class Lacks, class Union)
import Record as R
import Web.Event.Event as WE
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

-- TYPES ---------------------------

foreign import data DOMClass :: Type -> Type -> Type
foreign import data ImpulseEl :: Type -> Type
foreign import data ImpulseStash :: Type -> Type
foreign import data ImpulseAttachment :: Type -> Type
foreign import data Collector :: Type -> Type

type DOM e c a = Reader (DOMClass e c) a

-- CORE API IMPORT -----------------

foreign import envImpl :: forall e c. DOMClass e c -> e

foreign import withAlteredEnvImpl :: forall e1 e2 c a. (e1 -> e2) -> (DOMClass e2 c -> a) -> DOMClass e1 c -> a

foreign import keyedImpl :: forall e c a. String -> (DOMClass e c -> a) -> DOMClass e c -> a

foreign import createElementImpl :: forall e c a. String -> Attrs -> (DOMClass e c -> a) -> DOMClass e c -> ImpulseEl a

foreign import textImpl :: forall e c. String -> DOMClass e c -> Unit

foreign import e_collectImpl :: forall e c1 c2 a b. (c1 -> Collector a -> c2) -> (c2 -> Collector a) -> (FRP.Event a -> DOMClass e c2 -> b) -> DOMClass e c1 -> b

foreign import e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit

foreign import s_bindDOMImpl :: forall e c a b. Sig.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> Sig.Signal b

foreign import s_useImpl :: forall e c a. (Sig.SigBuild a) -> DOMClass e c -> Sig.Signal a

foreign import d_stashImpl :: forall e c a. (DOMClass e c ->  a) -> DOMClass e c -> ImpulseStash a

foreign import d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a

foreign import d_memoImpl :: forall e c a b. Eq a => H.Hashable a => a -> (a -> DOMClass e c -> b) -> DOMClass e c -> b

------------------------------------

foreign import attachImpl :: forall e a. String -> e -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)

------------------------------------

foreign import elRes :: forall a. ImpulseEl a -> a

-- CORE API ------------------------

env :: forall e c. DOM e c e
env = ask <#> envImpl

withAlteredEnv :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c a
withAlteredEnv f inner = ask <#> withAlteredEnvImpl f (runReader inner)

keyed :: forall e c a. String -> DOM e c a -> DOM e c a
keyed s inner = ask <#> keyedImpl s (runReader inner)

createElement :: forall e c a. String -> Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
createElement tag attrs inner = do
  ask <#> createElementImpl tag attrs (runReader inner)

createElement_ :: forall r e a. String -> Attrs -> DOM r e a -> DOM r e a
createElement_ tag attrs inner = createElement tag attrs inner <#> elRes

text :: forall e c. String -> DOM e c Unit
text s = ask <#> textImpl s

e_collect ::
  forall res a sym e cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (Collector a) () cSym =>
  Cons sym (Collector a) cOSymless cO =>
  Union cSym cI cO =>
  SProxy sym ->
  (FRP.Event a -> DOM e (Record cO) res) ->
  DOM e (Record cI) res
e_collect p inner = ask <#> e_collectImpl (\cs c -> R.union (R.insert p c {}) cs)
                                          (R.get p)
                                          (runReader <<< inner)

e_emit ::
  forall e a c1 c2 l.
  IsSymbol l =>
  Cons l (Collector a) c1 c2 =>
  SProxy l ->
  FRP.Event a ->
  DOM e (Record c2) Unit
e_emit proxy event = ask <#> e_emitImpl (R.get proxy) event

s_bindDOM :: forall e c a b. Sig.Signal a -> (a -> DOM e c b) -> DOM e c (Sig.Signal b)
s_bindDOM s inner = ask <#> s_bindDOMImpl s (runReader <<< inner)

s_bindDOM_ :: forall r e a b. Sig.Signal a -> (a -> DOM r e b) -> DOM r e Unit
s_bindDOM_ s f = s_bindDOM s f <#> const unit

s_use :: forall e c a. (Sig.SigBuild a) -> DOM e c (Sig.Signal a)
s_use eff_s = ask <#> s_useImpl eff_s


-- | `d_stash inner`
-- |
-- | runs inner but does not render in place, instead stashes whatever
-- | was rendered such that it can be used later using `d_apply`.
-- | stashes are immutable and can be passed around as far as you like.
-- | ```
-- |    test :: forall e c. DOM e c Unit
-- |    test = do
-- |      ul_ anil do
-- |        stash <- d_stash do
-- |          li_ anil $ text "out"
-- |          li_ anil $ text "of"
-- |          li_ anil $ text "order?"
-- |        li_ anil $ text "You"
-- |        li_ anil $ text "thought"
-- |        li_ anil $ text "this"
-- |        li_ anil $ text "was"
-- |        d_apply stash
-- | ```
-- | results in
-- | ```
-- |   <ul>
-- |       <li>You</li>
-- |       <li>thought</li>
-- |       <li>this</li>
-- |       <li>was</li>
-- |       <li>out</li>
-- |       <li>of</li>
-- |       <li>order?</li>
-- |   </ul>
-- | ```

d_stash :: forall e c a. DOM e c a -> DOM e c (ImpulseStash a)
d_stash inner = ask <#> d_stashImpl (runReader inner)

d_apply :: forall e c a. ImpulseStash a -> DOM e c a
d_apply stash = ask <#> d_applyImpl stash

d_apply_ :: forall e c a. ImpulseStash a -> DOM e c Unit
d_apply_ stash = d_apply stash <#> const unit

d_memo :: forall e c a b. Eq a => H.Hashable a => a -> (a -> DOM e c b) -> DOM e c b
d_memo v inner = ask <#> d_memoImpl v (runReader <<< inner)


-- API UTILS -----------------------


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
getEnv proxy = env <#> R.get proxy

withEnv :: forall r1 r2 e a. r2 -> DOM r2 e a -> DOM r1 e a
withEnv newEnv = withAlteredEnv (const newEnv)

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
upsertEnv p v = withAlteredEnv $ R.union $ R.insert p v {}

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

p_clicks = (SProxy :: SProxy "clicks")

-- |    clickButton :: forall e c. Int -> String -> DOM e { clicks :: Collector Int | c } Unit
-- |    displayClicks :: forall e c. DOM { clicks :: Signal Int | e } c Unit
-- |    test :: forall e c. DOM e c Unit
-- |    test = do
-- |      e_collectAndReduce p_clicks (\agg change -> agg + change) 0 do
-- |        clickButton (-1) "Decrement Score"
-- |        displayClicks
-- |        clickButton (1) "Increment Score"
e_collectAndReduce ::
  forall res a b sym eI eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (Collector a) () cSym =>
  Cons sym (Collector a) cOSymless cO =>
  Union cSym cI cO =>
  Cons sym (Sig.Signal b) () eSym =>
  Cons sym (Sig.Signal b) eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  (b -> a -> b) ->
  b ->
  DOM { | eO } { | cO } res ->
  DOM { | eI } { | cI } res
e_collectAndReduce proxy reducer init inner = do
  e_collect proxy go
  where go e_raw = do
          let e = FRP.reduce reducer init e_raw
          s <- s_use $ Sig.s_make e init
          upsertEnv proxy s inner

------------------------------------

attach :: forall e a. String -> e -> DOM e {} a -> Effect (ImpulseAttachment a)
attach id envInit dom = attachImpl id envInit $ runReader dom

------------------------------------

test3 :: Effect Unit
test3 = Console.log "lul"