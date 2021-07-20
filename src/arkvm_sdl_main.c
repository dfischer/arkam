#include "arkvm_sdl.h"

typedef ArkVM   VM;
typedef ArkCode Code;


void usage() {
  fprintf(stderr, "Usage: arkam IMAGE\n");
  exit(1);
}


int handle_opts(int argc, char* argv[]) {
  const char* optstr = "hz";

  struct option long_opts[] =
    { { "help",  no_argument,       NULL, 'h' },
      { "zoom",  required_argument, NULL, 'z' },
    };

  opterr = 0; // disable logging error
  int c;
  int long_index;
  while ((c = getopt_long(argc, argv, optstr, long_opts, &long_index)) != -1) {
    switch (c) {
    case 'h':
      usage();
    case 'z':
      {
        char* invalid = NULL;
        int zoom = strtol(optarg, &invalid, 10);
        if (zoom == 0) die("Invalid zoom: %s", optarg);
        set_zoom(zoom);
        break;
      }
    case '?':
      fprintf(stderr, "Unknown option: %c\n", optopt);
      usage();
    }
  }

  return optind;
}



int main(int argc, char* argv[]) {
  int argi     = handle_opts(argc, argv);
  int restc    = argc - argi;
  int image_i  = argi;
  if (restc < 1) usage();
  int app_argi = argi;
  int app_argc = restc;
  char* image_name = argv[image_i];

  VM* vm = setup_arkam_vm(image_name);

  setup_sdlvm(vm, app_argc, argv + app_argi);

  Code code = ark_get(vm, ARK_ADDR_START);
  guard_err(vm, code);
  vm->ip = vm->result;

  code = sdl_run(vm);
  guard_err(vm, code);

  ark_free_vm(vm);
  return 0;
}
