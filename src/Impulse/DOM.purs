module Impulse.DOM where

import Prim.Row
import Type.Equality
import Control.Monad ((<#>))
import Control.Monad.Reader (Reader, ReaderT(..), runReader)
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

foreign import keyedImpl :: forall a. DOMClass a -> String -> Unit

foreign import collectImpl :: forall a b. DOMClass a -> (a -> EventCollector b) -> Event b -> Unit

foreign import bindSignalImpl :: forall a b c d. (DOMClass a -> d -> c) -> DOMClass a -> Signal b -> (b -> d) -> Signal c

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

keyed :: forall e c. String -> DOM e c Unit
keyed s = ReaderT (\r -> pure $ keyedImpl r s)

grabEventCollector :: forall e c a. DOM e c (EventCollector a)
grabEventCollector = ReaderT (\r -> pure $ grabEventCollectorImpl r)

env :: forall e c. DOM e c e
env = ReaderT (\r -> pure $ fst $ getRawEnvImpl r)

emitRecordless :: forall e c a. (c -> EventCollector a) -> Event a -> DOM e c Unit
emitRecordless getColl event = ReaderT (\r -> pure $ collectImpl r (\rawEnv -> getColl $ snd rawEnv) event)

bindSignal :: forall e c a b. Signal a -> (a -> DOM e c b) -> DOM e c (Signal b)
bindSignal signal inner = ReaderT (\r -> pure $ bindSignalImpl runDOM r signal inner)

reduceEvent :: forall e c a b. Event a -> (b -> a -> b) -> b -> DOM e c (Signal b)
reduceEvent event reducer init = ReaderT (\r -> pure $ reduceEventImpl r event reducer init)

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

preemptEvent :: forall e c a b. (b -> Event a) -> (Event a -> DOM e c b) -> DOM e c b
preemptEvent resToE innerF = ReaderT (\r -> pure $ preemptEventImpl runDOM r resToE innerF)

preemptEvent' :: forall e c a b. (b -> Event a) -> (Event a -> DOM e c b) -> DOM e c Unit
preemptEvent' resToE innerF = do
  _ <- preemptEvent resToE innerF
  pure unit

attach' :: forall env a. String -> env -> DOM env {} a -> Effect Unit
attach' id env dom = do
  _ <- attach id env dom
  pure unit

bindSignal' :: forall e c a b. Signal a -> (a -> DOM e c b) -> DOM e c Unit
bindSignal' signal inner = do
  _ <- bindSignal signal inner
  pure unit

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
    s <- reduceEvent e reducer init
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

-- macro bait
a :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
a attrs inner = createElement "a" attrs inner

a_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
a_ attrs inner = createElement "a" attrs inner <#> innerRes

a' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
a' attrs inner = createElement "a" attrs inner <#> (\_ -> unit)

abbr :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
abbr attrs inner = createElement "abbr" attrs inner

abbr_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
abbr_ attrs inner = createElement "abbr" attrs inner <#> innerRes

abbr' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
abbr' attrs inner = createElement "abbr" attrs inner <#> (\_ -> unit)

acronym :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
acronym attrs inner = createElement "acronym" attrs inner

acronym_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
acronym_ attrs inner = createElement "acronym" attrs inner <#> innerRes

acronym' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
acronym' attrs inner = createElement "acronym" attrs inner <#> (\_ -> unit)

address :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
address attrs inner = createElement "address" attrs inner

address_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
address_ attrs inner = createElement "address" attrs inner <#> innerRes

address' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
address' attrs inner = createElement "address" attrs inner <#> (\_ -> unit)

applet :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
applet attrs inner = createElement "applet" attrs inner

applet_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
applet_ attrs inner = createElement "applet" attrs inner <#> innerRes

applet' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
applet' attrs inner = createElement "applet" attrs inner <#> (\_ -> unit)

area :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
area attrs inner = createElement "area" attrs inner

area_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
area_ attrs inner = createElement "area" attrs inner <#> innerRes

area' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
area' attrs inner = createElement "area" attrs inner <#> (\_ -> unit)

article :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
article attrs inner = createElement "article" attrs inner

article_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
article_ attrs inner = createElement "article" attrs inner <#> innerRes

article' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
article' attrs inner = createElement "article" attrs inner <#> (\_ -> unit)

aside :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
aside attrs inner = createElement "aside" attrs inner

aside_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
aside_ attrs inner = createElement "aside" attrs inner <#> innerRes

aside' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
aside' attrs inner = createElement "aside" attrs inner <#> (\_ -> unit)

audio :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
audio attrs inner = createElement "audio" attrs inner

audio_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
audio_ attrs inner = createElement "audio" attrs inner <#> innerRes

audio' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
audio' attrs inner = createElement "audio" attrs inner <#> (\_ -> unit)

b :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
b attrs inner = createElement "b" attrs inner

b_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
b_ attrs inner = createElement "b" attrs inner <#> innerRes

b' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
b' attrs inner = createElement "b" attrs inner <#> (\_ -> unit)

base :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
base attrs inner = createElement "base" attrs inner

base_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
base_ attrs inner = createElement "base" attrs inner <#> innerRes

base' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
base' attrs inner = createElement "base" attrs inner <#> (\_ -> unit)

basefont :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
basefont attrs inner = createElement "basefont" attrs inner

basefont_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
basefont_ attrs inner = createElement "basefont" attrs inner <#> innerRes

basefont' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
basefont' attrs inner = createElement "basefont" attrs inner <#> (\_ -> unit)

bdo :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
bdo attrs inner = createElement "bdo" attrs inner

bdo_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
bdo_ attrs inner = createElement "bdo" attrs inner <#> innerRes

bdo' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
bdo' attrs inner = createElement "bdo" attrs inner <#> (\_ -> unit)

big :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
big attrs inner = createElement "big" attrs inner

big_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
big_ attrs inner = createElement "big" attrs inner <#> innerRes

big' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
big' attrs inner = createElement "big" attrs inner <#> (\_ -> unit)

blockquote :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
blockquote attrs inner = createElement "blockquote" attrs inner

blockquote_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
blockquote_ attrs inner = createElement "blockquote" attrs inner <#> innerRes

blockquote' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
blockquote' attrs inner = createElement "blockquote" attrs inner <#> (\_ -> unit)

body :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
body attrs inner = createElement "body" attrs inner

body_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
body_ attrs inner = createElement "body" attrs inner <#> innerRes

body' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
body' attrs inner = createElement "body" attrs inner <#> (\_ -> unit)

br :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
br attrs inner = createElement "br" attrs inner

br_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
br_ attrs inner = createElement "br" attrs inner <#> innerRes

br' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
br' attrs inner = createElement "br" attrs inner <#> (\_ -> unit)

button :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
button attrs inner = createElement "button" attrs inner

button_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
button_ attrs inner = createElement "button" attrs inner <#> innerRes

button' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
button' attrs inner = createElement "button" attrs inner <#> (\_ -> unit)

canvas :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
canvas attrs inner = createElement "canvas" attrs inner

canvas_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
canvas_ attrs inner = createElement "canvas" attrs inner <#> innerRes

canvas' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
canvas' attrs inner = createElement "canvas" attrs inner <#> (\_ -> unit)

caption :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
caption attrs inner = createElement "caption" attrs inner

caption_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
caption_ attrs inner = createElement "caption" attrs inner <#> innerRes

caption' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
caption' attrs inner = createElement "caption" attrs inner <#> (\_ -> unit)

center :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
center attrs inner = createElement "center" attrs inner

center_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
center_ attrs inner = createElement "center" attrs inner <#> innerRes

center' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
center' attrs inner = createElement "center" attrs inner <#> (\_ -> unit)

cite :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
cite attrs inner = createElement "cite" attrs inner

cite_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
cite_ attrs inner = createElement "cite" attrs inner <#> innerRes

cite' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
cite' attrs inner = createElement "cite" attrs inner <#> (\_ -> unit)

code :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
code attrs inner = createElement "code" attrs inner

code_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
code_ attrs inner = createElement "code" attrs inner <#> innerRes

code' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
code' attrs inner = createElement "code" attrs inner <#> (\_ -> unit)

col :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
col attrs inner = createElement "col" attrs inner

col_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
col_ attrs inner = createElement "col" attrs inner <#> innerRes

col' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
col' attrs inner = createElement "col" attrs inner <#> (\_ -> unit)

colgroup :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
colgroup attrs inner = createElement "colgroup" attrs inner

colgroup_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
colgroup_ attrs inner = createElement "colgroup" attrs inner <#> innerRes

colgroup' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
colgroup' attrs inner = createElement "colgroup" attrs inner <#> (\_ -> unit)

datalist :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
datalist attrs inner = createElement "datalist" attrs inner

datalist_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
datalist_ attrs inner = createElement "datalist" attrs inner <#> innerRes

datalist' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
datalist' attrs inner = createElement "datalist" attrs inner <#> (\_ -> unit)

dd :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
dd attrs inner = createElement "dd" attrs inner

dd_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
dd_ attrs inner = createElement "dd" attrs inner <#> innerRes

dd' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
dd' attrs inner = createElement "dd" attrs inner <#> (\_ -> unit)

del :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
del attrs inner = createElement "del" attrs inner

del_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
del_ attrs inner = createElement "del" attrs inner <#> innerRes

del' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
del' attrs inner = createElement "del" attrs inner <#> (\_ -> unit)

dfn :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
dfn attrs inner = createElement "dfn" attrs inner

dfn_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
dfn_ attrs inner = createElement "dfn" attrs inner <#> innerRes

dfn' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
dfn' attrs inner = createElement "dfn" attrs inner <#> (\_ -> unit)

div :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
div attrs inner = createElement "div" attrs inner

div_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
div_ attrs inner = createElement "div" attrs inner <#> innerRes

div' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
div' attrs inner = createElement "div" attrs inner <#> (\_ -> unit)

dl :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
dl attrs inner = createElement "dl" attrs inner

dl_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
dl_ attrs inner = createElement "dl" attrs inner <#> innerRes

dl' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
dl' attrs inner = createElement "dl" attrs inner <#> (\_ -> unit)

dt :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
dt attrs inner = createElement "dt" attrs inner

dt_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
dt_ attrs inner = createElement "dt" attrs inner <#> innerRes

dt' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
dt' attrs inner = createElement "dt" attrs inner <#> (\_ -> unit)

em :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
em attrs inner = createElement "em" attrs inner

em_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
em_ attrs inner = createElement "em" attrs inner <#> innerRes

em' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
em' attrs inner = createElement "em" attrs inner <#> (\_ -> unit)

embed :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
embed attrs inner = createElement "embed" attrs inner

embed_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
embed_ attrs inner = createElement "embed" attrs inner <#> innerRes

embed' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
embed' attrs inner = createElement "embed" attrs inner <#> (\_ -> unit)

fieldset :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
fieldset attrs inner = createElement "fieldset" attrs inner

fieldset_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
fieldset_ attrs inner = createElement "fieldset" attrs inner <#> innerRes

fieldset' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
fieldset' attrs inner = createElement "fieldset" attrs inner <#> (\_ -> unit)

figcaption :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
figcaption attrs inner = createElement "figcaption" attrs inner

figcaption_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
figcaption_ attrs inner = createElement "figcaption" attrs inner <#> innerRes

figcaption' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
figcaption' attrs inner = createElement "figcaption" attrs inner <#> (\_ -> unit)

figure :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
figure attrs inner = createElement "figure" attrs inner

figure_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
figure_ attrs inner = createElement "figure" attrs inner <#> innerRes

figure' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
figure' attrs inner = createElement "figure" attrs inner <#> (\_ -> unit)

font :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
font attrs inner = createElement "font" attrs inner

font_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
font_ attrs inner = createElement "font" attrs inner <#> innerRes

font' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
font' attrs inner = createElement "font" attrs inner <#> (\_ -> unit)

footer :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
footer attrs inner = createElement "footer" attrs inner

footer_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
footer_ attrs inner = createElement "footer" attrs inner <#> innerRes

footer' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
footer' attrs inner = createElement "footer" attrs inner <#> (\_ -> unit)

form :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
form attrs inner = createElement "form" attrs inner

form_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
form_ attrs inner = createElement "form" attrs inner <#> innerRes

form' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
form' attrs inner = createElement "form" attrs inner <#> (\_ -> unit)

frame :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
frame attrs inner = createElement "frame" attrs inner

frame_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
frame_ attrs inner = createElement "frame" attrs inner <#> innerRes

frame' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
frame' attrs inner = createElement "frame" attrs inner <#> (\_ -> unit)

frameset :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
frameset attrs inner = createElement "frameset" attrs inner

frameset_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
frameset_ attrs inner = createElement "frameset" attrs inner <#> innerRes

frameset' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
frameset' attrs inner = createElement "frameset" attrs inner <#> (\_ -> unit)

head :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
head attrs inner = createElement "head" attrs inner

head_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
head_ attrs inner = createElement "head" attrs inner <#> innerRes

head' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
head' attrs inner = createElement "head" attrs inner <#> (\_ -> unit)

header :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
header attrs inner = createElement "header" attrs inner

header_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
header_ attrs inner = createElement "header" attrs inner <#> innerRes

header' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
header' attrs inner = createElement "header" attrs inner <#> (\_ -> unit)

h1 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h1 attrs inner = createElement "h1" attrs inner

h1_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h1_ attrs inner = createElement "h1" attrs inner <#> innerRes

h1' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h1' attrs inner = createElement "h1" attrs inner <#> (\_ -> unit)

h2 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h2 attrs inner = createElement "h2" attrs inner

h2_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h2_ attrs inner = createElement "h2" attrs inner <#> innerRes

h2' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h2' attrs inner = createElement "h2" attrs inner <#> (\_ -> unit)

h3 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h3 attrs inner = createElement "h3" attrs inner

h3_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h3_ attrs inner = createElement "h3" attrs inner <#> innerRes

h3' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h3' attrs inner = createElement "h3" attrs inner <#> (\_ -> unit)

h4 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h4 attrs inner = createElement "h4" attrs inner

h4_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h4_ attrs inner = createElement "h4" attrs inner <#> innerRes

h4' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h4' attrs inner = createElement "h4" attrs inner <#> (\_ -> unit)

h5 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h5 attrs inner = createElement "h5" attrs inner

h5_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h5_ attrs inner = createElement "h5" attrs inner <#> innerRes

h5' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h5' attrs inner = createElement "h5" attrs inner <#> (\_ -> unit)

h6 :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
h6 attrs inner = createElement "h6" attrs inner

h6_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
h6_ attrs inner = createElement "h6" attrs inner <#> innerRes

h6' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
h6' attrs inner = createElement "h6" attrs inner <#> (\_ -> unit)

hr :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
hr attrs inner = createElement "hr" attrs inner

hr_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
hr_ attrs inner = createElement "hr" attrs inner <#> innerRes

hr' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
hr' attrs inner = createElement "hr" attrs inner <#> (\_ -> unit)

html :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
html attrs inner = createElement "html" attrs inner

html_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
html_ attrs inner = createElement "html" attrs inner <#> innerRes

html' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
html' attrs inner = createElement "html" attrs inner <#> (\_ -> unit)

i :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
i attrs inner = createElement "i" attrs inner

i_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
i_ attrs inner = createElement "i" attrs inner <#> innerRes

i' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
i' attrs inner = createElement "i" attrs inner <#> (\_ -> unit)

iframe :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
iframe attrs inner = createElement "iframe" attrs inner

iframe_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
iframe_ attrs inner = createElement "iframe" attrs inner <#> innerRes

iframe' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
iframe' attrs inner = createElement "iframe" attrs inner <#> (\_ -> unit)

img :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
img attrs inner = createElement "img" attrs inner

img_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
img_ attrs inner = createElement "img" attrs inner <#> innerRes

img' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
img' attrs inner = createElement "img" attrs inner <#> (\_ -> unit)

input :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
input attrs inner = createElement "input" attrs inner

input_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
input_ attrs inner = createElement "input" attrs inner <#> innerRes

input' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
input' attrs inner = createElement "input" attrs inner <#> (\_ -> unit)

ins :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
ins attrs inner = createElement "ins" attrs inner

ins_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
ins_ attrs inner = createElement "ins" attrs inner <#> innerRes

ins' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
ins' attrs inner = createElement "ins" attrs inner <#> (\_ -> unit)

kbd :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
kbd attrs inner = createElement "kbd" attrs inner

kbd_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
kbd_ attrs inner = createElement "kbd" attrs inner <#> innerRes

kbd' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
kbd' attrs inner = createElement "kbd" attrs inner <#> (\_ -> unit)

label :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
label attrs inner = createElement "label" attrs inner

label_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
label_ attrs inner = createElement "label" attrs inner <#> innerRes

label' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
label' attrs inner = createElement "label" attrs inner <#> (\_ -> unit)

legend :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
legend attrs inner = createElement "legend" attrs inner

legend_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
legend_ attrs inner = createElement "legend" attrs inner <#> innerRes

legend' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
legend' attrs inner = createElement "legend" attrs inner <#> (\_ -> unit)

li :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
li attrs inner = createElement "li" attrs inner

li_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
li_ attrs inner = createElement "li" attrs inner <#> innerRes

li' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
li' attrs inner = createElement "li" attrs inner <#> (\_ -> unit)

link :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
link attrs inner = createElement "link" attrs inner

link_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
link_ attrs inner = createElement "link" attrs inner <#> innerRes

link' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
link' attrs inner = createElement "link" attrs inner <#> (\_ -> unit)

{-}
main :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c (ElRes a)
main attrs inner = createElement "main" attrs inner

main_ :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c a
main_ attrs inner = createElement "main" attrs inner <#> innerRes

main' :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c Unit
main' attrs inner = createElement "main" attrs inner <#> (\_ -> unit)
-}
map :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
map attrs inner = createElement "map" attrs inner

map_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
map_ attrs inner = createElement "map" attrs inner <#> innerRes

map' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
map' attrs inner = createElement "map" attrs inner <#> (\_ -> unit)

mark :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
mark attrs inner = createElement "mark" attrs inner

mark_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
mark_ attrs inner = createElement "mark" attrs inner <#> innerRes

mark' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
mark' attrs inner = createElement "mark" attrs inner <#> (\_ -> unit)

meta :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
meta attrs inner = createElement "meta" attrs inner

meta_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
meta_ attrs inner = createElement "meta" attrs inner <#> innerRes

meta' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
meta' attrs inner = createElement "meta" attrs inner <#> (\_ -> unit)

meter :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
meter attrs inner = createElement "meter" attrs inner

meter_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
meter_ attrs inner = createElement "meter" attrs inner <#> innerRes

meter' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
meter' attrs inner = createElement "meter" attrs inner <#> (\_ -> unit)

nav :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
nav attrs inner = createElement "nav" attrs inner

nav_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
nav_ attrs inner = createElement "nav" attrs inner <#> innerRes

nav' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
nav' attrs inner = createElement "nav" attrs inner <#> (\_ -> unit)

noscript :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
noscript attrs inner = createElement "noscript" attrs inner

noscript_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
noscript_ attrs inner = createElement "noscript" attrs inner <#> innerRes

noscript' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
noscript' attrs inner = createElement "noscript" attrs inner <#> (\_ -> unit)

object :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
object attrs inner = createElement "object" attrs inner

object_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
object_ attrs inner = createElement "object" attrs inner <#> innerRes

object' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
object' attrs inner = createElement "object" attrs inner <#> (\_ -> unit)

ol :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
ol attrs inner = createElement "ol" attrs inner

ol_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
ol_ attrs inner = createElement "ol" attrs inner <#> innerRes

ol' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
ol' attrs inner = createElement "ol" attrs inner <#> (\_ -> unit)

optgroup :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
optgroup attrs inner = createElement "optgroup" attrs inner

optgroup_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
optgroup_ attrs inner = createElement "optgroup" attrs inner <#> innerRes

optgroup' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
optgroup' attrs inner = createElement "optgroup" attrs inner <#> (\_ -> unit)

option :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
option attrs inner = createElement "option" attrs inner

option_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
option_ attrs inner = createElement "option" attrs inner <#> innerRes

option' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
option' attrs inner = createElement "option" attrs inner <#> (\_ -> unit)

p :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
p attrs inner = createElement "p" attrs inner

p_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
p_ attrs inner = createElement "p" attrs inner <#> innerRes

p' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
p' attrs inner = createElement "p" attrs inner <#> (\_ -> unit)

param :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
param attrs inner = createElement "param" attrs inner

param_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
param_ attrs inner = createElement "param" attrs inner <#> innerRes

param' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
param' attrs inner = createElement "param" attrs inner <#> (\_ -> unit)

pre :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
pre attrs inner = createElement "pre" attrs inner

pre_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
pre_ attrs inner = createElement "pre" attrs inner <#> innerRes

pre' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
pre' attrs inner = createElement "pre" attrs inner <#> (\_ -> unit)

progress :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
progress attrs inner = createElement "progress" attrs inner

progress_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
progress_ attrs inner = createElement "progress" attrs inner <#> innerRes

progress' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
progress' attrs inner = createElement "progress" attrs inner <#> (\_ -> unit)

q :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
q attrs inner = createElement "q" attrs inner

q_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
q_ attrs inner = createElement "q" attrs inner <#> innerRes

q' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
q' attrs inner = createElement "q" attrs inner <#> (\_ -> unit)

{-}
s :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c (ElRes a)
s attrs inner = createElement "s" attrs inner

s_ :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c a
s_ attrs inner = createElement "s" attrs inner <#> innerRes

s' :: forall e c a attrs. {| attrs} -> DOM e c a -> DOM e c Unit
s' attrs inner = createElement "s" attrs inner <#> (\_ -> unit)
-}
samp :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
samp attrs inner = createElement "samp" attrs inner

