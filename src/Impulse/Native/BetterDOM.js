"use strict";

const frp = require('ps-impulse-impl');
const h = require('snabbdom/h').default;
const snabbdom = require('snabbdom');
const patch = snabbdom.init([
	require('snabbdom/modules/class').default,
	require('snabbdom/modules/style').default,
	require('snabbdom/modules/attributes').default,
]);

///////////////////////////////////////////////////////////////////////////////

let nextSysId = 1;
const idomTreeBySysId = {};
const currBindEnvBySysId = {};
const currParentEnvBySysId = {};
const currEnvBySysId = {};

const getSys = (obj) => ({ sysId }) => obj[sysId];
const setSys = (obj) => (value) => ({ sysId }) => { obj[sysId] = value; };

const getBindEnv = getSys(currBindEnvBySysId);
const setBindEnv = setSys(currBindEnvBySysId);

const getParentEnv = getSys(currParentEnvBySysId);
const setParentEnv = setSys(currParentEnvBySysId);

const getEnv = getSys(currEnvBySysId);
const setEnv = setSys(currEnvBySysId);

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

	return { innerRes, path };
};

// -- textImpl :: forall e c. String -> DOMClass e c -> Unit
const textImpl = (text) => (domClass) => {
	getParentEnv(domClass).children.push(
		iText(text)
	);
	return;
};

// -- e_collectImpl :: forall e c1 c2 a b. (c1 -> Collector a -> c2) -> (c2 -> Collector a) -> (FRP.Event a -> DOMClass e c2 -> b) -> DOMClass e c1 -> b
const e_collectImpl = (addCollector) => (getCollector) => (domFE) => (domClass) => {};

// -- e_emitImpl :: forall e c a. (c -> Collector a) -> FRP.Event a -> DOMClass e c -> Unit
const e_emitImpl = (getCollector) => (e) => (domClass) => {};

// -- s_bindDOMImpl :: forall e c a b. Sig.Signal a -> (a -> DOMClass e c -> b) -> DOMClass e c -> Sig.Signal b
const s_bindDOMImpl = () => {};

// -- s_useImpl :: forall e c a. Effect (Sig.Signal a) -> DOMClass e c -> Sig.Signal a
const s_useImpl = () => {};

// -- d_stashImpl :: forall e c a. (DOMClass e c ->  a) -> DOMClass e c -> ImpulseStash a
const d_stashImpl = () => {};

// -- d_applyImpl :: forall e c a. ImpulseStash a -> DOMClass e c -> a
const d_applyImpl = () => {};

// -- d_memoImpl :: forall e c a b. Eq a => H.Hashable a => a -> (a -> DOMClass e c -> b) -> DOMClass e c -> b
const d_memoImpl = () => {};

// -- attachImpl :: forall e a. String -> e -> (DOMClass e {} -> a) -> Effect (ImpulseAttachment a)
const attachImpl = (id) => (env) => (domF) => () => {
	const sysId = nextSysId;
	nextSysId++;
	const domClass = { sysId };
	setEnv(env)(domClass);
	setParentEnv(mkParentEnv(ROOT))(domClass);
	return domF(domClass);
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
exports.elRes = () => {};
