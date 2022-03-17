# BytePusher VM
# aquova, 2022

import sdl
from os import paramCount, paramStr, sleep

const RAM_SIZE = 0x1000000
const SLEEP_TIME = 16 # 60 FPS in ms, rounded
const NUM_OPS = 65536
const NUM_PAL = 216

const SCALE = 3
const DISP_SIZE = SCALE * 256

const KEYBOARD_ADDR = 0x0000
const PC_ADDR       = 0x0002
const PIXEL_ADDR    = 0x0005
const AUDIO_ADDR    = 0x0006

type RGB = tuple[r: uint8, g: uint8, b: uint8]

type Emu = object
    PC: int
    RAM: seq[uint8]
    pal: array[256, RGB]

proc set_pc(e: var Emu, a: int) =
    e.PC = a

proc inc_pc(e: var Emu) =
    e.set_pc(e.PC + 3)

proc read(e: var Emu, a: int): int =
    let v = (int(e.RAM[a]) shl 16) or (int(e.RAM[a + 1]) shl 8) or int(e.RAM[a + 2])
    return v

proc tick(e: var Emu) =
    let aaa = e.read(e.PC)
    e.inc_pc()
    let bbb = e.read(e.PC)
    e.inc_pc()
    let ccc = e.read(e.PC)
    e.RAM[bbb]= e.RAM[aaa]
    e.set_pc(ccc)

proc render(e: Emu, r: var SdlRendererPtr) =
    r.setDrawColor(0, 0, 0, 255)
    r.clear()

    let msb = int(e.RAM[PIXEL_ADDR]) shl 16
    var rect: Rect
    rect.w = SCALE
    rect.h = SCALE
    for x in countup(0x00, 0xFF):
        for y in countup(0x00, 0xFF):
            let a = msb or (y shl 8) or x
            let col_idx = e.RAM[a]
            let c = e.pal[col_idx]
            rect.x = cint(x * SCALE)
            rect.y = cint(y * SCALE)
            r.setDrawColor(c.r, c.g, c.b, 255)
            r.fillRect(rect)
    r.present()

proc init(e: var Emu, filename: string): bool =
    var f: File
    if not f.open(filename):
        return false

    e.RAM = newSeq[uint8](RAM_SIZE)
    var buf: seq[char]
    newSeq(buf, RAM_SIZE)
    discard f.readChars(buf)
    for i, v in buf.pairs():
        e.RAM[i] = uint8(v)
    f.close()

    for i in 0..<NUM_PAL:
        let r = uint8(i / 36) mod 6
        let g = uint8(i / 6) mod 6
        let b = uint8(i mod 6)
        let c = (r: 0x33 * r, g: 0x33 * g, b: 0x33 * b)
        e.pal[i] = c

    return true

proc main() =
    if paramCount() == 0:
        quit("Usage: ./bytepusher path/to/rom")
    var emu = Emu()
    let success = init(emu, paramStr(1))
    if not success:
        quit("Unable to open file")

    if sdl.init(INIT_VIDEO) == -1:
        quit("Couldn't initialize SDL")

    var wndw: SdlWindowPtr
    var renderer: SdlRendererPtr

    if createWindowAndRenderer(DISP_SIZE, DISP_SIZE, 0, wndw, renderer) == -1:
        quit("Unable to create an SDL window")

    while true:
        # TODO: Poll for keys
        discard pollEvent(nil)
        emu.PC = emu.read(PC_ADDR)
        for _ in countup(1, NUM_OPS):
            emu.tick()
        emu.render(renderer)
        # TODO: Send 256 byte buffer specified by 0x0006 to audio device
        sleep(SLEEP_TIME) # TODO: subtract time this frame took

main()
