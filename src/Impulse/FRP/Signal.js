"use strict";

exports.s_destroy_raw = (frp) => frp.s_destroy;
exports.s_subRes_raw = (frp) => frp.s_subRes;
exports.s_unsub_raw = (frp) => frp.s_unsub;
exports.s_sub_raw = (frp) => frp.s_sub;
exports.s_inst_raw = (frp) => frp.s_inst;
exports.s_changed_raw = (frp) => frp.s_changed;
exports.s_tagWith_raw = (frp) => frp.s_tagWith;

exports.s_fromImpl_raw = (frp) => frp.s_fromImpl;
exports.s_fmapImpl_raw = (frp) => frp.s_fmapImpl;
exports.s_constImpl_raw = (frp) => frp.s_constImpl;
exports.s_zipWithImpl_raw = (frp) => frp.s_zipWithImpl;
exports.s_flattenImpl_raw = (frp) => frp.s_flattenImpl;
exports.s_dedupImpl_raw = (frp) => frp.s_dedupImpl;

exports.s_buildImpl_raw = (frp) => frp.s_buildImpl;
exports.sigBuildToRecordImpl_raw = (frp) => frp.sigBuildToRecordImpl;
exports.s_builderInstImpl_raw = (frp) => frp.s_inst;
