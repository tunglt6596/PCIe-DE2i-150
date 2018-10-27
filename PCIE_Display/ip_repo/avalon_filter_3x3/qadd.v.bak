`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    09:28:18 08/24/2011 
// Design Name: 
// Module Name:    q15_add 
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
module qadd #(
	//Parameterized values
	parameter FP_WORD_LENGTH = 32,
    parameter FP_FRAC_LENGTH = 15
)
(
    input [FP_WORD_LENGTH-1:0] a,
    input [FP_WORD_LENGTH-1:0] b,
    output [FP_WORD_LENGTH-1:0] c
);

reg [FP_WORD_LENGTH-1:0] res;

assign c = res;

always @(a,b) begin
    // both negative or both positive
    if(a[FP_WORD_LENGTH-1] == b[FP_WORD_LENGTH-1]) begin						//	Since they have the same sign, absolute magnitude increases
        res[FP_WORD_LENGTH-2:0] = a[FP_WORD_LENGTH-2:0] + b[FP_WORD_LENGTH-2:0];		//		So we just add the two numbers
        res[FP_WORD_LENGTH-1] = a[FP_WORD_LENGTH-1];							//		and set the sign appropriately...  Doesn't matter which one we use, 
                                                            //		they both have the same sign
                                                            //	Do the sign last, on the off-chance there was an overflow...  
        end												//		Not doing any error checking on this...
    //	one of them is negative...
    else if(a[FP_WORD_LENGTH-1] == 0 && b[FP_WORD_LENGTH-1] == 1) begin		//	subtract a-b
        if( a[FP_WORD_LENGTH-2:0] > b[FP_WORD_LENGTH-2:0] ) begin					//	if a is greater than b,
            res[FP_WORD_LENGTH-2:0] = a[FP_WORD_LENGTH-2:0] - b[FP_WORD_LENGTH-2:0];			//		then just subtract b from a
            res[FP_WORD_LENGTH-1] = 0;										//		and manually set the sign to positive
            end
        else begin												//	if a is less than b,
            res[FP_WORD_LENGTH-2:0] = b[FP_WORD_LENGTH-2:0] - a[FP_WORD_LENGTH-2:0];			//		we'll actually subtract a from b to avoid a 2's complement answer
            if (res[FP_WORD_LENGTH-2:0] == 0)
                res[FP_WORD_LENGTH-1] = 0;										//		I don't like negative zero....
            else
                res[FP_WORD_LENGTH-1] = 1;										//		and manually set the sign to negative
            end
        end
    else begin												//	subtract b-a (a negative, b positive)
        if( a[FP_WORD_LENGTH-2:0] > b[FP_WORD_LENGTH-2:0] ) begin					//	if a is greater than b,
            res[FP_WORD_LENGTH-2:0] = a[FP_WORD_LENGTH-2:0] - b[FP_WORD_LENGTH-2:0];			//		we'll actually subtract b from a to avoid a 2's complement answer
            if (res[FP_WORD_LENGTH-2:0] == 0)
                res[FP_WORD_LENGTH-1] = 0;										//		I don't like negative zero....
            else
                res[FP_WORD_LENGTH-1] = 1;										//		and manually set the sign to negative
            end
        else begin												//	if a is less than b,
            res[FP_WORD_LENGTH-2:0] = b[FP_WORD_LENGTH-2:0] - a[FP_WORD_LENGTH-2:0];			//		then just subtract a from b
            res[FP_WORD_LENGTH-1] = 0;										//		and manually set the sign to positive
            end
    end
end

endmodule
