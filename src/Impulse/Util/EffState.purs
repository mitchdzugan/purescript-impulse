module Impulse.Util.EffState where

import Prelude
import Data.Tuple as T
import Effect

type EffState s a = Effect a

foreign import get :: forall s. EffState s s
foreign import put :: forall s. s -> EffState s Unit
foreign import runImpl :: forall a s c. (s -> a -> c) -> s -> EffState s a -> Effect c

modify :: forall s. (s -> s) -> EffState s s
modify f = do
  curr <- get
  let next = f curr
  put next
  pure next

modify_ :: forall s. (s -> s) -> EffState s Unit
modify_ f = modify f <#> const unit

gets :: forall s a. (s -> a) -> EffState s a
gets f = get <#> f

runState :: forall s a. EffState s a -> s -> Effect (T.Tuple a s)
runState eff init = runImpl (flip T.Tuple) init eff

evalState :: forall s a. EffState s a -> s -> Effect a
evalState eff init = runState eff init <#> T.fst

execState :: forall s a. EffState s a -> s -> Effect s
execState eff init = runState eff init <#> T.snd

withState :: forall s a. (s -> s) -> EffState s a -> EffState s a
withState f eff = do
  curr <- get
  put $ f curr
  res <- eff
  put curr
  pure res

mapState :: forall s a b. (T.Tuple a s -> T.Tuple b s) -> EffState s a -> EffState s b
mapState f eff = do
  res <- eff
  curr <- get
  let T.Tuple fres next = f $ T.Tuple res curr
  put next
  pure fres
