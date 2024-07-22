
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

initial
begin
    $dumpfile("wave.vcd");
    $dumpvars(0);
end

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