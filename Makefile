$SRC := $(wildcard src/*.c)
$OBJ := $(patsubst src/%.c, out/%.o, $(SRC))
$DEP := $(patsubst src/%.c, out/%.d, $(SRC))


CC = gcc

CFLAGS  = -Wall -I./out
LDFLAGS =



.PHONY: meta
out/forth1.ark: bin/arkvm forth.ark lib/meta.f lib/core.f
	./bin/arkvm forth.ark lib/meta.f out/forth1.ark
meta: out/forth1.ark
	./bin/arkvm out/forth1.ark --quit


.PHONY: meta-check
out/forth2.ark: out/forth1.ark
	./bin/arkvm out/forth1.ark lib/meta.f out/forth2.ark
meta-check: out/forth2.ark
	diff out/forth1.ark out/forth2.ark

.PHONY: meta-test
meta-test: out/forth1.ark bin/test_arkvm
	./test/run.sh out/forth1.ark


.PHONY: meta-install
meta-install: meta meta-check meta-test
	cp forth.ark out/forth.ark.old
	mv out/forth1.ark forth.ark


.PHONY: all
all: bin out bin/arkam bin/arkvm


.PHONY: arkam
arkam: bin/arkam



.PHONY: sarkam
sarkam: bin/sarkam



.PHONY: test
test: arkvm bin/forth bin/test_arkvm forth.ark
	./test/run.sh forth.ark



.PHONY: clean
clean:
	$(RM) -f bin/* out/*



.PHONY: sarkam-scratch
sarkam-scratch: bin sarkam
	./bin/sarkam forth.ark test/sarkam-scratch.f



.PHONY: sprited
out/tmp.spr: lib/basic.spr
	cp lib/basic.spr out/tmp.spr
sprited: bin sarkam out/tmp.spr
	./bin/sarkam forth.ark tools/sprited.f out/tmp.spr



.PHONY: fmparams
fmparams: bin sarkam
	./bin/sarkam forth.ark example/fmparams.f


bin/file2c.ark: bin/arkvm forth.ark tools/file2c.f
	./bin/arkvm forth.ark tools/file2c.f


.PHONY: arkam
arkam: bin/arkam
	./bin/arkam

out/forth.ark.h: bin/arkvm forth.ark bin/file2c.ark
	./bin/arkvm bin/file2c.ark -b forth forth.ark out/forth.ark.h



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


ARKVM_DEPS := $(call DEPS, src/vm_console.c)
bin/arkvm: LDFLAGS += -lm
bin/arkvm: $(ARKVM_DEPS)
	$(CC) -o bin/arkvm $(ARKVM_DEPS) $(CFLAGS) $(LDFLAGS)


SARKAM_DEPS := $(call DEPS, src/sdl_main.c)
bin/sarkam: CFLAGS  += -g `sdl2-config --cflags`
bin/sarkam: LDFLAGS += `sdl2-config --libs` -lm
bin/sarkam: $(SARKAM_DEPS)
	$(CC) -o bin/sarkam $(SARKAM_DEPS) $(CFLAGS) $(LDFLAGS)


ARKAM_DEPS := $(call DEPS, src/arkam_console.c)
bin/arkam: LDFLAGS += -lm
bin/arkam: $(ARKAM_DEPS) out/forth.ark.h
	$(CC) -o bin/arkam $(ARKAM_DEPS) $(CFLAGS) $(LDFLAGS)


TEST_DEPS := $(call DEPS, src/test.c)
bin/test_arkvm: $(TEST_DEPS)
	$(CC) -o bin/test_arkvm $(TEST_DEPS) $(CFLAGS) $(LDFLAGS)



-include $(DEP)
