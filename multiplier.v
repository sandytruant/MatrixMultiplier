module multiplier (
    input clk,
    input rst,
    input ready,
    input signed [7:0] data1,
    input signed [7:0] data2,
    output reg [15:0] result,
    output reg done
);

localparam IDLE = 0, CALC = 1;

reg state;
reg [3:0] data2_addr;
reg signed [15:0] temp1;
reg signed [7:0] temp2;
reg signed [15:0] temp3;

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
    end
    else begin
        case (state)
            IDLE: begin
                if (ready) begin
                    state <= CALC;
                    temp3 <= 16'b0;
                    done <= 1'b0;
                    data2_addr <= 3'b0;
                    temp1 <= $signed(data1);
                    temp2 <= $signed(data2);
                end
            end
            CALC: begin
                if (data2_addr == 8) begin
                    state <= IDLE;
                    done <= 1'b1;
                    result <= temp3;
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
        endcase
    end
end

endmodule
