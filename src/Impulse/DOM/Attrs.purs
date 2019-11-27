module Impulse.DOM.Attrs where

import Prelude
import Control.Monad.State as S
import Data.List as L
import Data.Maybe as M
import Debug.Trace

type DOMAttrs = { className :: M.Maybe String
                , style :: M.Maybe String
                , id :: M.Maybe String
                , rows :: M.Maybe Int
                , disabled :: M.Maybe Boolean
                , value :: M.Maybe String
                , selected :: M.Maybe String
                }
type Attrs a = S.State DOMAttrs a

anil :: Attrs Unit
anil = pure unit

classNames :: S.State (L.List String) Unit -> Attrs Unit
classNames m = do
  let classes = S.execState m L.Nil
      className = L.foldl (\a b -> a <> " " <> b) "" classes
  S.modify_ _ { className = M.Just className }

styles :: S.State (L.List String) Unit -> Attrs Unit
styles m = do
  let styleList = S.execState m L.Nil
      style = L.foldl (\a b -> b <> "; " <> b) "" styleList
  S.modify_ _ { style = M.Just style }

id :: forall a. Show a => a -> Attrs Unit
id i =
  S.modify_ _ { id = M.Just $ show i }

rows :: forall a. Int -> Attrs Unit
rows n =
  S.modify_ _ { rows = M.Just n }

disabled :: forall a. Boolean -> Attrs Unit
disabled b =
  S.modify_ _ { disabled = M.Just b }

value :: forall a. Show a => a -> Attrs Unit
value v =
  S.modify_ _ { value = M.Just $ show v }

selected :: forall a. Show a => a -> Attrs Unit
selected v =
  S.modify_ _ { selected = M.Just $ show v }

mkAttrs :: Attrs Unit -> DOMAttrs
mkAttrs m =
  S.execState m { className: M.Nothing
                , style: M.Nothing
                , id: M.Nothing
                , rows: M.Nothing
                , disabled: M.Nothing
                , value: M.Nothing
                , selected: M.Nothing
                }
