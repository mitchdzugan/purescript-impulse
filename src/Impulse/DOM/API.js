"use strict";

const isOneWord = s => typeof s === 'string' && !s.trim().includes(' ');

const flatMap = (f) => (a) => {
	const res = [];
	a.forEach((iv) => f(iv).forEach(v => res.push(v)));
	return res;
};

///////////////////////////////////////////////////////////////////////////////

let nextSysId = 1;
const currSysEnvBySysId = {};
const currBindEnvBySysId = {};
const currParentEnvBySysId = {};
const currEnvBySysId = {};

const getSys = (obj) => ({ sysId }) => obj[sysId];
const setSys = (obj) => (value) => ({ sysId }) => { obj[sysId] = value; };

const getSysEnv = getSys(currSysEnvBySysId);
const setSysEnv = setSys(currSysEnvBySysId);

const getBindEnv = getSys(currBindEnvBySysId);
const setBindEnv = setSys(currBindEnvBySysId);

const getParentEnv = getSys(currParentEnvBySysId);
const setParentEnv = setSys(currParentEnvBySysId);

const getEnv = getSys(currEnvBySysId);
const setEnv = setSys(currEnvBySysId);

let collCount = 0;
const makeColl = (frp) => {
	const collId = collCount++;
	const collE = frp.mkEvent();
	let isOff = false;
	let offs = [];
	const coll = {
		collId,
		offs,
		es: {},
		nextEId: 1,
		getE () {
			return frp.fmap(a => a)(collE);
		},
		isOff,
		off () { isOff = true; offs.forEach(off => off()); offs = []; }
	};
	coll.join = (e) => {
		const eId = coll.nextEId;
		coll.nextEId++;
		const localOff = frp.consume(
			(v) => () => {
				// console.log({ isOff, eId, nextEId: coll.nextEId, v, collId });
				if (!isOff) {
					frp.push(v)(collE)();
				}
			}
		)(e)();
		offs.push(localOff);
		return localOff;
	};
	return coll;
};

const toArray = (list, carry) => {
	if (!carry) {
		return toArray(list, []);
	}
	if (!list) {
		return carry;
	}
	carry.push(list.getColl);
	return toArray(list.rest, carry);
};

const freshCollectors = (frp, bindEnv, node, offPrev = false) => {
	if (!node) {
		return {};
	}

	if (offPrev) {
		// console.log('offing!', node.getColl(bindEnv.collectors));
		node.getColl(bindEnv.collectors).off();
	}
	return node.addColl(freshCollectors(frp, bindEnv, node.rest, offPrev))(makeColl(frp));
};

const mkBindEnv = (frp) => ({
	offsByPath: {},
	used: {},
	collectors: {},
	collectorSpecs: null,
	renderOffs: [],
	refresh () {
		// console.log(this.renderOffs);
		// console.log('refreshing!!!');
		this.renderOffs.forEach(off => off());
		this.renderOffs = [];
		this.collectors = freshCollectors(frp, this, this.collectorSpecs, true);
		this.used = {};
	},
	mkFresh () {
		const fresh = mkBindEnv(frp);
		fresh.collectors = freshCollectors(frp, this, this.collectorSpecs);
		fresh.collectorSpecs = this.collectorSpecs;
		return fresh;
	},
	getCollectorsArray () {
		return toArray(this.collectorSpecs);
	}
});

const mkParentEnv = (path = '', uniquePath = null) => ({
	children: [],
	nextKey: null,
	nextUniqueKey: null,
	countTakenByType: {},
	path,
	uniquePath: uniquePath || path,
	mkFresh (step) {
		const res = mkParentEnv(
			`${step}${this.nextKey ? `.${this.nextKey}` : ''} | ${this.path}`,
			`${step}${this.nextKey ? `.${this.nextKey}` : (!this.nextUniqueKey ? '' : `.${this.nextUniqueKey}`)} | ${this.uniquePath}`
		);
		this.nextKey = null;
		this.nextUniqueKey = null;
		return res;
	},
	refresh () {
		this.nextKey = null;
		this.nextUniqueKey = null;
		this.children = [];
		this.countTakenByType = {};
	}
});

