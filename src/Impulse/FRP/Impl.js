"use strict";

let nextId = 1;
const mkEventJS = (onRequired = () => () => {}) => {
	const id = nextId;
	nextId = id + 1;
	return {
		id,
		nextSubscriberId: 0,
		subscribers: {},
		consumerCount: 0,
		onRequired,
		offCallback() {},
	};
};
let pushCount = 0;
const pushJS = (value) => (event) => {
	const { subscribers } = event;
	pushCount++;
	Object.values(subscribers).forEach(handler => handler(value, pushCount));
};
const consumeJS = (f) => (event) => {
	const { nextSubscriberId } = event;
	if (!event.consumerCount) {
		event.offCallback = event.onRequired(
			(value) => pushJS(value)(event)
		);
	}
	event.consumerCount += 1;
	const subscriberId = nextSubscriberId;
	event.nextSubscriberId = subscriberId + 1;
	event.subscribers[subscriberId] = f;
	return () => {
		if (event.subscribers[subscriberId]) {
			event.consumerCount -= 1;
			if (!event.consumerCount) {
				event.offCallback();
			}
			delete event.subscribers[subscriberId];
		}
	};
};


// -- mkEvent :: forall a. ((a -> Effect Unit) -> Effect (Effect Unit)) -> Event a
const mkEvent = (onRequired = () => () => () => () => {}) => mkEventJS(pushSelf => onRequired(v => () => pushSelf(v))());

// -- push :: forall a. a -> Event a -> Effect Unit
const push = (value) => (event) => () => pushJS(value)(event);

// -- consume :: forall a. (a -> Effect Unit) -> Event a -> Effect (Effect Unit)
const consume = (f) => (event) => () => consumeJS(v => f(v)())(event);

// -- rebuildBy :: forall a b. (a -> Array b) -> Event a -> Event b
const rebuildBy = (toNexts) => (event) =>{
	return mkEventJS(
		(pushSelf) => consumeJS(
			(curr) => toNexts(curr).forEach(pushSelf)
		)(event)
	);
};

// -- fmap :: forall a b. (a -> b) -> Event a -> Event b
const fmap = (f) => (event) => (
	rebuildBy(v => [f(v)])(event)
);

// -- filter :: forall a. (a -> Boolean) -> Event a -> Event a
const filter = (pred) => (event) => (
	rebuildBy(v => pred(v) ? [v] : [])(event)
);

// -- reduce :: forall a b. (a -> b -> a) -> a -> Event b -> Event a
const reduce = (reducer) => (init) => (event) => {
	let agg = init;
	return rebuildBy((curr) => {
		agg = reducer(agg)(curr);
		return [agg];
	})(event);
};

// -- flatMap :: forall a b. (a -> Event b) -> Event a -> Event b
const flatMap = (toEvent) => (event) => {
	let currOff = () => {};
	let fullOff = () => {};
	return mkEventJS(
		(pushSelf) => {
			fullOff = consumeJS((curr) => {
				currOff();
				const innerE = toEvent(curr);
				currOff = consumeJS(pushSelf)(innerE);
			})(event);
			return () => {
				currOff();
				fullOff();
				currOff = () => {};
				fullOff = () => {};
			};
		}
	);
};

// -- join :: forall a. Array (Event a) -> Event a
const join = (events) => {
	const maxPushCountById = {};
	return mkEventJS(
		(pushSelf) => {
			const offs = events.map(event => consumeJS((value, pushCount) => {
				const maxPushCount = maxPushCountById[event.id] || 0;
				if (pushCount <= maxPushCount) {
					console.log('skipping due to out of order');
					return;
				}
				maxPushCountById[event.id] = pushCount;
				pushSelf(value);
			})(event));
			return () => { offs.map(off => off()); };
		}
	);
};

// -- dedupImpl :: forall a. (a -> a -> Boolean) -> Event a -> Event a
const dedupImpl = (eq) => (event) => {
	let isFirst = true;
	let prev;
	return mkEventJS(
		(pushSelf) => {
			const off = consumeJS((curr) => {
				if (isFirst || !eq(prev)(curr)) {
					pushSelf(curr);
					prev = curr;
				}
				isFirst = false;
			})(event);
			return () => { off(); isFirst = true; };
		}
	);
};

// -- once :: forall a. a -> Event a
const once = (a) => mkEventJS((pushSelf) => setTimeout(() => pushSelf(a), 0));

// -- never :: forall a. Event a
const never = mkEventJS(() => {
	never.subscribers = {};
	return () => {
		never.subscribers = {};
	};
});

