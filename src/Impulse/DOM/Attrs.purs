module Impulse.DOM.Attrs where

import Prelude
import Control.Monad.State as S
import Data.List as L
import Data.Maybe as M

type DOMAttrs = { className :: M.Maybe String
                , style :: M.Maybe String
                , id :: M.Maybe String
                , type :: M.Maybe String
                , href :: M.Maybe String
                , rows :: M.Maybe Int
                , disabled :: M.Maybe Boolean
                , value :: M.Maybe String
                , selected :: M.Maybe Boolean
                , controls :: M.Maybe Boolean
                , width :: M.Maybe Int
                , height :: M.Maybe Int
                , src :: M.Maybe String
                }
type Attrs = S.State DOMAttrs Unit

anil :: Attrs
anil = pure unit

classNames :: S.State (L.List String) Unit -> Attrs
classNames m = do
  let classes = L.foldl (\a b -> a <> " " <> b) ""
                      $ L.reverse
                      $ S.execState m L.Nil
  S.modify_ _ { className = M.Just classes }

cn :: String -> S.State (L.List String) Unit
cn s = S.modify_ $ L.Cons s

className :: String -> Attrs
className classAsStr =
  S.modify_ _ { className = M.Just classAsStr }

styles :: S.State (L.List String) Unit -> Attrs
styles m = do
  let styleList = S.execState m L.Nil
      el_style = L.foldl (\a b -> b <> "; " <> a) "" styleList
  S.modify_ _ { style = M.Just el_style }

style :: String -> String -> S.State (L.List String) Unit
style prop val = S.modify_ $ L.Cons $ prop <> ": " <> val

id :: String -> Attrs
id i =
  S.modify_ _ { id = M.Just i }

href :: String -> Attrs
href uri =
  S.modify_ _ { href = M.Just uri }

src :: String -> Attrs
src uri =
  S.modify_ _ { src = M.Just uri }

rows :: Int -> Attrs
rows n =
  S.modify_ _ { rows = M.Just n }

width :: Int -> Attrs
width n =
  S.modify_ _ { width = M.Just n }

height :: Int -> Attrs
height n =
  S.modify_ _ { height = M.Just n }

disabled :: Boolean -> Attrs
disabled b =
  S.modify_ _ { disabled = M.Just b }

attr_value :: String -> Attrs
attr_value v =
  S.modify_ _ { value = M.Just v }

attr_type :: String -> Attrs
attr_type v =
  S.modify_ _ { type = M.Just v }

selected :: Boolean -> Attrs
selected true =
  S.modify_ _ { selected = M.Just $ true }
selected false =
  S.modify_ _ { selected = M.Nothing }

controls :: Boolean -> Attrs
controls true =
  S.modify_ _ { controls = M.Just $ true }
controls false =
  S.modify_ _ { controls = M.Nothing }

mkAttrs :: Attrs -> DOMAttrs
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
                , controls: M.Nothing
                , width: M.Nothing
                , height: M.Nothing
                , src: M.Nothing
                }
