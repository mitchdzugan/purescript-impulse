'use strict';

const snabbdom = require('snabbdom');
let i = 0;
const patch = snabbdom.init([
	require('snabbdom/modules/class').default,
	require('snabbdom/modules/style').default,
	require('snabbdom/modules/attributes').default,
]);
const h = require('snabbdom/h').default;
const {
	makeEvent,
	joinEvents,
	adaptEvent,
	makeSignal,
} = require('ps-impulse-impl');

const Leaf = (text) => ({ type: 'LEAF', text });
const Tag = (tag, attrs, store) => ({ type: 'TAG', tag, attrs, store });
const Bind = (chunkId) => ({ type: 'BIND', chunkId });
const Stash = (stashPath) => ({ type: 'STASH', stashPath });

let makeContext;
const rootChunkId = '__root';
const makeAppStore = (mountPoint) => {
	const APP_STORE = {};
	let prev = mountPoint;
	let curr;

	const chunks = {};
	let usedChunks = {};
	let renderLessChunks = {};
	const getOrCreateChunkStore = (chunkId, depth, parents, parentStore, env, appStore, s, sf, skipRender) => {
		let emitOffs = [];
		const signals = {};
		usedChunks[chunkId] = true;
		if (chunks[chunkId]) {
			const store = chunks[chunkId];
			store.parents = {};
			store.parents[chunkId] = true;
			Object.keys(parents).forEach(chunkId => {
				store.parents[chunkId] = true;
			});
			return store.refresh(s, sf, env, appStore);
		}
		console.log('building chunk store, ', { chunkId });
		let resSignal;
		let offPlus = () => {};
		let elStore = parentStore.step(chunkId);
		let nextStashId = 1;
		const stashStores = {};


		let collCount = 0;
		const colls = {};
		const makeCollector = (key) => {
			
			if (colls[key]) {
				const coll = colls[key];
				coll.e.track += 1;
				console.log(coll.es, 'vy conf');
				coll.es.forEach(({ joine, off }) => { joine.clear(); off(); joine.skip = true; joine.push = (v) => { console.log('ignoring push', { v }); }; });
				coll.es = [];
				return coll;
			}
			
			const e = makeEvent();
			const res = {
				e,
				join: joine => {
					const myTack = e.track;
					const off = joine.consume(val => {
						console.log('SKYEEUUP', joine.skip, myTack, e.track, key);
						if (joine.skip || myTack !== e.track) {
							return;
						}
						return e.push(val);
					});
					res.es.push({ joine, off });
					return off;
				},
				es: []
			};
			e.track = 0;
			colls[key] = res;
			return res;
		};

		const addStashStore = (store) => {
			const stashId = nextStashId++;
			stashStores[stashId] = store;
			return { chunkId, stashId };
		};
		const getStashStore = stashId => stashStores[stashId];
		const store = {
			addStashStore,
			getStashStore,
			s,
			addEmitOff (off) { emitOffs.push(off); },
			signals,
			usedSignals: {},
			id: chunkId,
			depth,
			parents,
			toVdomList () { return elStore.toVdomList(); },
			getResSignal () { return resSignal; },
			off () {
				offPlus();
				Object.keys(store.signals).forEach(key => {
					store.signals[key].off();
				});
			},
			makeCollector
		};
		chunks[chunkId] = store;
		const resE = makeEvent();
		const refresh = (s, sf, env, appStore) => {
			let isFirst = true;
			offPlus();
			const consCount = s.consCount || 0;
			s.consCount = consCount + 1;
			const consumeRes = s.consume(v => {
				elStore = elStore.fresh();
				const context = makeContext(env, appStore, store, elStore);
				let res;
				if (isFirst) {
					res = sf(v)(context);
				} else {
					store.do = () => {
						emitOffs.forEach(off => off());
						emitOffs = [];
						const isStillActive = !!appStore.getChunkStore(chunkId);
						if (!isStillActive) {
							console.log('`do`ing after store deleted! Shutting off store.', { chunkId });
							store.off();
							store.off = () => console.log('already off, not doing again.', { chunkId });
							return;
						}
						store.usedSignals = {};
						const res = sf(v)(context);
						resE.push(res);
						Object.keys(store.signals).forEach(key => {
							if (store.usedSignals[key]) {
								return;
							}
							const sig = store.signals[key];
							sig.off();
							delete store.signals[key];
						});
						store.do = null;
					};
					const rendering = !skipRender && appStore.requestRender(chunkId);
					if (!parents[rendering]) {
						usedChunks[chunkId] = true;
						store.do();
					}
				}
				isFirst = false;
				return res;
			});
			const resInit = consumeRes.res;
			offPlus = () => {
				s.consCount--;
				if (!s.consCount) {
					consumeRes.off();
				}
			};
			resE.push(resInit);
			return store;
		};
		resSignal = makeSignal(resE);
		store.refresh = refresh;
		return store.refresh(s, sf, env, appStore);
	};
	const getChunkStore = chunkId => chunks[chunkId];
	const getAllChunks = () => chunks;
	let renderCount = 0;
	const render = () => {
		renderCount++;
		const root = getChunkStore(rootChunkId);
		curr = h('div', {}, root.toVdomList());
		patch(prev, curr);
		prev = curr;
		window.APP_STORE = APP_STORE;
	};

	let timeoutId;
	let requestedChunks = {};
	let isRendering = false;
	const requestRender = (chunkId) => {
		if (isRendering) {
			// TODO maybe run DO on the store
			return isRendering;
		}
		if (timeoutId) {
			clearTimeout(timeoutId);
		}
		requestedChunks[chunkId] = true;
		const myTimeoutId = setTimeout(
			() => {
				isRendering = true;
				let chunks = Object.keys(requestedChunks);
				const chunkStoresById = {};
				chunks.forEach(chunk => {
					const store = getChunkStore(chunk);
					if (store) {
						chunkStoresById[chunk] = store;
					}
				});
				chunks = Object.keys(chunkStoresById);
				const chunksToRender = [];
				while (chunks.length) {
					let minDepthChunkStore = chunkStoresById[chunks[0]];
					chunks.forEach(chunk => {
						const chunkStore = chunkStoresById[chunk];
						minDepthChunkStore = chunkStore.depth < minDepthChunkStore.depth ?
							chunkStore :
							minDepthChunkStore;
					});
					chunksToRender.push(minDepthChunkStore.id);
					chunks = chunks.filter(chunk => {
						const chunkStore = chunkStoresById[chunk];
						return !chunkStore.parents[minDepthChunkStore.id] && chunkStore.id !== minDepthChunkStore.id;
					});
				}
				usedChunks = {};
				renderLessChunks = {};
				chunksToRender.forEach(chunk => {
					isRendering = chunk;
					usedChunks[chunk] = true;

					if (chunkStoresById[chunk] && !chunkStoresById[chunk].do) {
						renderLessChunks[chunk] = true;
					}
					if (chunkStoresById[chunk] && chunkStoresById[chunk].do) {
						chunkStoresById[chunk].do();
					}
				});
				const allChunks = getAllChunks();
				Object.keys(requestedChunks).forEach(chunk => {
					if (!usedChunks[chunk]) {
						if (allChunks[chunk]) {
							let isStillInUse = false;
							Object.keys(allChunks[chunk].parents).forEach(key => {
								isStillInUse = isStillInUse || renderLessChunks[key];
							});
							if (!isStillInUse) {
								// console.log('deleting chunk... 1', { chunk });
								allChunks[chunk].off();
								delete allChunks[chunk];
							}
						}
					}
				});
				render();
				Object.keys(allChunks).forEach(chunk => {
					if (usedChunks[chunk]) {
						return;
					}
					chunksToRender.forEach(rchunk => {
						if (allChunks[chunk] && allChunks[chunk].parents[rchunk]) {
							allChunks[chunk] && allChunks[chunk].off();
							// console.log('deleting chunk... 2', { chunk });
							delete allChunks[chunk];
						}
					});
				});
				requestedChunks = {};
				timeoutId = null;
				isRendering = false;
			},
			10
		);
		timeoutId = myTimeoutId;
		return false;
	};

	const getOrCreateSignal = (chunkStore, key, event, reducer, init, forceNew = false) => {
		chunkStore.usedSignals[key] = true;
		const currSig = chunkStore.signals[key] || (
			{ getVal () { return init; }, off () {} }
		);
		const newInit = currSig.getVal();
		const sig = makeSignal(event.reduce(reducer, newInit), newInit);
		chunkStore.signals[key] = sig;
		currSig.off();
		return sig;
	};
	const markUsed = chunkId => { usedChunks[chunkId] = true; };
	APP_STORE.getAllChunks = getAllChunks;
	APP_STORE.getOrCreateSignal = getOrCreateSignal;
	APP_STORE.getOrCreateChunkStore = getOrCreateChunkStore;
	APP_STORE.getChunkStore = getChunkStore;
	APP_STORE.render = render;
	APP_STORE.markUsed = markUsed;
	APP_STORE.requestRender = requestRender;
	return APP_STORE;
};
const makeElStore = (appStore, path) => {
	let children = [];
	let key = null;
	let keyTypeCounts = {};
	const impls = {
		LEAF ({ text }) { return [text]; },
		TAG ({ tag, attrs, store }) {
			return [h(tag, attrs, store.toVdomList())];
		},
		BIND ({ chunkId }) {
			appStore.markUsed(chunkId);
			const store = appStore.getChunkStore(chunkId);
			return store.toVdomList();
		},
		STASH ({ stashPath: { chunkId, stashId } }) {
			appStore.markUsed(chunkId);
			const store = appStore.getChunkStore(chunkId);
			return store.getStashStore(stashId).toVdomList();
		}
	};
	const push = el => children.push(el);
	const concat = els => { children = children.concat(els); };
	const fresh = () => makeElStore(appStore, path);
	const step = (el) => makeElStore(appStore, `${path}:${el}`);
	const toVdomList = () => {
		return children
			.map(child => impls[child.type](child))
			.reduce((agg, children) => agg.concat(children), []);
	};
	const setKey = (k) => { key = k; };
	const grabKeyIfPresent = () => {
		const k = key;
		key = null;
		return k;
	};
	const grabKey = (type) => {
		let k = grabKeyIfPresent();
		if (k) { return k; }
		const count = keyTypeCounts[type] || 0;
		k = `$_autogen-${path}-${type}-${count}_`;
		keyTypeCounts[type] = count+1;
		return k;
	};
	return {
		push,
		concat,
		fresh,
		toVdomList,
		children,
		step,
		setKey,
		grabKey,
		grabKeyIfPresent,
	};
};