// -- preempt :: forall a b. (b -> Event a) -> (Event a -> b) -> b
const preempt = (e_fromRes) => (f) => {
	let p_eResolve = () => {};
	const p_e = new Promise(
		(resolve) => { p_eResolve = resolve; }
	);
	let p_off = new Promise(resolve => resolve());
	const res = f(
		mkEventJS(
			(pushSelf) => {
				p_off = p_e.then((event) => consumeJS(pushSelf)(event));
				return () => {
					p_off.then((off) => off());
					p_off = new Promise(resolve => resolve());
				};
			}
		)
	);
	p_eResolve(e_fromRes(res));
	return res;
};

// -- timer :: Int -> Event Int
const timer = (ms) => mkEventJS(
	(pushSelf) => {
		let count = 1;
		const id = setInterval(
			() => { pushSelf(count); count++; },
			ms
		);
		return () => clearInterval(id);
	}
);

// -- debounce :: forall a. Int -> Event a -> Event a
const debounce = (ms) => (event) => {
	let timeoutId;
	return mkEventJS(
		(pushSelf) => {
			const off = consumeJS(
				(v) => {
					if (timeoutId) {
						clearTimeout(timeoutId);
					}
					timeoutId = setTimeout(
						() => pushSelf(v),
						ms
					);
				}
			)(event);
			return () => {
				off();
				if (timeoutId) {
					clearTimeout(timeoutId);
					timeoutId = null;
				}
			};
		}
	);
};

// -- throttle :: forall a. Int -> Event a -> Event a
const throttle = (ms) => (event) => {
	let timeoutId;
	let latest;
	return mkEventJS(
		(pushSelf) => {
			const off = consumeJS(
				(v) => {
					latest = v;
					if (!timeoutId) {
						timeoutId = setTimeout(
							() => {
								timeoutId = null;
								return pushSelf(latest);
							},
							ms
						);
					}
				}
			)(event);
			return () => {
				off();
				if (timeoutId) {
					clearTimeout(timeoutId);
					timeoutId = null;
				}
			};
		}
	);
};

const deferOff = (ms) => (event) => {
	let softOn = false;
	let isOn = false;
	let offFn = () => {};
	return mkEventJS(
		(pushSelf) => {
			softOn = true;
			if (!isOn) {
				offFn = consumeJS(v => softOn && pushSelf(v))(event);
				isOn = true;
			}
			return () => {
				softOn = false;
				setTimeout(
					() => {
						if (softOn) {
							return;
						}

						isOn = false;
						offFn();
						offFn = () => {};
					},
					ms
				);
			};
		}
	);
};

// -- tagWith :: forall a b c. (a -> b -> c) -> Event a -> Event b -> c -> Event c
const tagWith = (f) => (tagged) => (tagger) => {
	let taggerVal;
	let hasTaggerVal = false;
	return mkEventJS(
		(pushSelf) => {
			const off1 = consumeJS((tv => {
				taggerVal = tv;
				hasTaggerVal = true;
			}))(tagger);
			const off2 = consumeJS((taggedVal) => {
				if (!hasTaggerVal) {
					return;
				}
				pushSelf(f(taggedVal)(taggerVal));
			})(tagged);
			return () => { off1(); off2(); };
		}
	);
};

///////////////////////////////////////////

let nextSigBuilderId = 1;
const sigBuilders = {};

const mkSigBuilder = () => ({ destroys: [] });

// -- s_destroy :: forall a. Signal a -> Effect Unit
const s_destroy = (s) => () => s.destroy();

// -- s_subRes :: forall a. SubRes a -> a
const s_subRes = ({ res }) => res;

// -- s_unsub :: forall a. SubRes a -> Effect Unit
const s_unsub = ({ off }) => () => off();

// -- s_sub :: forall a b. (a -> Effect b) -> Signal a -> Effect (SubRes b)
const s_sub = (f) => (s) => () => s.sub(val => f(val)());

// -- s_inst :: forall a. Signal a -> Effect a
const s_inst = s => () => s.getVal();

// -- s_changed :: forall a. Signal a -> Event.Event a
const s_changed = ({ changed }) => changed;

// -- s_tagWith :: forall a b c. (a -> b -> c) -> Event.Event a -> Signal b -> Event.Event c
const s_tagWith = (f) => (e) => (s) => fmap((a) => f(a)(s.getVal()))(e);

