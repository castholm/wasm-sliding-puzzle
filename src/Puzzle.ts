const SIZE = 4
const CELL_COUNT = SIZE * SIZE
const CELLS_FIELD_OFFSET = 0
const IS_SOLVED_FIELD_OFFSET = CELL_COUNT

const $puzzle = document.querySelector("ul#puzzle") as HTMLUListElement
const $newPuzzle = document.querySelector("button#new-puzzle") as HTMLButtonElement

let wasmImports: WasmImports = null!

export type WasmImports = Readonly<{
  memory: WebAssembly.Memory
  newPuzzle(seed: number): void
  moveTile(cellIndex: number): void
}>

export let init = (imports: WasmImports) => {
  if (wasmImports) return
  wasmImports = imports

  for (let i = 0; i < CELL_COUNT; i++) {
    const $cell = $puzzle.children.item(i) as HTMLLIElement
    $cell.addEventListener("click", e => {
      e.preventDefault()
      wasmImports.moveTile(i)
    })
  }

  $newPuzzle.addEventListener("click", e => {
    e.preventDefault()
    // Random 32-bit unsigned integer.
    const seed = ~~(Math.random() * 2 ** 32)
    wasmImports.newPuzzle(seed)
  })

  // Automatically generate an initial puzzle configuration after everything has been initialized.
  queueMicrotask(() => $newPuzzle.click())
}

export const wasmExports = {
  updatePuzzleDisplay: (puzzlePtr: number): void => {
    // Pointers passed from WebAssembly are represented as plain numbers in JavaScript. To obtain the actual field data
    // of the 'Puzzle' struct we must wrap the chunk of WebAssembly memory the pointer points to in typed arrays.
    const puzzleCells = new Uint8Array(wasmImports.memory.buffer, puzzlePtr + CELLS_FIELD_OFFSET, CELL_COUNT)
    const isSolved = new Uint8Array(wasmImports.memory.buffer, puzzlePtr + IS_SOLVED_FIELD_OFFSET, 1)
    for (let i = 0; i < CELL_COUNT; i++) {
      const $cell = $puzzle.children.item(i)!
      const tileNumber = puzzleCells[i]
      $cell.textContent = !!isSolved[0]! ? "😎" : String(tileNumber)
      $cell.classList.toggle("empty", tileNumber === 0)
    }
  }
} as const