const prepareKeyForType = (type, setNextKey = true) => (parentEnv) => {
	if (parentEnv.nextKey) {
		return parentEnv;
	}

	const myId = parentEnv.countTakenByType[type] || 0;
	parentEnv.countTakenByType[type] = myId + 1;
	if (setNextKey) {
		parentEnv.nextKey = `${myId}`;
	}
	parentEnv.nextUniqueKey = `${myId}`;
	return parentEnv;
};

const altered = (f_newVal) => (obj) => (domClass) => (f) => {
	const curr = getSys(obj)(domClass);
	setSys(obj)(f_newVal(curr))(domClass);
	const res = f();
	setSys(obj)(curr)(domClass);
	return res;
};

///////////////////////////////////////////////////////////////////////////////

const idomTypes = {
	CreateElement: 'CreateElement',
	Bind: 'Bind',
	Stash: 'Stash',
	Text: 'Text'
};

const iCreateElement = (tag_, attrs_, children, path, key) => {
	let tag = tag_;
	const attrs = Object.assign({}, attrs_);
	const baseClass = attrs.class || '';
	const otherClass = attrs.className || '';
	const fullClass = `${baseClass} ${otherClass}`;
	attrs.class = fullClass.trim();
	if (attrs.class === '') {
		delete attrs.class;
	}
	delete attrs.className;

	if (attrs.id && isOneWord(attrs.id)) {
		tag += `#${attrs.id.trim()}`;
		delete attrs.id;
	}
	if (attrs.class && isOneWord(attrs.class)) {
		tag += `.${attrs.class}`;
		delete attrs.class;
	}

	return {
		type: idomTypes.CreateElement, tag, attrs, children, path, key
	};
};
const iBind = (path) => ({ type: idomTypes.Bind, path });
const iStash = (stashId) => ({ type: idomTypes.Stash, stashId });
const iText = (text) => ({ type: idomTypes.Text, text });

///////////////////////////////////////////////////////////////////////////////

const ROOT = 'ROOT';
const ROOT_BIND = `s_bind.0 | ${ROOT}`;

// -- envImpl :: forall e c. DOMClass e c -> e
const envImpl = getEnv;

// -- withAlteredEnvImpl :: forall e1 e2 c a. (e1 -> e2) -> (DOMClass e2 c -> a) -> DOMClass e1 c -> a
const withAlteredEnvImpl = (f) => (domF) => (domClass) => (
	altered(f)(currEnvBySysId)(domClass)(
		() => domF(domClass)
	)
);

// -- keyedImpl :: forall e c a. String -> (DOMClass e c -> a) -> DOMClass e c -> a
const keyedImpl = (key) => (domF) => (domClass) => {
	const preEnv = getParentEnv(domClass);
	const { children } = preEnv;
	preEnv.nextKey = null;
	const newEnv = preEnv.mkFresh(`keyed.${key}`);
	setParentEnv(newEnv)(domClass);
	newEnv.nextKey = key;
	const res = domF(domClass);
	newEnv.children.forEach(child => children.push(child));
	setParentEnv(preEnv)(domClass);
	return res;
};

