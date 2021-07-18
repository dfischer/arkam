#include "standard_main.h"
#include <forth.ark.h>


int main(int argc, char* argv[]) {
  VM* vm = setup_arkam_with_image(forth, sizeof(forth));
  setup_app(vm, argc, argv);

  Code code = ark_get(vm, ARK_ADDR_START);
  guard_err(vm, code);
  vm->ip = vm->result;

  code = ark_run(vm);
  guard_err(vm, code);

  code = ark_pop(vm);
  guard_err(vm, code);
  Cell r = vm->result;

  ark_free_vm(vm);
  return r;
}
