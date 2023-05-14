const std = @import("std");

// By marking this struct as 'extern' we can use it in 'export'/'extern' functions.
pub const Puzzle = extern struct {
    pub const size = 4;
    pub const cell_count = size * size;

    cells: [cell_count]u8,
    is_solved: bool,

    // This struct will be exposed to JavaScript as a sequence of raw bytes (without any means of
    // automatically obtaining offsets of different fields) so we use a comptime block here to
    // verify that our assumptions about each field's offset are correct.
    comptime {
        std.debug.assert(@offsetOf(Puzzle, "cells") == 0);
        std.debug.assert(@offsetOf(Puzzle, "is_solved") == cell_count);
    }

    pub const solved: Puzzle = .{
        .cells = .{
            1,  2,  3,  4,
            5,  6,  7,  8,
            9,  10, 11, 12,
            13, 14, 15, 0,
        },
        .is_solved = true,
    };

    pub const InitError = error{
        RandomizationAttemptQuotaExceeded,
    };

    /// Initializes the puzzle instance to a random configuration.
    pub fn init(
        self: *Puzzle,
        rng: std.rand.Random,
        randomization_attempt_quota: usize,
    ) InitError!void {
        var new = solved;

        for (0..randomization_attempt_quota) |_| {
            // Shuffle everything but the last cell (the empty cell).
            rng.shuffle(u8, new.cells[0 .. cell_count - 1]);
            if (new.isSolvable() and !new.isSolved()) break;
        } else {
            return error.RandomizationAttemptQuotaExceeded;
        }
        new.is_solved = false;

        self.* = new;
    }

    fn isSolvable(self: Puzzle) bool {
        // Adapted from <https://www.geeksforgeeks.org/check-instance-15-puzzle-solvable/>.
        //
        // To test whether a square sliding puzzle is solvable, we need to first count the total
        // number of inversions present in the puzzle. An inversion is when a tile of a higher
        // number appears before a tile of a lower number.
        //
        // If the size of the puzzle is even, it is solvable if the inversion count is even and the
        // empty cell is on an odd row (0-indexed), or if the inversion count is odd and the empty
        // cell is on an even row.
        //
        // If the size of the puzzle is odd, it is solvable if the inversion count is even.

        // The only property of the inversion count we care about is whether it is even or odd, so
        // we can use a single bit for this.
        var parity: u1 = 0;
        var empty_index: ?usize = null;

        for (self.cells, 0..) |first, first_index| {
            if (first == 0) {
                empty_index = first_index;
                continue;
            }
            for (self.cells[first_index + 1 ..]) |second| {
                if (second == 0) continue;
                if (first > second) {
                    parity +%= 1;
                }
            }
        }

        // Our puzzle is currently hard-coded to always be 4x4 so the else branch will never be
        // taken, but I'm leaving the odd size case in for posterity.
        if (size % 2 == 0) {
            return parity != empty_index.? / size % 2;
        } else {
            return parity == 0;
        }
    }

    pub const MoveTileError = error{
        PuzzleSolved,
        CellIndexOutOfBounds,
        TileNotAdjacentToEmptyCell,
    };

    /// Attempts to move the tile at the specified index to the empty cell.
    pub fn moveTile(self: *Puzzle, cell_index: u8) MoveTileError!void {
        if (self.is_solved) return error.PuzzleSolved;
        if (cell_index >= cell_count) return error.CellIndexOutOfBounds;

        const x = cell_index % size;
        const y = cell_index / size;

        var empty_index = if (x < size - 1 and self.cells[y * 4 + x + 1] == 0) // Right
            y * size + x + 1
        else if (x >= 1 and self.cells[y * size + x - 1] == 0) // Left
            y * size + x - 1
        else if (y < size - 1 and self.cells[(y + 1) * size + x] == 0) // Down
            (y + 1) * size + x
        else if (y >= 1 and self.cells[(y - 1) * size + x] == 0) // Up
            (y - 1) * size + x
        else
            return error.TileNotAdjacentToEmptyCell;

        self.cells[empty_index] = self.cells[cell_index];
        self.cells[cell_index] = 0;

        self.is_solved = self.isSolved();
    }

    pub fn isSolved(self: Puzzle) bool {
        return std.mem.eql(u8, &self.cells, &solved.cells);
    }
};
