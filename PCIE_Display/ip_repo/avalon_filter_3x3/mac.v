// Multiply Accumulate Unit
`timescale 1ns / 1ps

module mac
#(
    parameter integer FP_WORD_LENGTH = 32,
    parameter integer FP_FRAC_LENGTH = 15
)
(
    input clk,
    input valid,
    input [7:0] in,
    input [FP_WORD_LENGTH-1:0] w,
    input [FP_WORD_LENGTH-1:0] b,
    output [FP_WORD_LENGTH-1:0] out
    );

	wire [FP_WORD_LENGTH-1:0] d;

    qmults 
    #(
        .FP_WORD_LENGTH(FP_WORD_LENGTH),
        .FP_FRAC_LENGTH(FP_FRAC_LENGTH)
    )qmults_unit(
        .clk(clk),
        .valid(valid),
        .a(in),
        .b(w),
        .y(d)
    );
	
    qadd #(
        .FP_WORD_LENGTH(FP_WORD_LENGTH),
        .FP_FRAC_LENGTH(FP_FRAC_LENGTH)
    )qadd_unit(
        .a(d),
        .b(b),
        .c(out)
    );

endmodule
