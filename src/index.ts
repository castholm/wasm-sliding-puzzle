import * as Puzzle from "./Puzzle.ts"
import * as Stderr from "./Stderr.ts"

const wasmImports = {
  puzzle: Puzzle.wasmExports,
  stderr: Stderr.wasmExports,
} as const

// In our 'build.zig' file we have configured esbuild to replace all uses of this constant with the filename of the
// compiled WebAssembly artifact.
declare const __WASM_ARTIFACT_FILENAME: string

const instantiateResult = await WebAssembly.instantiateStreaming(fetch(__WASM_ARTIFACT_FILENAME), wasmImports)

const wasmExports = instantiateResult.instance.exports as Puzzle.WasmImports & Stderr.WasmImports

Puzzle.init(wasmExports)
Stderr.init(wasmExports)
