module Impulse.Native.FRP.Signal
       ( s_from
       , s_fmap
       , s_const
       , s_zipWith
       , s_flatten
       , s_dedup
       , s_build
       , s_make
       , s_destroy
       , s_subRes
       , s_unsub
       , s_sub
       , s_inst
       , s_changed
       , s_tagWith
       , Signal
       , SigClass
       , SigBuild
       , SubRes
       ) where

import Control.Monad.Reader
import Prelude hiding (const)
import Prelude (const) as P
import Data.List as L
import Data.HashMap as HM
import Data.Traversable as TRV
import Effect (Effect)
import Effect.Ref as Ref
import Impulse.Native.FRP.Event as Event

foreign import data SigBuild :: Type -> Type
foreign import data SigClass :: Type
foreign import data Signal :: Type -> Type
foreign import data SubRes :: Type -> Type

type SigBuilder a = Reader SigClass (Signal a)


foreign import s_destroy :: forall a. Signal a -> Effect Unit
foreign import s_subRes :: forall a. SubRes a -> a
foreign import s_unsub :: forall a. SubRes a -> Effect Unit
foreign import s_sub :: forall a b. (a -> Effect b) -> Signal a -> Effect (SubRes b)
foreign import s_inst :: forall a. Signal a -> Effect a
foreign import s_changed :: forall a. Signal a -> Event.Event a
foreign import s_tagWith :: forall a b c. (a -> b -> c) -> Event.Event a -> Signal b -> Event.Event c

foreign import s_fromImpl :: forall a. Event.Event a -> a -> SigClass -> Signal a
foreign import s_fmapImpl :: forall a b. (a -> b) -> Signal a -> SigClass -> Signal b
foreign import s_constImpl :: forall a. a -> SigClass -> Signal a
foreign import s_zipWithImpl :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> SigClass -> Signal c
foreign import s_flattenImpl :: forall a. Signal (Signal a) -> SigClass -> Signal a
foreign import s_dedupImpl :: forall a. (a -> a -> Boolean) -> Signal a -> SigClass -> Signal a

foreign import s_buildImpl :: forall a. (SigClass -> Signal a) -> SigBuild a
foreign import sigBuildToRecordImpl ::
  forall a.
  (Effect Unit -> Signal a -> { destroy :: Effect Unit, signal :: Signal a }) ->
  SigBuild a ->
  Effect { destroy :: Effect Unit, signal :: Signal a }


s_from :: forall a. Event.Event a -> a -> SigBuilder a
s_from e i = ask <#> s_fromImpl e i

s_fmap :: forall a b. (a -> b) -> Signal a -> SigBuilder b
s_fmap f s = ask <#> s_fmapImpl f s

s_const :: forall a. a -> SigBuilder a
s_const v = ask <#> s_constImpl v

s_zipWith :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> SigBuilder c
s_zipWith f a b = ask <#> s_zipWithImpl f a b

s_flatten :: forall a. Signal (Signal a) -> SigBuilder a
s_flatten ss = ask <#> s_flattenImpl ss

s_dedup :: forall a. Eq a => Signal a -> SigBuilder a
s_dedup s = ask <#> s_dedupImpl (==) s


s_build :: forall a. SigBuilder a -> SigBuild a
s_build reader = s_buildImpl $ runReader reader

s_make :: forall a. Event.Event a -> a -> SigBuild a
s_make e i = s_build $ s_from e i

eff_sigBuilder ::
  forall a.
  SigBuilder a ->
  Effect { destroy :: Effect Unit, signal :: Signal a }
eff_sigBuilder = s_build >>> sigBuildToRecordImpl (\destroy signal -> { destroy, signal })
