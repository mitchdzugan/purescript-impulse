"use strict";

const frp = require('ps-impulse-impl');

exports.mkEvent = frp.mkEvent;
exports.push = frp.push;
exports.consume = frp.consume;
exports.rebuildBy = frp.rebuildBy;
exports.fmap = frp.fmap;
exports.filter = frp.filter;
exports.reduce = frp.reduce;
exports.flatMap = frp.flatMap;
exports.join = frp.join;
exports.dedupImpl = frp.dedupImpl;
exports.preempt = frp.preempt;
exports.never = frp.never;
exports.tagWith = frp.tagWith;
exports.timer = frp.timer;
exports.debounce = frp.debounce;
exports.throttle = frp.throttle;
