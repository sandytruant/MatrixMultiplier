# MatrixMultiplier

## IO
1. Input:
- Size:
$2 \times 512 \times 512 \times 8bit=4194304bits=4Mb$
- Input file(input_mem.csv):
$65536 rows \times 8integers \times 8bits=65536 rows \times 16 hexes = 4Mb$
- Input memory(u_input_mem in testbench_top.v):
$DataWidth = 64, AddrWidth = 16; 64 \times 2^{16} = 4Mb$ 
- So 1 data in memory contains 8 integers, i.e. 1 row in input_mem.csv
2. Output:
- Size:
$512 \times 512 \times 8bit=2Mb$
- Output memory(u_res_mem in testbench_top.v): 
## TODO
1. 