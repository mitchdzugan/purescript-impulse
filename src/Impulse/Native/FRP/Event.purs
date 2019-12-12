module Impulse.Native.FRP.Event
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

foreign import data Event :: Type -> Type

foreign import mkEvent :: forall a. ((a -> Effect Unit) -> Effect (Effect Unit)) -> Event a

foreign import push :: forall a. a -> Event a -> Effect Unit

foreign import consume :: forall a. (a -> Effect Unit) -> Event a -> Effect (Effect Unit)

foreign import rebuildBy :: forall a b. (a -> Array b) -> Event a -> Event b

foreign import fmap :: forall a b. (a -> b) -> Event a -> Event b

foreign import filter :: forall a. (a -> Boolean) -> Event a -> Event a

foreign import reduce :: forall a b. (a -> b -> a) -> a -> Event b -> Event a

foreign import flatMap :: forall a b. (a -> Event b) -> Event a -> Event b

foreign import join :: forall a. Array (Event a) -> Event a

foreign import timer :: Int -> Event Int

foreign import never :: forall a. Event a

foreign import dedupImpl :: forall a. (a -> a -> Boolean) -> Event a -> Event a

dedup :: forall a. Eq a => Event a -> Event a
dedup = dedupImpl (==)

foreign import preempt :: forall a b. (b -> Event a) -> (Event a -> b) -> b

foreign import debounce :: forall a. Int -> Event a -> Event a

foreign import throttle :: forall a. Int -> Event a -> Event a

foreign import tagWith :: forall a b c. (a -> b -> c) -> Event a -> Event b -> c -> Event c

tagWithSkipPreR :: forall l r c. (l -> r -> c) -> Event l -> Event r -> Event c
tagWithSkipPreR f eL eR = tagWith (\l r -> M.Just $ f l r) eL eR M.Nothing
                        # rebuildBy (\m_c -> M.fromMaybe [] $ m_c <#> \c -> [c])

instance functorEvent :: Functor Event where
  map = fmap

instance applyEvent :: Apply Event where
  apply = tagWithSkipPreR ($)

instance bindEvent :: Bind Event where
  bind = flip flatMap
