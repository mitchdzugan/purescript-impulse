"use strict";

const { makeSignal, makeEvent, zipWith } = require('ps-impulse-impl');
exports.makeSignal = e => init => () => makeSignal(e, init);
exports.off = s => s.off;
exports.consumeImpl = builder => f => s => () => {
    const res = s.consume(v => f(v)());
    return builder(res.res)(res.off);
};
exports.val = s => () => s.getVal();
exports.changed = s => s.changed;
exports.dedupImpl = p => s => () => s.dedup((v1, v2) => p(v1)(v2));
exports.tag = e => s => s.tagEvent(e);
exports.fmap = f => s => () => s.fmap(f);
exports.flatMap = fs => s => () => s.flatMap(v => fs(v)());
exports.zipWith = f => s1 => s2 => () => zipWith((a, b) => f(a)(b), s1, s2);
exports.ofVal = v => () => makeSignal(makeEvent(), v);