makeContext = (env, appStore, chunkStore, parentStore) => {
	const grabEventCollector = () => {
		const key = parentStore.grabKey('eventColl');
		return chunkStore.makeCollector(key);
	};
	const getEnv = () => env;
	const keyed = (key, inner, doEval = (c => f => f(c))) => {
		const store = parentStore.step(key);
		const childContext = makeContext(env, appStore, chunkStore, store);
		const res = doEval(childContext)(inner);
		parentStore.setKey(key);
		parentStore.concat(store.children);
		return res;
	};
	const dedupSignal = (signal, pred) => {
		const key = parentStore.grabKey('dedup');
		let prev = signal.getVal();
		const e = signal.changed.filter(curr => {
			console.log({ prev, curr, pred, fore: 'be' });
			if (pred(prev, curr)) {
				console.log('after');
				return false;
			}
			console.log('after');
			prev = curr;
			return true;
		});
		return appStore.getOrCreateSignal(
			chunkStore,
			key,
			e,
			() => a => a,
			prev
		);
	};
	const flattenSignal = (signalSignal) => {
		const key = parentStore.grabKey('flatten');
		const initS = signalSignal.getVal();
		let off = () => {};
		let prev = initS;
		const e = joinEvents(
			initS.changed,
			signalSignal.changed.flatMap(s => {
				off();
				off = s.off;
				prev = s;
				return s.changed;
			}),
			signalSignal.changed.fmap(s => s.getVal())
		);
		return appStore.getOrCreateSignal(
			chunkStore,
			key,
			e,
			() => a => a,
			initS.getVal(),
			true
		);
	};
	const bindSignal = (signal, innerF, doEval = (c => f => f(c)), skipRender = false) => {
		const chunkId = parentStore.grabKey('bindSignal');
		const parentKeys = Object.keys(chunkStore.parents);
		const childParents = {};
		childParents[chunkStore.id] = true;
		parentKeys.forEach(key => { childParents[key] = true; });
		const newChunkStore = appStore.getOrCreateChunkStore(
			chunkId,
			chunkStore.depth + 1,
			childParents,
			parentStore,
			env,
			appStore,
			signal,
			v => c => doEval(c)(innerF(v)),
			skipRender
		);
		parentStore.push(Bind(chunkId));
		return newChunkStore.getResSignal();
	};
	const reduceEvent = (event, reducer, init) => {
		const key = parentStore.grabKey('reduceEvent');
		return appStore.getOrCreateSignal(chunkStore, key, event, reducer, init);
	};
	const createElement = (tag, attrs, inner, doEval = (c => f => f(c))) => {
		const key = parentStore.grabKeyIfPresent();
		const store = parentStore.step(`${tag}${!key ? '' : `--key-${key}`}`);
		let log = console.log;
		log = () => {};
		const elEvent = makeEvent();
		const data = {
			attrs,
			hook: {
				create (_, node) { log('create', node); node.elm.rc = 0; elEvent.push([node.elm]); },
				insert (node) { log('insert', node); },
				update (_, node) {
					if (node.elm) {
						const _ons = node.elm._ons || {}; // _e.clear();
						Object.values(_ons).forEach(e => e.clear());
					}
					const currRc = node.elm.rc || 0;
					node.elm.rc = currRc + 1;
					elEvent.push([node.elm]);
					if (node.elm.to) {
						clearTimeout(node.elm.to);
					}
					if (attrs.value) {
						if (typeof attrs.value !== 'string') {
							return;
						}
						const curr = node.elm.value || '';
						if (attrs.value.trim() !== curr.trim()) {
							node.elm.to = setTimeout(() => {
								if (!node.elm) {
									return;
								}
								const curr = node.elm.value || '';
								if (attrs.value.trim() !== curr.trim()) {
									node.elm.value = attrs.value;
								}
								// TODO this is sketch
								// fixes a problem with textareas
							}, 500);
						}
					}
				},
				postPatch (_, node) { log('postPatch', node); },
			},
		};
		if (key) {
			data.key = key;
		}
		parentStore.push(Tag(tag, data, store));
		const childContext = makeContext(env, appStore, chunkStore, store);
		const res = doEval(childContext)(inner);
		// TODO clean up this.
		// TODO the el._e.clear is the thing that is good
		const mkEvent = (on) => {
			return elEvent.flatMap(([el]) => {
				const myRc = el.rc;
				const _ons = el._ons || {};
				if (_ons[on]) {
					return _ons[on];
				}
				const e = adaptEvent(
					push => {
						const f = e => {
							const _push = el._push || {};
							const push = _push[on] || (() => {});
							push(e);
						};
						const _softListening = el._softListening || {};
						_softListening[on] = true;
						el._softListening = _softListening;
						const _listening = el._listening || {};
						if (!_listening[on]) {
							_listening[on] = true;
							el._listening = _listening;
							el.addEventListener(on, f);
						}
						const _push = el._push || {};
						_push[on] = push;
						el._push = _push;
						return f;
					},
					push => {
						const _softListening = el._softListening || {};
						_softListening[on] = false;
						el._softListening = _softListening;
						setTimeout(() => {
							const _softListening = el._softListening || {};
							if (_softListening[on]) {
								return;
							}
							const _listening = el._listening || {};
							_listening[on] = false;
							el._listening = _listening;
							el.removeEventListener(on, push);
						}, 100);
					}
				);
				_ons[on] = e;
				el._ons = _ons;
				return e;
			});
		};
		return { res, mkEvent };
	};
	const leaf = (text) => parentStore.push(Leaf(text));
	const withEnv = (env, inner, doEval=(c => f => f(c))) => (
		doEval(makeContext(env, appStore, chunkStore, parentStore))(inner)
	);
	const collect = (modEnv, getCollector, innerF, doEval = (c => f => f(c))) => {
		const R = makeContext(
			modEnv(getEnv()), appStore, chunkStore, parentStore
		);
		const coll = getCollector(R.getEnv());
		return doEval(R)(innerF(coll.e));
	};
	const joinEvent = (getCollector, event) => {
		const coll = getCollector(getEnv());
		chunkStore.addEmitOff(coll.join(event));
	};
	const preemptEvent = (fInner, resToE = a => a, doEval = (c => f => f(c))) => {
		const ee = makeEvent();
		const e = ee.flatMap(e => e);
		const R = makeContext(
			getEnv(), appStore, chunkStore, parentStore
		);
		const res = doEval(R)(fInner(e));
		ee.push(resToE(res));
		return res;
	};

	const stashDOM = (inner, doEval = (c => f => f(c))) => {
		const key = parentStore.grabKey('stash');
		const stashStore = parentStore.step(key);
		const R = makeContext(
			env, appStore, chunkStore, stashStore
		);
		const res = doEval(R)(inner);
		const stashPath = chunkStore.addStashStore(stashStore);
		return { res, stashPath };
	};

	const applyDOM = ({ stashPath, res }) => {
		parentStore.push(Stash(stashPath));
		return res;
	};

	return {
		stashDOM,
		applyDOM,
		getEnv,
		keyed,
		joinEvent,
		bindSignal,
		dedupSignal,
		flattenSignal,
		reduceEvent,
		collect,
		createElement,
		leaf,
		withEnv,
		grabEventCollector,
		preemptEvent,
	};
};

