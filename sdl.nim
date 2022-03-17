# SDL wrapping code adapted from here: https://livebook.manning.com/book/nim-in-action/chapter-8/

when defined(Windows):
    const libName* = "SDL2.dll"
elif defined(Linux):
    const libName* = "libSDL2.so"
elif defined(MacOsX):
    const libName* = "libSDL2.dylib"

const INIT_VIDEO* = 0x00000020

type
    SdlWindow = object
    SdlWindowPtr* = ptr SdlWindow
    SdlRenderer = object
    SdlRendererPtr* = ptr SdlRenderer
    Rect* = tuple[x, y, w, h: cint]

{.push dynlib: libName.}
proc init*(flags: uint32): cint {.importc: "SDL_Init".}

proc createWindowAndRenderer*(width, height: cint, window_flags: cuint, window: var SdlWindowPtr, renderer: var SdlRendererPtr): cint {.importc: "SDL_CreateWindowAndRenderer".}

proc pollEvent*(event: pointer): cint {.importc: "SDL_PollEvent".}

proc setDrawColor*(renderer: SdlRendererPtr, r, g, b, a: uint8): cint {.importc: "SDL_SetRenderDrawColor", discardable.}

proc fillRect*(renderer: SdlRendererPtr, rect: var Rect): cint {.importc: "SDL_RenderFillRect", discardable.}

proc present*(renderer: SdlRendererPtr) {.importc: "SDL_RenderPresent".}

proc clear*(renderer: SdlRendererPtr) {.importc: "SDL_RenderClear".}
{.pop.}
