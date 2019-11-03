module Impulse.FRP.Signal where

import Prelude
import Effect (Effect)
import Impulse.FRP.Event (Event)

foreign import data Signal :: Type -> Type

data ConsumeRes a
  = ConsumeRes a (Effect Unit)

foreign import makeSignal :: forall a. Event a -> a -> Effect (Signal a)

foreign import makeSignalLazy :: forall a. Event a -> a -> Signal a

foreign import off :: forall a. Signal a -> Effect Unit

foreign import consumeImpl :: forall a b. (b -> Effect Unit -> ConsumeRes b) -> (a -> Effect b) -> Signal a -> Effect (ConsumeRes b)

consume :: forall a b. (a -> Effect b) -> Signal a -> Effect (ConsumeRes b)
consume = consumeImpl ConsumeRes

foreign import val :: forall a. Signal a -> Effect a

foreign import changed :: forall a. Signal a -> Event a

foreign import dedupImpl :: forall a. (a -> a -> Boolean) -> Signal a -> Signal a

foreign import tag :: forall a b. Event a -> Signal b -> Event b

foreign import fmap :: forall a b. (a -> b) -> Signal a -> Signal b

foreign import fmapLazy :: forall a b. (a -> b) -> Signal a -> Signal b

foreign import flatMap :: forall a b. (a -> Signal b) -> Signal a -> Signal b

foreign import flatMapLazy :: forall a b. (a -> Signal b) -> Signal a -> Signal b

foreign import zipWith :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> Signal c

foreign import zipWithLazy :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> Signal c

foreign import ofVal :: forall a. a -> Signal a

dedup :: forall a. Eq a => Signal a -> Signal a
dedup sig = dedupImpl (\v1 v2 -> v1 == v2) sig

