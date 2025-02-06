/**
 * Simulation of Output multiplexer.
**/

// define timescale
`timescale 1 ns / 10 ps

module OutputMux_test();

	// local constants
	localparam SIM_DURATION = 300;	// 300 ns
	
	localparam WIDTH = 4;
	
	// test signals
	wire [WIDTH-1:0] out_line;
	
	// test registers
	reg [WIDTH-1:0] in_line0 = 0;
	reg [WIDTH-1:0] in_line1 = 0;
	reg [WIDTH-1:0] select_line = 4'b0000;
	
	// instantiate uut
	OutputMux #(
		.WIDTH(WIDTH)
	) UUT (
		.in_line0(in_line0),
		.in_line1(in_line1),
		.select_line(select_line),
		.out_line(out_line)
	);
	
	// generate some signal on input line 0
	initial
	begin
		#10;
		in_line0 = 7;
		#15;
		in_line0 = 3;
		#13;
		in_line0 = 14;
		#11;
		in_line0 = 2;
		#18;
		in_line0 = 7;
		#11;
		in_line0 = 8;
		#9;
		in_line0 = 0;
		#10;
		in_line0 = 1;
	end
	
	// generate some signal on input line 0
	initial
	begin
		#8;
		in_line0 = 1;
		#19;
		in_line0 = 11;
		#12;
		in_line0 = 15;
		#14;
		in_line0 = 6;
		#17;
		in_line0 = 4;
		#3;
		in_line0 = 7;
		#14;
		in_line0 = 12;
		#5;
		in_line0 = 0;
	end
	
	// test code
	initial
	begin
		#5;
		select_line = 4'b1111;
		#5;
		select_line = 4'b0000;
		#5;
		select_line = 4'b1001;
		#5;
		select_line = 4'b1100;
		#5;
		select_line = 4'b0110;
		#5;
		select_line = 4'b0011;
		#5;
		select_line = 4'b1000;
		#5;
		select_line = 4'b0001;
		#5;
		select_line = 4'b0010;
		#5;
		select_line = 4'b0100;
		#5;
		select_line = 4'b1110;
		#5;
		select_line = 4'b0111;
		#5;
		select_line = 4'b1011;
		#5;
		select_line = 4'b1101;
		#5;
		select_line = 4'b0000;
		#5;
		select_line = 4'b1111;
	end
	
	// run simulation (output to .vcd file)
	initial
	begin
		
		// create simulation output file
		$dumpfile("OutputMux_test.vcd");
		$dumpvars(0, OutputMux_test);
		
		// wait for simulation to complete
		#(SIM_DURATION);
		
		// end simulation
		$finish;
	end

endmodule