use @import("std").os.windows;

// The extern specifier is used to declare a function that will be resolved
// at link time, when linking statically, or at runtime, when linking
// dynamically.
// The stdcallcc specifier changes the calling convention of the function.
extern "user32" stdcallcc fn MessageBoxA(hWnd: ?HANDLE, lpText: ?LPCTSTR, lpCaption: ?LPCTSTR, uType: UINT) c_int;

export fn WinMain(hInstance: HINSTANCE, hPrevInstance: HINSTANCE, lpCmdLine: PWSTR, nCmdShow: INT) INT
{
    _ = MessageBoxA(null, c"hello", c"title", 0);
    return 0;
}
