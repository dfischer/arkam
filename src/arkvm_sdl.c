#include "arkvm_sdl.h"


#ifdef __GNUC__
#  define DEBUG_AID __attribute__ ((unused))
#else
#  define DEBUG_AID
#endif


typedef ArkamVM   VM;
typedef ArkamCode Code;


static Cell zoom = 2;
#define WIDTH  256
#define HEIGHT 192

static Cell poll_step      = 5000;
static Cell req_poll       = 1;
static const double FPS_MS = 1000.0f / 60.0f;


/* ===== Setter ===== */

void set_zoom(int z) {
  zoom = z;
}


/* ===== Graceful Shutdown ===== */

static void quit(int code) {
  SDL_Quit();
  exit(code);
}



/* ===== Pixel Processing Unit ===== */

#define SPRITE_WIDTH 8
#define SPRITE_SIZE  64 /* 8x8 */
#define SPRITE_NUM   256

// 64 * 4 = 256 ( 1 byte )
#define PALETTES 64
#define COLORS   4
#define Color (ppu->palette_i * COLORS + ppu->color)

typedef struct PPU {
  Cell  width;
  Cell  height;
  Cell  pixels;
  Byte* fg;
  Byte* bg;
  Cell* out;
  Cell  palette_i;
  UCell palettes[PALETTES][COLORS];
  Cell  color; // color number
  int   req_redraw;
  /* 8x8 Sprites */
  Cell sprites[SPRITE_NUM];
  Cell sprite_i;
  /* SDL Specific */
  SDL_Window   *window;
  SDL_Renderer *renderer;
  SDL_Texture  *texture;
} PPU;


PPU* ppu;


static void init_sdl(PPU* ppu) {
  if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
    die("Can't initialize SDL: %s", SDL_GetError());
    
  ppu->window = SDL_CreateWindow("Arkam",
                                 SDL_WINDOWPOS_CENTERED,
                                 SDL_WINDOWPOS_CENTERED,
                                 ppu->width  * zoom,
                                 ppu->height * zoom,
                                 0
                                 );
  
  ppu->renderer = SDL_CreateRenderer(ppu->window, -1, 0);
  if (!ppu->renderer) die("Can't create renderer: %s", SDL_GetError());

  ppu->texture = SDL_CreateTexture(ppu->renderer,
                               SDL_PIXELFORMAT_ARGB8888,
                               SDL_TEXTUREACCESS_STATIC,
                               ppu->width,
                               ppu->height
                               );
  if (!ppu->texture) die("Can't create texture: %s", SDL_GetError());

  SDL_ShowCursor(SDL_ENABLE);
}

static PPU* new_ppu(Cell width, Cell height) {
  PPU* ppu = calloc(sizeof(PPU), 1);
  if (!ppu) die("Can't create ppu");

  ppu->width  = width;
  ppu->height = height;
  Cell pixels = ppu->pixels = width * height;
  

  if (!(ppu->fg  = calloc(sizeof(Byte), pixels))) die("Can't create ppu-fg");
  if (!(ppu->bg  = calloc(sizeof(Byte), pixels))) die("Can't create ppu-bg");
  if (!(ppu->out = calloc(sizeof(Cell), pixels))) die("Can't create ppu-out");

  ppu->palette_i = 0;
  ppu->palettes[0][0] = 0xFF86A35A;
  ppu->palettes[0][1] = 0xFF6F894F;
  ppu->palettes[0][2] = 0xFF58754F;
  ppu->palettes[0][3] = 0xFF32544F;

  init_sdl(ppu);

  return ppu;
}


static void draw_ppu(PPU* ppu) {
  // render on-screen buffer to out buffer
  Cell pixels = ppu->pixels;
  for (int i = 0; i < pixels; i++) {
      Cell pixel = ppu->fg[i];
      Cell palette_i = pixel / PALETTES;
      Cell color_i = pixel % PALETTES;
      Cell color = ppu->palettes[palette_i][color_i];
      ppu->out[i] = color;
  }
}

