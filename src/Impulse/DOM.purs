module Impulse.DOM where

import Prelude
import Prim.Row (class Cons, class Lacks, class Union)
import Control.Monad.Reader (Reader, ReaderT(..), runReader)
import Data.Maybe as M
import Data.Symbol (class IsSymbol, SProxy)
import Data.Hashable as H
import Data.Eq as Eq
import Data.Tuple (Tuple(..), fst, snd)
import Effect (Effect)
import Impulse.DOM.Attrs (Attrs, DOMAttrs, mkAttrs)
import Impulse.FRP.Event (Event, makeFrom)
import Impulse.FRP.Signal (Signal, val)
import Record as Record
import Web.UIEvent.MouseEvent as ME
import Web.UIEvent.KeyboardEvent as KE
import Web.Event.Event as WE
import DOM.HTML.Indexed as HTML

foreign import data EventCollector :: Type -> Type

foreign import data DOMClass :: Type -> Type

foreign import data ElRes :: Type -> Type

foreign import data DOMStash :: Type -> Type

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

foreign import createElementImpl :: forall a b c d. (DOMClass a -> c -> b) -> (d -> M.Maybe d -> d) -> DOMClass a -> String -> DOMAttrs -> c -> ElRes b

foreign import textImpl :: forall a. DOMClass a -> String -> Unit

foreign import withRawEnvImpl :: forall a b c d. (DOMClass b -> d -> c) -> DOMClass a -> b -> d -> c

foreign import preemptEventImpl :: forall a b c d. (DOMClass a -> c -> b) -> DOMClass a -> (b -> Event d) -> (Event d -> c) -> b

foreign import attachImpl :: forall a b c. (DOMClass a -> b -> c) -> String -> b -> a -> Effect c

foreign import toMarkupImpl :: forall a b c. (DOMClass a -> b -> c) -> b -> a -> Effect String

foreign import stashDOMImpl :: forall a b c. (DOMClass a -> c -> b) -> DOMClass a -> c -> DOMStash b

foreign import memoImpl :: forall a b c d. H.Hashable d => Eq.Eq d => (d -> d -> Boolean) -> (d -> Int) -> (DOMClass a -> c -> b) -> DOMClass a -> d -> c -> b

foreign import applyDOMImpl :: forall a b. DOMClass a -> DOMStash b -> b

type DOM env collecting
  = Reader (DOMClass (Tuple env collecting))

foreign import reduceSignalImpl ::
  forall e c x y z.
  (z -> DOM e c z) ->
  (DOMClass (Tuple e c) -> y -> z) ->
  DOMClass (Tuple e c) ->
  Signal x ->
  (z -> x -> z) ->
  z ->
  Signal z

s_reduce :: forall e c x y. Signal x -> (y -> x -> y) -> y -> DOM e c (Signal y)
s_reduce s reducer i = ReaderT (\r -> pure $ reduceSignalImpl pure runDOM r s reducer i)

runDOM :: forall e c a. DOMClass (Tuple e c) -> DOM e c a -> a
runDOM domClass dom = runReader dom domClass

d_memo :: forall e c a b. H.Hashable a => Eq.Eq a => a -> DOM e c b -> DOM e c b
d_memo k inner = ReaderT (\r -> pure $ memoImpl (==) (H.hash) runDOM r k inner)

stashDOM :: forall e c a. DOM e c a -> DOM e c (DOMStash a)
stashDOM inner = ReaderT (\r -> pure $ stashDOMImpl runDOM r inner)

stashDOM_ :: forall e c a. DOM e c a -> DOM e c (DOMStash Unit)
stashDOM_ inner = stashDOM $ inner <#> const unit

applyDOM :: forall e c a. DOMStash a -> DOM e c a
applyDOM stash = ReaderT (\r -> pure $ applyDOMImpl r stash)

applyDOM_ :: forall e c a. DOMStash a -> DOM e c Unit
applyDOM_ stash = applyDOM stash <#> const unit

