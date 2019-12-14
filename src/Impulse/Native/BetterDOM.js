"use strict";

const frp = require('ps-impulse-impl');
const h = require('snabbdom/h').default;
const snabbdom = require('snabbdom');
const patch = snabbdom.init([
	require('snabbdom/modules/class').default,
	require('snabbdom/modules/style').default,
	require('snabbdom/modules/attributes').default,
]);

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
	const coll = { e: frp.never };
	coll.join = (e) => { coll.e = frp.join([coll.e, e]); };
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

const mkParentEnv = (path = '') => ({
	children: [],
	nextKey: null,
	countTakenByType: {},
	path,
	mkFresh (step) {
		return mkParentEnv(
			`${step}${this.nextKey ? `.${this.nextKey}` : ''} | ${this.path}`
		);
	}
});

const prepareKeyForType = (type) => (parentEnv) => {
	if (parentEnv.nextKey) {
		return parentEnv;
	}

	const myId = parentEnv.countTakenByType[type] || 0;
	parentEnv.countTakenByType[type] = myId + 1;
	parentEnv.nextKey = `${myId}`;
	return parentEnv;
};

const altered = (newVal) => altered_f(() => newVal);
const altered_f = (f_newVal) => (obj) => (domClass) => (f) => {
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

const iCreateElement = (tag, attrs, children, path) => ({
	tag, attrs, children, path,
	type: idomTypes.CreateElement
});
const iBind = (path) => ({ type: idomTypes.Bind, path });
const iStash = () => ({ type: idomTypes.Stash });
const iText = (text) => ({ type: idomTypes.Text, text });

///////////////////////////////////////////////////////////////////////////////

const ROOT = 'ROOT';
const ROOT_BIND = `s_bind.0 | ${ROOT}`;

// -- envImpl :: forall e c. DOMClass e c -> e
const envImpl = getEnv;

// -- withAlteredEnvImpl :: forall e1 e2 c a. (e1 -> e2) -> (DOMClass e2 c -> a) -> DOMClass e1 c -> a
const withAlteredEnvImpl = (f) => (domF) => (domClass) => (
	altered_f(f)(currEnvBySysId)(domClass)(
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
	const { innerRes, children, path } = altered_f(env => env.mkFresh(tag))(currParentEnvBySysId)(domClass)(
		() => {
			const innerRes = domF(domClass);
			const { children, path } = getParentEnv(domClass);
			return { innerRes, children, path };
		}
	);

	getParentEnv(domClass).children.push(
		iCreateElement(tag, attrs, children, path)
	);

	const { e_el_mount } = getSysEnv(domClass);
	const mkOn = (on) => {
		const filtered = frp.filter((mount) => { console.log({ mount, path }); return mount.path === path; })(e_el_mount);
		return frp.flatMap(({ elm }) => {
			const _ons = elm._ons || {};
			if (_ons[on]) {
				return _ons[on];
			}
			const e = frp.mkEvent((pushSelf) => () => {
				const push = v => {
					console.log('AY YO V', v);
					pushSelf(v)();
				};
				elm.addEventListener('click', push);
				return () => elm.removeEventListener('click', push);
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
	return altered_f(modBindEnv)(currBindEnvBySysId)(domClass)(
		() => {
			const { res } = frp.preempt(({ e }) => e)((e) => {
				const res = domFE(e)(domClass);
				return { res, e: coll.e };
			});
			return res;
		}
	);
};

// -- e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit
const e_emitImpl = (getCollector) => (e) => (domClass) => {
	const bindEnv = getBindEnv(domClass);
	getCollector(bindEnv.collectors).join(e);
	return;
};

// -- s_bindDOMImpl :: forall e c a b. Sig.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> Sig.Signal b
const s_bindDOMImpl = (s) => (domFS) => (domClass) => {
	const e_res = frp.mkEvent();
	const e_collectors = frp.mkEvent();
	let isFirst = true;
	const { signal, path } = altered_f(env => prepareKeyForType('s_bind')(env).mkFresh('s_bind'))(currParentEnvBySysId)(domClass)(
		() => {
			const prevBindEnv = getBindEnv(domClass);
			const bindEnv = prevBindEnv.mkFresh();
			const env = getEnv(domClass);
			const parentEnv = getParentEnv(domClass);
			const { path } = parentEnv;
			const {
				off, res: { res, collectors }
			} = frp.s_sub((val) => () => {
				parentEnv.children = [];
				setEnv(env)(domClass);
				bindEnv.used = {};
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
				}
				isFirst = false;
				return {
					res, collectors: bindEnv.collectors
				};
			})(s)();
			const { destroy, signal } = frp.s_buildImpl(frp.s_fromImpl(e_res)(res))();
			const shutdown = () => {
				destroy();
				off();
				Object.values(bindEnv.offsByPath).forEach(off => off());
			};
			const offs = prevBindEnv.offsByPath[path] || [];
			offs.push(shutdown);
			prevBindEnv.used[path] = true;
			setBindEnv(prevBindEnv)(domClass);
			setEnv(env)(domClass);
			const getCollectors = prevBindEnv.getCollectorsArray();
			getCollectors.forEach((getCollector) => {
				getCollector(prevBindEnv.collectors).join([
					getCollector(collectors).e,
					frp.flatMap(colls => getCollector(colls).e)(e_collectors)
				]);
			});
			return { signal, path };
		}
	);
	getParentEnv(domClass).children.push(iBind(path));
	getParentEnv(domClass).nextKey = null;
	return signal;
};

// -- s_useImpl :: forall e c a. Sig.SigBuild a -> DOMClass e c -> Sig.Signal a
const s_useImpl = (sbf) => (domClass) => {
	const res = altered_f(env => prepareKeyForType('s_use')(env).mkFresh('s_use'))(currParentEnvBySysId)(domClass)(
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
			offs.push(destroy);
			bindEnv.offsByPath[path] = offs;
			return signal;
		}
	);
	getParentEnv(domClass).nextKey = null;
	return res;
};

// -- d_stashImpl :: forall e c a. (DOMClass e c ->  a) -> DOMClass e c -> ImpulseStash a
const d_stashImpl = () => {};

// -- d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a
const d_applyImpl = () => {};

// -- d_memoImpl :: forall e c a b. Eq a => H.Hashable a => a -> (a -> DOMClass e c -> b) -> DOMClass e c -> b
const d_memoImpl = () => {};

// -- attachImpl :: forall e a. String -> e -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)
const attachImpl = (id) => (env) => (domF) => () => {
	let prev = document.getElementById(id);
	const sysId = nextSysId;
	nextSysId++;
	const domClass = { sysId };
	setEnv(env)(domClass);
	const e_el_mount = frp.mkEvent();
	const e_render = frp.mkEvent();
	const requestRender = () => frp.push()(e_render)();
	setSysEnv({ signals: {}, idomByPath: {}, e_el_mount, requestRender })(domClass);
	const bindEnv = mkBindEnv();
	setBindEnv(bindEnv)(domClass);
	setParentEnv(mkParentEnv(ROOT))(domClass);
	const { destroy, signal } = frp.s_buildImpl(frp.s_constImpl())();
	const resultSignal = s_bindDOMImpl(signal)(() => domF)(domClass);
	const res = resultSignal.getVal();
	const off = frp.consume(
		() => () => {
			const { idomByPath } = getSysEnv(domClass);
			const rootIdom = idomByPath[ROOT_BIND];
			let fromIDOMtoVDOM;
			const toVDOMObjs = {
				[idomTypes.CreateElement] (idom) {
					const children = fromIDOMtoVDOM(idom.children);



					let tag = idom.tag;
					const attrs = idom.attrs;

					const baseClass = attrs.class || '';
					const otherClass = attrs.className || '';
					const fullClass = `${baseClass} ${otherClass}`;
					delete attrs.className;
					attrs.class = fullClass.trim();

					if (attrs.class && isOneWord(attrs.class)) {
						tag += `.${attrs.class}`;
						delete attrs.class;
					}
					if (attrs.id && isOneWord(attrs.id)) {
						tag += `#${attrs.id.trim()}`;
						delete attrs.id;
					}

					const hook = {
						insert ({ elm }) {
							elm._ons = {};
							frp.push({ path: idom.path, elm })(e_el_mount)();
						}
					};
					const data = { attrs, hook };













					return [h(tag, data, children)];
				},
				[idomTypes.Text] (idom) {
					return [idom.text];
				},
				[idomTypes.Bind] (idom) {
					const boundIdom = idomByPath[idom.path] || [];
					return fromIDOMtoVDOM(boundIdom);
				},
				[idomTypes.Stash] () {
					return [];
				}
			};
			const toVDOMs = (idom) => {
				const f = toVDOMObjs[idom.type] || (() => []);
				return f(idom);
			};
			fromIDOMtoVDOM = flatMap(toVDOMs);
			const vdom = fromIDOMtoVDOM(rootIdom);
			const curr = h('div', {}, vdom);
			patch(prev, curr);
			prev = curr;
		}
	)(
		frp.throttle(100)(e_render)
	)();
	requestRender();
	const detach = () => {
		destroy();
		off();
		Object.values(bindEnv.offsByPath).forEach(off => off());
	};
	return { res, detach };
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
exports.elRes = ({ innerRes }) => innerRes;
exports._effImpl = eff => () => eff();

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

exports.onClick = ({ mkOn }) => mkOn('click');
exports.onDoubleClick = ({ mkOn }) => mkOn('doubleclick');
exports.onChange = ({ mkOn }) => mkOn('change');
exports.onKeyUp = ({ mkOn }) => mkOn('keyup');
exports.onKeyDown = ({ mkOn }) => mkOn('keydown');
exports.onKeyPress = ({ mkOn }) => mkOn('keypress');
exports.onMouseDown = ({ mkOn }) => mkOn('mousedown');
exports.onMouseEnter = ({ mkOn }) => mkOn('mouseenter');
exports.onMouseLeave = ({ mkOn }) => mkOn('mouseleave');
exports.onMouseMove = ({ mkOn }) => mkOn('mousemove');
exports.onMouseOut = ({ mkOn }) => mkOn('mouseout');
exports.onMouseOver = ({ mkOn }) => mkOn('mouseover');
exports.onMouseUp = ({ mkOn }) => mkOn('mouseup');
exports.onTransitionEnd = ({ mkOn }) => mkOn('transitionend');
exports.onScroll = ({ mkOn }) => mkOn('scroll');