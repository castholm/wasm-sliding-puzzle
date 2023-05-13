// Strings passed from WebAssembly can't be used in JavaScript as is and must first be decoded from UTF-8.
const utf8Decoder = new TextDecoder()

const $stderr = document.querySelector("pre#stderr") as HTMLPreElement

let wasmImports: WasmImports = null!

export type WasmImports = Readonly<{
  memory: WebAssembly.Memory
}>

export let init = (imports: WasmImports) => {
  if (wasmImports) return
  wasmImports = imports
}

export const wasmExports = {
  writeToStderr(stringPtr: number, stringLength: number): void {
    // Replicate writing to the terminal by appending text to a <pre> element.
    const string = utf8Decoder.decode(new Uint8Array(wasmImports.memory.buffer, stringPtr, stringLength))
    $stderr.textContent += string
  },
} as const