let createCount = 0;
let flatMapCount = 0;
// -- createElementImpl :: forall e c a. String -> Attrs -> (DOMClass e c -> a) -> DOMClass e c -> ImpulseEl a
const createElementImpl_raw = (frp) => (tag) => (attrs) => (domF) => (domClass) => {
	const key = getParentEnv(domClass).nextKey;
	const { innerRes, children, uniquePath } = altered(env => prepareKeyForType(tag, false)(env).mkFresh(tag))(currParentEnvBySysId)(domClass)(
		() => {
			const innerRes = domF(domClass);
			const { children, uniquePath } = getParentEnv(domClass);
			return { innerRes, children, uniquePath };
		}
	);

	getParentEnv(domClass).nextKey = null;
	getParentEnv(domClass).children.push(
		iCreateElement(tag, attrs, children, uniquePath, key)
	);

	createCount++;
	const { e_el_mount } = getSysEnv(domClass);
	// console.log('rendering', { uniquePath });
	const mkOn = (on) => {
		const filtered = frp.filter((mount) => { return mount.path === uniquePath; })(e_el_mount);
		const flattened = frp.flatMap(({ elm }) => {
			flatMapCount++;
			// console.log(path);
			// console.log('flatMapping :::', path, elm);
			const _ons = elm._ons || {};
			if (_ons[on]) {
				return frp.fmap(a => a)(_ons[on]);
			}
			const e = frp.mkEvent((pushSelf) => () => {
				const push = v => pushSelf(v)();
				// console.log('A el _ ', path);
				const f = v => {
					// console.log({ uniquePath, v });
					push(v);
				};
				elm.addEventListener(on, f);
				return () => {
					// console.log('R el _ ', path);
					elm.removeEventListener(on, f);
				};
			});
			_ons[on] = frp.deferOff(10)(e);
			elm._ons = _ons;
			return frp.fmap(a => a)(_ons[on]);
		})(filtered);
		return flattened;
	};
	return { innerRes, mkOn };
};

// -- textImpl :: forall e c. String -> DOMClass e c -> Unit
const textImpl = (text) => (domClass) => {
	getParentEnv(domClass).children.push(
		iText(text)
	);
	return;
};

// -- e_collectImpl :: forall e c1 c2 a b. (c1 -> Collector a -> c2) -> (c2 -> Collector a) -> (FRP.Event a -> DOMClass e c2 -> b) -> DOMClass e c1 -> b
const e_collectImpl_raw = (frp) => (addCollector) => (getCollector) => (domFE) => (domClass) => {
	getParentEnv(domClass).nextKey = null;
	const bindEnv = getBindEnv(domClass);
	const prevColl = getCollector(bindEnv.collectors);
	// console.log({ prevColl });
	const coll = makeColl(frp);
	const modBindEnv = (bindEnv) => Object.assign(
		{},
		bindEnv,
		{
			collectors: addCollector(bindEnv.collectors)(coll),
			collectorSpecs: {
				addColl: addCollector,
				getColl: getCollector,
				rest: bindEnv.collectorSpecs
			}
		}
	);
	return altered(modBindEnv)(currBindEnvBySysId)(domClass)(
		() => {
			const { res } = frp.preempt(({ e }) => e)((e) => {
				const res = domFE(e)(domClass);
				return { res, e: coll.getE() };
			});
			return res;
		}
	);
};

// -- e_consumeImpl :: forall e c a. (a -> Effect Unit) -> Event a -> DOMClass e c -> Unit
const e_consumeImpl_raw = (frp) => (f) => (e) => (domClass) => {
	const bindEnv = getBindEnv(domClass);
	const off = frp.consume(a => f(a))(e)();
	bindEnv.renderOffs.push(off);
	return;
};

// -- e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit
const e_emitImpl = (getCollector) => (e) => (domClass) => {
	const bindEnv = getBindEnv(domClass);
	bindEnv.renderOffs.push(getCollector(bindEnv.collectors).join(e));
	return;
};

