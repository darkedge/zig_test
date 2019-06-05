//use @import("std").os.windows;
//
//// The extern specifier is used to declare a function that will be resolved
//// at link time, when linking statically, or at runtime, when linking
//// dynamically.
//// The stdcallcc specifier changes the calling convention of the function.
//extern "user32" stdcallcc fn MessageBoxA(hWnd: ?HANDLE, lpText: ?LPCTSTR, lpCaption: ?LPCTSTR, uType: UINT) c_int;
//
//export fn WinMain(hInstance: HINSTANCE, hPrevInstance: HINSTANCE, lpCmdLine: PWSTR, nCmdShow: INT) INT
//{
//    _ = MessageBoxA(null, c"hello", c"title", 0);
//    return 0;
//}

const c = @cImport({
  @cInclude("SDL.h");
  });
const assert = @import("std").debug.assert;

// See https://github.com/zig-lang/zig/issues/565
// SDL_video.h:#define SDL_WINDOWPOS_UNDEFINED         SDL_WINDOWPOS_UNDEFINED_DISPLAY(0)
// SDL_video.h:#define SDL_WINDOWPOS_UNDEFINED_DISPLAY(X)  (SDL_WINDOWPOS_UNDEFINED_MASK|(X))
// SDL_video.h:#define SDL_WINDOWPOS_UNDEFINED_MASK    0x1FFF0000u
const SDL_WINDOWPOS_UNDEFINED = @bitCast(c_int, c.SDL_WINDOWPOS_UNDEFINED_MASK);

extern fn SDL_PollEvent(event: *c.SDL_Event) c_int;

// SDL_RWclose is fundamentally unrepresentable in Zig, because `ctx` is
// evaluated twice. One could make the case that this is a bug in SDL,
// especially since the docs list a real function prototype that would not
// have this double-evaluation of the parameter.
// If SDL would instead of a macro use a static inline function,
// it would resolve the SDL bug as well as make the function visible to Zig
// and to debuggers.
// SDL_rwops.h:#define SDL_RWclose(ctx)        (ctx)->close(ctx)
inline fn SDL_RWclose(ctx: [*]c.SDL_RWops) c_int {
  return ctx[0].close.?(ctx);
}

pub fn main() !void
{
  if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0)
  {
    c.SDL_Log(c"Unable to initialize SDL: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  }
  defer c.SDL_Quit();

  const screen = c.SDL_CreateWindow(c"My Game Window", SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 300, 73, c.SDL_WINDOW_OPENGL) orelse
  {
    c.SDL_Log(c"Unable to create window: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  };
  defer c.SDL_DestroyWindow(screen);

  const renderer = c.SDL_CreateRenderer(screen, -1, 0) orelse
  {
    c.SDL_Log(c"Unable to create renderer: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  };
  defer c.SDL_DestroyRenderer(renderer);

  const zig_bmp = @embedFile("zig.bmp");
  
  const optional0: ?[*]c.SDL_RWops = c.SDL_RWFromConstMem(
    @ptrCast(*const c_void, &zig_bmp[0]),
    @intCast(c_int, zig_bmp.len),
    );
  const rw = optional0 orelse
  {
    c.SDL_Log(c"Unable to get RWFromConstMem: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  };
  defer assert(SDL_RWclose(rw) == 0);

  const optional1: ?*c.SDL_Surface = c.SDL_LoadBMP_RW(rw, 0);
  const zig_surface = optional1 orelse
  {
    c.SDL_Log(c"Unable to load bmp: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  };
  defer c.SDL_FreeSurface(zig_surface);

  const zig_texture = c.SDL_CreateTextureFromSurface(renderer, zig_surface) orelse
  {
    c.SDL_Log(c"Unable to create texture from surface: %s", c.SDL_GetError());
    return error.SDLInitializationFailed;
  };
  defer c.SDL_DestroyTexture(zig_texture);

  var quit = false;
  while (!quit)
  {
    var event: c.SDL_Event = undefined;
    while (SDL_PollEvent(&event) != 0)
    {
      switch (event.@"type")
      {
        c.SDL_QUIT =>
        {
          quit = true;
        },
          else =>
          {},
      }
    }

    _ = c.SDL_RenderClear(renderer);
    const n: ?[*]c.SDL_Rect = null;
    _ = c.SDL_RenderCopy(renderer, zig_texture, n, n);
    c.SDL_RenderPresent(renderer);

    c.SDL_Delay(17);
  }
}
