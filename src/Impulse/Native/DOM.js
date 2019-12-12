"use strict";

const h = require('snabbdom/h').default;
const snabbdom = require('snabbdom');
const patch = snabbdom.init([
	require('snabbdom/modules/class').default,
	require('snabbdom/modules/style').default,
	require('snabbdom/modules/attributes').default,
]);

const isOneWord = s => typeof s === 'string' && !s.trim().includes(' ');
exports.vdomTag = (fromMaybe) => (path) => (pushMount) => (tag) => (raw_attrs) => (children) => {
	let ftag = tag;
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

	if (attrs.class && isOneWord(attrs.class)) {
		ftag += `.${attrs.class}`;
		delete attrs.class;
	}
	if (attrs.id && isOneWord(attrs.id)) {
		ftag += `#${attrs.id.trim()}`;
		delete attrs.id;
	}

	const hook = {
		insert ({ elm }) { pushMount(path)(elm)(); console.log('insert', elm); },
	};
	const data = { attrs, hook };
	return h(ftag, data, children);
};

exports.addListener = (el) => (on) => (pushSelf) => () => {
	el.addEventListener(on, pushSelf);
	return () => el.removeEventListener(on, pushSelf);
};

exports.vdomText = (text) => text;

let prev;
exports.patch = (id) => (vdom) => () => {
	if (!prev) {
		prev = document.getElementById(id);
	}
	const curr = h('div', {}, vdom);
	patch(prev, curr);
	prev = curr;
};

let nextSysId = 1;
const vdomTreeBySysId = {};
const currBindEnvBySysId = {};
const currElEnvBySysId = {};

// :: String -> DOM e c a -> DOM e c a
const keyedImpl = () => {};

// :: DOM e c a
const envImpl = () => {};
// :: (e1 -> e2) -> DOM e2 c a -> DOM e1 c a
const withEnvImpl = () => {};

// :: String -> Attrs -> DOM e c a -> DOM e c (ImpulseEl a)
const createElementImpl = () => {};
// :: String -> DOM e c Unit
const textImpl = () => {};

// :: ?
const e_listenImpl = () => {};
const e_emitImpl = () => {};

// :: Signal a -> (a -> DOM e c b) -> DOM e c (Signal b)
const s_bindDOMImpl = () => {};
// :: Effect (Signal a) -> DOM e c (Signal a)
const s_use = () => {};

// :: DOM e c a -> DOM e c (ImpulseStash a)
const d_stashImpl = () => {};
// :: ImpulseStash a -> DOM e c a
const d_applyImpl = () => {};
// :: Eq a => Hashable a => a -> (a -> DOM e c b) -> DOM e c b
const d_memoImpl = () => {};