// -- s_bindDOMImpl :: forall e c a b. FRP.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> FRP.Signal b
const s_bindDOMImpl_raw = (frp) => (s) => (domFS) => (domClass) => {
	getParentEnv(domClass).nextKey = null;
	const e_res = frp.mkEvent();
	const e_collectors = frp.mkEvent();
	let isFirst = true;
	const { signal, path } = altered(env => prepareKeyForType('s_bind')(env).mkFresh('s_bind'))(currParentEnvBySysId)(domClass)(
		() => {
			const prevBindEnv = getBindEnv(domClass);
			const bindEnv = prevBindEnv.mkFresh();
			const env = getEnv(domClass);
			const parentEnv = getParentEnv(domClass);
			const { path } = parentEnv;
			// console.log('s_bindDOM', { path });
			const {
				off, res: { res, collectors }
			} = frp.s_sub((val) => () => {
				setEnv(env)(domClass);
				parentEnv.refresh();
				bindEnv.refresh();
				setBindEnv(bindEnv)(domClass);
				setParentEnv(parentEnv)(domClass);
				const res = domFS(val)(domClass);
				const { children } = getParentEnv(domClass);
				const sysEnv = getSysEnv(domClass);
				sysEnv.idomByPath[path] = children;
				if (!isFirst) {
					frp.push(res)(e_res)();
					frp.push(bindEnv.collectors)(e_collectors)();
					sysEnv.requestRender();
					// console.log('---- stats ----', path);
					// console.log(Object.keys(bindEnv.offsByPath));
					// console.log(Object.keys(bindEnv.used));
					Object.keys(bindEnv.offsByPath).forEach((offKey) => {
						if (bindEnv.used[offKey]) {
							return;
						}
						bindEnv.offsByPath[offKey].forEach(off => off());
					});
				}
				isFirst = false;
				return {
					res, collectors: bindEnv.collectors
				};
			})(s)();
			const { destroy, signal } = frp.s_buildImpl(frp.s_fromImpl(e_res)(res))();
			const shutdown = () => {
				// console.log('offing s_bindDOM', { path });
				const sysEnv = getSysEnv(domClass);
				destroy();
				off();
				Object.values(bindEnv.offsByPath).forEach(
					offs => offs.forEach(off => off())
				);
				bindEnv.offsByPath = {};
				bindEnv.renderOffs.forEach(off => off());
				bindEnv.renderOffs = [];
				const getCollectors = bindEnv.getCollectorsArray();
				getCollectors.forEach((getCollector) => {
					getCollector(bindEnv.collectors).off();
				});
				delete prevBindEnv.offsByPath[path];
				delete sysEnv.idomByPath[path];
			};
			prevBindEnv.renderOffs.push(() => {
				off();
				destroy();
				const getCollectors = bindEnv.getCollectorsArray();
				getCollectors.forEach((getCollector) => {
					getCollector(bindEnv.collectors).off();
				});
				bindEnv.renderOffs.forEach(off => off());
				bindEnv.renderOffs = [];
				/*
				Object.values(bindEnv.offsByPath).forEach(
					offs => offs.forEach(off => off())
				);
				bindEnv.offsByPath = {};
				*/
			});
			const offs = prevBindEnv.offsByPath[path] || [];
			offs.push(shutdown);
			prevBindEnv.offsByPath[path] = offs;
			prevBindEnv.used[path] = true;
			setBindEnv(prevBindEnv)(domClass);
			setEnv(env)(domClass);
			const getCollectors = prevBindEnv.getCollectorsArray();
			getCollectors.forEach((getCollector) => {
				prevBindEnv.renderOffs.push(getCollector(prevBindEnv.collectors).join(frp.join([
					getCollector(collectors).getE(),
					frp.flatMap(colls => getCollector(colls).getE())(e_collectors)
				])));
			});
			return { signal, path };
		}
	);
	getParentEnv(domClass).children.push(iBind(path));
	return signal;
};