attach :: forall env a. String -> env -> DOM env {} a -> Effect a
attach id localEnv dom = attachImpl runDOM id dom $ Tuple localEnv {}

toMarkup :: forall env a. env -> DOM env {} a -> Effect String
toMarkup localEnv dom = toMarkupImpl runDOM dom $ Tuple localEnv {}

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

createElement :: forall e c a. String -> Attrs Unit -> DOM e c a -> DOM e c (ElRes a)
createElement tag attrs inner = ReaderT (\r -> pure $ createElementImpl runDOM M.fromMaybe r tag (mkAttrs attrs) inner)

createElement_ :: forall e c a. String -> Attrs Unit -> DOM e c a -> DOM e c Unit
createElement_ tag attrs inner = createElement tag attrs inner <#> const unit

text :: forall e c. String -> DOM e c Unit
text s = ReaderT (\r -> pure $ textImpl r s)

dnil :: forall e c. DOM e c Unit
dnil = pure unit

withEnv :: forall e1 e2 c a. e2 -> DOM e2 c a -> DOM e1 c a
withEnv localEnv inner = do
  Tuple _ c <- ReaderT (\r -> pure $ getRawEnvImpl r)
  ReaderT (\r -> pure $ withRawEnvImpl runDOM r (Tuple localEnv c) inner)

e_preempt :: forall e c a b. (b -> Event a) -> (Event a -> DOM e c b) -> DOM e c b
e_preempt resToE innerF = ReaderT (\r -> pure $ preemptEventImpl runDOM r resToE innerF)

e_preempt_ :: forall e c a. (Event a -> DOM e c (Event a)) -> DOM e c (Event a)
e_preempt_ innerF = do
  e_preempt identity innerF

s_preempt :: forall e c a b. a -> (b -> Event a) -> (Signal a -> DOM e c b) -> DOM e c b
s_preempt init resToE innerF = do
  e_preempt resToE \e -> do
    s <- e_reduce e (\agg curr -> curr) init
    innerF s

s_preempt_ :: forall e c a. a -> (Signal a -> DOM e c (Event a)) -> DOM e c (Signal a)
s_preempt_ init innerF = do
  e <- s_preempt init identity innerF
  e_reduce e (\agg curr -> curr) init

attach_ :: forall env a. String -> env -> DOM env {} a -> Effect Unit
attach_ id localEnv dom = do
  _ <- attach id localEnv dom
  pure unit

s_bindDOM_ :: forall e c a b. Signal a -> (a -> DOM e c b) -> DOM e c Unit
s_bindDOM_ signal inner = do
  _ <- s_bindDOM signal inner
  pure unit

s_bindKeyedDOM :: forall e c a b. (Show a) => Signal a -> (a -> DOM e c b) -> DOM e c (Signal b)
s_bindKeyedDOM signal inner = do
  s_bindDOM signal \val -> keyed (show val) $ inner val

s_bindKeyedDOM_ :: forall e c a b. (Show a) => Signal a -> (a -> DOM e c b) -> DOM e c Unit
s_bindKeyedDOM_ signal inner = do
  s_bindDOM_ signal \val -> keyed (show val) $ inner val

s_bind :: forall e c a b. Signal a -> (a -> b) -> DOM e c (Signal b)
s_bind signal inner = ReaderT (\r -> pure $ bindSignalImpl runDOM r true signal \v -> pure $ inner v)

s_bindAndFlatten :: forall e c a b. Signal a -> (a -> DOM e c (Signal b)) -> DOM e c (Signal b)
s_bindAndFlatten signal inner = s_flatten =<< s_bindDOM signal inner

withEnv_ :: forall e1 e2 c a. e2 -> DOM e2 c a -> DOM e1 c Unit
withEnv_ localEnv inner = do
  _ <- withEnv localEnv inner
  pure unit

withAlteredEnv :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c a
withAlteredEnv envF inner = do
  curr <- env
  withEnv (envF curr) inner

withAlteredEnv_ :: forall e1 e2 c a. (e1 -> e2) -> DOM e2 c a -> DOM e1 c Unit
withAlteredEnv_ envF inner = do
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

