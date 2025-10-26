package chip8
import rl "vendor:raylib"
import "base:runtime"
import mem "core:mem"

get_keymap :: proc(key: rune) -> u16 {
  switch key {
  case '1': 
    return 0x1
  case '2':
    return 0x2
  case '3':
    return 0x3
  case '4':
    return 0xC
  case 'q':
    return 0x4
  case 'w':
    return 0x5
  case 'e':
    return 0x6
  case 'r':
    return 0xD
  case 'a':
    return 0x7
  case 's':
    return 0x8
  case 'd':
    return 0x9
  case 'f':
    return 0xE
  case 'z':
    return 0xA
  case 'x':
    return 0x0
  case 'c':
    return 0xB
  case 'v':
    return 0xF
  case:
    return INVALID_KEY
  }
}

c8_clear_screen :: proc() {
  mem.set(&g_c8_screen, 0, MEM_SIZE_BYTES)
}

c8_init :: proc() -> int {
	copy_slice(g_mem[:FONTS_CNT], g_fonts[:])
  //read rom 
  if len(os.args) != 2 {
  }

}

c8_cycle :: proc() {

}

main :: proc() {
	c8_init();
	rl.InitWindow(C8_SCREEN_WIDTH * SCALE, C8_SCREEN_HEIGHT * SCALE, "Chip-8")
	defer rl.CloseWindow()
	rl.SetTargetFPS(60)
	for !rl.WindowShouldClose() {
    key := get_keymap(rune(rl.GetCharPressed()))
    if key != INVALID_KEY {
      g_keys |= Number_Set{int(key)}
      g_key_pressed = key
    }
    c8_cycle()
		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawRectangle(0, 0, SCALE * 1, SCALE * 1, rl.RAYWHITE)

    g_key_pressed = 0
    g_keys &= Number_Set{}
	}

}