// -- s_useImpl :: forall e c a. FRP.SigBuild a -> DOMClass e c -> FRP.Signal a
const s_useImpl = (sbf) => (domClass) => {
	const res = altered(env => prepareKeyForType('s_use')(env).mkFresh('s_use'))(currParentEnvBySysId)(domClass)(
		() => {
			const { path } = getParentEnv(domClass);
			// console.log('s_use', { path });
			const sysEnv = getSysEnv(domClass);
			const bindEnv = getBindEnv(domClass);
			bindEnv.used[path] = true;
			if (sysEnv.signals[path]) {
				return sysEnv.signals[path];
			}
			const { destroy, signal } = sbf();
			sysEnv.signals[path] = signal;
			const offs = bindEnv.offsByPath[path] || [];
			offs.push(() => {
				// console.log('offing s_use', { path });
				destroy();
				delete sysEnv.signals[path];
				delete bindEnv.offsByPath[path];
			});
			bindEnv.offsByPath[path] = offs;
			return signal;
		}
	);
	getParentEnv(domClass).nextKey = null;
	return res;
};

// -- d_stashImpl :: forall e c a. (DOMClass e c ->  a) -> DOMClass e c -> ImpulseStash a
const d_stashImpl = (domF) => (domClass) => {
	const res = altered(env => prepareKeyForType('d_stash')(env).mkFresh('d_stash'))(currParentEnvBySysId)(domClass)(
		() => {
			const sysEnv = getSysEnv(domClass);
			const bindEnv = getBindEnv(domClass);
			const res = domF(domClass);
			const { children, path } = getParentEnv(domClass);
			const stashId = path;
			sysEnv.idomByPath[path] = children;
			const lastPath = sysEnv.stashes[stashId];
			sysEnv.stashes[stashId] = path;
			sysEnv.stashUsage[stashId] = 0;
			return { stashId, res };
		}
	);
	getParentEnv(domClass).nextKey = null;
	return res;
};

// -- d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a
const d_applyImpl = ({ stashId, res }) => (domClass) => {
	const sysEnv = getSysEnv(domClass);
	sysEnv.stashUsage[stashId] += 1;
	// console.log(' on', { stashId });
	const bindEnv = getBindEnv(domClass);
	bindEnv.renderOffs.push(() => { /*console.log('off', { stashId });*/ sysEnv.stashUsage[stashId] -= 1; });
	getParentEnv(domClass).children.push(
		iStash(stashId)
	);
	return res;
};

// -- d_memoImpl :: forall e c a b. (a -> Int) -> a -> (a -> DOMClass e c -> b) -> DOMClass e c -> b
const d_memoImpl = (getHash) => (a) => (domFA) => (domClass) => {
	const bindEnv = getBindEnv(domClass);
	const sysEnv = getSysEnv(domClass);
	const { children: currChildren } = getParentEnv(domClass);
	const res = altered(env => prepareKeyForType('d_memo')(env).mkFresh('d_memo'))(currParentEnvBySysId)(domClass)(
		() => {
			const { path } = getParentEnv(domClass);
			bindEnv.used[path] = true;
			bindEnv.offsByPath[path] = [() => {
				delete sysEnv.hasByPathAndHash[path];
				delete sysEnv.domByPathAndHash[path];
				delete sysEnv.valByPathAndHash[path];
				Object.values(sysEnv.mbeByPathAndHash[path] || []).forEach((mbe) => (
					Object.values(mbe.offsByPath).forEach((offs) => (
						offs.forEach(off => off())
					))
				));
				delete sysEnv.mbeByPathAndHash[path];
			}];
			const hasByHash = sysEnv.hasByPathAndHash[path] || {};
			const domByHash = sysEnv.domByPathAndHash[path] || {};
			const valByHash = sysEnv.valByPathAndHash[path] || {};
			const mbeByHash = sysEnv.valByPathAndHash[path] || {};
			const hash = getHash(a);
			if (hasByHash[hash]) {
				domByHash[hash].forEach(dom => currChildren.push(dom));
				return valByHash[hash];
			}
			const mbe = bindEnv.mkFresh();
			setBindEnv(mbe)(domClass);
			valByHash[hash] = domFA(a)(domClass);
			domByHash[hash] = getParentEnv(domClass).children;
			hasByHash[hash] = true;
			mbeByHash[hash] = mbe;
			sysEnv.valByPathAndHash[path] = valByHash;
			sysEnv.domByPathAndHash[path] = domByHash;
			sysEnv.hasByPathAndHash[path] = hasByHash;
			sysEnv.mbeByPathAndHash[path] = mbeByHash;
			domByHash[hash].forEach(dom => currChildren.push(dom));
			setBindEnv(bindEnv)(domClass);
			return valByHash[hash];
		}
	);
	getParentEnv(domClass).nextKey = null;
	return res;
};

