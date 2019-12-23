# Gentle Introduction To `impulse` for javascript developers
## text (s)

```javascript
const ui1 = (I) => {
	I.text("Hel");
	I.text("lo ";
	I.text("wor");
	I.text("ld!");
};
```
```html
<div id="app">Hello World!</div>
```
## getEnv(prop) => val / upsertEnv(prop, val, drawChildren)
Impulse maintains a readonly environment. It can be accessed with `getEnv` and while the current environment can not be modified, we can run other components inside a modified environment using `upsertEnv`. 
```javascript
const ui1 = (I) => {
	I.upsertEnv('a', 1, (I) => {
		I.upsertEnv('a', 2, (I) => {
			const a = I.getEnv('a');
			I.text(`Inner val: ${a}.`);
		});
		const a = I.getEnv('a');
		I.text(`Outer val: ${a}.`);
	});
};
```
```html
<div id="app">Inner val: 2. Outer val: 1</div>
```

## s_bindDOM(signal, drawChildrenFromVal)

```javascript
const s_timer = frp.reduce(count => count + 1, 0, frp.timer(1000));
const ui2 = (I) => {
	I.s_bindDOM(s_timer, (timer) => (I) => {
		I.text(`${timer}`);
	});
	I.text(" second(s) elapsed.");
};
```
```html
<div id="app">_N_ second(s) elapsed.</div>
```
where `_N_` is always updating to be the number of seconds since the signal was created.

## s_use(buildSignal)
s_use lets you create a signal whose lifetime is tied to the component it is used in. Looking at this example very similar to the above:

```javascript
const ui3 = (I) => {
	const s_timer = I.s_use(
		(S) => S.reduce_e(count => count + 1, 0, frp.timer(1000))
	);
	I.s_bindDOM(s_timer, (timer) => (I) => {
		I.text(`${timer}`);
	});
	I.text(" second(s) elapsed.");
};
```
```html
<div id="app">_N_ second(s) elapsed.</div>
```
where `_N_` is always updating to be the number of seconds **since the component was mounted**.

Note the "since the component was mounted" for this example compared to "since the signal was created" in the previous example. In this example the signal gets created on mount, garbage collected on unmount and rebuilt on future remounts. In the previous example the signal would keep updating as long as the application was running (unless some action was taken to explicitly shut if off) even if the component was not mounted.

`s_use` allows you to chain several signal manipulating actions together, and the framework will bundle all of their shutdown handlers into one function that it calls on unmount.

```javascript
const ui4 = (I) => {
	const s_timer = I.s_use(
		(S) => S.reduce_e(count => count + 1, 0, frp.timer(1000))
	);
	const s_timerHalfTime = I.s_use(
		(S) => {
			// s_odds will be automatically garbage collected
			// at the same time as s_timerHalfTime
			const s_odds = S.filter(i => i % 2 === 1, s_timer);
			return S.fmap(i => i / 2, s_odds);
		}
	);
	I.s_bindDOM(s_timer, (timer) => (I) => {
		I.text(`${timer}`);
	});
	I.text(" tick(s) normal speed. ");
	I.s_bindDOM(s_timerHalfTime, (timerHalfTime) => (I) => {
		I.text(`${timerHalfTime}`);
	});
	I.text(" tick(s) half speed.");
};
```
```html
<div id="app">_N_ tick(s) normal speed. _N2_ tick(s) half speed.</div>
```
where `_N_` is incrementing every second since the company was mounted and `_N2` is  incrementing every 2 seconds since the component was mounted.

## createElement (tag, attrs, drawChildren) => ImpulseEl
Draws a DOM element `tag` in the next place in the DOM with its children defined by `drawChildren` being a function from `ImpulseContext` to any value. The return value is an `ImpulseEl` which contains a set of events for the drawn DOM element (ie `onClick`, `onHover`, `onChange` etc.) as well as the return value of the `drawChildren` function.