static void render_ppu(PPU* ppu) {
  // render out buffer to window
  draw_ppu(ppu);
  Cell bytes_of_line = ppu->width * sizeof(Cell);
  SDL_UpdateTexture(ppu->texture, NULL, ppu->out, bytes_of_line);
  SDL_RenderClear(ppu->renderer);
  SDL_RenderCopy(ppu->renderer, ppu->texture, NULL, NULL);
  SDL_RenderPresent(ppu->renderer);
}


static Code handlePPU(VM* vm, Cell op) {
  switch (op) {
  case 0: /* set palette color ( color i -- ) */
    {
      if (!ark_has_ds_items(vm, 2)) Raise(DS_UNDERFLOW);
      Cell i = Pop();
      Cell c = Pop();
      if (i < 0 || i >= COLORS) die("Invalid color number %d", i);
      UCell color = 0xFF000000 | c;
      ppu->palettes[ppu->palette_i][i] = color;
      return ARK_OK;
    }

  case 1: /* set color number ( i -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell i = Pop();
      if (i < 0 || i >= COLORS) die("Invalid color number: %d", i);
      ppu->color = i;
      return ARK_OK;
    }

  case 2: /* set palette number ( i -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell i = Pop();
      if (i < 0 || i >= PALETTES) die("Invalid palette number: %d", i);
      ppu->palette_i = i;
      return ARK_OK;
    }

  case 3: /* get palette number ( -- i ) */
    {
      if (!ark_has_ds_spaces(vm, 1)) Raise(DS_OVERFLOW);
      Push(ppu->palette_i);
      return ARK_OK;
    }

  case 10: /* clear */
    {
      Cell pixels = ppu->pixels;
      for (int i = 0; i < pixels; i++) {
        ppu->bg[i] = Color;
      }
      return ARK_OK;
    }

  case 11: /* plot ( x y -- ) */
    {
      if (!ark_has_ds_items(vm, 2)) Raise(DS_UNDERFLOW);
      Cell y = Pop();
      Cell x = Pop();
      if (x < 0 || x >= ppu->width)  die("Invalid position x: %d", x);
      if (y < 0 || y >= ppu->height) die("Invalid position y: %d", y);
      ppu->bg[y*ppu->width + x] = Color;
      return ARK_OK;
    }

  case 12: /* ploti ( i -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell i = Pop();
      if (i < 0 || i >= ppu->pixels)  die("Invalid index i: %d", i);
      ppu->bg[i] = Color;
      return ARK_OK;      
    }

  case 13: /* switch */
    {
      Byte* tmp = ppu->fg;
      ppu->fg = ppu->bg;
      ppu->bg = tmp;
      ppu->req_redraw = 1;
      return ARK_OK;
    }

  case 14: /* transfer ( addr -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell pixels = ppu->pixels;
      Cell start = Pop();
      Cell end   = start+pixels - 1;
      if (!(ark_valid_addr(vm, start) && ark_valid_addr(vm, end)))
        Raise(INVALID_ADDR);
      memcpy(ppu->bg, vm->mem + start, pixels);
      return ARK_OK;
    }

  case 15: /* copy ( -- ) copy fg to bg */
    {
      memcpy(ppu->bg, ppu->fg, ppu->pixels);
      return ARK_OK;
    }

  case 16: /* width ( -- w ) */
    {
      if (!ark_has_ds_spaces(vm, 1)) Raise(DS_OVERFLOW);
      Push(ppu->width);
      return ARK_OK;
    }

  case 17: /* height ( -- h ) */
    {
      if (!ark_has_ds_spaces(vm, 1)) Raise(DS_OVERFLOW);
      Push(ppu->height);
      return ARK_OK;
    }

  case 20: /* sprite number ( i -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell i = Pop();
      if (i < 0 || i >= SPRITE_NUM) die("Invalid sprite number: %d", i);
      ppu->sprite_i = i;
      return ARK_OK;
    }

  case 21: /* load sprite ( addr -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell a; PopValid(&a);
      if (!ark_valid_addr(vm, a + SPRITE_SIZE - 1))
        die("Invalid address of sprite data %d", a);
      ppu->sprites[ppu->sprite_i] = a;
      return ARK_OK;
    }

  case 22: /* plot sprite to bg ( x y -- ) */
    {
      if (!ark_has_ds_items(vm, 2)) Raise(DS_UNDERFLOW);
      Cell oy = Pop();
      Cell ox = Pop();
      Cell addr = ppu->sprites[ppu->sprite_i];
      if (addr == 0) return ARK_OK; // ignore null sprite
      Cell w = ppu->width;
      Cell h = ppu->height;
      Byte* sprite = vm->mem + addr;
      int i = 0;
      for (int dy = 0; dy < SPRITE_WIDTH; dy++) {
        for (int dx = 0; dx < SPRITE_WIDTH; dx++) {
          Cell x = ox + dx;
          Cell y = oy + dy;
          if (x >= 0 && x < w && y >= 0 && y < h) {
            Cell bi = y * w + x;
            if (sprite[i] != 0) ppu->bg[bi] = sprite[i] + (COLORS * ppu->palette_i);
          }
          i++;
        }
      }
      return ARK_OK;
    }
    
  default: Raise(IO_UNKNOWN_OP);
  }
}

