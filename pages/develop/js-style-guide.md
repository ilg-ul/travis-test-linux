---
layout: page
permalink: /develop/js-style-guide/
title: JavaScript Style Guide
author: Liviu Ionescu
---

## From [_npm's "funny" coding style_](https://docs.npmjs.com/misc/coding-style)

### Line length

Keep lines shorter than **80** characters

### Indentation

Indentation is **two spaces**

### Curly braces

Curly braces belong on the same line

``` js
const f = function () {
  while (foo) {
    bar()
  }
}
```

### Semicolons

Don't use semicolons, except when required; for example to prevent the expression from being interpreted as a function call or property access, respectively.

``` js
;(x || y).doSomething()
;[a, b, c].forEach(doSomething)

```

### Comma first

Put the **comma at the start** of the next line, directly below the token that starts the list

``` js
const magicWords = [ 'abracadabra'
                 , 'gesundheit'
                 , 'ventrilo'
                 ]
  , spells = { 'fireball' : function () { setOnFire() }
             , 'water' : function () { putOut() }
             }
  , a = 1
  , b = 'abc'
  , etc
  , somethingElse
```

### Quotes

Use single quotes for strings except to avoid escaping

``` js
const ok = 'String contains "double" quotes'
const alsoOk = "String contains 'single' quotes or apostrophe"
const paramOk = `Back quotes string with ${parameter}`
```

### Whitespaces

Put a single space in front of `(` for anything other than a function call

### Functions

Use named functions.

- always create a new `Error` object with your message (`new Error('msg')`)
- logging is done using the [`npmlog`](https://github.com/npm/npmlog) utility

### Case, naming, etc

- use **lowerCamelCase** for multiword identifiers when they refer to objects, functions, methods, properties, or anything not specified in this section
- use **UpperCamelCase** for class names (things that you'd pass to "new")
- use **all-lower-hyphen-css-case** for multiword filenames and config keys
- use named functions, they make stack traces easier to follow
- use **CAPS\_SNAKE\_CASE** for constants, things that should never change and are rarely used

### null, undefined, false

- boolean variables and functions should always be either `true` or `false`
- when something is intentionally missing or removed, set it to `null`
- don't set things to `undefined`
- boolean objects are verboten

### Exceptions

When using callbacks, never to ever ever throw anything. It's worse than useless. Just send the error message back as the first argument to the callback.

## From [node.js modules](https://nodejs.org/dist/latest-v6.x/docs/api/modules.html)

### Modules

To add functions and objects to the root of your module, you can add them to the special `exports` object:

``` js
const PI = Math.PI
exports.area = (r) => PI * r * r
exports.circumference = (r) => 2 * PI * r
```

If you want the root of your module's export to be a function (such as a constructor) or if you want to export a complete object in one assignment instead of building it one property at a time, assign it to `module.exports` instead of `exports`.

``` js
const square = require('./square.js')
const mySquare = square(2)
console.log(`The area of my square is ${mySquare.area()}`)

// assigning to exports will not modify module, must use module.exports
module.exports = (width) => {
  return {
    area: () => width * width
  }
}
```

### Accessing the main module

When a file is run directly from Node.js, require.main is set to its module. That means that you can determine whether a file has been run directly by testing

``` js
require.main === module
```

### Caching

Modules are cached after the first time they are loaded. This means (among other things) that every call to require('foo') will get exactly the same object returned, if it would resolve to the same file.

Multiple calls to require('foo') may not cause the module code to be executed multiple times.

### The module wrapper

Before a module's code is executed, Node.js will wrap it with a function wrapper that looks like the following:

``` js
(function (exports, require, module, __filename, __dirname) {
  // Your module code actually lives in here
});
```

In each module, the module free variable is a reference to the object representing the current module. For convenience, `module.exports` is also accessible via the exports module-global. module isn't actually a global but rather local to each module.

The `module.exports` object is created by the Module system. Sometimes this is not acceptable; many want their module to be an instance of some class. To do this, assign the desired export object to `module.exports`. Note that assigning the desired object to `exports` will simply rebind the local exports variable, which is probably not what you want to do.

Note that assignment to `module.exports` must be done immediately. It cannot be done in any callbacks.

The `exports` variable that is available within a module starts as a reference to `module.exports`. As with any variable, if you assign a new value to it, it is no longer bound to the previous value.

As a guideline, if the relationship between `exports` and `module.exports` seems like magic to you, ignore `exports` and only use `module.exports`.

## From _Understanding ECMAScript 6_

### Block bindings

Use `const` by default, and only use `let` when you know a variable’s value needs to change

### Functions

Use default parameters.

``` js
const makeRequest = function (url, timeout = 2000, callback = function() {}) {
  // the rest of the function
}

const add = function (first, second = getValue(first)) {
  return first + second
}
```

Use _rest_ parameters.

``` js
const pick = function (object, ...keys) {
  let result = Object.create(null)
  for (let i = 0, len = keys.length; i < len; i++) {
    result[keys[i]] = object[keys[i]]
  }
  return result
}
```

The `Function` constructor.

``` js
var add = new Function("first", 'second = first',
                 'return first + second')
console.log(add(1, 1))     // 2
console.log(add(1))        // 2
```

JavaScript has two different internal-only methods for functions: `[[Call]]` and `[[Construct]]`. When a function is called without new, the `[[Call]]` method is executed, which executes the body of the function as it appears in the code. When a function is called with new, that’s when the `[[Construct]]` method
is called. The `[[Construct]]` method is responsible for creating a new object, called the instance, and then executing the function body with this set to the instance. Functions that have a `[[Construct]]` method are called constructors.

``` js
const Person = function (name) {
  if (this instanceof Person) {
    this.name = name
  } else {
    throw new Error('You must use new with Person.')
  }
}
var person = new Person('Nicholas')
var notAPerson = Person.call(person, 'Michael')    // works!
```

Block-level functions

``` js
'use strict';

if (true) {
  console.log(typeof doSomething) // throws an error
  let doSomething = function () {
    // empty
  }
  doSomething()
}
console.log(typeof doSomething)
```

Arrow functions are functions defined with a new syntax that uses an arrow (`=>`)

- **No this, super, arguments, and new.target bindings** The values of `this`, `super`, arguments, and new.target inside the function are defined by the closest containing non-arrow function
- **Cannot be called with new** Arrow functions do not have a [[Construct]] method and therefore cannot be used as constructors. Arrow functions throw an error when used with new.
- **No prototype** Because you can’t use new on an arrow function, there’s no need for a prototype. The prototype property of an arrow function doesn’t exist.
- **Can’t change this** The value of this inside the function can’t be changed. It remains the same throughout the entire life cycle of the function.
- **No arguments object** Because arrow functions have no arguments binding, you must rely on named and rest parameters to access function arguments.
- **No duplicate named parameters** Arrow functions cannot have duplicate named parameters in strict or non-strict mode, as opposed to non-arrow functions, which cannot have duplicate named parameters only in strict mode.

``` js
let sum = (num1, num2) => num1 + num2
// effectively equivalent to:
let sum = function(num1, num2) {
  return num1 + num2
};
```

### Enhanced Object Functionality

It’s now possible to modify an object’s prototype after it’s been created thanks to ECMAScript 6’s `Object.setPrototypeOf()` method.

In addition, you can use the `super` keyword to call methods on an object’s prototype. The `this` binding inside a method invoked using `super` is set up to automatically work with the current value of `this`.


