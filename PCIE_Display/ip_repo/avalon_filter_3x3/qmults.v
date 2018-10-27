`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:33:36 01/02/2014 
// Design Name: 
// Module Name:    qmults 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module qmults 
    #(
	//Parameterized values
	parameter FP_WORD_LENGTH = 32,
	parameter FP_FRAC_LENGTH = 15
	)
	(
	input wire clk,
	input wire valid,
	input wire [7:0] a,
	input wire [FP_WORD_LENGTH-1:0] b,
	output wire [FP_WORD_LENGTH-1:0] y
	);
    
    reg [7:0] a_pipeline [0:6];
    reg [2*FP_WORD_LENGTH-2:0] b_pipeline [0:6];
    reg [2*FP_WORD_LENGTH-2:0] partials [0:7];
    reg [0:7] signs;
    integer i;
    
	always @( posedge clk )
	begin
        if( valid ) begin
            a_pipeline[0] <= a;
            b_pipeline[0] <= b;
            signs[0] <= b[FP_WORD_LENGTH-1];
            for (i = 1; i < 7; i = i+1) begin
                a_pipeline[i] <= a_pipeline[i-1];
                b_pipeline[i] <= b_pipeline[i-1];
            end
            partials[0] <= a[0] ? b : 0;
            for (i = 1; i < 8; i = i+1) begin
                partials[i] <= (a_pipeline[i-1][i] ? b_pipeline[i-1] << i : 0) +
                        partials[i-1];
                signs[i] <= signs[i-1];
            end
        end
	end
	assign y[FP_WORD_LENGTH-1] = signs[7];
	assign y[FP_WORD_LENGTH-2:0] = partials[7][FP_WORD_LENGTH-2:0];
	
endmodule