static void setup_ppu(VM* vm, Cell width, Cell height) {
  ppu = new_ppu(width, height);
  vm->io_handlers[ARK_DEVICE_VIDEO] = handlePPU;  
}


/* ===== Mouse ===== */

typedef struct Mouse {
  Cell x, y;
  Cell lx, ly, lpress;
  Cell rx, ry, rpress;
} Mouse;


Mouse* mouse;


static Mouse* new_mouse() {
  Mouse* m = calloc(sizeof(Mouse), 1);
  return m;
}

static Code handleMOUSE(VM* vm, Cell op) {
  switch (op) {
  case 0: /* addr pos ( &x &y -- ) */
    {
      if (!ark_has_ds_items(vm, 2)) Raise(DS_UNDERFLOW);
      PopValid(&(mouse->y));
      PopValid(&(mouse->x));      
      return ARK_OK;
    }
  case 1: /* addr left ( &x &y &press -- ) */
    {
      if (!ark_has_ds_items(vm, 3)) Raise(DS_UNDERFLOW);
      PopValid(&(mouse->lpress));
      PopValid(&(mouse->ly));
      PopValid(&(mouse->lx));
      return ARK_OK;
    }
  case 2: /* addr right */
    {
      if (!ark_has_ds_items(vm, 3)) Raise(DS_UNDERFLOW);
      PopValid(&(mouse->rpress));
      PopValid(&(mouse->ry));
      PopValid(&(mouse->rx));
      return ARK_OK;      
    }
  default: Raise(IO_UNKNOWN_OP);
  }
}

static Cell clamp(Cell n, Cell min, Cell max) {
  // min <= n < max
  return n < min ? min : (n > max ? max : n);
}

static void handle_mouse_event(VM* vm, SDL_Event* ev) {
  Cell x = clamp(ev->motion.x / zoom, 0, ppu->width - 1);
  Cell y = clamp(ev->motion.y / zoom, 0, ppu->height - 1);

  Cell cx, cy, cp;
  switch (ev->button.button) {
  case SDL_BUTTON_LEFT:  cx = mouse->lx; cy = mouse->ly; cp = mouse->lpress; break;
  case SDL_BUTTON_RIGHT: cx = mouse->rx; cy = mouse->ry; cp = mouse->rpress; break;
  }

  switch(ev->type) {
  case SDL_MOUSEBUTTONUP:
    if (cx) Set(cx, x);
    if (cy) Set(cy, y);
    if (cp) Set(cp, 0);
    return;
  case SDL_MOUSEBUTTONDOWN:
    if (cx) Set(cx, x);
    if (cy) Set(cy, y);
    if (cp) Set(cp, -1);    
    return;
  case SDL_MOUSEMOTION:
    if (mouse->x) Set(mouse->x, x);
    if (mouse->y) Set(mouse->y, y);
    return;
  }
}

static void setup_mouse(VM* vm) {
  mouse = new_mouse();
  vm->io_handlers[ARK_DEVICE_MOUSE] = handleMOUSE;
}


/* ===== Audio ===== */