// -- s_fromImpl :: forall a. Event.Event a -> a -> SigClass -> Signal a
let sigOns = 0;
let sigOffs = 0;
const s_fromImpl = (changed) => (init) => (id) => {
	let subs = {};
	let nextSubId = 1;
	let isDestroyed = false;
	let val = init;
	sigOns++;
	// console.log({ sigOns, sigOffs });
	const off = consumeJS(
		(curr) => {
			if (isDestroyed) {
				return;
			}
			val = curr;
			Object.values(subs).forEach((handler) => handler(val));
		}
	)(changed);
	const getVal = () => val;
	const sub = (f) => {
		if (isDestroyed) {
			return f(val);
		}

		const subId = nextSubId;
		nextSubId++;
		subs[subId] = f;
		const res = f(val);
		const off = () => {
			delete subs[subId];
		};
		return { res, off };
	};
	const destroy = () => {
		sigOffs++;
		// console.log({ sigOffs, sigOns });
		off();
		subs = {};
		isDestroyed = true;
	};

	const sigBuilder = sigBuilders[id];
	sigBuilder.destroys.push(destroy);

	return {
		destroy,
		getVal,
		changed,
		sub
	};
};

// -- s_fmapImpl :: forall a b. (a -> b) -> Signal a -> SigClass -> Signal b
const s_fmapImpl = (f) => (s) => (
	s_fromImpl(fmap(f)(s.changed))(f(s.getVal()))
);

// -- s_constImpl :: forall a. a -> SigClass -> Signal a
const s_constImpl = (v) => s_fromImpl(never)(v);

// -- s_zipWithImpl :: forall a b c. (a -> b -> c) -> Signal a -> Signal b -> SigClass -> Signal c
const s_zipWithImpl = (f) => (s1) => (s2) => (
	s_fromImpl(
		fmap(
			() => f(s1.getVal())(s2.getVal())
		)(
			join([s1.changed, s2.changed])
		)
	)(
		f(s1.getVal())(s2.getVal())
	)
);

// -- s_flattenImpl :: forall a. Signal (Signal a) -> SigClass -> Signal a
const s_flattenImpl = (ss) => (
	s_fromImpl(
		join([
			flatMap(({ changed }) => changed)(ss.changed),
			fmap(({ getVal }) => getVal(), ss.changed),
			ss.getVal().changed
		])
	)(ss.getVal().getVal())
);

// -- s_dedupImpl :: forall a. (a -> a -> Boolean) -> Signal a -> SigClass -> Signal a
const s_dedupImpl = (eq) => (s) => (id) => {
	let prev;
	let isFirst = true;
	return s_fromImpl(
		filter(
			(val) => {
				if (isFirst) {
					isFirst = false;
					prev = val;
					return true;
				}

				if (val == prev || eq(val)(prev)) {
					return false;
				}

				prev = val;
				return true;
			}
		)(s.changed)
	)(s.getVal())(id);
};

// -- s_buildImpl :: forall a. (SigClass -> Signal a) -> SigBuild a
const s_buildImpl = f => () => {
	const sigBuilderId = nextSigBuilderId;
	nextSigBuilderId++;
	sigBuilders[sigBuilderId] = mkSigBuilder();
	const signal = f(sigBuilderId);
	const sigBuilder = sigBuilders[sigBuilderId];
	const destroys = sigBuilder.destroys;
	const destroy = () => (
		destroys.forEach(destroy => destroy())
	);
	delete sigBuilders[sigBuilderId];
	return { destroy, signal };
};

// -- sigBuildToRecordImpl ::
//      forall a.
//      (Effect Unit -> Signal a -> { destroy :: Effect Unit, signal :: Signal a }) ->
//      SigBuild a ->
//      Effect { destroy :: Effect Unit, signal :: Signal a }
const sigBuildToRecordImpl = (toRecord) => (sbf) => () => {
	const { destroy, signal } = sbf();
	return toRecord(destroy)(signal);
};

///////////////////////////////////////////

exports.impl = {
	mkEvent,
	push,
	consume,
	rebuildBy,
	fmap,
	filter,
	reduce,
	flatMap,
	join,
	dedupImpl,
	preempt,
	once,
	never,
	tagWith,
	timer,
	debounce,
	throttle,
	deferOff,
	s_destroy,
	s_subRes,
	s_unsub,
	s_sub,
	s_inst,
	s_changed,
	s_tagWith,
	s_fromImpl,
	s_fmapImpl,
	s_constImpl,
	s_zipWithImpl,
	s_flattenImpl,
	s_dedupImpl,
	s_buildImpl,
	sigBuildToRecordImpl
};
