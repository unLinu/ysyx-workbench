# Variables
SIMULATOR = verilator
TOP_MODULE = top
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj_dir
CFLAGS = --cc --exe --build -j 0 -Wall --top-module $(TOP_MODULE) --Mdir $(OBJ_DIR)

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

clean:
	@rm -rf $(BUILD_DIR)

include ../Makefile
