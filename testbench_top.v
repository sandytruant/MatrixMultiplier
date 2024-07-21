
`timescale 1ns/1ns
`include "mem.v"
`include "accelerator.v"
`define T 2 // define macro for clock period

module testbench_top;

integer i, file1;
reg clk = 0;
always #(`T/2) clk = ~clk;
reg comp_enb;

wire [15:0] mem_addr;
wire [63:0] mem_data;
wire mem_read_enb;
wire mem_write_enb;
wire [15:0] res_addr;
wire [63:0] res_data;
wire busyb, done;
wire [2:0] state;
wire [5:0] counter1;
wire [4:0] counter2;
wire [9:0] sram_addr2;
wire [3:0] col;
wire [15:0] bf_out;
wire [23:0] dout_systolic_array;
wire [4:0] addr1_systolic_array;
wire [3:0] addr2_systolic_array;

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0);
end


initial begin
    $monitor("time=%d, clk=%b, state=%d, counter1=%d, counter2=%d, comp_enb=%b, mem_addr=%h, mem_data=%h, mem_read_enb=%b, mem_write_enb=%b, res_addr=%h, res_data=%h, busyb=%b, done=%b", $time, clk, state, counter1, counter2, comp_enb, mem_addr, mem_data, mem_read_enb, mem_write_enb, res_addr, res_data, busyb, done);
end

/*
initial begin
    $monitor("res_addr=%h, res_data=%h, bf_out=%h, dout=%h, addr1=%d, addr2=%d", res_addr, res_data, bf_out, dout_systolic_array, addr1_systolic_array, addr2_systolic_array);
end
*/
accelerator u_accelerator (
 .clk           (clk)
,.comp_enb      (comp_enb)
,.mem_addr      (mem_addr)
,.mem_data      (mem_data)
,.mem_read_enb  (mem_read_enb)
,.mem_write_enb (mem_write_enb)
,.res_addr      (res_addr)
,.res_data      (res_data)
,.busyb         (busyb)
,.done          (done)
,.state         (state)
,.counter1      (counter1)
,.counter2      (counter2)
,.sram_addr2    (sram_addr2)
,.col           (col)
,.bf_out        (bf_out)
,.dout_systolic_array (dout_systolic_array)
,.addr1_systolic_array (addr1_systolic_array)
,.addr2_systolic_array (addr2_systolic_array)
);

ram #(.DATA_WIDTH(64), .ADDR_WIDTH(16)) u_input_mem (
 .clk       (clk)
,.web       (~mem_read_enb)
,.address   (mem_addr)
,.d         ()
,.q         (mem_data)
,.cs        (1'b1)
);

ram #(.DATA_WIDTH(64), .ADDR_WIDTH(16)) u_res_mem (
 .clk       (clk)
,.web       (mem_write_enb)
,.address   (res_addr)
,.d         (res_data)
,.q         (),
.cs         (1'b1)
);

// %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

always @(posedge clk) begin
    if (done) begin
        #(`T * 10); // wait for 10 clock cycles
        // readout result_memory content to "result_mem.csv"
        file1=$fopen("result_mem.csv","w");
        for(i=0;i<(1<<16);i++)
            $fwrite( file1 , "%8h\n" , u_res_mem.mem[i]);
        $fclose(file1);
        $finish; 
    end
end

initial begin
    // start simulation
    $readmemh("input_mem.csv", u_input_mem.mem);
    comp_enb = 1;
    #(`T * 10) comp_enb = 0;
end

endmodule