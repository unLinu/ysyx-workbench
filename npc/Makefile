# Variables
SIMULATOR = verilator
TOP_MODULE = top
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
CFLAGS = --cc --exe --build -j 0 -Wall --top-module $(TOP_MODULE) --Mdir $(OBJ_DIR)

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
	 csrc/tb_$(TOP_MODULE).cpp vsrc/$(TOP_MODULE).v
	@$(OBJ_DIR)/V$(TOP_MODULE) > /dev/null
	@echo "Simulation with FST trace completed."
	@gtkwave $(OBJ_DIR)/simx.fst
else
	@$(SIMULATOR) $(CFLAGS) --trace-vcd \
	 csrc/tb_$(TOP_MODULE).cpp vsrc/$(TOP_MODULE).v
	@$(OBJ_DIR)/V$(TOP_MODULE) > /dev/null
	@echo "Simulation with VCD trace completed."
	@gtkwave $(OBJ_DIR)/simx.vcd
endif

### NVBoard 

$(shell mkdir -p $(BUILD_DIR))

# constraint file
SRC_AUTO_BIND = $(abspath $(BUILD_DIR)/auto_bind.cpp)
$(SRC_AUTO_BIND): $(NXDC_FILES)
	python3 $(NVBOARD_HOME)/scripts/auto_pin_bind.py $^ $@

# project source
VSRCS = $(shell find $(abspath ./vsrc) -name "*.v")
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
