$SRC := $(wildcard src/*.c)
$OBJ := $(patsubst src/%.c, out/%.o, $(SRC))
$DEP := $(patsubst src/%.c, out/%.d, $(SRC))


CC = gcc

CFLAGS  = -Wall -I./out
LDFLAGS =



.PHONY: all
all: bin out bin/arkam bin/forth


.PHONY: arkam
arkam: bin/arkam



.PHONY: sarkam
sarkam: bin/sarkam



.PHONY: test
test: arkam bin/test_arkam bin/sol
	./test/run.sh



.PHONY: clean
clean:
	$(RM) -f bin/* out/*


.PHONY: hello
hello: out arkam bin/sol test/hello.sol
	./bin/sol test/hello.sol out/tmp.img
	./bin/arkam out/tmp.img


.PHONY: hello_sarkam
hello_sarkam: bin sarkam bin/sol
	./bin/sol example/hello_sarkam.sol out/hello_sarkam.ark
	./bin/sarkam out/hello_sarkam.ark



.PHONY: sarkam-scratch
sarkam-scratch: bin sarkam bin/forth.ark
	./bin/sarkam bin/forth.ark test/sarkam-scratch.f



.PHONY: sprited
out/tmp.spr: lib/basic.spr
	cp lib/basic.spr out/tmp.spr
sprited: bin sarkam bin/forth.ark out/tmp.spr
	./bin/sarkam bin/forth.ark tools/sprited.f out/tmp.spr



.PHONY: genepalette
genepalette: bin sarkam bin/sol
	./bin/sol tools/genepalette.sol bin/genepalette.ark
	./bin/sarkam bin/genepalette.ark



.PHONY: rand_fm_beat
rand_fm_beat: bin sarkam bin/sol
	./bin/sol example/rand_fm_beat.sol out/rand_fm_beat.ark
	./bin/sarkam out/rand_fm_beat.ark



.PHONY: forth
forth: arkam bin/forth
	./bin/forth

bin/forth.ark: bin/sol tools/forth.sol
	./bin/sol tools/forth.sol bin/forth.ark

out/forth.ark.h: bin/forth.ark bin/text2c
	./bin/text2c -b forth bin/forth.ark out/forth.ark.h



.PHONY: test-forth
test-forth: bin/forth_test.ark
	./bin/arkam bin/forth_test.ark

bin/forth_test.ark: bin/forth.ark tools/forth_test.sol
	./bin/sol tools/forth_test.sol bin/forth_test.ark



# ===== Prepare =====

bin:
	mkdir -p bin

out:
	mkdir -p out


out/%.o: src/%.c
	$(CC) -c $< -o $@ $(CFLAGS) $(LDFLAGS)


out/%.d: src/%.c
	$(CC) -MM $< -MF $@


DEPS = $(patsubst src/%.h, out/%.o, $(shell $(CC) -MM $(1) | sed 's/^.*: //;s/\\$$//' | tr '\n' ' '))


ARKAM_DEPS := $(call DEPS, src/console_main.c)
bin/arkam: LDFLAGS += -lm
bin/arkam: $(ARKAM_DEPS)
	$(CC) -o bin/arkam $(ARKAM_DEPS) $(CFLAGS) $(LDFLAGS)


SARKAM_DEPS := $(call DEPS, src/sdl_main.c)
bin/sarkam: CFLAGS  += -g `sdl2-config --cflags`
bin/sarkam: LDFLAGS += `sdl2-config --libs` -lm
bin/sarkam: $(SARKAM_DEPS)
	$(CC) -o bin/sarkam $(SARKAM_DEPS) $(CFLAGS) $(LDFLAGS)


FORTH_DEPS := $(call DEPS, src/forth_main.c)
bin/forth: LDFLAGS += -lm
bin/forth: $(FORTH_DEPS) out/forth.ark.h
	$(CC) -o bin/forth $(FORTH_DEPS) $(CFLAGS) $(LDFLAGS)


TEST_DEPS := $(call DEPS, src/test.c)
bin/test_arkam: $(TEST_DEPS)
	$(CC) -o bin/test_arkam $(TEST_DEPS) $(CFLAGS) $(LDFLAGS)


SOL_DEPS := $(call DEPS, src/sol.c)
bin/sol: $(SOL_DEPS) out/core.sol.h
	$(CC) -o bin/sol $(SOL_DEPS) $(CFLAGS) $(LDFLAGS)


bin/text2c: src/text2c.c
	$(CC) -o bin/text2c src/text2c.c $(CFLAGS) $(LDFLAGS)


out/core.sol.h: lib/core.sol bin/text2c
	./bin/text2c core_lib lib/core.sol out/core.sol.h



-include $(DEP)
