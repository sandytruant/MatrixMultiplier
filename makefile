
default:
	iverilog -o wave testbench_top.v
	vvp -n wave

generate_input:
	python InputGen.py

clean:
	rm -f ./wave 
	rm -f ./*.vcd 
	rm -f ./result_mem.csv
	rm -f ./input_mem.csv