samp_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
samp_ attrs inner = createElement "samp" attrs inner <#> innerRes

samp' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
samp' attrs inner = createElement "samp" attrs inner <#> (\_ -> unit)

script :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
script attrs inner = createElement "script" attrs inner

script_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
script_ attrs inner = createElement "script" attrs inner <#> innerRes

script' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
script' attrs inner = createElement "script" attrs inner <#> (\_ -> unit)

section :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
section attrs inner = createElement "section" attrs inner

section_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
section_ attrs inner = createElement "section" attrs inner <#> innerRes

section' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
section' attrs inner = createElement "section" attrs inner <#> (\_ -> unit)

select :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
select attrs inner = createElement "select" attrs inner

select_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
select_ attrs inner = createElement "select" attrs inner <#> innerRes

select' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
select' attrs inner = createElement "select" attrs inner <#> (\_ -> unit)

small :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
small attrs inner = createElement "small" attrs inner

small_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
small_ attrs inner = createElement "small" attrs inner <#> innerRes

small' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
small' attrs inner = createElement "small" attrs inner <#> (\_ -> unit)

source :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
source attrs inner = createElement "source" attrs inner

source_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
source_ attrs inner = createElement "source" attrs inner <#> innerRes

source' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
source' attrs inner = createElement "source" attrs inner <#> (\_ -> unit)

