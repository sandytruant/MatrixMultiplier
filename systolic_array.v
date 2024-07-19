`include "processing_element.v"

module SystolicArray(
    input clk,
    input rst,
    input ready,
    input [3:0] addr1, // 读取结果的地址
    input [3:0] addr2, // 读取结果的地址
    input signed [127:0] data1,
    input signed [127:0] data2,
    output all_done,
    output signed [22:0] dout
);

    wire signed [7:0] actual_data1 [0:15];
    wire signed [7:0] actual_data2 [0:15];

    // 中间连线
    reg signed [7:0] in_data1 [0:15][0:15];
    reg signed [7:0] in_data2 [0:15][0:15];
    wire signed [7:0] out_data1 [0:15][0:15];
    wire signed [7:0] out_data2 [0:15][0:15];
    wire signed [22:0] result [0:15][0:15];
    wire done [0:15][0:15];

    // 行列生成
    genvar i, j;
    generate
        for (i = 0; i < 16; i = i + 1) begin : row
            for (j = 0; j < 16; j = j + 1) begin : col
                ProcessingElement pe_inst (
                    .clk(clk),
                    .rst(rst),
                    .ready(ready),
                    .in_data1(in_data1[i][j]),
                    .in_data2(in_data2[i][j]),
                    .result(result[i][j]),
                    .done(done[i][j]),
                    .out_data1(out_data1[i][j]),
                    .out_data2(out_data2[i][j])
                );
            end
        end
    endgenerate

    generate
        for (i = 0; i < 16; i = i + 1) begin
            assign actual_data1[i] = data1[8 * i +: 8];
            assign actual_data2[i] = data2[8 * i +: 8];
        end
    endgenerate

    integer k, l;

    always @(posedge clk) begin
        if (rst) begin
            for (k = 0; k < 16; k = k + 1) begin
                for (l = 0; l < 16; l = l + 1) begin
                    in_data1[k][l] <= 0;
                    in_data2[k][l] <= 0;
                end
            end
        end
        else begin
            if (done[0][0]) begin
                in_data1[0][0] <= actual_data1[0];
                in_data2[0][0] <= actual_data2[0];
            end
            for (k = 1; k < 16; k = k + 1) begin
                if (done[k][0]) begin
                    in_data1[k][0] <= actual_data1[k];
                    in_data2[k][0] <= out_data2[k - 1][0];
                end
                if (done[0][k]) begin
                    in_data2[0][k] <= actual_data2[k];
                    in_data1[0][k] <= out_data1[0][k - 1];
                end
            end
            for (k = 1; k < 16; k = k + 1) begin
                for (l = 1; l < 16; l = l + 1) begin
                    if (done[k][l]) begin
                        in_data1[k][l] <= out_data1[k][l - 1];
                        in_data2[k][l] <= out_data2[k - 1][l];
                    end
                end
            end
        end
    end

    assign all_done = done[15][15];
    assign dout = result[addr1][addr2];

endmodule
