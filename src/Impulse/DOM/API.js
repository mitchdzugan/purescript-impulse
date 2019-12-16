"use strict";

const frp = require('ps-impulse-impl');
const h = require('snabbdom/h').default;
const snabbdom = require('snabbdom');
const patch = snabbdom.init([
	require('snabbdom/modules/class').default,
	require('snabbdom/modules/style').default,
	require('snabbdom/modules/attributes').default,
]);

const SNABBDOM = { h, patch };

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

const makeColl = () => {
	const coll = {
		es: {},
		nextEId: 1,
		getE () {
			return frp.join(Object.values(coll.es));
		}
	};
	coll.join = (e) => {
		const eId = coll.nextEId;
		coll.nextEId++;
		coll.es[eId] = e;
		return () => {
			delete coll.es[eId];
		};
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

const freshCollectors = (node) => {
	if (!node) {
		return {};
	}

	return node.addColl(freshCollectors(node.rest))(makeColl());
};

const mkBindEnv = () => ({
	offsByPath: {},
	used: {},
	collectors: {},
	collectorSpecs: null,
	renderOffs: [],
	refresh () {
		this.renderOffs.forEach(off => off());
		this.renderOffs = [];
		this.collectors = freshCollectors(this.collectorSpecs);
		this.collectorSpecs = this.collectorSpecs;
		this.used = {};
	},
	mkFresh () {
		const fresh = mkBindEnv();
		fresh.collectors = freshCollectors(this.collectorSpecs);
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
			`${step}${this.nextKey ? `.${this.nextKey}` : `.${this.nextUniqueKey}`} | ${this.path}`
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

const iCreateElement = (tag_, attrs_, children, path) => {
	let tag = tag_;
	const attrs = attrs_;
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
		type: idomTypes.CreateElement, tag, attrs, children, path
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
	preEnv.nextKey = key;
	const res = domF(domClass);
	const postEnv = getParentEnv(domClass);
	postEnv.nextKey = null;
	setParentEnv(postEnv)(domClass);
	return res;
};

// -- createElementImpl :: forall e c a. String -> Attrs -> (DOMClass e c -> a) -> DOMClass e c -> ImpulseEl a
const createElementImpl = (tag) => (attrs) => (domF) => (domClass) => {
	const { innerRes, children, uniquePath } = altered(env => prepareKeyForType(tag, false)(env).mkFresh(tag))(currParentEnvBySysId)(domClass)(
		() => {
			const innerRes = domF(domClass);
			const { children, uniquePath } = getParentEnv(domClass);
			return { innerRes, children, uniquePath };
		}
	);

	getParentEnv(domClass).children.push(
		iCreateElement(tag, attrs, children, uniquePath)
	);

	const { e_el_mount } = getSysEnv(domClass);
	const mkOn = (on) => {
		const filtered = frp.filter((mount) => { return mount.path === uniquePath; })(e_el_mount);
		return frp.flatMap(({ elm, path }) => {
			const _ons = elm._ons || {};
			if (_ons[on]) {
				return _ons[on];
			}
			const e = frp.mkEvent((pushSelf) => () => {
				const push = v => pushSelf(v)();
				elm.addEventListener(on, push);
				return () => elm.removeEventListener(on, push);
			});
			_ons[on] = e;
			elm._ons = _ons;
			return e;
		})(filtered);
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
const e_collectImpl = (addCollector) => (getCollector) => (domFE) => (domClass) => {
	const coll = makeColl();
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

// -- e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit
const e_emitImpl = (getCollector) => (e) => (domClass) => {
	const bindEnv = getBindEnv(domClass);
	bindEnv.renderOffs.push(getCollector(bindEnv.collectors).join(e));
	return;
};

// -- s_bindDOMImpl :: forall e c a b. FRP.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> FRP.Signal b
const s_bindDOMImpl = (s) => (domFS) => (domClass) => {
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
				const sysEnv = getSysEnv(domClass);
				destroy();
				off();
				Object.values(bindEnv.offsByPath).forEach(
					offs => offs.forEach(off => off())
				);
				bindEnv.offsByPath = {};
				bindEnv.renderOffs.forEach(off => off());
				bindEnv.renderOffs = [];
				delete prevBindEnv.offsByPath[path];
				delete sysEnv.idomByPath[path];
			};
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
	getParentEnv(domClass).nextKey = null;
	return signal;
};

// -- s_useImpl :: forall e c a. FRP.SigBuild a -> DOMClass e c -> FRP.Signal a
const s_useImpl = (sbf) => (domClass) => {
	const res = altered(env => prepareKeyForType('s_use')(env).mkFresh('s_use'))(currParentEnvBySysId)(domClass)(
		() => {
			const { path } = getParentEnv(domClass);
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
	const sysEnv = getSysEnv(domClass);
	const stashId = sysEnv.nextStashId;
	sysEnv.nextStashId++;
	sysEnv.stashUsage[stashId] = 0;
	return altered(env => prepareKeyForType(`d_stash.${stashId}`)(env).mkFresh(`d_stash.${stashId}`))(currParentEnvBySysId)(domClass)(
		() => {
			const res = domF(domClass);
			const { children, path } = getParentEnv(domClass);
			sysEnv.idomByPath[path] = children;
			sysEnv.stashes[stashId] = path;
			return { stashId, res };
		}
	);
};

// -- d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a
const d_applyImpl = ({ stashId, res }) => (domClass) => {
	const sysEnv = getSysEnv(domClass);
	sysEnv.stashUsage[stashId] += 1;
	const bindEnv = getBindEnv(domClass);
	bindEnv.renderOffs.push(() => { sysEnv.stashUsage[stashId] -= 1; });
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
			const { path } = getParentEnv(domClass);
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
};

// TODO I really think postRender should work on IDOM instead of
// VDOM but this is ok for now. this is because only client rendering
// needs the snabbdom dependency, so only it should use it.
const run = (env) => (domF) => (postRender) => {
	const sysId = nextSysId;
	nextSysId++;
	const domClass = { sysId };
	const e_el_mount = frp.mkEvent();
	const e_render = frp.mkEvent();
	const requestRender = () => frp.push()(e_render)();
	const bindEnv = mkBindEnv();
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
	const resultSignal = s_bindDOMImpl(signal)(() => domF)(domClass);
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
							frp.push({ path: idom.path, elm })(e_el_mount)();
						}
					};
					return [SNABBDOM.h(idom.tag, { attrs: idom.attrs, hook }, children)];
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

// -- attachImpl :: forall e a. String -> e -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)
const attachImpl = (id) => (env) => (domF) => () => {
	let prev = document.getElementById(id);
	return run(env)(domF)(
		(vdom) => {
			const curr = SNABBDOM.h('div', {}, vdom);
			SNABBDOM.patch(prev, curr);
			prev = curr;
		}
	);
};

// -- toMarkupImpl :: forall e a. e -> (DOMClass e {} -> a) -> Effect (ImpulseSSR a)
const toMarkupImpl = (env) => (domF) => () => {
	let vdomsResolve;
	const vdomsPromise = new Promise((resolve) => { vdomsResolve = resolve; });
	const { res, detach } = run(env)(domF)(vdomsResolve);
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

exports.keyedImpl = keyedImpl;
exports.envImpl = envImpl;
exports.withAlteredEnvImpl = withAlteredEnvImpl;
exports.createElementImpl = createElementImpl;
exports.textImpl = textImpl;
exports.e_collectImpl = e_collectImpl;
exports.e_emitImpl = e_emitImpl;
exports.s_bindDOMImpl = s_bindDOMImpl;
exports.s_useImpl = s_useImpl;
exports.d_stashImpl = d_stashImpl;
exports.d_applyImpl = d_applyImpl;
exports.d_memoImpl = d_memoImpl;
exports.attachImpl = attachImpl;
exports.toMarkupImpl = toMarkupImpl;

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
