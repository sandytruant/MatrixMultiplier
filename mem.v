module ram # 
(parameter DATA_WIDTH = 64, ADDR_WIDTH = 16) //default is: 64b/word * (2^16)address) = 4Mb
(
clk         , // Clock Input
address     , // Address Input
d           , // Data input
q           , // Data output
cs          , // Chip Select
web           // Write Enable/Read Enable, low active
); 

localparam RAM_DEPTH = 1 << ADDR_WIDTH;

//--------------Input Ports----------------------- 
input clk;
input [ADDR_WIDTH-1:0] address;
input cs;
input web;

//--------------Inout Ports----------------------- 
input [DATA_WIDTH-1:0]  d;
output [DATA_WIDTH-1:0]  q;
reg [DATA_WIDTH-1:0]  data_out;

//--------------Internal variables---------------- 
reg [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

//--------------Core Function--------------------- 
// Tri-State Buffer control 
// output : When web = 1, oe = 1, cs = 1
assign q = (cs) ? data_out : 'bz; 

// Memory Write Block 
// Write Operation : When web = 0, cs = 1
always @ (posedge clk)
begin : MEM_WRITE
   if ( cs && ~web ) begin
       mem[address] = d;
   end
end

// Memory Read Block 
// Read Operation : When web = 1, oe = 1, cs = 1
always @ (address or cs or web)
begin : MEM_READ
    if (cs && web ) begin
         data_out = mem[address];
    end
end

endmodule