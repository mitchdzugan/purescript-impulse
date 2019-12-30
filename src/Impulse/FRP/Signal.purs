module Impulse.FRP.Signal
       ( s_from
       , s_fmap
       , s_const
       , s_zipWith
       , s_flatten
       , s_dedup
       , s_build
       , s_destroy
       , s_subRes
       , s_unsub
       , s_sub
       , s_inst
       , s_changed
       , s_tagWith
       , s_tag
       , s_reduce
       , s_reduce_e
       , s_reduce_s
       , Signal
       , SigClass
       , SigBuild
       , SigBuilder
       , SubRes
       , eff_sigBuilder
       ) where

import Control.Monad.Reader
import Prelude hiding (const)
import Prelude (const) as P
import Data.List as L
import Data.HashMap as HM
import Data.Traversable as TRV
import Effect (Effect)
import Effect.Ref as Ref
import Impulse.FRP.Event as Event
import Impulse.FRP.Impl as FRPImpl

foreign import data SigBuild :: Type -> Type
foreign import data SigClass :: Type
foreign import data Signal :: Type -> Type
foreign import data SubRes :: Type -> Type

type SigBuilder a = Reader SigClass (Signal a)


foreign import s_destroy_raw :: forall a. FRPImpl.FRPImpl -> Signal a -> Effect Unit
s_destroy :: forall a. Signal a -> Effect Unit
s_destroy = s_destroy_raw FRPImpl.impl

foreign import s_subRes_raw :: forall a. FRPImpl.FRPImpl -> SubRes a -> a
s_subRes :: forall a. SubRes a -> a
s_subRes = s_subRes_raw FRPImpl.impl

foreign import s_unsub_raw :: forall a. FRPImpl.FRPImpl -> SubRes a -> Effect Unit
s_unsub :: forall a. SubRes a -> Effect Unit
s_unsub = s_unsub_raw FRPImpl.impl

foreign import s_sub_raw :: forall a b. FRPImpl.FRPImpl -> (a -> Effect b) -> Signal a -> Effect (SubRes b)
s_sub :: forall a b. (a -> Effect b) -> Signal a -> Effect (SubRes b)
s_sub = s_sub_raw FRPImpl.impl

foreign import s_inst_raw :: forall a. FRPImpl.FRPImpl -> Signal a -> Effect a
s_inst :: forall a. Signal a -> Effect a
s_inst = s_inst_raw FRPImpl.impl

foreign import s_changed_raw :: forall a. FRPImpl.FRPImpl -> Signal a -> Event.Event a
s_changed :: forall a. Signal a -> Event.Event a
s_changed = s_changed_raw FRPImpl.impl

foreign import s_tagWith_raw :: forall a b c. FRPImpl.FRPImpl -> (a -> b -> c) -> Event.Event a -> Signal b -> Event.Event c
s_tagWith :: forall a b c. (a -> b -> c) -> Event.Event a -> Signal b -> Event.Event c
s_tagWith = s_tagWith_raw FRPImpl.impl

foreign import s_fromImpl_raw :: forall a. FRPImpl.FRPImpl -> Event.Event a -> a -> SigClass -> Signal a
s_fromImpl :: forall a. Event.Event a -> a -> SigClass -> Signal a
s_fromImpl = s_fromImpl_raw FRPImpl.impl

foreign import s_fmapImpl_raw :: forall a b. FRPImpl.FRPImpl -> (a -> b) -> Signal a -> SigClass -> Signal b
s_fmapImpl :: forall a b. (a -> b) -> Signal a -> SigClass -> Signal b
s_fmapImpl = s_fmapImpl_raw FRPImpl.impl

foreign import s_constImpl_raw :: forall a. FRPImpl.FRPImpl -> a -> SigClass -> Signal a
s_constImpl :: forall a. a -> SigClass -> Signal a
s_constImpl = s_constImpl_raw FRPImpl.impl

foreign import s_zipWithImpl_raw :: forall a b c. FRPImpl.FRPImpl -> (a -> b -> c) -> Signal a -> Signal b -> SigClass -> Signal c
s_zipWithImpl :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> SigClass -> Signal c
s_zipWithImpl = s_zipWithImpl_raw FRPImpl.impl

foreign import s_flattenImpl_raw :: forall a. FRPImpl.FRPImpl -> Signal (Signal a) -> SigClass -> Signal a
s_flattenImpl :: forall a. Signal (Signal a) -> SigClass -> Signal a
s_flattenImpl = s_flattenImpl_raw FRPImpl.impl

foreign import s_dedupImpl_raw :: forall a. FRPImpl.FRPImpl -> (a -> a -> Boolean) -> Signal a -> SigClass -> Signal a
s_dedupImpl :: forall a. (a -> a -> Boolean) -> Signal a -> SigClass -> Signal a
s_dedupImpl = s_dedupImpl_raw FRPImpl.impl

foreign import s_builderInstImpl_raw :: forall a. FRPImpl.FRPImpl -> Signal a -> SigClass -> a
s_builderInstImpl :: forall a. Signal a -> SigClass -> a
s_builderInstImpl = s_builderInstImpl_raw FRPImpl.impl

s_tag :: forall a b. Event.Event a -> Signal b -> Event.Event b
s_tag = s_tagWith (\_ b -> b)

foreign import s_buildImpl_raw :: forall a. FRPImpl.FRPImpl -> (SigClass -> Signal a) -> SigBuild a
s_buildImpl :: forall a. (SigClass -> Signal a) -> SigBuild a
s_buildImpl = s_buildImpl_raw FRPImpl.impl

foreign import sigBuildToRecordImpl_raw ::
  forall a.
  FRPImpl.FRPImpl ->
  (Effect Unit -> Signal a -> { destroy :: Effect Unit, signal :: Signal a }) ->
  SigBuild a ->
  Effect { destroy :: Effect Unit, signal :: Signal a }
sigBuildToRecordImpl ::
  forall a.
  (Effect Unit -> Signal a -> { destroy :: Effect Unit, signal :: Signal a }) ->
  SigBuild a ->
  Effect { destroy :: Effect Unit, signal :: Signal a }
sigBuildToRecordImpl = sigBuildToRecordImpl_raw FRPImpl.impl

s_builderInst :: forall a. Signal a -> Reader SigClass a
s_builderInst s = ask <#> s_builderInstImpl s

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

s_reduce_e :: forall a b. (a -> b -> a) -> a -> Event.Event b -> SigBuilder a
s_reduce_e r i e = s_from (Event.reduce r i e) i

s_reduce_s :: forall a b. (a -> b -> a) -> a -> Signal b -> SigBuilder a
s_reduce_s r pre_i s = do
  i_b <- s_builderInst s
  let i = r pre_i i_b
      e = s_changed s
  s_from (Event.reduce r i e) i

s_reduce :: forall a. (a -> a -> a) -> Signal a -> SigBuilder a
s_reduce r s = do
  i <- s_builderInst s
  let e = s_changed s
  s_from (Event.reduce r i e) i

s_build :: forall a. SigBuilder a -> SigBuild a
s_build reader = s_buildImpl $ runReader reader

eff_sigBuilder ::
  forall a.
  SigBuilder a ->
  Effect { destroy :: Effect Unit, signal :: Signal a }
eff_sigBuilder = s_build >>> sigBuildToRecordImpl (\destroy signal -> { destroy, signal })
