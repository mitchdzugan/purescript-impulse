module Impulse.DOM where

import Prim.Row
import Type.Equality
import Control.Monad ((<#>), (=<<))
import Control.Monad.Reader (Reader, ReaderT(..), runReader)
import Data.Eq
import Data.Symbol (class IsSymbol, SProxy(..))
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Impulse.FRP.Event (Event)
import Impulse.FRP.Signal (Signal)
import Prelude (Unit, bind, pure, unit, ($))
import Prim.Row (class Lacks, class Cons)
import Record as Record

foreign import main :: Effect Unit

foreign import data EventCollector :: Type -> Type

foreign import data DOMClass :: Type -> Type

foreign import data DOMStash :: Type

foreign import data ElRes :: Type -> Type

data StashRes a
  = StashRes a DOMStash

foreign import effImpl :: forall a b. DOMClass a -> Effect b -> b

foreign import grabEventCollectorImpl :: forall a b. DOMClass a -> EventCollector b

foreign import getRawEnvImpl :: forall a. DOMClass a -> a

foreign import keyedImpl :: forall a b c. (DOMClass a -> c -> b) -> DOMClass a -> String -> c -> b

foreign import collectImpl :: forall a b. DOMClass a -> (a -> EventCollector b) -> Event b -> Unit

foreign import bindSignalImpl :: forall a b c d. (DOMClass a -> d -> c) -> DOMClass a -> Boolean -> Signal b -> (b -> d) -> Signal c

foreign import flattenSignalImpl :: forall a b. DOMClass a -> Signal (Signal b) -> Signal b

foreign import dedupSignalImpl :: forall a b. DOMClass a -> (b -> b -> Boolean) -> Signal b -> Signal b

foreign import reduceEventImpl :: forall a b c. DOMClass a -> Event b -> (c -> b -> c) -> c -> Signal c

foreign import trapImpl :: forall a b c d e. (DOMClass b -> e -> d) -> DOMClass a -> (a -> b) -> (b -> EventCollector c) -> (Event c -> e) -> d

foreign import createElementImpl :: forall a b c attr. (DOMClass a -> c -> b) -> DOMClass a -> String -> { | attr } -> c -> ElRes b

foreign import textImpl :: forall a. DOMClass a -> String -> Unit

foreign import stashDOMImpl :: forall a b c. (DOMClass a -> c -> b) -> (b -> DOMStash -> StashRes b) -> DOMClass a -> c -> StashRes b

foreign import renderStashedDOMImpl :: forall a b. DOMClass a -> StashRes b -> Unit

foreign import withRawEnvImpl :: forall a b c d. (DOMClass b -> d -> c) -> DOMClass a -> b -> d -> c

foreign import preemptEventImpl :: forall a b c d. (DOMClass a -> c -> b) -> DOMClass a -> (b -> Event d) -> (Event d -> c) -> b

foreign import attachImpl :: forall a b c. (DOMClass a -> b -> c) -> String -> b -> a -> Effect c

type DOM env collecting
  = Reader (DOMClass (Tuple env collecting))

runDOM :: forall e c a. DOMClass (Tuple e c) -> DOM e c a -> a
runDOM domClass dom = runReader dom domClass

attach :: forall env a. String -> env -> DOM env {} a -> Effect a
attach id env dom = attachImpl runDOM id dom $ Tuple env {}

eff :: forall e c a. Effect a -> DOM e c a
eff effect = ReaderT (\r -> pure $ effImpl r effect)

keyed :: forall e c a. String -> DOM e c a -> DOM e c a
keyed s inner = ReaderT (\r -> pure $ keyedImpl runDOM r s inner)

grabEventCollector :: forall e c a. DOM e c (EventCollector a)
grabEventCollector = ReaderT (\r -> pure $ grabEventCollectorImpl r)

env :: forall e c. DOM e c e
env = ReaderT (\r -> pure $ fst $ getRawEnvImpl r)

emitRecordless :: forall e c a. (c -> EventCollector a) -> Event a -> DOM e c Unit
emitRecordless getColl event = ReaderT (\r -> pure $ collectImpl r (\rawEnv -> getColl $ snd rawEnv) event)

s_bindDOM :: forall e c a b. Signal a -> (a -> DOM e c b) -> DOM e c (Signal b)
s_bindDOM signal inner = ReaderT (\r -> pure $ bindSignalImpl runDOM r false signal inner)

s_flatten :: forall e c a. Signal (Signal a) -> DOM e c (Signal a)
s_flatten ss = ReaderT (\r -> pure $ flattenSignalImpl r ss)

s_dedup :: forall e c a. (Eq a) => Signal a -> DOM e c (Signal a)
s_dedup s = ReaderT (\r -> pure $ dedupSignalImpl r (\a b -> a == b) s)

e_reduce :: forall e c a b. Event a -> (b -> a -> b) -> b -> DOM e c (Signal b)
e_reduce event reducer init = ReaderT (\r -> pure $ reduceEventImpl r event reducer init)

listenRecordless :: forall e c1 c2 a b. (c1 -> c2) -> (c2 -> EventCollector a) -> (Event a -> DOM e c2 b) -> DOM e c1 b
listenRecordless modColls getColl inner = ReaderT (\r -> pure $ trapImpl runDOM r (\rawEnv -> Tuple (fst rawEnv) (modColls (snd rawEnv))) (\rawEnv -> getColl $ snd rawEnv) inner)

createElement :: forall e c a attrs. String -> { | attrs } -> DOM e c a -> DOM e c (ElRes a)
createElement tag attrs inner = ReaderT (\r -> pure $ createElementImpl runDOM r tag attrs inner)

text :: forall e c. String -> DOM e c Unit
text s = ReaderT (\r -> pure $ textImpl r s)

stashDOM :: forall e c a. DOM e c a -> DOM e c (StashRes a)
stashDOM inner = ReaderT (\r -> pure $ stashDOMImpl runDOM StashRes r inner)

renderStashedDOM :: forall e c a. StashRes a -> DOM e c Unit
renderStashedDOM stash = ReaderT (\r -> pure $ renderStashedDOMImpl r stash)

withEnv :: forall e1 e2 c a. e2 -> DOM e2 c a -> DOM e1 c a
withEnv env inner = do
  Tuple _ c <- ReaderT (\r -> pure $ getRawEnvImpl r)
  ReaderT (\r -> pure $ withRawEnvImpl runDOM r (Tuple env c) inner)

e_preempt :: forall e c a b. (b -> Event a) -> (Event a -> DOM e c b) -> DOM e c b
e_preempt resToE innerF = ReaderT (\r -> pure $ preemptEventImpl runDOM r resToE innerF)

e_preempt' :: forall e c a b. (b -> Event a) -> (Event a -> DOM e c b) -> DOM e c Unit
e_preempt' resToE innerF = do
  _ <- e_preempt resToE innerF
  pure unit

attach' :: forall env a. String -> env -> DOM env {} a -> Effect Unit
attach' id env dom = do
  _ <- attach id env dom
  pure unit

s_bindDOM' :: forall e c a b. Signal a -> (a -> DOM e c b) -> DOM e c Unit
s_bindDOM' signal inner = do
  _ <- s_bindDOM signal inner
  pure unit

s_bind :: forall e c a b. Signal a -> (a -> b) -> DOM e c (Signal b)
s_bind signal inner = ReaderT (\r -> pure $ bindSignalImpl runDOM r true signal \v -> pure $ inner v)

s_bindAndFlatten :: forall e c a b. Signal a -> (a -> DOM e c (Signal b)) -> DOM e c (Signal b)
s_bindAndFlatten signal inner = s_flatten =<< s_bindDOM signal inner

withEnv' :: forall e1 e2 c a. e2 -> DOM e2 c a -> DOM e1 c Unit
withEnv' env inner = do
  _ <- withEnv env inner
  pure unit

withAlteredEnv :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c a
withAlteredEnv envF inner = do
  curr <- env
  withEnv (envF curr) inner

withAlteredEnv' :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c Unit
withAlteredEnv' envF inner = do
  _ <- withAlteredEnv envF inner
  pure unit

listen ::
  forall res a sym e cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (EventCollector a) () cSym =>
  Cons sym (EventCollector a) cOSymless cO =>
  Union cSym cI cO =>
  SProxy sym ->
  (Event a -> DOM e (Record cO) res) ->
  DOM e (Record cI) res
listen proxy inner = do
  coll <- grabEventCollector
  listenRecordless (Record.union (Record.insert proxy coll {})) (\(r :: Record cO) -> Record.get proxy r) inner

listen' ::
  forall e res a sym cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (EventCollector a) () cSym =>
  Cons sym (EventCollector a) cOSymless cO =>
  Union cSym cI cO =>
  SProxy sym ->
  (Event a -> DOM e (Record cO) res) ->
  DOM e (Record cI) Unit
listen' proxy inner = do
  _ <- listen proxy inner
  pure unit

emit ::
  forall e a r1 r2 l.
  IsSymbol l =>
  Cons l (EventCollector a) r1 r2 =>
  SProxy l ->
  Event a ->
  DOM e (Record r2) Unit
emit proxy event = emitRecordless (\r -> Record.get proxy r) event

upsertEnv ::
  forall res a sym eI eSym eO eOSymless c.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym a () eSym =>
  Cons sym a eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  a ->
  DOM { | eO } c res ->
  DOM { | eI } c res
upsertEnv p v inner = withAlteredEnv (Record.union (Record.insert p v {})) inner

upsertEnv' ::
  forall res a sym eI eSym eO eOSymless c.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym a () eSym =>
  Cons sym a eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  a ->
  DOM { | eO } c res ->
  DOM { | eI } c Unit
upsertEnv' p v inner = do
  _ <- upsertEnv p v inner
  pure unit

listenAndReduce ::
  forall res a b sym eI eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (EventCollector a) () cSym =>
  Cons sym (EventCollector a) cOSymless cO =>
  Union cSym cI cO =>
  Cons sym (Signal b) () eSym =>
  Cons sym (Signal b) eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  (b -> a -> b) ->
  b ->
  DOM { | eO } { | cO } res ->
  DOM { | eI } { | cI } res
listenAndReduce proxy reducer init inner = do
  listen proxy inListen
  where
  inListen e = do
    s <- e_reduce e reducer init
    upsertEnv proxy s inner

listenAndReduce' ::
  forall res a b sym eI eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (EventCollector a) () cSym =>
  Cons sym (EventCollector a) cOSymless cO =>
  Union cSym cI cO =>
  Cons sym (Signal b) () eSym =>
  Cons sym (Signal b) eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  (b -> a -> b) ->
  b ->
  DOM { | eO } { | cO } res ->
  DOM { | eI } { | cI } Unit
listenAndReduce' proxy reducer init inner = do
  _ <- listenAndReduce proxy reducer init inner
  pure unit

getEnv ::
  forall c a r1 r2 l.
  IsSymbol l =>
  Cons l a r1 r2 =>
  SProxy l ->
  DOM (Record r2) c a
getEnv proxy = do
  curr <- env
  pure $ Record.get proxy curr

foreign import innerRes :: forall a. ElRes a -> a

foreign import onClick :: forall a b c. ElRes a -> Event { target :: { value :: String | c } | b }

foreign import onChange :: forall a b c. ElRes a -> Event { target :: { value :: String | c } | b }

foreign import onKeyUp :: forall a b c. ElRes a -> Event { target :: { value :: String | c } | b }