// TODO I really think postRender should work on IDOM instead of
// VDOM but this is ok for now. this is because only client rendering
// needs the snabbdom dependency, so only it should use it.
const run = (SNABBDOM) => (frp) => (env) => (domF) => (postRender) => {
	const sysId = nextSysId;
	nextSysId++;
	const domClass = { sysId };
	const e_el_mount = frp.mkEvent();
	const e_render = frp.mkEvent();
	const requestRender = () => frp.push()(e_render)();
	const bindEnv = mkBindEnv(frp);
	const sysEnv = {
		nextStashId: 1,
		stashes: {},
		stashUsage: {},
		signals: {},
		idomByPath: {},
		e_el_mount,
		requestRender,
		domByPathAndHash: {},
		valByPathAndHash: {},
		hasByPathAndHash: {},
		mbeByPathAndHash: {}
	};
	setEnv(env)(domClass);
	setSysEnv(sysEnv)(domClass);
	setBindEnv(bindEnv)(domClass);
	setParentEnv(mkParentEnv(ROOT))(domClass);
	const { destroy, signal } = frp.s_buildImpl(frp.s_constImpl())();
	const resultSignal = s_bindDOMImpl_raw(frp)(signal)(() => domF)(domClass);
	const res = resultSignal.getVal();
	const off = frp.consume(
		() => () => {
			const { idomByPath, stashes, stashUsage } = getSysEnv(domClass);
			const rootIdom = idomByPath[ROOT_BIND];
			let fromIDOMtoVDOM;
			const toVDOMsObj = {
				[idomTypes.CreateElement] (idom) {
					const children = fromIDOMtoVDOM(idom.children);
					const hook = {
						insert ({ elm }) {
							// console.log('inserting:', idom.path, elm);
							// console.log('inserting', { path: idom.path });
							frp.push({ path: idom.path, elm })(e_el_mount)();
						},
						postpatch (ignore, { elm }) {
							// console.log('patching', { path: idom.path });
							frp.push({ path: idom.path, elm })(e_el_mount)();
						}
					};
					const data = { attrs: idom.attrs, hook };
					if (idom.key) {
						data.key = idom.key;
					}
					return [SNABBDOM.h(idom.tag, data, children)];
				},
				[idomTypes.Text] (idom) {
					return [idom.text];
				},
				[idomTypes.Bind] (idom) {
					const boundIdom = idomByPath[idom.path] || [];
					return fromIDOMtoVDOM(boundIdom);
				},
				[idomTypes.Stash] (idom) {
					const stashedIdom = idomByPath[stashes[idom.stashId]] || [];
					return fromIDOMtoVDOM(stashedIdom);
				}
			};
			const toVDOMs = (idom) => {
				const f = toVDOMsObj[idom.type] || (() => []);
				return f(idom);
			};
			fromIDOMtoVDOM = flatMap(toVDOMs);
			const vdom = fromIDOMtoVDOM(rootIdom);
			postRender(vdom);
			// console.log('-------- stats!! ----------');
			// console.log(Object.keys(idomByPath));
			// console.log(Object.keys(stashes));
			// console.log(stashUsage);
			Object.keys(stashUsage).forEach((stashId) => {
				if (stashUsage[stashId] > 0) { return; }
				delete idomByPath[stashes[stashId]];
				delete stashes[stashId];
				delete stashUsage[stashId];
			});
		}
	)(
		frp.throttle(10)(e_render)
	)();
	requestRender();
	const detach = () => {
		destroy();
		off();
		Object.values(bindEnv.offsByPath).forEach(offs => offs.forEach(off => off()));
	};
	return { res, detach };
};

