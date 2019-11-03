"use strict";

const { makeEvent, joinEvents, adaptEvent } = require('ps-frp-impl');

exports.getA = () => { throw "Kappa!"; };
exports.makeEvent = (eff) => () => makeEvent(eff);
exports.push = v => e => () => e.push(v);
exports.consume = f => e => () => e.consume(v => f(v)());
exports.fmap = f => e => e.fmap(f);
exports.filter = f => e => e.filter(f);
exports.reduce = f => init => e => e.reduce(f, init);
exports.flatMap = f => e => e.flatMap(f);
exports.join = e1 => e2 => joinEvents(e1, e2);
exports.adaptEvent = sub => unsub => () => adaptEvent(
	(push) => (
		() => sub(val => push(val)())
	),
	unsubVal => unsub(unsubVal)()
);
exports.timer = (interval) => {
	let count = 0;
	let e = { push: () => {} };
	const id = setInterval(
		() => { e.push(count); count++; }, interval
	);
	e = makeEvent(() => () => clearInterval(id));
	return e;
};
exports.never = makeEvent();