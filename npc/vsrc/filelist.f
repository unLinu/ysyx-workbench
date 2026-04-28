-I./include/
-I../../ysyxSoC/perip/uart16550/rtl/
-I../../ysyxSoC/perip/spi/rtl/

./pkg/isa_pkg.sv
./pkg/ctrl_pkg.sv
./pkg/pipeline_pkg.sv
./pkg/bypass_pkg.sv

./tb/npc_bind.sv

../../ysyxSoC/build/ysyxSoCFull.v

-y ./core/
-y ./if/
-y ./tb/
-y ./axi/

+libext+.sv+.v
