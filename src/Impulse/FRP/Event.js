"use strict";

exports.mkEvent_raw = (frp) => frp.mkEvent;
exports.push_raw = (frp) => frp.push;
exports.consume_raw = (frp) => frp.consume;
exports.rebuildBy_raw = (frp) => frp.rebuildBy;
exports.fmap_raw = (frp) => frp.fmap;
exports.filter_raw = (frp) => frp.filter;
exports.reduce_raw = (frp) => frp.reduce;
exports.flatMap_raw = (frp) => frp.flatMap;
exports.join_raw = (frp) => frp.join;
exports.dedupImpl_raw = (frp) => frp.dedupImpl;
exports.preempt_raw = (frp) => frp.preempt;
exports.never_raw = (frp) => frp.never;
exports.tagWith_raw = (frp) => frp.tagWith;
exports.timer_raw = (frp) => frp.timer;
exports.debounce_raw = (frp) => frp.debounce;
exports.throttle_raw = (frp) => frp.throttle;
exports.deferOff_raw = (frp) => frp.deferOff;
