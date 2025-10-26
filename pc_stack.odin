package chip8

STACK_SIZE_ :: 16
INVALID_ACCESS :: 0xFFFF

PcStack :: struct {
  data : [STACK_SIZE_]u16,
  cur_index : i16,
}

g_pcstack_ : PcStack

pcstack_init :: proc() {
  g_pcstack_.cur_index = -1
}

pcstack_pop :: proc() {
  if g_pcstack_.cur_index >= 0 {
    g_pcstack_.cur_index -= 1
  }
}

pcstack_get_top :: proc() -> u16 {
  if g_pcstack_.cur_index == -1 {
    return INVALID_ACCESS
  }
  return g_pcstack_.data[g_pcstack_.cur_index]
}

pcstack_push :: proc(value : u16) {
  if g_pcstack_.cur_index < STACK_SIZE_ - 1 {
    g_pcstack_.cur_index += 1
    g_pcstack_.data[g_pcstack_.cur_index] = value
  }
}
