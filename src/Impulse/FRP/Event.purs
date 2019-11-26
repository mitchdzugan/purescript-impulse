module Impulse.FRP.Event where

import Prelude
import Effect (Effect)
import Data.Functor

foreign import data Event :: Type -> Type

foreign import makeEvent :: forall a. Effect (Effect Unit) -> Effect (Event a)

foreign import push :: forall a. a -> Event a -> Effect Unit

foreign import consume :: forall a. (a -> Effect Unit) -> Event a -> Effect (Effect Unit)

foreign import fmap :: forall a b. (a -> b) -> Event a -> Event b

foreign import filter :: forall a. (a -> Boolean) -> Event a -> Event a

foreign import reduce :: forall a b. (a -> b -> a) -> a -> Event b -> Event a

foreign import flatMap :: forall a b. (a -> Event b) -> Event a -> Event b

foreign import join :: forall a. Event a -> Event a -> Event a

foreign import adaptEvent :: forall a b. ((a -> Effect Unit) -> Effect b) -> (b -> Effect Unit) -> Effect (Event a)

foreign import timer :: Int -> Event Int

foreign import never :: forall a. Event a

foreign import mapEff ::
  forall a b.
  (a -> (b -> Effect Unit) -> Effect Unit) ->
  Event a ->
  Effect (Event b)

instance functorEvent :: Functor Event where
  map = fmap
