
default:
	iverilog -o wave testbench_top.v
	vvp -n wave

generate_input:
	python InputGen.py

verilator:
	verilator -cc -trace --timing testbench_top.v -exe sim_main.cpp

check_result:
	python CheckResult.py

verilator:
	verilator -cc -trace --timing testbench_top.v -exe sim_main.cpp

clean:
	rm -f ./wave 
	rm -f ./*.vcd 
	rm -f ./result_mem.csv
	rm -f ./input_mem.csv
	rm -f ./in.npy