span :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
span attrs inner = createElement "span" attrs inner

span_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
span_ attrs inner = createElement "span" attrs inner <#> innerRes

span' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
span' attrs inner = createElement "span" attrs inner <#> (\_ -> unit)

strike :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
strike attrs inner = createElement "strike" attrs inner

strike_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
strike_ attrs inner = createElement "strike" attrs inner <#> innerRes

strike' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
strike' attrs inner = createElement "strike" attrs inner <#> (\_ -> unit)

strong :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
strong attrs inner = createElement "strong" attrs inner

strong_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
strong_ attrs inner = createElement "strong" attrs inner <#> innerRes

strong' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
strong' attrs inner = createElement "strong" attrs inner <#> (\_ -> unit)

style :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
style attrs inner = createElement "style" attrs inner

style_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
style_ attrs inner = createElement "style" attrs inner <#> innerRes

style' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
style' attrs inner = createElement "style" attrs inner <#> (\_ -> unit)

sub :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
sub attrs inner = createElement "sub" attrs inner

sub_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
sub_ attrs inner = createElement "sub" attrs inner <#> innerRes

sub' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
sub' attrs inner = createElement "sub" attrs inner <#> (\_ -> unit)

sup :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
sup attrs inner = createElement "sup" attrs inner

sup_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
sup_ attrs inner = createElement "sup" attrs inner <#> innerRes

