module Impulse.DOM.API
       ( DOM
       , Collector
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
       , e_emit
       -- , e_consume (probably?)
       -- misc
       , d_memo
       , d_stash
       , d_apply
       , d_apply_
       -- vdom keys
       , keyed
       -- putting to use
       , attach
       , toMarkup
       -- for dealing `ImpulseStash`s
       , ImpulseStash
       , stashRes
       -- for dealing `ImpulseSSR`s
       , ImpulseSSR
       , ssr_then
       -- for dealing `ImpulseAttachment`s
       , ImpulseAttachment
       , detach
       , attachRes
       -- core API but not mostly made useless by better wrappers --
       , env
       , withAlteredEnv
       -- types required to be exported but should remain unused
       , DOMClass
       ) where

import Prelude
import Control.Monad.Reader
import Data.Array as A
import Data.Hashable as H
import Data.Maybe as M
import Data.Symbol (class IsSymbol, SProxy(..))
import Effect (Effect)
import Prim.Row (class Cons, class Lacks, class Union)
import Record as R
import Impulse.DOM.Attrs
import Impulse.DOM.ImpulseEl as El
import Impulse.FRP as FRP

-- TYPES ---------------------------

foreign import data DOMClass :: Type -> Type -> Type
foreign import data ImpulseStash :: Type -> Type
foreign import data ImpulseAttachment :: Type -> Type
foreign import data ImpulseSSR :: Type -> Type
foreign import data Collector :: Type -> Type
foreign import data JSAttrs :: Type

type DOM e c a = Reader (DOMClass e c) a


foreign import toJSAttrs :: forall a. (a -> M.Maybe a -> a) -> DOMAttrs -> JSAttrs

-- CORE API IMPORT -----------------

foreign import envImpl :: forall e c. DOMClass e c -> e

foreign import withAlteredEnvImpl :: forall e1 e2 c a. (e1 -> e2) -> (DOMClass e2 c -> a) -> DOMClass e1 c -> a

foreign import keyedImpl :: forall e c a. String -> (DOMClass e c -> a) -> DOMClass e c -> a

foreign import createElementImpl :: forall e c a. String -> JSAttrs -> (DOMClass e c -> a) -> DOMClass e c -> El.ImpulseEl a

foreign import textImpl :: forall e c. String -> DOMClass e c -> Unit

foreign import e_collectImpl ::
  forall e c1 c2 a b.
  (c1 -> Collector a -> c2) ->
  (c2 -> Collector a) ->
  (FRP.Event a -> DOMClass e c2 -> b) ->
  DOMClass e c1 ->
  b

foreign import e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit

foreign import s_bindDOMImpl :: forall e c a b. FRP.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> FRP.Signal b

foreign import s_useImpl :: forall e c a. (FRP.SigBuild a) -> DOMClass e c -> FRP.Signal a

foreign import d_stashImpl :: forall e c a. (DOMClass e c ->  a) -> DOMClass e c -> ImpulseStash a

foreign import d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a

foreign import d_memoImpl :: forall e c a b. (a -> Int) -> a -> (a -> DOMClass e c -> b) -> DOMClass e c -> b

------------------------------------

foreign import attachImpl :: forall e a. String -> e -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)

foreign import toMarkupImpl :: forall e a. e -> (DOMClass e {} -> a) -> Effect (ImpulseSSR a)

------------------------------------

foreign import ssr_then :: forall a. ImpulseSSR a -> (String -> a -> Effect Unit) -> Effect Unit

foreign import attachRes :: forall a. ImpulseAttachment a -> a

foreign import detach :: forall a. ImpulseAttachment a -> Effect Unit

foreign import stashRes :: forall a. ImpulseStash a -> a

-- CORE API ------------------------

env :: forall e c. DOM e c e
env = ask <#> envImpl

withAlteredEnv :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c a
withAlteredEnv f inner = ask <#> withAlteredEnvImpl f (runReader inner)

keyed :: forall e c a. String -> DOM e c a -> DOM e c a
keyed s inner = ask <#> keyedImpl s (runReader inner)

createElement :: forall e c a. String -> Attrs -> DOM e c a -> DOM e c (El.ImpulseEl a)
createElement tag attrs inner = do
  ask <#> createElementImpl tag (toJSAttrs M.fromMaybe $ mkAttrs attrs) (runReader inner)

createElement_ :: forall r e a. String -> Attrs -> DOM r e a -> DOM r e a
createElement_ tag attrs inner = createElement tag attrs inner <#> El.elRes

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
e_emit proxy event = do
  pure unit
  ask <#> e_emitImpl (R.get proxy) event

s_bindDOM :: forall e c a b. FRP.Signal a -> (a -> DOM e c b) -> DOM e c (FRP.Signal b)
s_bindDOM s inner = ask <#> s_bindDOMImpl s (runReader <<< inner)

s_bindDOM_ :: forall r e a b. FRP.Signal a -> (a -> DOM r e b) -> DOM r e Unit
s_bindDOM_ s f = s_bindDOM s f <#> const unit

s_use :: forall e c a. (FRP.SigBuilder a) -> DOM e c (FRP.Signal a)
s_use sb = ask <#> s_useImpl (FRP.s_build sb)


-- | `d_stash inner`
-- |
-- | runs `inner` but does not render in place, instead stashes whatever
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

d_memo :: forall e c a b. H.Hashable a => a -> (a -> DOM e c b) -> DOM e c b
d_memo v inner = ask <#> d_memoImpl H.hash v (runReader <<< inner)

------------------------------------

attach :: forall e a. String -> e -> DOM e {} a -> Effect (ImpulseAttachment a)
attach id envInit dom = attachImpl id envInit $ runReader dom

toMarkup :: forall e a. e -> DOM e {} a -> Effect (ImpulseSSR a)
toMarkup envInit dom = toMarkupImpl envInit $ runReader dom

------------------------------------