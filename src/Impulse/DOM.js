const snabbdom = require('snabbdom');
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

const makeCollector = () => {
	const e = makeEvent();
	return {
		e,
		join: joine => {
			joine.consume(val => e.push(val));
		}
	};
};

let makeContext;
const rootChunkId = '__root';
const makeAppStore = (mountPoint) => {
	let prev = mountPoint;
	let curr;

	const signals = {};
	const chunks = {};
	let usedChunks = {};
	const getOrCreateChunkStore = (chunkId, depth, parents, parentStore, env, appStore, s, sf, skipRender) => {
		usedChunks[chunkId] = true;
		if (chunks[chunkId]) {
			const store = chunks[chunkId];
			store.parents = {};
			store.parents[chunkId] = true;
			Object.keys(parents).forEach(chunkId => {
				store.parents[chunkId] = true;
			});
			return store.refresh(s, sf);
		}
		let resSignal;
		let off = () => {};
		let elStore = parentStore.step(chunkId);
		const store = {
			s,
			id: chunkId,
			depth,
			parents,
			toVdomList () { return elStore.toVdomList(); },
			getResSignal () { return resSignal; },
			off () { off(); },
		};
		chunks[chunkId] = store;
		const resE = makeEvent();
		const refresh = (s, sf) => {
			off();
			let isFirst = true;
			const consumeRes = s.consume(v => {
				elStore = elStore.fresh();
				const context = makeContext(env, appStore, store, elStore);
				let res;
				if (isFirst) {
					res = sf(v)(context);
				} else {
					store.do = () => {
						const res = sf(v)(context);
						resE.push(res);
						store.do = null;
					};
					const rendering = !skipRender && appStore.requestRender(chunkId);
					if (!parents[rendering]) {
						store.do();
					}
				}
				isFirst = false;
				return res;
			});
			const resInit = consumeRes.res;
			resE.push(resInit);
			off = consumeRes.off;
			return store;
		};
		resSignal = makeSignal(resE);
		store.refresh = refresh;
		return store.refresh(s, sf);
	};
	const getChunkStore = chunkId => chunks[chunkId];
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
				chunksToRender.forEach(chunk => {
					isRendering = chunk;
					usedChunks[chunk] = true;
					if (chunkStoresById[chunk] && chunkStoresById[chunk].do) {
						chunkStoresById[chunk].do();
					}
				});
				Object.keys(requestedChunks).forEach(chunk => {
					if (!usedChunks[chunk]) {
						if (chunkStoresById[chunk]) {
							if (chunkStoresById[chunk].do) {
								chunkStoresById[chunk].do = () => {};
							}
							chunkStoresById[chunk].off();
							delete chunkStoresById[chunk];
						}
					}
				});
				requestedChunks = {};
				timeoutId = null;
				render();
				isRendering = false;
			},
			10
		);
		timeoutId = myTimeoutId;
		return false;
	};

	const getOrCreateSignal = (key, event, reducer, init) => {
		const currSig = signals[key] || ({ getVal () { return init; } });
		const newInit = currSig.getVal();
		const sig = makeSignal(event.reduce(reducer, newInit), init);
		signals[key] = sig;
		currSig.off && currSig.off();
		return sig;
	};
	return {
		getOrCreateSignal,
		getOrCreateChunkStore,
		getChunkStore,
		render,
		requestRender,
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
			return appStore.getChunkStore(chunkId).toVdomList();
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
	const grabEventCollector = () => makeCollector();
	const getEnv = () => env;
	const keyed = (key) => {
		parentStore.setKey(key);
	};
	const dedupSignal = (signal, pred) => {
		const key = parentStore.grabKey('dedup');
		let prev = signal.getVal();
		const e = signal.changed.filter(curr => {
			if (pred(prev, curr)) {
				return false;
			}
			prev = curr;
			return true;
		});
		return appStore.getOrCreateSignal(
			key,
			e,
			() => a => a,
			signal.getVal()
		);
	};
	const flattenSignal = (signalSignal) => {
		const key = parentStore.grabKey('flatten');
		const initS = signalSignal.getVal();
		const e = joinEvents(
			initS.changed,
			signalSignal.changed.flatMap(s => s.changed),
			signalSignal.changed.fmap(s => s.getVal())
		);
		return appStore.getOrCreateSignal(
			key,
			e,
			() => a => a,
			initS.getVal()
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
		return appStore.getOrCreateSignal(key, event, reducer, init);
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
				create (_, node) { log('create', node); elEvent.push(node.elm); },
				insert (node) { log('insert', node); },
				update (_, node) { log('update', node); },
				postPatch (_, node) { log('postPatch', node); },
			},
		};
		if (key) {
			data.key = key;
		}
		parentStore.push(Tag(tag, data, store));
		const childContext = makeContext(env, appStore, chunkStore, store);
		const res = doEval(childContext)(inner);
		const mkEvent = (on) => {
			return elEvent.flatMap(el => {
				const el_ons = el._ons || {};
				if (el_ons[on]) { return el_ons[on]; }
				const e = adaptEvent(
					push => { el.addEventListener(on, push); return push;},
					push => { el.removeEventListener(on, push); }
				);
				el_ons[on] = e;
				el._ons = el_ons;
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
exports.keyedImpl = C => key => C.keyed(key);
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