sup' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
sup' attrs inner = createElement "sup" attrs inner <#> (\_ -> unit)

table :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
table attrs inner = createElement "table" attrs inner

table_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
table_ attrs inner = createElement "table" attrs inner <#> innerRes

table' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
table' attrs inner = createElement "table" attrs inner <#> (\_ -> unit)

tbody :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
tbody attrs inner = createElement "tbody" attrs inner

tbody_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
tbody_ attrs inner = createElement "tbody" attrs inner <#> innerRes

tbody' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
tbody' attrs inner = createElement "tbody" attrs inner <#> (\_ -> unit)

td :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
td attrs inner = createElement "td" attrs inner

td_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
td_ attrs inner = createElement "td" attrs inner <#> innerRes

td' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
td' attrs inner = createElement "td" attrs inner <#> (\_ -> unit)

textarea :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
textarea attrs inner = createElement "textarea" attrs inner

textarea_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
textarea_ attrs inner = createElement "textarea" attrs inner <#> innerRes

textarea' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
textarea' attrs inner = createElement "textarea" attrs inner <#> (\_ -> unit)

tfoot :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
tfoot attrs inner = createElement "tfoot" attrs inner

tfoot_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
tfoot_ attrs inner = createElement "tfoot" attrs inner <#> innerRes

