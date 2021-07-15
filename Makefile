$SRC := $(wildcard src/*.c)
$OBJ := $(patsubst src/%.c, out/%.o, $(SRC))
$DEP := $(patsubst src/%.c, out/%.d, $(SRC))


CC = gcc

CFLAGS  = -Wall -I./out
LDFLAGS =



.PHONY: meta
out/forth1.ark: bin/arkam forth.ark forth/meta.f forth/core.f
	./bin/arkam forth.ark forth/meta.f out/forth1.ark
meta: out/forth1.ark
	./bin/arkam out/forth1.ark --quit


.PHONY: meta-check
out/forth2.ark: out/forth1.ark
	./bin/arkam out/forth1.ark forth/meta.f out/forth2.ark
meta-check: out/forth2.ark
	diff out/forth1.ark out/forth2.ark

.PHONY: meta-test
meta-test: out/forth1.ark
	./test/run.sh out/forth1.ark


.PHONY: meta-install
meta-install: meta meta-check meta-test
	cp forth.ark out/forth.ark.old
	mv out/forth1.ark forth.ark


.PHONY: all
all: bin out bin/arkam bin/forth


.PHONY: arkam
arkam: bin/arkam



.PHONY: sarkam
sarkam: bin/sarkam



.PHONY: test
test: arkam bin/forth bin/test_arkam forth.ark
	./test/run.sh forth.ark



.PHONY: clean
clean:
	$(RM) -f bin/* out/*


.PHONY: sarkam-scratch
sarkam-scratch: bin sarkam bin/forth.ark
	./bin/sarkam bin/forth.ark test/sarkam-scratch.f



.PHONY: sprited
out/tmp.spr: lib/basic.spr
	cp lib/basic.spr out/tmp.spr
sprited: bin sarkam bin/forth.ark out/tmp.spr
	./bin/sarkam bin/forth.ark tools/sprited.f out/tmp.spr



.PHONY: fmparams
fmparams: bin sarkam bin/forth.ark
	./bin/sarkam bin/forth.ark example/fmparams.f



.PHONY: forth
forth: arkam bin/forth
	./bin/forth

out/forth.ark.h: forth.ark bin/text2c
	./bin/text2c -b forth forth.ark out/forth.ark.h



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
