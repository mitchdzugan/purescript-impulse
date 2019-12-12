module Impulse.Native.DOM
       {-}
       ( test3
       , DOM
       , IDOM
       , DOMState
       , DOMEl
       -- env
       , env
       , getEnv
       , withEnv
       , withAlteredEnv
       , upsertEnv
       -- vdom keys
       , keyed
       -- creating DOM elements
       , createElement
       , createElement_
       , text
       -- signals
       , s_bindDOM
       , s_bindDOM_
       -- putting to use
       , attach
       )
       -}
       where

{-}
import Prelude
import Debug.Trace
import Control.Monad.State.Trans as StateT
import DOM.HTML.Indexed as HTML
import Data.Array as A
import Data.HashMap as HM
import Data.List as L
import Data.Maybe as M
import Data.Symbol (class IsSymbol, SProxy(..))
import Data.Traversable as TRV
import Data.Tuple as T
import Effect (Effect)
import Effect.Class (liftEffect)
import Effect.Console as Console
import Effect.Ref as Ref
import Impulse.Native.DOM.Attrs
import Impulse.Native.FRP as FRP
import Impulse.Native.FRP.Signal as Sig
import Impulse.Util.EffState as EffState
import Prim.Row (class Cons, class Lacks, class Union)
import Record as Record
import Web.Event.Event as WE
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

--------------- TYPES --------------

data IDOMType = CreateElement String String DOMAttrs (Array IDOM)
              | Bind String
              | Stash String String
              | Text String

data IDOM = IDOM IDOMType (M.Maybe String)

-- | private internal DOM state
type DOMState r e = { env :: r
                    , events :: e
                    , m_nextKey :: M.Maybe String
                    , ownerPath :: String
                    , currPath :: String
                    , r_offsByPath :: Ref.Ref (HM.HashMap String (L.List (Effect Unit)))
                    , r_idomByPath :: Ref.Ref (HM.HashMap String (Array IDOM))
                    , r_stashByPath :: Ref.Ref (HM.HashMap String (Array IDOM))
                    , idom :: L.List IDOM
                    , nextBindKey :: Int
                    , requestRerender :: Effect Unit
                    , pushMount :: String -> DOMEl -> Effect Unit
                    , pushRender :: String -> DOMEl -> Effect Unit
                    }

-- | Monad containing DOM actions
-- type DOM r e a = EffState.EffState (DOMState r e) a
type DOM r e a = StateT.StateT (DOMState r e) Effect a

pathStep :: String -> String -> M.Maybe String -> String
pathStep s typeLabel m_key =
  "<" <> typeLabel <> " " <> keyLabel m_key <> "/>" <> s
  where keyLabel M.Nothing = ""
        keyLabel (M.Just key) = "k." <> key <> " "

--------- PRIVATE FUNCTIONS --------

e_mounts :: FRP.Event { path :: String, domEl :: DOMEl }
e_mounts = FRP.mkEvent $ const $ pure $ pure unit

e_renders :: FRP.Event { path :: String, domEl :: DOMEl }
e_renders = FRP.mkEvent $ const $ pure $ pure unit

modify_ :: forall r e. (DOMState r e -> DOMState r e) -> DOM r e Unit
modify_ = StateT.modify_

gets :: forall r e a. (DOMState r e -> a) -> DOM r e a
gets = StateT.gets

get :: forall r e. DOM r e (DOMState r e)
get = StateT.get

put :: forall r e. DOMState r e -> DOM r e Unit
put = StateT.put

runState :: forall r e a. DOM r e a -> DOMState r e -> Effect (T.Tuple a (DOMState r e))
runState = StateT.runStateT

evalState :: forall r e a. DOM r e a -> DOMState r e -> Effect a
evalState = StateT.evalStateT

foreign import data VDOM :: Type
foreign import data DOMEl :: Type

foreign import vdomTag ::
  forall a attrs.
  (a -> M.Maybe a -> a)            -> -- M.fromMaybe
  String                           -> -- path
  (String -> DOMEl -> Effect Unit) -> -- pushMount
  String                           -> -- tag
  { | attrs }                      -> -- attrs
  Array VDOM                       -> -- children
  VDOM
foreign import vdomText :: String -> VDOM
foreign import patch :: String -> Array VDOM -> Effect Unit
foreign import addListener :: forall e. DOMEl -> String -> (e -> Effect Unit) -> Effect (Effect Unit)

