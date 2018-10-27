//-----------------------------------------------------------------------------
//
// Title       : register
// Design      : sobel_filter
// Author      : TungLT
// Company     : Hust
//
//-----------------------------------------------------------------------------
//
// File        : d:\my_designs\sobel_filter\sobel_filter\src\register.v
// Generated   : Mon Jun 25 01:31:50 2018
// From        : interface description file
// By          : Itf2Vhdl ver. 1.22
//
//-----------------------------------------------------------------------------
//
// Description : 
//
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps

//{{ Section below this comment is automatically maintained
//   and may be overwritten
//{module {register}}
module register
#(
    parameter FP_WORD_LENGTH = 32
) 
(
	input clk,
	input reset, 
	input valid,
	input [FP_WORD_LENGTH-1:0] w, 
	output reg [FP_WORD_LENGTH-1:0] r
);

// -- Enter your statements here -- //
always @(posedge clk)
begin
	if( reset ) 
		r <= 0;
	else if( valid )
		r <= w;
end	 

endmodule 
