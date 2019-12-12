"use strict";

let state;
exports.get = () => state;
exports.put = v => () => { state = v; };
exports.runImpl = toRes => init => eff => () => {
	const curr = state;
	state = init;
	const a = eff();
	const res = toRes(state)(a);
	state = curr;
	return res;
}