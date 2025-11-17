const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Create module.
    const mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Setup tests
    const test_step = b.step("test", "Run unit tests");
    const run_unit_tests = b.addRunArtifact(b.addTest(.{ .root_module = mod }));
    test_step.dependOn(&run_unit_tests.step);
}