/**
 * Initial SSR Implementation
 * eventually would like to be able to
 *   a) wait for signal to reach certain value before rendering
 *   b) attach event listeners that queue events for them to be
 *      processed when the client attaches itself.
 * TODO
 *   [] make sure there are no memory leaks from not being
 *      careful about discarding single value signals
 */
const makeSSRContext = (env_) => {
	let markup = '';
	let CTXT;
	let env = env_;
	const getEnv = () => env;
	const keyed = (key, inner, doEval = (c => f => f(c))) => (
		doEval(CTXT)(inner)
	);
	const joinEvent = () => {};
	const bindSignal = (signal, innerF, doEval = (c => f => f(c))) => (
		makeSignal(
			makeEvent(),
			doEval(CTXT)(innerF(signal.getVal()))
		)
	);
	const dedupSignal = (s) => s;
	const flattenSignal = (ss) => ss.getVal();
	const reduceEvent = (e, r, init) => (
		makeSignal(makeEvent(), init)
	);
	const collect = (modEnv, getCollector, innerF, doEval = (c => f => f(c))) => (
		doEval(CTXT)(innerF(makeEvent()))
	);
	const createElement = (tag, attrs, inner, doEval = (c => f => f(c))) => {
		markup += `<${tag}`;
		Object.keys(attrs).forEach(attr => {
			markup += ` ${attr}="${attrs[attr]}"`;
		});
		markup += '>';
		const res = doEval(CTXT)(inner);
		markup += `</${tag}>`;
		return { res, mkEvent () { return makeEvent(); } };
	};
	const leaf = (text) => { markup += text; };
	const withEnv = (innerEnv, inner, doEval = (c => f => f(c))) => {
		const currEnv = env;
		env = innerEnv;
		const res = doEval(CTXT)(inner);
		env = currEnv;
		return res;
	};
	const grabEventCollector = () => {};
	const preemptEvent = (innerF, resToE, doEval = (c => f => f(c))) => (
		doEval(CTXT)(innerF(makeEvent()))
	);
	const getMarkup = () => markup;


	const stashDOM = (inner, doEval = (c => f => f(c))) => {
		const CTXT2 = makeSSRContext(env);
		const res = doEval(CTXT2)(inner);
		const stashMarkup = CTXT2.getMarkup();
		return { res, stashMarkup };
	};

	const applyDOM = ({ stashMarkup, res }) => {
		markup += stashMarkup;
		return res;
	};

	CTXT = {
		IS_SERVER: true,
		stashDOM,
		applyDOM,
		getEnv,
		keyed,
		joinEvent,
		bindSignal,
		dedupSignal,
		flattenSignal,
		reduceEvent,
		collect,
		createElement,
		leaf,
		withEnv,
		grabEventCollector,
		preemptEvent,

		getMarkup
	};

	return CTXT;
};