// -- attachImpl :: forall e a. String -> e -> Effect Unit -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)
const attachImpl_raw = (SNABBDOM) => (frp) => (id) => (env) => (postRender) => (domF) => () => {
	let prev = document.getElementById(id);
	return run(SNABBDOM)(frp)(env)(domF)(
		(vdom) => {
			const curr = SNABBDOM.h('div', {}, vdom);
			SNABBDOM.patch(prev, curr);
			  prev = curr;
        postRender();
		}
	);
};

// -- toMarkupImpl :: forall e a. e -> (DOMClass e {} -> a) -> Effect (ImpulseSSR a)
const toMarkupImpl_raw = (SNABBDOM) => (frp) => (env) => (domF) => () => {
	let vdomsResolve;
	const vdomsPromise = new Promise((resolve) => { vdomsResolve = resolve; });
	const { res, detach } = run(SNABBDOM)(frp)(env)(domF)(vdomsResolve);
	return vdomsPromise.then((vdoms) => {
		let markup = "";
		const vdomProcess = (vdom) => {
			if (typeof vdom === 'string') {
				markup += vdom;
				return;
			}
			if (vdom.text && !vdom.sel) {
				markup += vdom.text;
				return;
			}

			const { children, data: { attrs }, sel } = vdom;
			let tag, id, className;
			const split1 = sel.split('#');
			const hasId = split1.length > 1;
			const split2 = hasId ?
				split1[1].split('.') :
				split1[0].split('.');
			const hasClass = split2.length > 1;
			tag = hasId ? split1[0] : split2[0];
			id = !hasId ? null : split2[0];
			className = !hasClass ? null : split2[1];
			markup += `<${tag}${!id ? '' : ` id="${id}"`}${!className ? '' : ` class="${className}"`}`;
			Object.keys(attrs).forEach((attr_key) => {
				let attr_val = attrs[attr_key];
				attr_val = typeof attr_val === 'string' ? `"${attr_val}"` : attr_val;
				markup += ` ${attr_key}=${attr_val}`;
			});
			markup += '>';
			children.forEach(vdomProcess);
			markup += `</${tag}>`;
		};
		vdoms.forEach(vdomProcess);
		detach();
		return { markup, res };
	});
};

///////////////////////////////////////////////////////////////////////////////

exports.createElementImpl_raw = createElementImpl_raw;
exports.e_collectImpl_raw = e_collectImpl_raw;
exports.s_bindDOMImpl_raw = s_bindDOMImpl_raw;
exports.attachImpl_raw = attachImpl_raw;
exports.toMarkupImpl_raw = toMarkupImpl_raw;

exports.keyedImpl = keyedImpl;
exports.envImpl = envImpl;
exports.withAlteredEnvImpl = withAlteredEnvImpl;
exports.textImpl = textImpl;
exports.e_consumeImpl_raw = e_consumeImpl_raw;
exports.e_emitImpl = e_emitImpl;
exports.s_useImpl = s_useImpl;
exports.d_stashImpl = d_stashImpl;
exports.d_applyImpl = d_applyImpl;
exports.d_memoImpl = d_memoImpl;

exports.stashRes = ({ res }) => res;
exports.attachRes = ({ res }) => res;
exports.detach = ({ detach }) => detach;
exports.ssr_then = promise => f => () => (
	promise.then(({ markup, res }) => f(markup)(res)())
);

exports.toJSAttrs = (fromMaybe) => (raw_attrs) => {
	const attrs = {};
	Object.keys(raw_attrs).forEach(attr => {
		const val = fromMaybe(null)(raw_attrs[attr]);
		if (val == null) {
			return;
		}
		attrs[attr] = val;
	});
	return attrs;
};

exports._effImpl = (eff) => () => eff();
