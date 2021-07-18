# Architecture


## Arkam

### ArkVM Core

The core of VM is consisted from two files [arkvm.h](arkvm.h) and [arkvm.c](arkvm.c).

It should be used as a library.

The rest of all are also examples of its usage.



### ArkVM (console)

[arkvm_console.c](arkvm_console.c) uses Arkam Core and produces a simple VM that runs an image on console.



### test_arkam

[test.c](test.c) uses Arkam Core and produces a test runner. It tests the internal of arkam core.



## text2c

[text2c](text2c.c) is used for amalgamation sol and core.sol.



## shorthands

[shorthands.h](shorthands.h) is an example of dirty shorthands for Arkam Core.

It is used by sol and test_arkam.