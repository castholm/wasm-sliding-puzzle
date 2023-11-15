# wasm-sliding-puzzle

Very simple example project showcasing how to write a simple interactive web app in Zig and TypeScript.

[Online demo](https://castholm.github.io/wasm-sliding-puzzle)

![Screenshot](screenshot.png)

Zig source code is compiled to WebAssembly using the [Zig compiler](https://ziglang.org/). TypeScript "glue code" is
compiled to JavaScript and bundled using [esbuild](https://esbuild.github.io/) (CSS is also bundled using esbuild). All
build steps are orchestrated using `zig build`.

Everything is implemented "vanilla" using stock Web APIs without any frameworks or runtime dependencies.

If you're familiar with traditional web technology and you're curious about Zig and WebAssembly but don't know where to
start I hope this might serve as a useful starting point for small experiments. Likewise, if you're already comfortable
with Zig but don't know how to get your code running in browsers this might be a helpful reference.

## Building/running

Requires a recent nightly master build of the [Zig compiler](https://ziglang.org/download/#release-master) (last tested
with 0.12.0-dev.1595+70d8baaec) and [npm](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm) (or some
other equivalent package manager).

After cloning this repo but before doing anything else, run `npm install` from the repository's root directory to
install esbuild and the TypeScript compiler.

Then, run `zig build run` to build and bundle everything and launch a local dev server that serves the results.

By default, `zig build` will instruct esbuild to output JavaScript/CSS source maps. Passing a release optimization
option like `-Doptimize=ReleaseSmall` will (in addition to optimizing the WebAssembly output) instruct esbuild to minify
all JavaScript/CSS output.

Web output targets the most recent set of browser features and assumes you're using a modern web browser.

Please open an issue if the project no longer builds with the most recent version of the Zig compiler and I'll try to
update it as soon as possible.
