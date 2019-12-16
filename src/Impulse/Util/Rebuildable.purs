module Impulse.Util.Rebuildable where

import Prelude
import Data.Array as A
import Data.Either as E
import Data.Maybe as M
import Impulse.FRP as FRP

rebuildABy :: forall a b. (a -> Array b) -> Array a -> Array b
rebuildABy f a = map f a # A.concat

class Rebuildable f where
  rebuildBy :: forall a b. (a -> Array b) -> f a -> f b

instance rebuildableArray :: Rebuildable Array where rebuildBy = rebuildABy
instance rebuildableEvent :: Rebuildable FRP.Event where rebuildBy = FRP.rebuildBy

arrayOfLeft :: forall a b. E.Either a b -> Array a
arrayOfLeft (E.Left a) = [a]
arrayOfLeft _ = []

arrayOfRight :: forall a b. E.Either a b -> Array b
arrayOfRight (E.Right b) = [b]
arrayOfRight _ = []

arrayOfMaybe :: forall a. M.Maybe a -> Array a
arrayOfMaybe (M.Just a) = [a]
arrayOfMaybe _ = []

lowerBy :: forall f a b. Rebuildable f => (a -> M.Maybe b) -> f a -> f b
lowerBy f = rebuildBy $ arrayOfMaybe <<< f

lower :: forall f a. Rebuildable f => f (M.Maybe a) -> f a
lower = lowerBy identity

partition :: forall f b c. Rebuildable f => f (E.Either b c) -> { left :: f b, right :: f c }
partition = partitionBy identity

partitionBy :: forall f a b c. Rebuildable f => (a -> E.Either b c) -> f a -> { left :: f b, right :: f c }
partitionBy f r = { left: rebuildBy (arrayOfLeft <<< f) r
                  , right: rebuildBy (arrayOfRight <<< f) r
                  }
