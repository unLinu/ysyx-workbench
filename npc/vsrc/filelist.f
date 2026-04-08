+incdir+./include/

./pkg/isa_pkg.sv
./pkg/ctrl_pkg.sv
./pkg/pipeline_pkg.sv
./pkg/bypass_pkg.sv

./core/npc_top.sv

-y ./core/
-y ./if/
-y ./tb/
-y ./axi/

+libext+.sv+.v
