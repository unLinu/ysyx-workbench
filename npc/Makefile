# Variables
SIMULATOR = verilator
TOP_MODULE = top
CFLAGS = --cc --exe --build -j 0 -Wall --top-module $(TOP_MODULE)

all:
	@echo "Write this Makefile by your self."

sim:
	$(call git_commit, "sim RTL") # DO NOT REMOVE THIS LINE!!!
ifdef FST
	@cd vsrc && $(SIMULATOR) $(CFLAGS) --trace-fst -CFLAGS "-DFST" \
	 *.cpp *.v
	@cd vsrc && ./obj_dir/V$(TOP_MODULE) > /dev/null
	@echo "Simulation with FST trace completed."
	@gtkwave vsrc/obj_dir/simx.fst
else
	@cd vsrc && $(SIMULATOR) $(CFLAGS) --trace-vcd \
	 *.cpp *.v
	@cd vsrc && ./obj_dir/V$(TOP_MODULE) > /dev/null
	@echo "Simulation with VCD trace completed."
	@gtkwave vsrc/obj_dir/simx.vcd
endif

include ../Makefile
