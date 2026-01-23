# Variables
SIMULATOR = verilator
WAVEVIEWER = surfer
TOP_MODULE = npc_core
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
VSRCS = $(wildcard ./vsrc/*.sv)

# Target path for libnpc.so
NPC_LIB = build/libnpc.so
# Source files and include paths for NPC
NPC_CSRCS = $(wildcard $(NPC_HOME)/csrc/src/*.cpp)

VERILATOR_CFLAGS = --cc -j $(shell nproc) -Wall --top-module $(TOP_MODULE) --Mdir $(OBJ_DIR)
VERILATOR_CFLAGS += -Ivsrc -CFLAGS "-g -fPIC -fvisibility=hidden"
VERILATOR_CFLAGS += -Wno-fatal
VERILATOR_CFLAGS += --trace-vcd
VERILATOR_CFLAGS += --lib-create npc
VERILATOR_CFLAGS += $(VSRCS) $(NPC_CSRCS)

all:
	@echo "Write this Makefile by your self."

verilating: $(VSRCS)
	@mkdir -p $(OBJ_DIR)
	$(SIMULATOR) $(VERILATOR_CFLAGS) $^

$(NPC_LIB): verilating
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP_MODULE).mk

shared: $(NPC_LIB)

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

clean:
	@rm -rf $(BUILD_DIR)

include ../Makefile