DEBUG_AID static void dbg_draw_env(PPU* ppu, double* table, int ox, int oy, int width, int height) {
  const int pixel = 3;

  double step = FM_ENV_TABLE_SIZE / (double)width;
  for (int x = 0; x < width; x++) {
    int i = (int)(x * step);
    if (i < 0 || i >= FM_ENV_TABLE_SIZE) die("Invalid table index:%d step:%lf", i, step);
    double e = table[i];
    int y = height - (height * e);
    int px = ox + x;
    int py = oy + y;
    if (x < 0 || x >= ppu->width)  die("Invalid position x:%d", x);
    if (y < 0 || y >= ppu->height) die("Invalid position y:%d e:%lf", y, e);
    ppu->fg[py*ppu->width + px] = pixel;
  }
}


DEBUG_AID static void dbg_draw_envs(PPU* ppu) {
  dbg_draw_env(ppu, fm_env_table_ed, 8,   8,  100, 48);
  dbg_draw_env(ppu, fm_env_table_eu, 120, 8,  100, 48);
  dbg_draw_env(ppu, fm_env_table_ld, 8,   96, 100, 48);
  dbg_draw_env(ppu, fm_env_table_lu, 120, 96, 100, 48);  
}


static void setup_audio(VM* vm) {
  setup_fmsynth(vm);
  vm->io_handlers[ARK_DEVICE_AUDIO] = handleFMSYNTH;
}



/* ===== Keyboard ===== */

static Cell key_handler_addr = 0;

