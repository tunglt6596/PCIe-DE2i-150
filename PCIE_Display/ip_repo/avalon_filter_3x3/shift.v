// Shifts data by a fixed depth.
// Optimize in future by finding a way to create 2-d arrays

module shift
#(
    parameter FP_WORD_LENGTH = 32,
    parameter IMAGE_WIDTH = 640,
    parameter KERNEL_SIZE = 3
)
(
	input clk,
	input valid,
	input [FP_WORD_LENGTH-1:0] data_in,
	output [FP_WORD_LENGTH-1:0] data_out
);

	localparam D = IMAGE_WIDTH-KERNEL_SIZE;

	// Define holding register for each bit
	reg [FP_WORD_LENGTH-1:0] hr[D-1:0];

	integer i;
	always @(posedge clk) 
	begin
	   if( valid ) begin
            hr[0] <= data_in;
            for(i=1; i<D; i=i+1)
                hr[i] <= hr[i-1];
       end
	end

	assign data_out = hr[D-1];

endmodule
