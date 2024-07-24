module processing_element (
    input wire clk,
    input wire rst,
    input wire signed [7:0] in_data1,
    input wire signed [7:0] in_data2,
    input wire ready,
    output reg signed [23:0] result,
    output reg done,
    output reg [7:0] out_data1,
    output reg [7:0] out_data2
);

    localparam IDLE = 0, CALC = 1, DONE1 = 2, DONE2 = 3;

    reg [1:0] state;
    reg [3:0] data2_addr;
    reg [15:0] temp1;
    reg [7:0] temp2;
    reg signed [15:0] temp3;

    reg sign1;
    reg sign2;

    always @(posedge clk) begin
        if (rst) begin
            state  <= IDLE;
            result <= 24'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (ready) begin
                        state <= CALC;
                        data2_addr <= 4'b0;
                        if (in_data1[7]) begin
                            temp1 <= ~in_data1 + 1;
                            sign1 <= 1'b1;
                        end else begin
                            temp1 <= in_data1;
                            sign1 <= 1'b0;
                        end
                        if (in_data2[7]) begin
                            temp2 <= ~in_data2 + 1;
                            sign2 <= 1'b1;
                        end else begin
                            temp2 <= in_data2;
                            sign2 <= 1'b0;
                        end
                        temp3 <= 16'b0;
                    end
                end
                CALC: begin
                    if (data2_addr == 8) begin
                        state <= DONE1;
                        done <= 1'b1;
                        if (sign1 == sign2) begin
                            result <= result + temp3;
                        end else begin
                            result <= result - temp3;
                        end
                        out_data1 <= in_data1;
                        out_data2 <= in_data2;
                    end else begin
                        if (temp2[data2_addr]) begin
                            temp3 <= temp3 + (temp1 << data2_addr);
                        end
                        data2_addr <= data2_addr + 1;
                    end
                end
                DONE1: begin
                    state <= DONE2;
                    done  <= 0;
                end
                default: begin  // DONE2
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
