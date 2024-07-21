module sint24_to_bf16(
    input wire [23:0] sint_in,
    output [15:0] bf16_out
);

reg sign;
reg [23:0] abs_value;
reg [7:0] exponent;
reg [6:0] mantissa;
reg [23:0] result;
integer i, j;
reg found;

assign bf16_out = result;

always @(sint_in) begin
    sign = sint_in[23];
    if (sign == 1'b1) begin
        abs_value = ~sint_in + 1;
    end else begin
        abs_value = sint_in;
    end

    exponent = 8'b0;
    mantissa = 7'b0;
    found = 1'b0;

    if (abs_value != 24'b0) begin
        for (i = 23; i >= 0 && !found; i = i - 1) begin
            if (abs_value[i] == 1'b1) begin
                exponent = 8'd127 + i;  // 127是偏移值
                for (j = i - 1; j >= 0; j = j - 1) begin
                    mantissa[j - i + 7] = abs_value[j];
                end
                found = 1'b1;
            end
        end
    end
    else begin
        exponent = 8'b0;
        mantissa = 7'b0;
    end

    result = {sign, exponent, mantissa};
end

endmodule
