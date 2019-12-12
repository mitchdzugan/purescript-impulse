module Impulse.Native.DOM.Attrs
       ( module A
       , Attrs(..)
       )
       where

import Prelude
import Impulse.DOM.Attrs hiding (Attrs(..)) as A
import Impulse.DOM.Attrs (Attrs(..)) as Aa

type Attrs = Aa.Attrs Unit
