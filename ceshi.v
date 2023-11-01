`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   08:52:48 03/15/2018
// Design Name:   adda_test
// Module Name:   E:/fpga learning/AX516/AX516.170526/AX516/09_VERILOG/28_adda_test/ceshi.v
// Project Name:  adda_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: adda_test
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ceshi;

	// Inputs
	reg clk;
	reg key4;
	reg [7:0] addata;

	// Outputs
	wire daclk;
	wire [7:0] dadata;
	wire adclk;

	// Instantiate the Unit Under Test (UUT)
	adda_test uut (
		.clk(clk), 
		.key4(key4), 
		.daclk(daclk), 
		.dadata(dadata), 
		.adclk(adclk), 
		.addata(addata)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		key4 = 0;
		addata = 0;

		// Wait 100 ns for global reset to finish
		#100;
      #2000000; 
			key4=1;
		#2000000;
			key4=2;
		#2000000; 
			key4=3;
		#2000000; 
			key4=4;
			
		// Add stimulus here

	end
      
endmodule

