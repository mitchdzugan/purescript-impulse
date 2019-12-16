module Impulse.DOM.ImpulseEl
       ( ImpulseEl
       , WebEvent
       , elRes
       , onClick
       , onDoubleClick
       , onMouseDown
       , onMouseEnter
       , onMouseLeave
       , onMouseMove
       , onMouseOut
       , onMouseOver
       , onMouseUp
       , onChange
       , onTransitionEnd
       , onScroll
       , onKeyUp
       , onKeyDown
       , onKeyPress
       ) where

import Prelude
import Impulse.FRP as FRP
import Web.Event.Event as WE
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME

foreign import data ImpulseEl :: Type -> Type

foreign import elRes :: forall a. ImpulseEl a -> a

type WebEvent = WE.Event

foreign import onClick :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onDoubleClick :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseDown :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseEnter :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseLeave :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseMove :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseOut :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseOver :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onMouseUp :: forall a. ImpulseEl a -> FRP.Event ME.MouseEvent

foreign import onChange :: forall a. ImpulseEl a -> FRP.Event WebEvent

foreign import onTransitionEnd :: forall a. ImpulseEl a -> FRP.Event WebEvent

foreign import onScroll :: forall a. ImpulseEl a -> FRP.Event WebEvent

foreign import onKeyUp :: forall a. ImpulseEl a -> FRP.Event KE.KeyboardEvent

foreign import onKeyDown :: forall a. ImpulseEl a -> FRP.Event KE.KeyboardEvent

foreign import onKeyPress :: forall a. ImpulseEl a -> FRP.Event KE.KeyboardEvent

