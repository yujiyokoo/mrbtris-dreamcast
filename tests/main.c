#include <mruby.h>
#include <mruby/irep.h>

extern const uint8_t test_suite[]; // declared in the rb file

int main(int argc, char **argv) {
    mrb_state *mrb = mrb_open();
    if (!mrb) { return 1; }

    mrb_load_irep(mrb, test_suite);

    mrb_close(mrb);

    return 0;
}