listen_ ::
  forall e res a sym cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (EventCollector a) () cSym =>
  Cons sym (EventCollector a) cOSymless cO =>
  Union cSym cI cO =>
  SProxy sym ->
  (Event a -> DOM e (Record cO) res) ->
  DOM e (Record cI) Unit
listen_ proxy inner = do
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

upsertEnv_ ::
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
upsertEnv_ p v inner = do
  _ <- upsertEnv p v inner
  pure unit

d_readAs ::
  forall sym e e' c a b res.
  IsSymbol sym =>
  Cons sym a e' e =>
  SProxy sym ->
  (a -> b) ->
  Reader b res ->
  DOM { | e } { | c } res
d_readAs sym f r = getEnv sym >>= f >>> runReader r >>> pure

d_read ::
  forall sym e e' c a res.
  IsSymbol sym =>
  Cons sym a e' e =>
  SProxy sym ->
  Reader a res ->
  DOM { | e } { | c } res
d_read sym = d_readAs sym identity

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

listenAndReduce_ ::
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
listenAndReduce_ proxy reducer init inner = do
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

foreign import stashRes :: forall a. DOMStash a -> a

foreign import innerRes :: forall a. ElRes a -> a

foreign import onClick :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onDoubleClick :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseDown :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseEnter :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseLeave :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseMove :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseOut :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseOver :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onMouseUp :: forall a. ElRes a -> Event ME.MouseEvent

foreign import onChange :: forall a. ElRes a -> Event WE.Event

foreign import onTransitionEnd :: forall a. ElRes a -> Event WE.Event

foreign import onScroll :: forall a. ElRes a -> Event WE.Event

foreign import onKeyUp :: forall a. ElRes a -> Event KE.KeyboardEvent

foreign import onKeyDown :: forall a. ElRes a -> Event KE.KeyboardEvent

foreign import onKeyPress :: forall a. ElRes a -> Event KE.KeyboardEvent

class WebEventable e where
  toWebEvent :: e -> WE.Event

instance webEventableMouseEvent :: WebEventable ME.MouseEvent where
  toWebEvent = ME.toEvent

instance webEventableKeyboardEvent :: WebEventable KE.KeyboardEvent where
  toWebEvent = KE.toEvent

instance webEventableWebEvent :: WebEventable WE.Event where
  toWebEvent e = e

withStopPropagation :: forall e. WebEventable e => Event e -> Event e
withStopPropagation e = makeFrom e \v push -> do WE.stopPropagation $ toWebEvent v
                                                 push v

withPreventDefault :: forall e. WebEventable e => Event e -> Event e
withPreventDefault e = makeFrom e \v push -> do WE.preventDefault $ toWebEvent v
                                                push v

foreign import targetImpl ::
  ({ | HTML.HTMLinput } -> M.Maybe { | HTML.HTMLinput }) ->
  M.Maybe { | HTML.HTMLinput } ->
  WE.Event ->
  Effect (M.Maybe { | HTML.HTMLinput })

target :: WE.Event -> Effect (M.Maybe { | HTML.HTMLinput })
target e = targetImpl M.Just M.Nothing e

domEventValue :: forall e. WebEventable e => Event e -> Event (M.Maybe String)
domEventValue e = makeFrom e $ \we push -> do m_target <- target $ toWebEvent we
                                              push $ m_target <#> _.value

s_val :: forall e c a. Signal a -> DOM e c a
s_val = eff <<< val

foreign import stashEqAble :: forall a. DOMStash a -> String

instance eqDOMStash :: (Eq a) => Eq (DOMStash a)
  where eq a b = (stashEqAble a) == (stashEqAble b) && (stashRes a) == (stashRes b) 

foreign import elResEqAble :: forall a. ElRes a -> String

instance eqElRes :: (Eq a) => Eq (ElRes a)
  where eq a b = (elResEqAble a) == (elResEqAble b) && (innerRes a) == (innerRes b)
