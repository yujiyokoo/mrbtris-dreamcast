#include <kos.h>
#include <mruby.h>
#include <mruby/irep.h>
#include <mruby/data.h>
#include <mruby/string.h>
#include <mruby/error.h>
#include <stdio.h>

#define PACK_PIXEL(r, g, b) ( ((r & 0xF8) << 8) | ((g & 0xFC) << 3) | (b >> 3)  )

extern const uint8_t game[]; // declared in the rb file

/* You can safely remove this line if you don't use a ROMDISK */
extern uint8 romdisk[];

/* These macros tell KOS how to initialize itself. All of this initialization
   happens before main() gets called, and the shutdown happens afterwards. So
   you need to set any flags you want here. Here are some possibilities:

   INIT_NONE        -- don't do any auto init
   INIT_IRQ     -- knable IRQs
   INIT_THD_PREEMPT -- Enable pre-emptive threading
   INIT_NET     -- Enable networking (doesn't imply lwIP!)
   INIT_MALLOCSTATS -- Enable a call to malloc_stats() right before shutdown

   You can OR any or all of those together. If you want to start out with
   the current KOS defaults, use INIT_DEFAULT (or leave it out entirely). */
KOS_INIT_FLAGS(INIT_DEFAULT | INIT_MALLOCSTATS);

/* And specify a romdisk, if you want one (or leave it out) */
KOS_INIT_ROMDISK(romdisk);

mrb_value put_pixel640(mrb_state *mrb, mrb_value self) {
  mrb_int x, y, r, g, b;
  mrb_get_args(mrb, "iiiii", &x, &y, &r, &g, &b);

  vram_s[x + y * 640] = PACK_PIXEL(r, g, b);

  return mrb_nil_value();
}

static mrb_value draw20x20_640(mrb_state *mrb, mrb_value self) {
  mrb_int x, y, r, g, b;
  mrb_get_args(mrb, "iiiii", &x, &y, &r, &g, &b);

  int i = 0, j = 0;

  for(i = 0; i < 20; i++) {
    for(j = 0; j < 20; j++) {
      vram_s[x+j + (y+i) * 640] = PACK_PIXEL(r, g, b);
    }
  }

  return mrb_nil_value();
}

static mrb_value waitvbl(mrb_state *mrb, mrb_value self) {
  vid_waitvbl();

  return mrb_nil_value();
}

static mrb_value get_button_state(mrb_state *mrb, mrb_value self) {
  maple_device_t *cont1;
  cont_state_t *state;
  if((cont1 = maple_enum_type(0, MAPLE_FUNC_CONTROLLER))){
    state = (cont_state_t *)maple_dev_status(cont1);
    //printf("controller state checked. %d\n", state->buttons);
    return mrb_fixnum_value(state->buttons);
  }
  return mrb_nil_value();
}

static mrb_value start_btn(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_START);
}

static mrb_value dpad_left(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_DPAD_LEFT);
}

static mrb_value dpad_right(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_DPAD_RIGHT);
}

static mrb_value dpad_up(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_DPAD_UP);
}

static mrb_value dpad_down(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_DPAD_DOWN);
}

static mrb_value btn_b(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_B);
}

static mrb_value btn_a(mrb_state *mrb, mrb_value self) {
  struct mrb_value state;
  mrb_get_args(mrb, "i", &state);

  return mrb_bool_value(mrb_fixnum(state) & CONT_A);
}

static mrb_value clear_score(mrb_state *mrb, mrb_value self) {
  char* clear_str = "Press START";
  bfont_draw_str(vram_s + 640 * 100 + 16, 640, 1, clear_str);

  return mrb_nil_value();
}

static mrb_value render_score(mrb_state *mrb, mrb_value self) {
  struct mrb_value score;
  mrb_get_args(mrb, "i", &score);
  char buf[20];
  snprintf(buf, 20, "Score: %8d", mrb_fixnum(score));
  bfont_draw_str(vram_s + 640 * 100 + 16, 640, 1, buf);

  return mrb_nil_value();
}

static void main_loop(int initx, int inity) {
  int x = initx;
  int y = inity;
  int last_x = 0;
  int last_y = 0;
  maple_device_t *cont1;
  cont_state_t *state;

  for(;;) {
    vid_waitvbl();

    if(last_x != x || last_y != y) {
      int i = 0;
      int j = 0;
      for(i = 0; i < 10 ; i++) {
        for(j = 0; j < 10; j++)
          vram_s[(last_x + i) + ((last_y+j) * 640)] = PACK_PIXEL(0, 0, 0);
      }
      for(i = 0; i < 10 ; i++) {
        for(j = 0; j < 10; j++)
          vram_s[(x+i) + ((y+j) * 640)] = PACK_PIXEL(255, 255, 255);
      }
    }

    if((cont1 = maple_enum_type(0, MAPLE_FUNC_CONTROLLER))) {
      if((state = (cont_state_t *)maple_dev_status(cont1))) {
        last_x = x;
        last_y = y;
        if(state->buttons & CONT_START)
          return;
        if(state->buttons & CONT_DPAD_LEFT)
          x -= 5;
        if(state->buttons & CONT_DPAD_RIGHT)
          x += 5;
        if(state->buttons & CONT_DPAD_UP)
          y -= 5;
        if(state->buttons & CONT_DPAD_DOWN)
          y += 5;
      }
    }
  }
}

void print_exception(mrb_state* mrb) {
    if(mrb->exc) {
      mrb_value backtrace = mrb_get_backtrace(mrb);
      puts(mrb_str_to_cstr(mrb, mrb_inspect(mrb, backtrace)));

      mrb_value obj = mrb_funcall(mrb, mrb_obj_value(mrb->exc), "inspect", 0);
      fwrite(RSTRING_PTR(obj), RSTRING_LEN(obj), 1, stdout);
      putc('\n', stdout);
    }
}

int main(int argc, char **argv) {
    vid_set_mode(DM_640x480_PAL_IL, PM_RGB565); // or DM_768x576_PAL_IL ?

    // bfont_draw_str(vram_s + 640 * 20 + 16, 640, 1, "START+A+B to exit");

    mrb_state *mrb = mrb_open();
    struct RClass *dc2d_module = mrb_define_module(mrb, "Dc2d");

    mrb_define_module_function(mrb, dc2d_module, "put_pixel640", put_pixel640, MRB_ARGS_REQ(5));
    mrb_define_module_function(mrb, dc2d_module, "draw20x20_640", draw20x20_640, MRB_ARGS_REQ(5));
    mrb_define_module_function(mrb, dc2d_module, "waitvbl", waitvbl, MRB_ARGS_NONE());

    mrb_define_module_function(mrb, dc2d_module, "clear_score", clear_score, MRB_ARGS_NONE());

    mrb_define_module_function(mrb, dc2d_module, "render_score", render_score, MRB_ARGS_REQ(1));

    mrb_define_module_function(mrb, dc2d_module, "get_button_state", get_button_state, MRB_ARGS_NONE());

    mrb_define_module_function(mrb, dc2d_module, "start_btn?", start_btn, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "dpad_left?", dpad_left, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "dpad_right?", dpad_right, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "dpad_up?", dpad_up, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "dpad_down?", dpad_down, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "btn_a?", btn_a, MRB_ARGS_REQ(1));
    mrb_define_module_function(mrb, dc2d_module, "btn_b?", btn_b, MRB_ARGS_REQ(1));

    if (!mrb) { return 1; }

    mrb_load_irep(mrb, game);

    print_exception(mrb);

    mrb_close(mrb);

    return 0;
}


