const std = @import("std");

pub fn build(b: *std.Build) !void {
    // Instead of exposing a standard '-Dtarget=[string]' option like in the 'build.zig' generated
    // by 'zig init-exe', we hard-code the target as 'wasm32-freestanding-none' as it is the only
    // target we care about supporting.
    const target: std.zig.CrossTarget = .{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
        .abi = .none,
    };
    // Expose '-Doptimize=[enum]' as a command-line option.
    const optimize = b.standardOptimizeOption(.{});
    // Artifacts are usually installed into a 'bin' or 'lib' directory in the install directory by
    // default, but here we want to install the files directly into the root install directory.
    const dest_dir: std.Build.InstallDir = .prefix;

    const wasm = b.addExecutable(.{
        .name = "sliding-puzzle",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    // Setting 'rdynamic' to true is required for all declarations marked with 'export' to be
    // included in the compiled artifact (if we don't set this the '.wasm' file will end up empty).
    wasm.rdynamic = true;
    // The wasm artifact doesn't have a 'main' entry point.
    wasm.entry = .disabled;
    b.getInstallStep().dependOn(&b.addInstallArtifact(wasm, .{
        .dest_dir = .{ .override = dest_dir },
    }).step);

    // Install 'index.html' into the root install directory.
    b.installFile("src/index.html", "index.html");

    // Use esbuild <https://esbuild.github.io/> to compile and bundle TypeScript and CSS.
    const esbuild_bundle_cmd = b.addSystemCommand(&.{
        b.pathFromRoot("node_modules/.bin/esbuild"),
        b.pathFromRoot("src/index.ts"),
        b.pathFromRoot("src/index.css"),
        "--bundle",
        "--format=esm",
        // This replaces all occurrences of '__WASM_ARTIFACT_FILENAME' in TypeScript source files
        // with the filename of the compiled WebAssembly artifact.
        b.fmt("--define:__WASM_ARTIFACT_FILENAME=\"{s}\"", .{wasm.out_filename}),
        // Output compiled/bundled files into the root install directory.
        b.fmt("--outdir={s}", .{try getAbsoluteInstallPath(b, dest_dir, "")}),
    });
    // Inform the Zig build system about esbuild's output so that it removes the files when we run
    // 'zig build uninstall'.
    b.pushInstalledFile(dest_dir, "index.js");
    b.pushInstalledFile(dest_dir, "index.css");

    if (optimize == .Debug) {
        // Generate source maps in debug mode.
        esbuild_bundle_cmd.addArg("--sourcemap");
        b.pushInstalledFile(dest_dir, "index.js.map");
        b.pushInstalledFile(dest_dir, "index.css.map");
    } else {
        // Minify bundles in release mode.
        esbuild_bundle_cmd.addArg("--minify");

        // In release mode, we also want to type check TypeScript source files for type errors
        // before bunding (esbuild doesn't do any type checking on its own). We can use the official
        // tsc TypeScript compiler for this. Our 'tsconfig.json' file has the 'noEmit' option set to
        // true, so tsc will type check without emitting any files.
        const tsc_cmd = b.addSystemCommand(&.{b.pathFromRoot("node_modules/.bin/tsc")});
        esbuild_bundle_cmd.step.dependOn(&tsc_cmd.step);
    }
    b.getInstallStep().dependOn(&esbuild_bundle_cmd.step);

    // Since we don't have an executable that we can run normally, we instead "run" our app by using
    // esbuild's serve mode to start a local development server that serves the contents of the
    // install directory.
    const esbuild_serve_cmd = b.addSystemCommand(&.{
        b.pathFromRoot("node_modules/.bin/esbuild"),
        "--serve",
        b.fmt("--servedir={s}", .{try getAbsoluteInstallPath(b, dest_dir, "")}),
    });
    esbuild_serve_cmd.step.dependOn(b.getInstallStep());

    const run_tls = b.step("run", "Run the app");
    run_tls.dependOn(&esbuild_serve_cmd.step);
}

fn getAbsoluteInstallPath(
    b: *std.Build,
    dir: std.Build.InstallDir,
    dest_rel_path: []const u8,
) ![]const u8 {
    return std.fs.path.resolve(b.allocator, &.{
        try std.process.getCwdAlloc(b.allocator),
        b.getInstallPath(dir, dest_rel_path),
    });
}