All tags have a corresponding function that is more succinct version of `createElement` ie:
```javascript
I.button = (attrs, drawChildren) => I.createElement('button', attrs, drawChildren);
I.div = (attrs, drawChildren) => I.createElement('div', attrs, drawChildren);
// ... etc
```
We can use the events returned by `createElement` to build and bind to signals.
```javascript
const ui100 = (I) => {
	const d_button = I.button({}, (I) => I.text("Click Me!"));
	const s_clicks = I.s_use(
		(S) => S.reduce_e((agg, onclickevent) => agg + 1, 0, d_button.onClick)
	);
	I.s_bindDOM(s_clicks, (I) => (clicks) => {
		I.span({}, (I) => { I.text(`You clicked ${clicks} times`); });
	});
};
```
```html
<div id="app">
	<button>Click Me!</button>
	<span>You clicked _N_ times</span>
</div>
```
where `_N_` is the always updating to be the number of times the button was clicked.

This is the first we are seeing of our UI components being able to return values but it is a very powerful concept and is what allows us to build truly reusable components that do not need to rely on additional 3rd party state management solutions. For example consider a Color Picker component that allows a user to drag a selector around a color wheel to pick the color they want. A well designed implementation of this in Impulse would draw the color picker on screen and return the signal representing the current selected color as well as an event representing any time the user hit enter while the picker was in focus or they clicked an "accept" button that the component rendered. This will be easy to slot into any impulse application because we can just use simple functions to transform and filter the returned signal and event to fit our specific types and use case.

## e_collect(prop, drawChildrenFromEvent) / e_emit(prop, event)
`e_collect` creates an event out of all of the `event` that are `e_emit`'ed to `prop` during the execution of `drawChildrenFromEvent`. `drawChildrenFromEvent` is ran by preemptively creating that resulting event and supplying it to `drawChildrenFromEvent`
```javascript
const ui12 = (I) => {
	I.e_collect('counter', (e_counter) => (I) => {
		const s_counter = I.s_use(
			(S) => S.reduce_e((agg, change) => agg + change, 0, e_counter)
		);
		const d_button1 = I.button({}, (I) => (
			I.text('Click for (+1)')
		));
		I.e_emit('counter', frp.fmap(() => 1, d_button1.onClick);
		I.s_bindDOM(s_counter, (counter) => (I) => {
			I.span({}, (I) => (
				I.text(`Points: ${counter}`)
			));
		});
		const d_button2 = I.button({}, (I) => (
			I.text('Click for (-1)')
		));
		I.e_emit('counter', frp.fmap(() => (-1), d_button2.onClick);
	});
};
```
```html
<div id="app">
	<button>Click for (+1)</button>
	<span>Points: _N_</span>
	<button>Click for (-1)</button>
</div>
```
where `_N_` is the always updating to be the number of times the top button was clicked minus the number of times the bottom button was clicked.
## e_collectAndReduce(prop, reducer, init, drawChildren)
`e_collectAndReduce` is a helper that uses an `e_collect` call, reducers the event to a signal based on `reducer` and `init` and then uses `upsertEnv` to stick that signal into the environment at `prop`. Compare this example to the previous.
```javascript
const changeScoreButton = (change, message) => (I) => {
	const d_button = I.button({}, (I) => (
		I.text(message)
	));
	I.e_emit('counter', frp.fmap(() => change, d_button.onClick);
};
const displayScore = (I) => {
	const s_count = I.getEnv('counter');
	I.s_bindDOM(s_counter, (counter) => (I) => {
		I.span({}, (I) => (
			I.text(`Points: ${counter}`)
		));
	});
};
const ui12 = (I) => {
	I.e_collectAndReduce('counter',(agg, change) => agg + change, 0, (I) => {
		changeScoreButton(  1 , 'Click for (+1)')(I);
		displayScore(I);
		changeScoreButton((-1), 'Click for (-1)')(I);
	});
};
```
```html
<div id="app">
	<button>Click for (+1)</button>
	<span>Points: _N_</span>
	<button>Click for (-1)</button>
</div>
```
where `_N_` is the always updating to be the number of times the top button was clicked minus the number of times the bottom button was clicked.

In this example we have split up the rendering into a few subcomponents. Notice that the `changeScoreButton` can be used anywhere that there is some `e_collect` above it listening to `Integer` events on `counter` and likewise `displayScore` can be used anywhere where there is some `upsertEnv` above it of a `Signal` of `Integer`s at `counter`. In purescript we will be able to represent and enforce these constraints in the type system.

## d_stash(drawChildren) => ImpulseStash / d_apply(impulseStash)
```javascript

```
<!--stackedit_data:
eyJoaXN0b3J5IjpbOTM4NDEwOTk4LDEwMzE3NjkyNDldfQ==
-->