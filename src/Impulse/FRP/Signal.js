"use strict";

const { makeSignal, makeEvent, zipWith, zipWithLazy } = require('ps-frp-impl');
exports.makeSignal = e => init => () => makeSignal(e, init);
exports.off = s => s.off;
exports.makeSignalLazy = e => init => makeSignal(e, init, true);
exports.consumeImpl = builder => f => s => () => {
    const res = s.consume(v => f(v)());
    return builder(res.res)(res.off);
};
exports.val = s => () => s.getVal();
exports.changed = s => s.changed;
exports.dedupImpl = p => s => s.dedup((v1, v2) => p(v1)(v2));
exports.tag = e => s => s.tagEvent(e);
exports.fmap = f => s => s.fmap(f);
exports.fmapLazy = f => s => s.fmap(f, true);
exports.flatMap = fs => s => s.flatMap(fs);
exports.flatMapLazy = fs => s => s.flatMap(fs, true);
exports.zipWith = f => s1 => s2 => zipWith((a, b) => f(a)(b), s1, s2);
exports.zipWithLazy = f => s1 => s2 => zipWithLazy((a, b) => f(a)(b), s1, s2);
exports.ofVal = v => makeSignal(makeEvent(), v);