const attach = (elId, f, env, doEval = (c => f => f(c))) => {
	const el = document.getElementById(elId);
	const appStore = makeAppStore(el);
	const parentStore = makeElStore(appStore, 'div');
	appStore.getOrCreateChunkStore(
		rootChunkId,
		0,
		{},
		parentStore,
		env,
		appStore,
		makeSignal(makeEvent()),
		() => context => doEval(context)(f),
		false
	);
	appStore.render();
};

const toMarkup = (f, env, doEval = (c => f => f(c))) => {
	const ctxt = makeSSRContext(env);
	doEval(ctxt)(f);
	return ctxt.getMarkup();
};

const isOneWord = s => typeof s === 'string' && !s.trim().includes(' ');

exports.effImpl = () => eff => eff();
exports.grabEventCollectorImpl = C => C.grabEventCollector();
exports.getRawEnvImpl = C => C.getEnv();
exports.keyedImpl = doEval => C => key => inner => C.keyed(key, inner, doEval);
exports.collectImpl = C => getColl => e => C.joinEvent(getColl, e);
exports.bindSignalImpl = doEval => C => skipRender => signal => inner => C.bindSignal(signal, inner, doEval, skipRender);
exports.dedupSignalImpl = C => pred => signal => C.dedupSignal(signal, (a, b) => pred(a)(b));
exports.flattenSignalImpl = C => signalSignal => C.flattenSignal(signalSignal);
exports.reduceSignalImpl = pure => doEval => C => s => reducer => init => {
	let acc = init;
	const f = (v) => {
		acc = reducer(acc)(v);
		return pure(acc);
	};
	return C.bindSignal(s, f, doEval, false);
};
exports.reduceEventImpl = C => e => reducer => init => C.reduceEvent(e, reducer, init);
exports.trapImpl = doEval => C => modEnv => getColl => innerF => C.collect(modEnv, getColl, innerF, doEval);
exports.createElementImpl = doEval => fromMaybe => C => tag => raw_attrs => inner => {
	let ftag = tag;
	const { IS_SERVER } = C;
	const attrs = {};
	Object.keys(raw_attrs).forEach(attr => {
		const val = fromMaybe(null)(raw_attrs[attr]);
		if (val == null) {
			return;
		}
		attrs[attr] = val;
	});

	const baseClass = attrs.class || '';
	const otherClass = attrs.className || '';
	const fullClass = `${baseClass} ${otherClass}`;
	delete attrs.className;
	attrs.class = fullClass.trim();

	if (attrs.class && !IS_SERVER && isOneWord(attrs.class)) {
		ftag += `.${attrs.class}`;
		delete attrs.class;
	}
	if (attrs.id && !IS_SERVER && isOneWord(attrs.id)) {
		ftag += `#${attrs.id.trim()}`;
		delete attrs.id;
	}
	return C.createElement(ftag, attrs, inner, doEval);
};
exports.textImpl = C => text => C.leaf(text);
exports.withRawEnvImpl = doEval => C => env => inner => C.withEnv(env, inner, doEval);
exports.preemptEventImpl = doEval => C => resToE => fInner => C.preemptEvent(fInner, resToE, doEval);
exports.attachImpl = doEval => elId => f => env => () => attach(elId, f, env, doEval);
exports.toMarkupImpl = doEval => f => env => () => toMarkup(f, env, doEval);
exports.innerRes = ({ res }) => res;
exports.stashRes = ({ res }) => res;
exports.stashDOMImpl = doEval => C => inner => C.stashDOM(inner, doEval);
exports.applyDOMImpl = C => stash => C.applyDOM(stash);

