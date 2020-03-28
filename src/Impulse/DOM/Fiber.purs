module Impulse.DOM.Fiber
       ( Fiber
       , mkFiber
       , mkFiber_
       , f_focus
       , f_view
       , f_getSignal
       ) where

import Prelude
import Data.Lens
import Data.Symbol
import Prim.Row
import Impulse.Util.Foldable
import Impulse.DOM.API
import Impulse.DOM.Util
import Impulse.FRP

newtype Fiber a = Fiber { signal :: Signal a
                        , event :: Event a
                        }

mkFiber ::
  forall sym a b res eI eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (Fiber a) () eSym =>
  Cons sym (Fiber a) eOSymless eO =>
  Union eSym eI eO =>
  Cons sym (Collector b) () cSym =>
  Cons sym (Collector b) cOSymless cO =>
  Union cSym cI cO =>
  SProxy sym ->
  a ->
  (a -> b -> a) ->
  DOM (Record eO) (Record cO) res ->
  DOM (Record eI) (Record cI) res
mkFiber p init reducer inner = do
  let event = mkEvent \_ -> pure $ pure unit
      sb = s_from event init
  signal <- s_use sb
  upsertEnv p (Fiber { signal, event }) do
    e_collect p \e_action -> do
      flip e_consume e_action \b -> do
        curr <- s_inst signal
        let next = reducer curr b
        push next event
      inner

mkFiber_ ::
  forall sym a res eI eSym eO eOSymless c.
  IsSymbol sym =>
  Lacks sym () =>
  Cons sym (Fiber a) () eSym =>
  Cons sym (Fiber a) eOSymless eO =>
  Union eSym eI eO =>
  SProxy sym ->
  a ->
  DOM (Record eO) c res ->
  DOM (Record eI) c res
mkFiber_ p init inner = do
  let event = mkEvent \_ -> pure $ pure unit
      sb = s_from event init
  signal <- s_use sb
  upsertEnv p (Fiber { signal, event }) inner

f_focus ::
  forall sout sin res a b c eI eIFiberless eSym eO eOSymless cI cSym cO cOSymless.
  IsSymbol sout =>
  IsSymbol sin =>
  Lacks sin () =>
  Cons sin (Fiber b) () eSym =>
  Cons sin (Fiber b) eOSymless eO =>
  Union eSym eI eO =>
  Cons sin (Collector c) () cSym =>
  Cons sin (Collector c) cOSymless cO =>
  Union cSym cI cO =>
  Cons sout (Fiber a) eIFiberless eI =>
  SProxy sout ->
  SProxy sin ->
  Lens' a b ->
  (b -> c -> b) ->
  DOM (Record eO) (Record cO) res ->
  DOM (Record eI) (Record cI) res
f_focus p_out p_in lens reducer inner = do
  Fiber { event, signal } <- getEnv p_out
  s_in <- s_use $ s_fmap (view lens) signal
  upsertEnv p_in (Fiber { event: s_changed s_in, signal: s_in }) do
    e_collect p_in \e_in -> do
      flip e_consume e_in \c -> do
        curr_out <- s_inst signal
        curr_in <- s_inst s_in
        let next = set lens (reducer curr_in c) curr_out
        push next event
      inner

f_view ::
  forall sout sin res a b eI eIFiberless eSym eO eOSymless c.
  IsSymbol sout =>
  IsSymbol sin =>
  Lacks sin () =>
  Cons sin (Fiber b) () eSym =>
  Cons sin (Fiber b) eOSymless eO =>
  Union eSym eI eO =>
  Cons sout (Fiber a) eIFiberless eI =>
  SProxy sout ->
  SProxy sin ->
  Lens' a b ->
  DOM (Record eO) c res ->
  DOM (Record eI) c res
f_view p_out p_in lens inner = do
  Fiber { event, signal } <- getEnv p_out
  s_in <- s_use $ s_fmap (view lens) signal
  upsertEnv p_in (Fiber { event: s_changed s_in, signal: s_in }) inner

f_getSignal ::
  forall sym a eFiberless e c.
  IsSymbol sym =>
  Cons sym (Fiber a) eFiberless e =>
  SProxy sym ->
  DOM (Record e) c (Signal a)
f_getSignal p = do 
  Fiber { signal } <- getEnv p
  pure signal
