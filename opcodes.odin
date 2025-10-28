package chip8
import "core:math/rand"
import "base:runtime"
import mem "core:mem"


get_op_f000 :: proc() -> u8 {
  return u8(g_opcode >> 12)
}

get_op_000f :: proc() -> u8 {
  return u8(g_opcode & 0xF)
}

get_op_00ff :: proc() -> u8 {
  return u8(g_opcode & 0x00FF)
}

get_op_0fff :: proc() -> u16 {
  return g_opcode & 0x0FFF
}

get_op_x :: proc() -> u8 {
  return u8((g_opcode & 0x0F00) >> 8)
}

get_op_y :: proc() -> u8 {
  return u8((g_opcode & 0x00F0) >> 4)
}

opcode_execute :: proc() {
  x := get_op_x()
  y := get_op_y()
  switch get_op_f000() {
  case 0x0: // 0
    switch value := get_op_000f(); value {
    case 0:
      mem.set(&g_c8_screen, 0, C8_SCREEN_HEIGHT)
      g_draw_flag = true
    case 0xE:
      g_pc = pcstack_get_top()
      pcstack_pop()
    }
  case 1: // 1NNN
    g_pc = get_op_0fff()
  case 2: //2NNN
    pcstack_push(g_pc)
    g_pc = get_op_0fff()
  case 3:
    if g_gp_regs[x] == get_op_00ff() {
      g_pc += 2
    }
  case 4:
    if g_gp_regs[x] != get_op_00ff() {
      g_pc += 2
    }
  case 5:
    if g_gp_regs[x] == g_gp_regs[y] {
      g_pc += 2
    }
  case 6:
    g_gp_regs[x] = get_op_00ff()
  case 7:
    g_gp_regs[x] += get_op_00ff()
  case 8:
    opcode_execute_8()
  case 9:
    if g_gp_regs[x] != g_gp_regs[y] {
      g_pc += 2
    }
  case 0xA:
    g_index = get_op_0fff()
  case 0xB:
    g_pc = u16(g_gp_regs[0]) + get_op_0fff()
  case 0xC:
    g_gp_regs[x] = u8(rand.int31() % 0xFF) & get_op_00ff()
  case 0xD:
    gfx_conf_sprite(x, y, get_op_000f())
  case 0xE:
    val := get_op_00ff()
    // check_val := g_keys & Number_Set{int(g_gp_regs[x])}
    check_val := int(g_gp_regs[x]) in g_keys
    if val == 0x9E && check_val {
      g_pc += 2
    } else if val == 0xA1 && check_val {
      g_pc += 2
    }
  case 0xF:
    opcode_execute_f()
  }
}

gfx_conf_sprite :: proc(ix, iy: u8, height: u8) {
  x := ix % C8_SCREEN_WIDTH
  y := iy % C8_SCREEN_HEIGHT
  sprite_bytes := g_mem[u16(g_index):u16(g_index) + u16(height)]
  screen_slice := g_c8_screen[u16(y):u16(y) + u16(height)]
  for sprite_byte, row in sprite_bytes {
    screen_slice[row] ~= u64(sprite_byte) << (56 - x)
  }
  g_draw_flag = true
}

opcode_execute_8 :: proc() {
  x := get_op_x()
  y := get_op_y()
  switch get_op_000f() {
  case 0:
    g_gp_regs[x] = g_gp_regs[y]
  case 1:
    g_gp_regs[x] |= g_gp_regs[y]
  case 2:
    g_gp_regs[x] &= g_gp_regs[y]
  case 3:
    g_gp_regs[x] ~= g_gp_regs[y]
  case 4:
    g_gp_regs[0xF] = (g_gp_regs[x] + g_gp_regs[y]) > 0xFF ? 1 : 0
    g_gp_regs[x] += g_gp_regs[y]
  case 5:
    g_gp_regs[0xF] = g_gp_regs[x] > g_gp_regs[y] ? 1 : 0
    g_gp_regs[x] -= g_gp_regs[y]
  case 6:
    g_gp_regs[0xF] = g_gp_regs[x] & 0x1
    g_gp_regs[x] >>= 1
  case 7:
    g_gp_regs[0xF] = g_gp_regs[x] < g_gp_regs[y] ? 1 : 0
    g_gp_regs[x] = g_gp_regs[y] - g_gp_regs[x]
  case 0xE:
    g_gp_regs[0xF] = g_gp_regs[x] & 0x80
    g_gp_regs[x] = g_gp_regs[y] << 1
  }
}

opcode_execute_f :: proc() {
  x := get_op_x()
  switch get_op_00ff() {
  case 0x07:
    g_gp_regs[x] = g_delay_timer
  case 0x0A:
    if g_key_pressed != KEY_NOT_PRESSED {
      g_gp_regs[x] = u8(g_key_pressed)
    } else {
      g_pc -= 2
    }
  case 0x15:
    g_delay_timer = g_gp_regs[x]
  case 0x18:
    g_gp_regs[x] = g_sound_timer
  case 0x1E:
    g_gp_regs[0xF] = g_index + u16(g_gp_regs[x]) > 0xFFF ? 1 : 0
    g_index += u16(g_gp_regs[x])
  case 0x29:
    g_index = u16(g_gp_regs[x]) * 0x5
  case 0x33:
    g_mem[g_index] = g_gp_regs[x] / 100
    g_mem[g_index + 1] = g_gp_regs[x] % 100 / 10
    g_mem[g_index + 2] = g_gp_regs[x] % 10
  case 0x55:
    copy_slice(g_mem[g_index:g_index + u16(x)], g_gp_regs[:x])
  case 0x65:
    copy_slice(g_gp_regs[:x], g_mem[g_index:g_index + u16(x)])
  }
}
