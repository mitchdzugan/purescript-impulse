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

let collCount = 0;
const makeCollector = () => {
	const e = makeEvent();
	const res = {
		e,
		join: joine => {
			joine.consume(val => {
				return e.push(val);
			});
		}
	};
	res.count = collCount++;
	e.Collcount = res.count;
	return res;
};

let makeContext;
const rootChunkId = '__root';
const makeAppStore = (mountPoint) => {
	let prev = mountPoint;
	let curr;

	const chunks = {};
	let usedChunks = {};
	let renderLessChunks = {};
	const getOrCreateChunkStore = (chunkId, depth, parents, parentStore, env, appStore, s, sf, skipRender) => {
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
		let resSignal;
		let offPlus = () => {};
		let elStore = parentStore.step(chunkId);
		const store = {
			s,
			signals,
			usedSignals: {},
			id: chunkId,
			depth,
			parents,
			toVdomList () { return elStore.toVdomList(); },
			getResSignal () { return resSignal; },
			off () {
				Object.keys(store.signals).forEach(key => {
					store.signals[key].off();
				});
			},
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
		curr = h("div", {}, root.toVdomList());
		patch(prev, curr);
		prev = curr;
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
	return {
		getOrCreateSignal,
		getOrCreateChunkStore,
		getChunkStore,
		render,
		markUsed,
		requestRender
	};
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
	};
	const push = el => children.push(el);
	const concat = els => { children = children.concat(els); };
	const fresh = () => makeElStore(appStore, path);
	const step = (el) => makeElStore(appStore, `${path}:${el}`);
	const toVdomList = () => (
		children
			.map(child => impls[child.type](child))
			.reduce((agg, children) => agg.concat(children), [])
	);
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
		return makeCollector();
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
			if (!curr) {
				return false;
			}
			if (pred(prev, curr)) {
				return false;
			}
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
		const isOne = key === "$_autogen-div:__root-flatten-0_";
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
		const res = appStore.getOrCreateSignal(
			chunkStore,
			key,
			e,
			() => a => a,
			initS.getVal(),
			true
		);
		res.isOne = isOne;
		return res;
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
					if (node.elm._e) {
						node.elm._e.clear();
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
				const el_ons = el._ons || {};
				const e = adaptEvent(
					push => {
						const f = e => {
							el._push(e);
						};
						el._softListening = true;
						if (!el._listening) {
							el._listening = true;
							el._f = f;
							el.addEventListener(on, f);
						}
						el._push = push;
						return f;
					},
					push => {
						el._softListening = false;
						setTimeout(() => {
							if (el._softListening) {
								return;
							}
							el._listening = false;
							el.removeEventListener(on, push);
						}, 100);
					}
				);
				el._e = e;
				return e;
			});
		};
		return { res, mkEvent };
	};
	const leaf = (text) => parentStore.push(Leaf(text));
	const stashDOM = (inner, doEval = (c => f => f(c))) => {
		const fauxStore = parentStore.fresh();
		const fauxContext = makeContext(env, appStore, chunkStore, fauxStore);
		const res = doEval(fauxContext)(inner);
		return { res, children: fauxStore.children };
	};
	const renderStashedDOM = ({ children }) => {
		parentStore.concat(children);
		return;
	};
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
		coll.join(event);
		return;
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
	return {
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
		stashDOM,
		renderStashedDOM,
		withEnv,
		grabEventCollector,
		preemptEvent,
	};
};

const attach = (elId, f, env, doEval = (c => f => f(c))) => {
	const el = document.getElementById(elId);
	const appStore = makeAppStore(el);
	const parentStore = makeElStore(appStore, 'div');
	const chunkStore = appStore.getOrCreateChunkStore(
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
const main = () => {
	const test = (I) => {
		const stashed = I.stashDOM(I => {
			I.createElement("span", {}, I => I.leaf("Goodbye!"));
			return "test";
		});
		I.createElement("section", {}, (I) => {
			I.createElement("span", {}, I => I.leaf("Hello!"));
			const res = I.createElement("div", {}, I => I.leaf(stashed.res));
			const s = I.reduceEvent(
				res.onClick, (agg => () => agg+1), 0
			);
			I.bindSignal(s, c => I => {
				I.createElement(
					"div", {}, I => I.leaf(`Clicked ${c} times!!!`)
				);
			});
			I.renderStashedDOM(stashed);
		});
	};
	attach("app", test, null);
};

exports.main = main;

exports.effImpl = C => eff => eff();
exports.grabEventCollectorImpl = C => C.grabEventCollector();
exports.getRawEnvImpl = C => C.getEnv();
exports.keyedImpl = doEval => C => key => inner => C.keyed(key, inner, doEval);
exports.collectImpl = C => getColl => e => C.joinEvent(getColl, e);
exports.bindSignalImpl = doEval => C => skipRender => signal => inner => C.bindSignal(signal, inner, doEval, skipRender);
exports.dedupSignalImpl = C => pred => signal => C.dedupSignal(signal, (a, b) => pred(a)(b));
exports.flattenSignalImpl = C => signalSignal => C.flattenSignal(signalSignal);
exports.reduceEventImpl = C => e => reducer => init => C.reduceEvent(e, reducer, init);
exports.trapImpl = doEval => C => modEnv => getColl => innerF => C.collect(modEnv, getColl, innerF, doEval);
exports.createElementImpl = doEval => C => tag => attrs => inner => {
	let ftag = tag;
	if (attrs.className) {
		ftag += `.${attrs.className}`;
		delete attrs.className;
	}
	if (attrs.id) {
		ftag += `#${attrs.id}`;
		delete attrs.id;
	}
	return C.createElement(ftag, attrs, inner, doEval);
};
exports.textImpl = C => text => C.leaf(text);
exports.stashDOMImpl = doEval => makeRes => C => inner => {
	const res = C.stashDOM(inner, doEval);
	return makeRes(res.res)(res.children);
};
exports.renderStashedDOMImpl = C => stash => C.renderStashedDOM(stash);
exports.withRawEnvImpl = doEval => C => env => inner => C.withEnv(env, inner, doEval);
exports.preemptEventImpl = doEval => C => resToE => fInner => C.preemptEvent(fInner, resToE, doEval);
exports.attachImpl = doEval => elId => f => env => () => attach(elId, f, env, doEval);
exports.innerRes = ({ res }) => res;
exports.onClick = ({ mkEvent }) => mkEvent('click');
exports.onChange = ({ mkEvent }) => mkEvent('change');
exports.onKeyUp = ({ mkEvent }) => mkEvent('keyup');
