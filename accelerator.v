`include "systolic_array.v"
`include "sram.v"
`include "sint24_to_bf16.v"

module accelerator (
    clk,
    comp_enb,
    mem_addr,
    mem_data,
    mem_read_enb,
    mem_write_enb,
    res_addr,
    res_data,
    busyb,
    done
);

    integer i;

    input clk;
    input comp_enb;
    output reg [15:0] mem_addr;
    input [63:0] mem_data;
    output reg mem_read_enb;
    output reg mem_write_enb;
    output reg [15:0] res_addr;
    output reg [63:0] res_data;
    output reg busyb;
    output reg done;

    reg [5:0] counter1; // 矩阵1的计数器
    reg [4:0] counter2; // 矩阵2的计数器
    reg [9:0] sram_addr1;
    reg [9:0] sram_addr2;
    reg sram_we;
    reg [127:0] sram_din1;
    reg [127:0] sram_din2;
    wire [127:0] sram_dout1;
    wire [127:0] sram_dout2;

    reg [3:0] row; // sram的行计数器
    reg [3:0] col; // sram的列计数器

    reg rst_systolic_array;
    reg ready_systolic_array;
    reg [4:0] addr1_systolic_array;
    reg [3:0] addr2_systolic_array;
    reg signed [127:0] data1_systolic_array;
    reg signed [127:0] data2_systolic_array;
    wire all_done_systolic_array;
    wire signed [23:0] dout_systolic_array;

    wire [15:0] bf_out;
    reg [63:0] res_temp;

    // Declare states
    parameter S_RST = 0, S_READ1 = 1, S_READ2 = 2, S_WORK = 3, S_WRITE = 4, S_DONE = 5;
    reg [2:0] state;
    reg [1:0] read_state;
    // Determine the next state synchronously, based on the
    // current state and the input
    always @(posedge clk) begin
        if (comp_enb) begin
            state <= S_RST;
            res_addr <= 0;
            res_data <= 0;
            counter1 <= 0;
            counter2 <= 0;
            mem_read_enb <= 1;
            mem_write_enb <= 1;
        end else begin
            case (state)
                S_RST: begin
                    mem_write_enb <= 1;
                    if (~comp_enb) begin
                        // state transfer logic to be designed
                        if (counter2 == 0) begin
                            state <= S_READ1;
                            read_state <= 0;
                        end
                        else begin
                            state <= S_READ2;
                            read_state <= 0;
                        end
                        sram_addr1 <= 0;
                        sram_addr2 <= 0;
                        sram_we <= 1;
                        sram_din1 <= 0;
                        sram_din2 <= 0;
                        mem_read_enb <= 0; // read from input memory
                        row <= 0;
                        col <= 0;
                    end
                end
                S_READ1: begin
                    if (sram_addr1 == 550) begin
                        if (read_state == 0) begin
                            read_state <= 1;
                        end
                        else if (read_state == 1) begin
                            read_state <= 2;
                        end
                        else begin
                           state <= S_READ2;
                            read_state <= 0; 
                        end
                    end
                    else begin
                        if (read_state == 0) begin
                            if (row >= sram_addr1 + 1 || (sram_addr1 >= 512 && row < sram_addr1 - 511)) begin
                                read_state <= 1;
                            end
                            else begin
                                mem_addr <= 64 * (counter1 * 16 + row) + (sram_addr1 - row) / 8;
                                read_state <= 1;
                            end
                        end
                        else if (read_state == 1) begin
                            if (row >= sram_addr1 + 1 || (sram_addr1 >= 512 && row < sram_addr1 - 511)) begin
                                sram_din1[8*row+:8] <= 0;
                            end
                            else begin
                                sram_din1[8*row+:8] <= mem_data[8 * (7 - ((sram_addr1 - row) % 8))+:8];
                            end
                            read_state <= 2;
                        end                 
                        else begin
                            if (row == 15) begin
                                row <= 0;
                                sram_addr1 <= sram_addr1 + 1;
                            end
                            else begin
                                row <= row + 1;
                            end
                            read_state <= 0;
                        end       
                    end
                end
                S_READ2: begin
                    if (sram_addr2 == 550) begin
                        if (read_state == 0) begin
                            read_state <= 1;
                        end
                        else if (read_state == 1) begin
                            read_state <= 2;
                        end
                        else begin
                            state <= S_WORK;
                            state <= S_WORK;
                            mem_read_enb <= 1;
                            sram_we <= 0;
                            sram_addr1 <= 0;
                            sram_addr2 <= 0;
                            rst_systolic_array <= 1;
                            ready_systolic_array <= 1;
                            addr1_systolic_array <= 0;
                            addr2_systolic_array <= 0;
                            data1_systolic_array <= 0;
                            data2_systolic_array <= 0;
                            if (counter2 == 31) begin
                                counter2 <= 0;
                                counter1 <= counter1 + 1;
                            end
                            else begin
                                counter2 <= counter2 + 1;
                            end
                            read_state <= 0;
                        end
                    end
                    else begin
                        if (read_state == 0) begin
                            if (col >= sram_addr2 + 1 || (sram_addr2 >= 512 && col < sram_addr2 - 511)) begin
                                read_state <= 1;
                            end
                            else begin
                                mem_addr <= (16'b1 << 15) + 64 * (sram_addr2 - col) + (counter2 * 16 + col) / 8;
                                read_state <= 1;
                            end
                        end
                        else if (read_state == 1) begin
                            if (col >= sram_addr2 + 1 || (sram_addr2 >= 512 && col < sram_addr2 - 511)) begin
                                sram_din2[8*col+:8] <= 0;
                            end
                            else begin
                                sram_din2[8*col+:8] <= mem_data[8*(7 - (counter2 * 16 + col) % 8)+:8];
                            end
                            read_state <= 2;
                        end                 
                        else begin
                            if (col == 15) begin
                                col <= 0;
                                sram_addr2 <= sram_addr2 + 1;
                            end
                            else begin
                                col <= col + 1;
                            end
                            read_state <= 0;
                        end       
                    end  
                end
                S_WORK: begin
                    rst_systolic_array <= 0;
                    if (sram_addr1 == 550 && sram_addr2 == 550) begin
                        state <= S_WRITE;
                        ready_systolic_array <= 0;
                        mem_write_enb <= 0;
                        res_temp <= 0;
                        addr1_systolic_array <= 0;
                        addr2_systolic_array <= 0;
                    end
                    if (all_done_systolic_array) begin
                        sram_addr1 <= sram_addr1 + 1;
                        sram_addr2 <= sram_addr2 + 1;
                        data1_systolic_array <= sram_dout1;
                        data2_systolic_array <= sram_dout2;
                    end
                end
                S_WRITE: begin
                    if (addr1_systolic_array == 16) begin
                        res_addr <= res_addr + 1;
                        res_data <= res_temp;
                        // mem_write_enb <= 1;
                        if (counter1 == 32) begin
                            state <= S_DONE;
                        end
                        else begin
                            state <= S_RST;
                        end
                    end
                    else begin
                        res_temp[16*(3-addr2_systolic_array%4)+:16] <= bf_out;
                        if (addr2_systolic_array % 4 == 0) begin
                            if (addr1_systolic_array == 0 && (addr2_systolic_array == 0 || addr2_systolic_array == 4)) begin
                                res_addr <= 64 * (counter1 * 32 + counter2 - 1);
                            end
                            else begin
                                res_addr <= res_addr + 1;
                            end
                            res_data <= res_temp;
                        end
                        if (addr2_systolic_array == 15) begin
                            addr1_systolic_array <= addr1_systolic_array + 1;
                            addr2_systolic_array <= 0;
                        end
                        else begin
                            addr2_systolic_array <= addr2_systolic_array + 1;
                        end
                    end
                end
                default: begin  //S_DONE
                    mem_write_enb <= 1;
                    if (comp_enb) state <= S_RST;
                end
            endcase
        end
    end

    // Determine the output based only on the current state
    // and the input (do not wait for a clock edge).
    always @(state) begin
        case (state)
            S_WORK: begin
                busyb <= 1;
                done  <= 0;
            end
            S_READ1: begin
                busyb <= 1;
                done  <= 0;
            end
            S_READ2: begin
                busyb <= 1;
                done  <= 0;
            end
            S_WRITE: begin
                busyb <= 1;
                done  <= 0;
            end
            S_DONE: begin
                busyb <= 0;
                done  <= 1;
            end
            default: begin  //S_RST
                busyb <= 0;
                done  <= 0;
            end
        endcase
    end

    SRAM sram1 (
        .clk(clk),
        .we(sram_we),
        .addr(sram_addr1),
        .din(sram_din1),
        .dout(sram_dout1)
    );

    SRAM sram2 (
        .clk(clk),
        .we(sram_we),
        .addr(sram_addr2),
        .din(sram_din2),
        .dout(sram_dout2)
    );

    systolic_array systolic_array (
        .clk(clk),
        .rst(rst_systolic_array),
        .ready(ready_systolic_array),
        .addr1(addr1_systolic_array),
        .addr2(addr2_systolic_array),
        .data1(data1_systolic_array),
        .data2(data2_systolic_array),
        .all_done(all_done_systolic_array),
        .dout(dout_systolic_array)
    );

    sint24_to_bf16 sint24_to_bf16 (
        .sint_in(dout_systolic_array),
        .bf16_out(bf_out)
    );

endmodule
