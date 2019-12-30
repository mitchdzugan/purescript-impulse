module Impulse.FRP.Event
       ( Event(..)
       , mkEvent
       , push
       , consume
       , rebuildBy
       , fmap
       , filter
       , reduce
       , flatMap
       , join
       , timer
       , dedup
       , tagWith
       , tagWithSkipPreR
       , never
       , debounce
       , throttle
       ) where

import Prelude
import Control.Apply
import Control.Bind
import Data.Maybe as M
import Effect (Effect)
import Impulse.FRP.Impl as FRPImpl

foreign import data Event :: Type -> Type

foreign import mkEvent_raw :: forall a. FRPImpl.FRPImpl -> ((a -> Effect Unit) -> Effect (Effect Unit)) -> Event a
mkEvent :: forall a. ((a -> Effect Unit) -> Effect (Effect Unit)) -> Event a
mkEvent = mkEvent_raw FRPImpl.impl

foreign import push_raw :: forall a. FRPImpl.FRPImpl -> a -> Event a -> Effect Unit
push :: forall a. a -> Event a -> Effect Unit
push = push_raw FRPImpl.impl

foreign import consume_raw :: forall a. FRPImpl.FRPImpl -> (a -> Effect Unit) -> Event a -> Effect (Effect Unit)
consume :: forall a. (a -> Effect Unit) -> Event a -> Effect (Effect Unit)
consume = consume_raw FRPImpl.impl

foreign import rebuildBy_raw :: forall a b. FRPImpl.FRPImpl -> (a -> Array b) -> Event a -> Event b
rebuildBy :: forall a b. (a -> Array b) -> Event a -> Event b
rebuildBy = rebuildBy_raw FRPImpl.impl

foreign import fmap_raw :: forall a b. FRPImpl.FRPImpl -> (a -> b) -> Event a -> Event b
fmap :: forall a b. (a -> b) -> Event a -> Event b
fmap = fmap_raw FRPImpl.impl

foreign import filter_raw :: forall a. FRPImpl.FRPImpl -> (a -> Boolean) -> Event a -> Event a
filter :: forall a. (a -> Boolean) -> Event a -> Event a
filter = filter_raw FRPImpl.impl

foreign import reduce_raw :: forall a b. FRPImpl.FRPImpl -> (a -> b -> a) -> a -> Event b -> Event a
reduce :: forall a b. (a -> b -> a) -> a -> Event b -> Event a
reduce = reduce_raw FRPImpl.impl

foreign import flatMap_raw :: forall a b. FRPImpl.FRPImpl -> (a -> Event b) -> Event a -> Event b
flatMap :: forall a b. (a -> Event b) -> Event a -> Event b
flatMap = flatMap_raw FRPImpl.impl

foreign import join_raw :: forall a. FRPImpl.FRPImpl -> Array (Event a) -> Event a
join :: forall a. Array (Event a) -> Event a
join = join_raw FRPImpl.impl

foreign import timer_raw :: FRPImpl.FRPImpl -> Int -> Event Int
timer :: Int -> Event Int
timer = timer_raw FRPImpl.impl

foreign import never_raw :: FRPImpl.FRPImpl -> forall a. Event a
never :: forall a. Event a
never = never_raw FRPImpl.impl

foreign import dedupImpl_raw :: forall a. FRPImpl.FRPImpl -> (a -> a -> Boolean) -> Event a -> Event a
dedupImpl :: forall a. (a -> a -> Boolean) -> Event a -> Event a
dedupImpl = dedupImpl_raw FRPImpl.impl

dedup :: forall a. Eq a => Event a -> Event a
dedup = dedupImpl (==)

foreign import preempt_raw :: forall a b. FRPImpl.FRPImpl -> (b -> Event a) -> (Event a -> b) -> b
preempt :: forall a b. (b -> Event a) -> (Event a -> b) -> b
preempt = preempt_raw FRPImpl.impl

foreign import debounce_raw :: forall a. FRPImpl.FRPImpl -> Int -> Event a -> Event a
debounce :: forall a. Int -> Event a -> Event a
debounce = debounce_raw FRPImpl.impl

foreign import throttle_raw :: forall a. FRPImpl.FRPImpl -> Int -> Event a -> Event a
throttle :: forall a. Int -> Event a -> Event a
throttle = throttle_raw FRPImpl.impl

foreign import deferOff_raw :: forall a. FRPImpl.FRPImpl -> Int -> Event a -> Event a
deferOff :: forall a. Int -> Event a -> Event a
deferOff = deferOff_raw FRPImpl.impl

foreign import tagWith_raw :: forall a b c. FRPImpl.FRPImpl -> (a -> b -> c) -> Event a -> Event b -> c -> Event c
tagWith :: forall a b c. (a -> b -> c) -> Event a -> Event b -> c -> Event c
tagWith = tagWith_raw FRPImpl.impl

tagWithSkipPreR :: forall l r c. (l -> r -> c) -> Event l -> Event r -> Event c
tagWithSkipPreR f eL eR = tagWith (\l r -> M.Just $ f l r) eL eR M.Nothing
                        # rebuildBy (\m_c -> M.fromMaybe [] $ m_c <#> \c -> [c])

instance functorEvent :: Functor Event where
  map = fmap

instance applyEvent :: Apply Event where
  apply = tagWithSkipPreR ($)

instance bindEvent :: Bind Event where
  bind = flip flatMap
