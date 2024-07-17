module ProcessingElement(
    input wire clk,
    input wire rst,
    input wire signed [7:0] in_data1,
    input wire signed [7:0] in_data2,
    input wire ready,
    output reg signed [22:0] result,
    output reg done,
    output reg [7:0] out_data1,
    output reg [7:0] out_data2
);

localparam IDLE = 0, CALC = 1, DONE1 = 2, DONE2 = 3;

reg [1:0] state;
reg [3:0] data2_addr;
reg signed [15:0] temp1;
reg signed [7:0] temp2;
reg signed [15:0] temp3;

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        result <= 23'b0;
    end
    else begin
        case (state)
            IDLE: begin
                if (ready) begin
                    state <= CALC;
                    data2_addr <= 4'b0;
                    temp1 <= $signed(in_data1);
                    temp2 <= $signed(in_data2);
                    temp3 <= 16'b0;
                end
            end
            CALC: begin
                if (data2_addr == 8) begin
                    state <= DONE1;
                    done <= 1'b1;
                    result <= result + $signed(temp3);
                    out_data1 <= in_data1;
                    out_data2 <= in_data2;
                end
                else begin
                    if (temp2[data2_addr]) begin
                        if (data2_addr == 7) begin
                            temp3 <= temp3 - (temp1 <<< data2_addr);
                        end
                        else begin
                            temp3 <= temp3 + (temp1 <<< data2_addr);
                        end
                    end
                    data2_addr <= data2_addr + 1;
                end
            end
            DONE1: begin
                state <= DONE2;
                done <= 0;
            end
            DONE2: begin
                state <= IDLE;
            end
        endcase
    end
end

endmodule