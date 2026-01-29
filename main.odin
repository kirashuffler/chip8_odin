package chip8
import rl "vendor:raylib"
import "base:runtime"
import fmt "core:fmt"
import io "core:io"
import os "core:os"
import "core:log"

c8_load_rom :: proc(filepath : string) -> int {
  info, err := os.stat(filepath)
  if err != os.ERROR_NONE {
    fmt.eprintf("Failed to access ROM '%s'\n", filepath)
    return -1
  }

  if info.size > MEM_SIZE_BYTES - MEM_START_OFFSET {
    fmt.eprintf("Failed to load ROM, its size too big: '%d'\n", info.size)
    return -1
  }
  
  if info.size == 0 {
    fmt.eprintln("Failed to load ROM, its empty")
    return -1
  }
  file : os.Handle 
  file, err = os.open(filepath)
  if err != os.ERROR_NONE {
    fmt.eprintf("Failed to open ROM '%s'\n", filepath)
    return -1
  }
  defer os.close(file)
  
  rom_buffer := g_mem[MEM_START_OFFSET:MEM_START_OFFSET + int(info.size)]
  bytes_read : int
  file_stream := os.stream_from_handle(file)
  bytes_read, err = io.read(file_stream, rom_buffer)
  if err != io.Error.None {
    fmt.eprintfln("Failed to read into rom buffer %v", err)
    return -1
  }

  if bytes_read != int(info.size) {
    fmt.eprintfln("Partial read: %v bytes of %v", bytes_read, int(info.size))
  }

  fmt.printfln("Loaded ROM: %v size: %v", filepath, bytes_read)
  return 0
}

c8_init :: proc(filepath: string) -> int {
  if c8_load_rom(filepath) != 0 {
    return -1
  }
	copy_slice(g_mem[:FONTS_CNT], g_fonts[:])
  return 0
}

c8_cycle :: proc() -> bool {
  g_opcode = (u16(g_mem[g_pc]) << 8) | u16(g_mem[g_pc + 1])
  if g_opcode == 0 {
    fmt.println("Reached the end of ROM")
    return false
  }
  g_pc += 2
  opcode_execute()
  if g_sound_timer > 0 {
    fmt.println("BEEP!");
    g_sound_timer -= 1
  }

  if g_delay_timer > 0 {
    g_delay_timer -= 1
  }
  return true
}

update_keys_state :: proc() {
  cur_keys := Number_Set{}
  for rl_key, value in g_keymap {
    is_down := rl.IsKeyDown(rl_key)
    if is_down {
      cur_keys |= Number_Set{value}
      g_key_is_pressed = true
    }
  }
  if card(cur_keys) == 0 {
    g_key_is_pressed = false
  }
  g_keys = cur_keys
}

main :: proc() {
  logger := log.create_console_logger()
  context.logger = logger
  defer log.destroy_console_logger(logger)
  if len(os.args) != 2 {
    fmt.println("Failed to launch: expected only 1 argument - path to ROM");
    return
  }

	if c8_init(os.args[1]) < 0 {
    return 
  }

	rl.InitWindow(C8_SCREEN_WIDTH * SCALE, C8_SCREEN_HEIGHT * SCALE, "Chip-8")
	defer rl.CloseWindow()
	rl.SetTargetFPS(TARGET_FPS)

	for !rl.WindowShouldClose() {
    for i in 0..<(TARGET_CPU_CLOCK / TARGET_FPS) {
      if !c8_cycle() {
        return
      }
    }
    update_keys_state()

		rl.BeginDrawing()
		defer rl.EndDrawing()
		rl.ClearBackground(rl.BLACK)
    for val, y in g_c8_screen {
      for x in 0..<C8_SCREEN_WIDTH {
        if (LM_ONE >> u16(x)) & val > 0 {
          rl.DrawRectangle(i32(x) * SCALE, i32(y) * SCALE, SCALE * 1, SCALE * 1, rl.RAYWHITE)
        }
      }
    }
	}

}
