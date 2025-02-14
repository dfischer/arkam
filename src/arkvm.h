#if !defined(__ARKVM_H__)
#define __ARKVM_H__

#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>

typedef int32_t  Cell;
typedef uint32_t UCell; // unsigned cell for logical shift
typedef uint8_t  Byte;

#define ARK_MAX_INT   2147483647
#define ARK_MIN_INT  -2147483648
#define ARK_MAX_UINT  4294967295

#define ARK_DEFAULT_MEM_CELLS (2 * 1000 * 1000) / sizeof(Cell); /* 2MiB */
#define ARK_DEFAULT_DS_CELLS 512
#define ARK_DEFAULT_RS_CELLS 512


/*
  Memory Layout
  | heap
  | data stack
  | return stack

  Heap Layout
  0x00 | DO NOT TOUCH HERE (error detection)
  0x04 | Start
  0x08 | Here
  0x0C | ( reserved )
  0x10 | Code Begin
*/

#define ARK_ADDR_START 0x04
#define ARK_ADDR_HERE  0x08
#define ARK_ADDR_CODE_BEGIN 0x10


/* ===== Notes =====
   - Many functions which requires ArkVM* and returns ArkCode set
     result data to vm->result or error to vm->err.
     ex. ark_pop(vm)
          returns ARK_OK  and set popped value to vm->result
       or returns ARK_ERR and set error code   to vm->err
*/


typedef struct ArkVM ArkVM;


// Result code
typedef enum
  { ARK_OK,
    ARK_ERR,
    ARK_HALT
  } ArkCode;


// Error code
enum {
      ARK_ERR_DS_OVERFLOW = 0,
      ARK_ERR_DS_UNDERFLOW,
      ARK_ERR_RS_OVERFLOW,
      ARK_ERR_RS_UNDERFLOW,
      ARK_ERR_INVALID_ADDR,
      ARK_ERR_INVALID_INST,
      ARK_ERR_ZERO_DIVISION,
      ARK_ERR_IO_UNKNOWN_DEV,
      ARK_ERR_IO_UNKNOWN_OP,
      ARK_ERR_IO_NOT_REGISTERED,
      ARK_ERROR_CODE_COUNT
};


// instructions
enum {
      ARK_INST_NOOP = 0,
      ARK_INST_HALT,
      ARK_INST_LIT,
      ARK_INST_RET,
      // Stack
      ARK_INST_DUP,
      ARK_INST_DROP,
      ARK_INST_SWAP,
      ARK_INST_OVER,
      // Arithmetics
      ARK_INST_ADD,
      ARK_INST_SUB,
      ARK_INST_MUL,
      ARK_INST_DMOD,
      // Compare
      ARK_INST_EQ,
      ARK_INST_NEQ,
      ARK_INST_GT,
      ARK_INST_LT,
      // Control flow
      ARK_INST_JMP,
      ARK_INST_ZJMP,
      // Memory
      ARK_INST_GET,
      ARK_INST_SET,
      ARK_INST_BGET,
      ARK_INST_BSET,
      // Bitwise
      ARK_INST_AND,
      ARK_INST_OR,
      ARK_INST_NOT,
      ARK_INST_XOR,
      ARK_INST_LSHIFT, // logical shift
      ARK_INST_ASHIFT, // arithmetic shift
      // Peripheral
      ARK_INST_IO,
      // Return stack
      ARK_INST_RPUSH,
      ARK_INST_RPOP,
      ARK_INST_RDROP,
      // Registers
      ARK_INST_GETSP,
      ARK_INST_SETSP,
      ARK_INST_GETRP,
      ARK_INST_SETRP,
      ARK_INSTRUCTION_COUNT
};


/* ===== I/O ===== */


typedef enum
  { ARK_DEVICE_SYS      = 0,
    ARK_DEVICE_STDIO    = 1,
    ARK_DEVICE_RANDOM   = 2,
    ARK_DEVICE_VIDEO    = 3,
    ARK_DEVICE_AUDIO    = 4,
    ARK_DEVICE_KEY      = 5,
    ARK_DEVICE_MOUSE    = 6,
    ARK_DEVICE_PAD      = 7,
    ARK_DEVICE_FILE     = 8,
    ARK_DEVICE_DATETIME = 9,
    ARK_DEVICE_SOCKET   = 10,
    ARK_DEVICE_EMU      = 11, /* Emulator Operation */
    ARK_DEVICE_APP      = 12, /* Application process */
    ARK_DEVICES_COUNT
  } ArkDevice;


typedef ArkCode (*ArkDeviceHandler)(ArkVM* vm, Cell op);


struct ArkVM {
  Byte* mem;     // entire memory
  Cell  cells;   // entire memory cells
  Cell  ds_size; // data stack size(cells)
  Cell  rs_size; // return stack size(cells)
  Cell  ds;      // data stack top
  Cell  rs;      // return stack top
  Cell  ip;      // instruction pointer
  Cell  sp;      // data stack pointer
  Cell  rp;      // return stack pointer
  Cell  result;
  Cell  err;
  ArkDeviceHandler io_handlers[ARK_DEVICES_COUNT];
};


typedef struct ArakamVMOptions {
  Cell memory_cells;
  Cell dstack_cells;
  Cell rstack_cells;
} ArkVMOptions;


// VM
void     ark_set_default_options (ArkVMOptions* opts);
ArkVM* ark_new_vm              (ArkVMOptions* opts);
void     ark_free_vm             (ArkVM* vm);


// Run
ArkCode ark_step   (ArkVM* vm);
ArkCode ark_run    (ArkVM* vm);


// Memory Operations
ArkCode ark_get   (ArkVM* vm, Cell i);
ArkCode ark_set   (ArkVM* vm, Cell i, Cell v);
ArkCode ark_push  (ArkVM* vm, Cell v);
ArkCode ark_pop   (ArkVM* vm);
ArkCode ark_rpush (ArkVM* vm, Cell v);
ArkCode ark_rpop  (ArkVM* vm);


// Checking
int ark_valid_addr(ArkVM* vm, Cell i);
int ark_has_ds_items(ArkVM* vm, Cell n);
int ark_has_ds_spaces(ArkVM* vm, Cell n);
ArkCode ark_pop_valid_addr(ArkVM* vm);


// Error
char* ark_err_str (int err);


#endif
