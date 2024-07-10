
module accelerator (
    clk, comp_enb, 
    mem_addr, mem_data, 
    mem_read_enb, mem_write_enb, 
    res_addr, res_data, 
    busyb, done
);

    input clk;
    input comp_enb;
    output reg [3:0] mem_addr;
    input [63:0] mem_data;
    output reg mem_read_enb;
    output reg mem_write_enb;
    output reg [3:0] res_addr;
    output reg [63:0] res_data;
    output reg busyb;
    output reg done;

    
    // Declare states
	parameter S_RST = 0, S_READ = 1, S_WORK = 2, S_DONE = 3;
	reg [1:0] state;
    reg [1:0] counter;
    reg [63:0] reg1, reg2;
	// Determine the next state synchronously, based on the
	// current state and the input
	always @ (posedge clk) begin
		if (comp_enb) begin
			state <= S_RST;
            res_addr <= 0;
            res_data <= 0;
            reg1 <= 0;
            reg2 <= 0;
            counter <= 0;
            mem_read_enb <= 0;
            mem_write_enb <= 1;
		end
		else begin
			case (state)
				S_RST: begin
                    if(~comp_enb)
                        state <= S_READ;
                end
				S_READ: begin
                    if(counter == 2'd0) begin
                        mem_addr <= 4'd0;
                        counter <= counter + 1;
                    end 
                    else if (counter == 2'd1) begin
                        reg1 <= mem_data;
                        mem_addr <= 4'd1;
                        counter <= counter + 1;
                    end
                    else if (counter == 2'd2) begin
                        reg2 <= mem_data;
                        counter <= 0;
                        state <= S_WORK;
                    end
                end
                S_WORK: begin
                    if(counter==0) begin
                        mem_write_enb <= 0;
                        res_addr = 4'd2;
                        res_data = reg1 + reg2;
                        counter <= counter + 1;
                    end
                    else begin
                        mem_write_enb <= 1;
                        counter <= 0;
                        state <= S_DONE;
                    end
                end
                default: begin //S_DONE
                    if(comp_enb)
                        state <= S_RST;
                end
			endcase
	    end
    end
	
	// Determine the output based only on the current state
	// and the input (do not wait for a clock edge).
	always @ (state)
	begin
		case (state)
			S_WORK: begin
                busyb <= 0;
                done <= 0;
            end
            S_DONE: begin
                busyb <= 0;
                done <= 1;
            end
            default: begin //S_RST
                busyb <= 1;
                done <= 0;
            end
		endcase
	end

endmodule