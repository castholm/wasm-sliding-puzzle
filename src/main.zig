const std = @import("std");
const Puzzle = @import("puzzle.zig").Puzzle;

/// The global puzzle instance.
var puzzle = Puzzle.solved;

/// Called when the player clicks on the "new puzzle" button.
export fn newPuzzle(seed: u32) void {
    var rng = std.rand.DefaultPrng.init(seed);
    // 5 is a low number intentionally chosen to give error handling a chance to actually occur in
    // practice. Each randomization attempt has a ~50% chance of generating a valid puzzle
    // configuration, so if we raise this quota to something like 100 we can guarantee that a valid
    // configuration is always generated.
    const randomization_attempt_quota = 5;

    puzzle.init(rng.random(), randomization_attempt_quota) catch |err| {
        switch (err) {
            error.RandomizationAttemptQuotaExceeded => std.log.err(
                "failed to generate a valid puzzle configuration within {} attempts (seed: {})",
                .{ randomization_attempt_quota, seed },
            ),
        }
        return;
    };

    std.log.info("puzzle reset (seed: {})", .{seed});

    drawPuzzle();
}

/// Called when the player clicks on a tile.
export fn moveTile(cell_index: u8) void {
    puzzle.moveTile(cell_index) catch |err| {
        std.log.warn("failed to move tile at index {}: {s}", .{
            cell_index,
            switch (err) {
                error.PuzzleSolved => "the puzzle is already solved",
                error.CellIndexOutOfBounds => "the cell index is out of bounds",
                error.TileNotAdjacentToEmptyCell => "the tile is not adjacent to the empty cell",
            },
        });
        return;
    };

    if (puzzle.isSolved()) {
        std.log.info("puzzle solved", .{});
    }

    drawPuzzle();
}

fn drawPuzzle() void {
    updatePuzzleDisplay(&puzzle);
}

/// Instructs the browser to update its puzzle display to match the state of the puzzle.
extern "puzzle" fn updatePuzzleDisplay(puzzle: *const Puzzle) void;

// Because we target 'wasm32-freestanding', OS-specific functionality like reading files or writing
// to the terminal is normally unavailable. However, Zig supports the concept of BYOOS ("bring your
// own operating system") by giving you the option of overriding OS-specific functionality with your
// own implementations. This is done by declaring an 'os.system' struct in the root source file.
//
// The chunk of code below implements the minimal set of functionality needed for things like
// 'std.log' and 'std.debug.print()' to work.
pub const os = struct {
    pub const system = struct {
        var errno: E = undefined;

        pub const E = std.os.wasi.E;

        pub fn getErrno(rc: anytype) E {
            return if (rc == -1) errno else .SUCCESS;
        }

        pub const fd_t = std.os.wasi.fd_t;

        pub const STDERR_FILENO = std.os.wasi.STDERR_FILENO;

        pub fn write(fd: i32, buf: [*]const u8, count: usize) isize {
            // We only support writing to stderr.
            if (fd != std.os.STDERR_FILENO) {
                errno = .PERM;
                return -1;
            }

            const clamped_count = @min(count, std.math.maxInt(isize));
            writeToStderr(buf, clamped_count);
            return @intCast(isize, clamped_count);
        }

        extern "stderr" fn writeToStderr(string_ptr: [*]const u8, string_length: usize) void;
    };
};
