# Include
-include $(NEMU_HOME)/include/config/auto.conf

# Variables
SIMULATOR = verilator
WAVEVIEWER = surfer
TOP_MODULE = npc_top
YOSYS_TOP_MODULE = npc_yosys_top
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
NPC_VSRCS = vsrc

# Target path for libnpc.so
NPC_LIB = $(BUILD_DIR)/libnpc.so
# Source files and include paths for NPC
NPC_CSRCS = $(wildcard $(NPC_HOME)/csrc/src/*.cpp)
# CFLAGS
CFLAGS = -fPIC -fvisibility=hidden
CFLAGS += $(if $(CONFIG_CC_DEBUG), -g, -O3)

# VERILATOR_FLAGS
VERILATOR_FLAGS = --cc -j $(shell nproc) -Wall --top-module $(TOP_MODULE) --Mdir $(OBJ_DIR)
VERILATOR_FLAGS += -CFLAGS "$(CFLAGS)"
VERILATOR_FLAGS += -Wno-fatal
VERILATOR_FLAGS += $(if $(CONFIG_WAVE_VCD), --trace-vcd --trace-threads 1)
VERILATOR_FLAGS += $(if $(CONFIG_WAVE_FST), --trace-fst --trace-threads 1)
VERILATOR_FLAGS += --lib-create npc
VERILATOR_FLAGS += -F $(NPC_VSRCS)/filelist.f $(NPC_CSRCS)

verilating: $(VSRCS)
	@mkdir -p $(OBJ_DIR)
	$(SIMULATOR) $(VERILATOR_FLAGS) $^

$(NPC_LIB): verilating
	$(MAKE) -C $(OBJ_DIR) -f V$(TOP_MODULE).mk

shared: $(NPC_LIB)

wave:
ifeq ($(CONFIG_WAVE_VCD), y)
	$(WAVEVIEWER) $(BUILD_DIR)/simx.vcd
else ifeq ($(CONFIG_WAVE_FST), y)
	$(WAVEVIEWER) $(BUILD_DIR)/simx.fst
else
	@echo "No wave format enabled. Please enable CONFIG_WAVE_VCD or CONFIG_WAVE_FST."
endif

sv2v:
	@echo "Converting SystemVerilog to Verilog ..."
	@mkdir -p $(NPC_VSRCS)/build
	sv2v --top=$(YOSYS_TOP_MODULE) -I=$(NPC_VSRCS)/include $(shell find ./vsrc -name "*.sv" ! -name "dpi_*.sv" ! -name "npc_top.sv") > $(NPC_VSRCS)/build/merged.v

yosys-sta: sv2v
	@echo "Running static analysis ..."
	make -C ../yosys-sta/ sta DESIGN=$(YOSYS_TOP_MODULE) RTL_FILES="$(NPC_HOME)/vsrc/build/merged.v" CLK_FREQ_MHZ=100 CLK_PORT_NAME=clk

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!

clean:
	rm -rf $(BUILD_DIR) && rm -rf $(NPC_VSRCS)/build

include ../Makefile
