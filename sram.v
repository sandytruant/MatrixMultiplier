module SRAM (
    input wire clk,
    input wire we,  // Write enable
    input wire [9:0] addr,  // Address bus
    input wire [127:0] din,  // Data input
    output reg [127:0] dout  // Data output
);

    // Declare memory array
    reg [127:0] memory [0:1023];  // 543 locations of 8-bit wide memory

    always @(posedge clk) begin
        if (we) begin
            // Write operationcontroller
            memory[addr] <= din;
        end else begin
            // Read operation
            dout <= memory[addr];
        end
    end
endmodule