exports.onClick = ({ mkEvent }) => mkEvent('click');
exports.onDoubleClick = ({ mkEvent }) => mkEvent('doubleclick');
exports.onChange = ({ mkEvent }) => mkEvent('change');
exports.onKeyUp = ({ mkEvent }) => mkEvent('keyup');
exports.onKeyDown = ({ mkEvent }) => mkEvent('keydown');
exports.onKeyPress = ({ mkEvent }) => mkEvent('keypress');
exports.onMouseDown = ({ mkEvent }) => mkEvent('mousedown');
exports.onMouseEnter = ({ mkEvent }) => mkEvent('mouseenter');
exports.onMouseLeave = ({ mkEvent }) => mkEvent('mouseleave');
exports.onMouseMove = ({ mkEvent }) => mkEvent('mousemove');
exports.onMouseOut = ({ mkEvent }) => mkEvent('mouseout');
exports.onMouseOver = ({ mkEvent }) => mkEvent('mouseover');
exports.onMouseUp = ({ mkEvent }) => mkEvent('mouseup');
exports.onTransitionEnd = ({ mkEvent }) => mkEvent('transitionend');
exports.onScroll = ({ mkEvent }) => mkEvent('scroll');

exports.targetImpl = just => nothing => e => () => (
	e.target ? just(e.target) : nothing
);

exports.memoImpl = () => {
    // TODO
};

exports.stashEqAble = a => {
	console.log({ a });
	return !a.stashMarkup ?
		`chunkId:${a.stashPath.chunkId}-stashId-${a.stashPath.stashId}` :
		a.stashMarkup;
};

exports.elResEqAble = (a) => {
	console.log({ a }, 'elres');
	// TODO probably do something else, maybe shouldnt
	// implement EQ for this at all
	return "true";
};