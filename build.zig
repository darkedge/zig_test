const std = @import("std");
const os = std.os;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void
{
  const mode = b.standardReleaseOptions();
  const exe = b.addExecutable("hello_windows", "main.zig");
  exe.setBuildMode(mode);

  exe.addIncludeDir("SDL2-2.0.9/include");

  exe.linkSystemLibrary("c");
  b.addNativeSystemLibPath("SDL2-2.0.9/lib/x64");
  //exe.linkSystemLibrary("SDL2main.lib");
  exe.linkSystemLibrary("SDL2.lib");

  var buildDirExists = true;
  os.makeDir("bin") catch |err|
  {
    if (err != error.PathAlreadyExists)
    {
      buildDirExists = false;
      std.debug.warn("Failed to create output directory: {}\n", @errorName(err));
    }
  };

  if (buildDirExists)
  {
    exe.setOutputDir("./bin");
 
    const run_cmd = exe.run();
 
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
 
    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);

//    b.copyFile("SDL2-2.0.9\\lib\\x64\\SDL2.dll", "C:\\Repositories\\zig_test\\bin\\") catch |err|
//    {
//      std.debug.warn("asdadasd: {}\n", @errorName(err));
//    };
  }
}
