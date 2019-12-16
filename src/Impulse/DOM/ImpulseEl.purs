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
       , class WebEventable
       , toWebEvent
       , withStopPropagation
       , withPreventDefault
       , d_m_value_e
       , d_value_e
       ) where

import Debug.Trace
import Prelude
import Data.Maybe as M
import DOM.HTML.Indexed as HTML
import Effect (Effect)
import Web.Event.Event as WE
import Web.UIEvent.KeyboardEvent as KE
import Web.UIEvent.MouseEvent as ME
import Impulse.FRP as FRP
import Impulse.Util.Rebuildable as Re

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

class WebEventable e where
  toWebEvent :: e -> WebEvent

instance webEventableMouseEvent :: WebEventable ME.MouseEvent where
  toWebEvent = ME.toEvent

instance webEventableKeyboardEvent :: WebEventable KE.KeyboardEvent where
  toWebEvent = KE.toEvent

instance webEventableWebEvent :: WebEventable WE.Event where
  toWebEvent e = e

withStopPropagation :: forall e. WebEventable e => FRP.Event e -> FRP.Event e
withStopPropagation e = FRP.mkEvent \pushSelf -> do
  flip FRP.consume e \we -> do
    WE.stopPropagation $ toWebEvent we
    pushSelf we

withPreventDefault :: forall e. WebEventable e => FRP.Event e -> FRP.Event e
withPreventDefault e = FRP.mkEvent \pushSelf -> do
  flip FRP.consume e \we -> do
    WE.preventDefault $ toWebEvent we
    pushSelf we

foreign import targetImpl ::
  ({ | HTML.HTMLinput } -> M.Maybe { | HTML.HTMLinput }) ->
  M.Maybe { | HTML.HTMLinput } ->
  WE.Event ->
  Effect (M.Maybe { | HTML.HTMLinput })

target :: WE.Event -> Effect (M.Maybe { | HTML.HTMLinput })
target e = targetImpl M.Just M.Nothing e

d_m_value_e :: forall e. WebEventable e => FRP.Event e -> FRP.Event (M.Maybe String)
d_m_value_e e = FRP.mkEvent \pushSelf -> do
  flip FRP.consume e \we -> do
    trace { we } \_ -> pure unit
    m_target <- target $ toWebEvent we
    pushSelf $ m_target <#> _.value

d_value_e :: forall e. WebEventable e => FRP.Event e -> FRP.Event String
d_value_e = d_m_value_e >>> Re.lower