static Code handleKEY(VM* vm, Cell op) {
  switch (op) {
  case 0: /* handler ( addr -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell a; PopValid(&a);
      key_handler_addr = a;
      return ARK_OK;
    }
  default: Raise(IO_UNKNOWN_OP);
  }
}

static void setup_keyboard(VM* vm) {
  SDL_StartTextInput();
  vm->io_handlers[ARK_DEVICE_KEY] = handleKEY;
}



/* ===== GamePad ===== */

#define MAX_GAMEPAD 32
SDL_Joystick* gamepads[MAX_GAMEPAD];
static Cell gamepad_handler_addr = 0;


static Code handlePAD(VM* vm, Cell op) {
  switch (op) {
  case 0: /* refresh_pads ( -- n ) */
    {
      if (!ark_has_ds_spaces(vm, 1)) Raise(DS_OVERFLOW);
      Cell pads = 0;
      for (int i = 0; i < MAX_GAMEPAD; i++) {
        if (gamepads[i]) pads++;
      }
      Push(pads);
      return ARK_OK;
    }
  case 1: /* handler ( q -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell s; PopValid(&s);
      gamepad_handler_addr = s;
      return ARK_OK;
    }
  default: Raise(IO_UNKNOWN_OP);
  }
}


static void handle_gamepad_event(VM* vm, SDL_Event* ev) {
  if (!gamepad_handler_addr) return;
  SDL_JoyButtonEvent je = ev->jbutton;
  Cell pad = je.which;
  if (pad >= MAX_GAMEPAD) return;
  if (!ark_has_ds_spaces(vm, 3)) die("DS Overflow");
  
  Cell button = je.button;
  Cell state = je.state == SDL_PRESSED ? -1 : 0;
  Push(state);
  Push(button);
  Push(pad);
  
  Cell old_ip = vm->ip;
  Cell code = ARK_OK;
  vm->ip = gamepad_handler_addr;
  while (code == ARK_OK) { code = ark_step(vm); }
  if (code != ARK_HALT) die("Gamepad handler aborted: %s", ark_err_str(vm->err));
  vm->ip = old_ip;
}


static void handle_gamepad_added(VM* vm, SDL_Event* ev) {
  Cell pad = ev->jdevice.which;
  if (pad >= MAX_GAMEPAD) return;
  gamepads[pad] = SDL_JoystickOpen(pad);
}


static void handle_gamepad_removed(VM* vm, SDL_Event* ev) {
  Cell pad = ev->jdevice.which;
  if (pad >= MAX_GAMEPAD) return;
  SDL_JoystickClose(gamepads[pad]);
  gamepads[pad] = NULL;
}


static void setup_pad(VM* vm) {
  int pads = SDL_NumJoysticks();

  for (int i = 0; i< MAX_GAMEPAD; i++) {
    gamepads[i] = NULL;
  }

  for (int i = 0; i < pads && i < MAX_GAMEPAD; i++) {
    gamepads[i] = SDL_JoystickOpen(i);
  }

  vm->io_handlers[ARK_DEVICE_PAD] = handlePAD;
}



/* ===== EMU ===== */

static Code handleEMU(VM* vm, Cell op) {
  switch (op) {
  case 0: /* set title ( s -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell s; PopValid(&s);
      SDL_SetWindowTitle(ppu->window, (char*)(vm->mem + s));
      return ARK_OK;
    }
  case 1: /* show/hide cursor ( n -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell n = Pop();
      switch (n) {
      case 0: /* hide */
        SDL_ShowCursor(SDL_DISABLE); break;
      case -1: /* show */
        SDL_ShowCursor(SDL_ENABLE); break;
      default: die("Unknown cursor state: %d", n);
      }
      return ARK_OK;
    }
  case 2: /* poll_step ( n -- ) */
    {
      if (!ark_has_ds_items(vm, 1)) Raise(DS_UNDERFLOW);
      Cell n = Pop();
      if (n < 1) die("Invalid poll_step: %d", n);
      poll_step = n;
      return ARK_OK;
    }
  case 3: /* poll ( -- ) */
    {
      req_poll = 1;
      return ARK_OK;
    }
  default: Raise(IO_UNKNOWN_OP);
  }
}

static void setup_emu(VM* vm) {
  vm->io_handlers[ARK_DEVICE_EMU] = handleEMU;
}



/* ===== Main Loop & Entrypoint ===== */
#define SDL_SCANCODE_MASK (1<<30);


static void poll_sdl_event(VM* vm, PPU* ppu) {
  SDL_Event event;
  
  while (SDL_PollEvent(&event) != 0) {
    switch(event.type) {
      
    case SDL_QUIT:
      quit(0);
      break;

    case SDL_WINDOWEVENT:
      if (event.window.event == SDL_WINDOWEVENT_EXPOSED) render_ppu(ppu);
      break;

      
    case SDL_MOUSEBUTTONUP:
    case SDL_MOUSEBUTTONDOWN:
    case SDL_MOUSEMOTION:
      handle_mouse_event(vm, &event);
      break;

      
    case SDL_KEYDOWN:
    case SDL_KEYUP:
      {
        if (!key_handler_addr) break;
        /* handler ( down(-1)/up(0) sym -- ) */
        Cell keycode = event.key.keysym.sym & ~SDL_SCANCODE_MASK;
        Push(event.type == SDL_KEYDOWN ? -1 : 0);
        Push(keycode);
        Cell old_ip = vm->ip;
        vm->ip = key_handler_addr;
        Code code = ARK_OK;
        while(code == ARK_OK) { code = ark_step(vm); }
        if (code != ARK_HALT) die("Key handler aborted: %s", ark_err_str(vm->err));
        vm->ip = old_ip;
        break;
      }

      
    case SDL_JOYBUTTONUP:
    case SDL_JOYBUTTONDOWN:
      handle_gamepad_event(vm, &event);
      break;
    case SDL_JOYDEVICEADDED:
      handle_gamepad_added(vm, &event);
      break;
    case SDL_JOYDEVICEREMOVED:
      handle_gamepad_removed(vm, &event);
      break;
    }
  }
}


Code sdl_run(VM* vm) {
  Code code = ARK_OK;

  Uint64 previous = SDL_GetPerformanceCounter();
  Uint64 current;
  double elapsed;

  while (1) {
    render_ppu(ppu);
    ppu->req_redraw = 0;
    poll_sdl_event(vm, ppu);

    while (!ppu->req_redraw) {
        code = ark_step(vm);
        if (code != ARK_OK) return code;
    }

    // adjust frame rate
    current = SDL_GetPerformanceCounter();
    elapsed = (double)(current - previous) / (double)SDL_GetPerformanceFrequency() * 1000.0f;
    previous = current;
    SDL_Delay(clamp(FPS_MS - elapsed, 0, FPS_MS));
  }
 
  return code;
}


void setup_sdlvm(VM* vm, int argc, char* argv[]) {
  setup_ppu(vm, WIDTH, HEIGHT);
  setup_mouse(vm);
  setup_audio(vm);
  setup_keyboard(vm);
  setup_pad(vm);
  setup_emu(vm);
  setup_app(vm, argc, argv);
}
