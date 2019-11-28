module Impulse.DOM.Attrs where

import Prelude
import Control.Monad.State as S
import Data.List as L
import Data.Maybe as M
import Debug.Trace

type DOMAttrs = { className :: M.Maybe String
                , style :: M.Maybe String
                , id :: M.Maybe String
                , type :: M.Maybe String
                , href :: M.Maybe String
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
  let classes = L.foldl (\a b -> a <> " " <> b) ""
                      $ L.reverse
                      $ S.execState m L.Nil
  S.modify_ _ { className = M.Just classes }

cn :: String -> S.State (L.List String) Unit
cn s = S.modify_ $ L.Cons s

className :: String -> Attrs Unit
className cn =
  S.modify_ _ { className = M.Just cn }

styles :: S.State (L.List String) Unit -> Attrs Unit
styles m = do
  let styleList = S.execState m L.Nil
      style = L.foldl (\a b -> b <> "; " <> a) "" styleList
  S.modify_ _ { style = M.Just style }

style :: String -> String -> S.State (L.List String) Unit
style prop val = S.modify_ $ L.Cons $ prop <> ": " <> val

id :: String -> Attrs Unit
id i =
  S.modify_ _ { id = M.Just i }

href :: String -> Attrs Unit
href uri =
  S.modify_ _ { href = M.Just uri }

rows :: forall a. Int -> Attrs Unit
rows n =
  S.modify_ _ { rows = M.Just n }

disabled :: Boolean -> Attrs Unit
disabled b =
  S.modify_ _ { disabled = M.Just b }

attr_value :: String -> Attrs Unit
attr_value v =
  S.modify_ _ { value = M.Just v }

attr_type :: String -> Attrs Unit
attr_type v =
  S.modify_ _ { type = M.Just v }

selected :: forall a. Show a => a -> Attrs Unit
selected v =
  S.modify_ _ { selected = M.Just $ show v }

mkAttrs :: Attrs Unit -> DOMAttrs
mkAttrs m =
  S.execState m { className: M.Nothing
                , style: M.Nothing
                , href: M.Nothing
                , id: M.Nothing
                , type: M.Nothing
                , rows: M.Nothing
                , disabled: M.Nothing
                , value: M.Nothing
                , selected: M.Nothing
                }
