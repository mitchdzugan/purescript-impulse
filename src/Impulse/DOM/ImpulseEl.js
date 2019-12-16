"use strict";

exports.elRes = ({ innerRes }) => innerRes;
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
exports.targetImpl = just => nothing => e => () => (
	e.target ? just(e.target) : nothing
);
