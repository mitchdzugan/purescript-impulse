var Main = require('./output/Test.Main');

const loaded = new Promise(resolve => { window.onload = resolve; });
let resolveRoot;
const root = new Promise(resolve => { resolveRoot = resolve; });
function main () {
	loaded.then(() => { Main.ui(); console.log('resolving root'); resolveRoot(); });
}

// HMR stuff
// For more info see: https://parceljs.org/hmr.html
if (module.hot) {
  module.hot.accept(function () {
		root.then(() => {
			const el = document.getElementById('test');
			if (el) {
				el.innerHTML = "<div id='app'></div>";
			}
			Main.ui();
		});
  });
}

console.log('Starting app');

if (document.readyState === "complete") {
	resolveRoot();
} else {
	main();
};
