# Matrix Multiplying Accelerator

This is a chip design for accelerating matrix multiplying (matrix shape is 512 * 512).

## Usage

- Generate 2 random input matrixes. This will generate input_mem.csv.
```Bash
python InputGen.py
```

- Simulate. This will genetare 3 files: wave, wave.vcd, result_mem.csv.
```Bash
iverilog -o wave testbench_top.v
vvp -n wave
```

- Check the result.
```Bash
python CheckResult.py