toVDOMs :: forall r e. IDOM -> DOM r e (Array VDOM)
toVDOMs (IDOM (CreateElement path tag attrs children) _) = do
  pushMount <- gets _.pushMount
  childrenVDOM <- mkVDOM children
  pure [ vdomTag M.fromMaybe path pushMount tag attrs childrenVDOM ]
toVDOMs (IDOM (Text text) _) = pure [ vdomText text ]
toVDOMs (IDOM (Bind idomLocation) _) = do
  idomByPath <- gets _.r_idomByPath >>= Ref.read >>> liftEffect
  let idom = M.fromMaybe [] $ HM.lookup idomLocation idomByPath
  mkVDOM idom
toVDOMs _ = pure []

mkVDOM :: forall r e. Array IDOM -> DOM r e (Array VDOM)
mkVDOM idom = TRV.for idom toVDOMs <#> A.concat

rootVDOM :: forall r e. DOM r e (Array VDOM)
rootVDOM = mkVDOM [ IDOM (Bind "") M.Nothing ]

getIdomArray :: forall r e. DOM r e (Array IDOM)
getIdomArray = gets _.idom <#> A.fromFoldable <#> A.reverse

attachSignal :: forall r e a b. Sig.Signal a -> String -> (a -> DOM r e b) -> DOM r e (Sig.Signal b)
attachSignal s path f = do
  let e_res = FRP.mkEvent $ const $ pure $ pure unit
  r_isFirst <- liftEffect $ Ref.new true
  idom <- gets _.idom
  ownerPath <- gets _.ownerPath
  currPath <- gets _.currPath
  m_nextKey <- gets _.m_nextKey
  domState <- get
  subRes <- liftEffect $ flip Sig.sub s \v -> do
    flip evalState domState do
      modify_ _ { idom = L.Nil
                , m_nextKey = M.Nothing
                , ownerPath = path
                , currPath = path
                , nextBindKey = 1
                }
      res <- f v
      currIdom <- getIdomArray
      idomByPath <- gets _.r_idomByPath >>= liftEffect <<< Ref.read
      let newIdomByPath = HM.insert path currIdom idomByPath
      gets _.r_idomByPath >>= Ref.write newIdomByPath >>> liftEffect
      unlessM (liftEffect $ Ref.read r_isFirst) do
        requestRerender <- gets _.requestRerender
        liftEffect requestRerender
        liftEffect $ FRP.push res e_res
      liftEffect $ Ref.write false r_isFirst
      pure res
  let el = IDOM (Bind path) m_nextKey
      unsub = Sig.unsub subRes
      resInit = Sig.subRes subRes
  s_res <- liftEffect $ Sig.mkSignal e_res resInit
  let destroyRes = Sig.destroy s_res
      addOffs l = L.Cons destroyRes $ L.Cons unsub l
  offsByPath <- gets _.r_offsByPath >>= Ref.read >>> liftEffect
  let newOffsByPath = HM.alter (\m_l -> M.Just $ M.fromMaybe (addOffs L.Nil) $ m_l <#> addOffs)
                               ownerPath
                               offsByPath
  gets _.r_offsByPath >>= liftEffect <<< Ref.write newOffsByPath
  modify_ _ { idom = L.Cons el idom
            , m_nextKey = M.Nothing
            , currPath = currPath
            , ownerPath = ownerPath
            }
  pure s_res

--------- PUBLIC FUNCTIONS ---------

s_bindDOM :: forall r e a b. Sig.Signal a -> (a -> DOM r e b) -> DOM r e (Sig.Signal b)
s_bindDOM s f = do
  currPath <- gets _.currPath
  m_nextKey <- gets _.m_nextKey
  key <- case m_nextKey of
    M.Just key -> pure key
    M.Nothing -> do
      nextBindKey <- gets _.nextBindKey
      modify_ _ { nextBindKey = nextBindKey + 1 }
      pure $ show nextBindKey
  modify_ _ { m_nextKey = M.Just key }
  attachSignal s (pathStep currPath "Bind" $ M.Just key) f

s_bindDOM_ :: forall r e a b. Sig.Signal a -> (a -> DOM r e b) -> DOM r e Unit
s_bindDOM_ s f = s_bindDOM s f <#> const unit

attach :: forall r a. String -> r -> DOM r {} a -> Effect Unit
attach id localEnv dom = do
  sig <- Sig.const unit
  r_idomByPath <- Ref.new HM.empty
  r_stashByPath <- Ref.new HM.empty
  r_offsByPath <- Ref.new HM.empty
  let pushRender path domEl = FRP.push { path, domEl } e_renders
      pushMount path domEl = FRP.push { path, domEl } e_mounts
      f = \_ -> dom
      e_rerender = FRP.mkEvent $ const $ pure $ pure unit
      requestRerender = FRP.push unit e_rerender
      domState = { env: localEnv
                 , events: {}
                 , m_nextKey: M.Nothing
                 , ownerPath: ""
                 , currPath: ""
                 , r_offsByPath
                 , r_idomByPath
                 , r_stashByPath
                 , idom: L.Nil
                 , requestRerender
                 , nextBindKey: 1
                 , pushRender
                 , pushMount
                 }
      effState = do _ <- attachSignal sig "" f
                    _ <- liftEffect $ flip FRP.consume (FRP.throttle 100 e_rerender) \_ -> do
                      Console.log "Rendering"
                      flip evalState domState do
                        vdom <- rootVDOM
                        liftEffect $ patch id vdom
                    pure unit
  evalState effState domState
  requestRerender

type ElRes a = { res :: a
               , onClick :: FRP.Event DOMEl
               }

createElement :: forall r e a. String -> Attrs -> DOM r e a -> DOM r e (ElRes a)
createElement tag attrs inner = do
  idom <- gets _.idom
  currPath <- gets _.currPath
  m_nextKey <- gets _.m_nextKey
  nextBindKey <- gets _.nextBindKey
  modify_ _ { idom = L.Nil
            , currPath = pathStep currPath tag m_nextKey
            , nextBindKey = 1
            }
  res <- inner
  children <- getIdomArray
  newElPath <- gets _.currPath
  let el = IDOM (CreateElement newElPath tag (mkAttrs attrs) children) m_nextKey
  modify_ _ { idom = L.Cons el idom
            , currPath = currPath
            , m_nextKey = M.Nothing
            , nextBindKey = nextBindKey
            }
  let onClick = e_mounts
                  # FRP.filter (\({ path }) -> newElPath == path)
                  # FRP.fmap _.domEl
                  # FRP.flatMap (\el -> FRP.mkEvent (addListener el "click"))
  pure { res
       , onClick
       }

createElement_ :: forall r e a. String -> Attrs -> DOM r e a -> DOM r e a
createElement_ tag attrs inner = createElement tag attrs inner <#> _.res

text :: forall r e. String -> DOM r e Unit
text s = do
  idom <- gets _.idom
  currPath <- gets _.currPath
  let el = IDOM (Text s) M.Nothing
  modify_ _ { idom = L.Cons el idom }
  pure unit

keyed :: forall r e a. String -> DOM r e a -> DOM r e a
keyed key inner = do
  m_nextKey <- gets _.m_nextKey
  modify_ _ { m_nextKey = M.Just key }
  res <- inner
  modify_ _ { m_nextKey = m_nextKey }
  pure res

env :: forall r e. DOM r e r
env = gets _.env

withAlteredEnv :: forall r1 r2 e a. (r1 -> r2) -> DOM r2 e a -> DOM r1 e a
withAlteredEnv f eff = do
  prevState <- get
  let env = f prevState.env
      initState = prevState { env = env }
  T.Tuple res currState <- liftEffect $ runState eff initState
  put $ currState { env = prevState.env }
  pure res

withEnv :: forall r1 r2 e a. r2 -> DOM r2 e a -> DOM r1 e a
withEnv env = withAlteredEnv (const env)

upsertEnv ::
  forall res a sym rI rSym rO rOSymless c.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym a () rSym =>
  Cons sym a rOSymless rO =>
  Union rSym rI rO =>
  SProxy sym ->
  a ->
  DOM (Record rO) c res ->
  DOM (Record rI) c res
upsertEnv p v = withAlteredEnv (\curr -> Record.union (Record.insert p v {})
                                                      (curr :: (Record rI)))

-- | `let p = (SProxy :: SProxy "test") in getEnv p == env <#> Record.get p`
getEnv ::
  forall c a r1 r2 l.
  IsSymbol l =>
  Cons l a r1 r2 =>
  SProxy l ->
  DOM (Record r2) c a
getEnv proxy = (env :: DOM (Record r2) c (Record r2)) <#> Record.get proxy

-- TYPE TESTING

test2 :: forall r e. DOM r e Unit
test2 = createElement_ "div" anil $ text "Hello World"

test3 :: Effect Unit
test3 = Console.log "lul"

-}

a = 1