tfoot' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
tfoot' attrs inner = createElement "tfoot" attrs inner <#> (\_ -> unit)

th :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
th attrs inner = createElement "th" attrs inner

th_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
th_ attrs inner = createElement "th" attrs inner <#> innerRes

th' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
th' attrs inner = createElement "th" attrs inner <#> (\_ -> unit)

thead :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
thead attrs inner = createElement "thead" attrs inner

thead_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
thead_ attrs inner = createElement "thead" attrs inner <#> innerRes

thead' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
thead' attrs inner = createElement "thead" attrs inner <#> (\_ -> unit)

time :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
time attrs inner = createElement "time" attrs inner

time_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
time_ attrs inner = createElement "time" attrs inner <#> innerRes

time' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
time' attrs inner = createElement "time" attrs inner <#> (\_ -> unit)

title :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
title attrs inner = createElement "title" attrs inner

title_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
title_ attrs inner = createElement "title" attrs inner <#> innerRes

title' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
title' attrs inner = createElement "title" attrs inner <#> (\_ -> unit)

tr :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
tr attrs inner = createElement "tr" attrs inner

tr_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
tr_ attrs inner = createElement "tr" attrs inner <#> innerRes

tr' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
tr' attrs inner = createElement "tr" attrs inner <#> (\_ -> unit)

