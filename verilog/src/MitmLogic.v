/**
 * Main MITM logic module:
 * - generates output data based on input data
 * - decides wether to output real and fake data
**/

module MitmLogic # (

	// parameters
	parameter	DATA_SIZE = 8
) (

	// inputs
	input					sys_clk,
	input					rst,
	input					eval,
	input	[DATA_SIZE-1:0] real_miso_data,
	input	[DATA_SIZE-1:0] real_mosi_data,
	
	// outputs
	output	reg	[DATA_SIZE-1:0] fake_miso_data = 0,
	output	reg	[DATA_SIZE-1:0] fake_mosi_data = 0,
	output	reg					fake_miso_select = 1'b0,
	output	reg					fake_mosi_select = 1'b0,
	output	reg					data_valid = 1'b0
	
);

	always @ (posedge sys_clk or posedge rst)
	begin
		// on reset clear internal state
		if (rst == 1'b1) begin
			fake_miso_data <= 0;
			fake_mosi_data <= 0;
			fake_miso_select <= 1'b0;
			fake_mosi_select <= 1'b0;
			data_valid <= 1'b0;
		end
		
		// on eval signal do the logic
		else if (eval == 1'b1) begin
			fake_miso_select <= 1'b0;
			fake_mosi_select <= 1'b0;
			data_valid <= 1'b1;
		end
	end

endmodule