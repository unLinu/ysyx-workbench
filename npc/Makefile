# Variables
SIMULATOR = verilator
WAVEVIEWER = surfer
TOP_MODULE = npc_core
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
CFLAGS = --cc --exe --build -j $(shell nproc) -Wall --top-module $(TOP_MODULE) --Mdir $(OBJ_DIR)
CFLAGS += -Ivsrc
CFLAGS += -Wno-fatal
SIMCPP = $(shell find $(abspath ./csrc) -name "*.cpp" ! -name "main.cpp")

NXDC_FILES = constr/top.nxdc
NVBOARD_CFLAGS += -MMD --build -cc  \
				-O3 --x-assign fast --x-initial fast --noassert
BIN = $(BUILD_DIR)/$(TOP_MODULE)

all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
	@mkdir -p $(OBJ_DIR)
ifdef FST
	@$(SIMULATOR) $(CFLAGS) --trace-fst -CFLAGS "-DFST" \
	 $(SIMCPP) $(VSRCS) 
	@$(OBJ_DIR)/V$(TOP_MODULE) 
	@echo "Simulation with FST trace completed."
	@$(WAVEVIEWER) $(OBJ_DIR)/simx.fst
else
	@$(SIMULATOR) $(CFLAGS) --trace-vcd \
	 $(SIMCPP) $(VSRCS)
	@$(OBJ_DIR)/V$(TOP_MODULE) 
	@echo "Simulation with VCD trace completed."
	@$(WAVEVIEWER) $(OBJ_DIR)/simx.vcd
endif

### NVBoard 

$(shell mkdir -p $(BUILD_DIR))

ifdef SEQ_LOGIC
NVBOARD_CFLAGS += --CFLAGS "-DSEQ_LOGIC"
endif

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v" -o -name "*.sv")
CSRCS = $(shell find $(abspath ./csrc) -name "main.cpp")
CSRCS += $(SRC_AUTO_BIND)

# rules for NVBoard
include $(NVBOARD_HOME)/scripts/nvboard.mk

# rules for verilator
INCFLAGS = $(addprefix -I, $(INC_PATH))
CXXFLAGS += $(INCFLAGS) -DTOP_NAME="\"V$(TOP_MODULE)\""

$(BIN): $(VSRCS) $(CSRCS) $(NVBOARD_ARCHIVE)
	@rm -rf $(OBJ_DIR)
	$(SIMULATOR) $(NVBOARD_CFLAGS) \
		--top-module $(TOP_MODULE) $^ \
		$(addprefix -CFLAGS , $(CXXFLAGS)) $(addprefix -LDFLAGS , $(LDFLAGS)) \
		--Mdir $(OBJ_DIR) --exe -o $(abspath $(BIN))

nvboard-run: $(BIN)
	@$^

clean:
	@rm -rf $(BUILD_DIR)

include ../Makefile
