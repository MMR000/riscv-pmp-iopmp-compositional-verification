# M5 REF-IOPMP adapter build (links official reference model)

REF_ROOT := $(abspath ../third_party/riscv-iopmp-official/iopmp_ref_model)
REF_INC  := $(REF_ROOT)/include
REF_VER  := $(REF_ROOT)/verif
REF_LIB  := $(REF_ROOT)/lib/iopmp_model.a

CC       ?= gcc
CFLAGS   := -Wall -Wextra -I$(REF_INC) -Iadapters -I$(REF_VER)
LDFLAGS  := -lm

.PHONY: all ref-lib m5-ref-campaign m5-ref-check clean

all: m5-ref-campaign m5-ref-check

ref-lib:
	$(MAKE) -C $(REF_ROOT) build model=full_model

$(REF_LIB):
	$(MAKE) -C $(REF_ROOT) build model=full_model

m5-ref-campaign: ref-lib tests/m5_ref_campaign.c adapters/ref_iopmp_adapter.c
	mkdir -p bin
	$(CC) $(CFLAGS) -o bin/m5_ref_campaign tests/m5_ref_campaign.c adapters/ref_iopmp_adapter.c $(REF_LIB) $(LDFLAGS)

m5-ref-check: ref-lib tests/m5_ref_check.c adapters/ref_iopmp_adapter.c
	mkdir -p bin
	$(CC) $(CFLAGS) -o bin/m5_ref_check tests/m5_ref_check.c adapters/ref_iopmp_adapter.c $(REF_LIB) $(LDFLAGS)

clean:
	rm -rf bin
