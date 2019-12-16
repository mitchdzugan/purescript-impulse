module Impulse.Util.Foldable
       ( reduceM
       , forM_
       , forMi_
       ) where

import Prelude
import Control.Monad.Rec.Class
import Data.Array as A
import Data.Foldable as F
import Data.List as L

reduceM_a :: forall m a b. MonadRec m => (b -> a -> m b) -> b -> Array a -> m b
reduceM_a f i a = do
  tailRecM go { acc: i, l: L.fromFoldable a } >>= pure <<< _.acc
  where goRaw acc L.Nil = pure $ Done { acc, l: L.Nil }
        goRaw acc (L.Cons el l) = do
          newAcc <- f acc el
          pure $ Loop { acc: newAcc, l }
        go { acc, l } = goRaw acc l

forM__a :: forall a m. MonadRec m => Array a -> (a -> m Unit) -> m Unit
forM__a a f = reduceM_a (const f) unit a

forMi__a :: forall a m. MonadRec m => Array a -> (Int -> a -> m Unit) -> m Unit
forMi__a a f = flip forM__a (\({ i, v }) -> f i v) $ A.mapWithIndex (\i v -> { i, v }) a

reduceM :: forall m a b f. MonadRec m => F.Foldable f => (b -> a -> m b) -> b -> f a -> m b
reduceM f i = A.fromFoldable >>> reduceM_a f i

forM_ :: forall a m f. MonadRec m => F.Foldable f => f a -> (a -> m Unit) -> m Unit
forM_ fldbl fun = forM__a (A.fromFoldable fldbl) fun

forMi_ :: forall a m f. MonadRec m => F.Foldable f => f a -> (Int -> a -> m Unit) -> m Unit
forMi_ fldbl fun = forMi__a (A.fromFoldable fldbl) fun