u :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
u attrs inner = createElement "u" attrs inner

u_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
u_ attrs inner = createElement "u" attrs inner <#> innerRes

u' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
u' attrs inner = createElement "u" attrs inner <#> (\_ -> unit)

ul :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
ul attrs inner = createElement "ul" attrs inner

ul_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
ul_ attrs inner = createElement "ul" attrs inner <#> innerRes

ul' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
ul' attrs inner = createElement "ul" attrs inner <#> (\_ -> unit)

var :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
var attrs inner = createElement "var" attrs inner

var_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
var_ attrs inner = createElement "var" attrs inner <#> innerRes

var' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
var' attrs inner = createElement "var" attrs inner <#> (\_ -> unit)

video :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
video attrs inner = createElement "video" attrs inner

video_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
video_ attrs inner = createElement "video" attrs inner <#> innerRes

video' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
video' attrs inner = createElement "video" attrs inner <#> (\_ -> unit)

wbr :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c (ElRes a)
wbr attrs inner = createElement "wbr" attrs inner

wbr_ :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c a
wbr_ attrs inner = createElement "wbr" attrs inner <#> innerRes

wbr' :: forall e c a attrs. { | attrs } -> DOM e c a -> DOM e c Unit
wbr' attrs inner = createElement "wbr" attrs inner <#> (\_ -> unit)
 {-
"a","abbr","acronym","address","applet","area","article","aside","audio","b","base","basefont","bdo",
"big","blockquote","body","br","button","canvas","caption","center","cite","code","col","colgroup",
"datalist","dd","del","dfn","div","dl","dt","em","embed","fieldset","figcaption","figure","font",
"footer","form","frame","frameset","head","header","h1 to &lt;h6&gt;","hr","html","i","iframe","img",
"input","ins","kbd","label","legend","li","link","main","map","mark","meta","meter","nav","noscript",
"object","ol","optgroup","option","p","param","pre","progress","q","s","samp","script","section",
"select","small","source","span","strike","strong","style","sub","sup","table","tbody","td",
"textarea","tfoot","th","thead","time","title","tr","u","ul","var","video","wbr"
-}
