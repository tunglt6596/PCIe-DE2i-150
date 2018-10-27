`timescale 1ns / 1ps

module conv
#(
    parameter integer IMAGE_HEIGHT = 480,
    parameter integer IMAGE_WIDTH  = 640,
    
    parameter integer KERNEL_SIZE  = 3,
    
    parameter integer FP_WORD_LENGTH = 32,
    parameter integer FP_FRAC_LENGTH = 15
	
)
(	
    input wire clk,
    input wire reset,
	
	input wire [6:0] display_mode,
	
    input wire [7:0] pxl_in,
    output reg [23:0] pxl_out,
    output wire ready_in,
	input wire valid_in,
	output wire valid_out,
	output wire sop_out,
	output wire eop_out
);
	
    reg [FP_WORD_LENGTH-1 : 0] kernel_00;
    reg [FP_WORD_LENGTH-1 : 0] kernel_01;
    reg [FP_WORD_LENGTH-1 : 0] kernel_02;
    reg [FP_WORD_LENGTH-1 : 0] kernel_10;
    reg [FP_WORD_LENGTH-1 : 0] kernel_11;
    reg [FP_WORD_LENGTH-1 : 0] kernel_12;
    reg [FP_WORD_LENGTH-1 : 0] kernel_20;
    reg [FP_WORD_LENGTH-1 : 0] kernel_21;
    reg [FP_WORD_LENGTH-1 : 0] kernel_22;
	
	always @*
	begin 
		case(display_mode)
			7'b0000000:			// original pixel
				begin
					kernel_00 = 32'b00000000000000000000000000000000;
					kernel_01 = 32'b00000000000000000000000000000000;
					kernel_02 = 32'b00000000000000000000000000000000;
					kernel_10 = 32'b00000000000000000000000000000000;
					kernel_11 = 32'b00000000000000001000000000000000;
					kernel_12 = 32'b00000000000000000000000000000000;
					kernel_20 = 32'b00000000000000000000000000000000;
					kernel_21 = 32'b00000000000000000000000000000000;
					kernel_22 = 32'b00000000000000000000000000000000;
				end
			7'b0000001:			// gaussian sigma 1
				begin
					kernel_00 = 32'b00000000000000000000100110011101;
					kernel_01 = 32'b00000000000000000000111111011010;
					kernel_02 = 32'b00000000000000000000100110011101;
					kernel_10 = 32'b00000000000000000000111111011010;
					kernel_11 = 32'b00000000000000000001101000100011;
					kernel_12 = 32'b00000000000000000000111111011010;
					kernel_20 = 32'b00000000000000000000100110011101;
					kernel_21 = 32'b00000000000000000000111111011010;
					kernel_22 = 32'b00000000000000000000100110011101;
				end
			7'b0000010:			// gaussian sigma 2
				begin
					kernel_00 = 32'b00000000000000000000110100001010;
					kernel_01 = 32'b00000000000000000000111011000110;
					kernel_02 = 32'b00000000000000000000110100001010;
					kernel_10 = 32'b00000000000000000000111011000110;
					kernel_11 = 32'b00000000000000000001000010111110;
					kernel_12 = 32'b00000000000000000000111011000110;
					kernel_20 = 32'b00000000000000000000110100001010;
					kernel_21 = 32'b00000000000000000000111011000110;
					kernel_22 = 32'b00000000000000000000110100001010;
				end
			7'b0000100:			// sobel x
				begin
					kernel_00 = 32'b00000000000000001000000000000000;
					kernel_01 = 32'b00000000000000000000000000000000;
					kernel_02 = 32'b10000000000000001000000000000000;
					kernel_10 = 32'b00000000000000010000000000000000;
					kernel_11 = 32'b00000000000000000000000000000000;
					kernel_12 = 32'b10000000000000010000000000000000;
					kernel_20 = 32'b00000000000000001000000000000000;
					kernel_21 = 32'b00000000000000000000000000000000;
					kernel_22 = 32'b10000000000000001000000000000000;
				end
			7'b0001000:			// sobel y
				begin
					kernel_00 = 32'b10000000000000001000000000000000;
					kernel_01 = 32'b10000000000000010000000000000000;
					kernel_02 = 32'b10000000000000001000000000000000;
					kernel_10 = 32'b00000000000000000000000000000000;
					kernel_11 = 32'b00000000000000000000000000000000;
					kernel_12 = 32'b00000000000000000000000000000000;
					kernel_20 = 32'b00000000000000001000000000000000;
					kernel_21 = 32'b00000000000000010000000000000000;
					kernel_22 = 32'b00000000000000001000000000000000;
				end
			7'b00010000:			// prewitt x
				begin
					kernel_00 = 32'b00000000000000001000000000000000;
					kernel_01 = 32'b00000000000000000000000000000000;
					kernel_02 = 32'b10000000000000001000000000000000;
					kernel_10 = 32'b00000000000000001000000000000000;
					kernel_11 = 32'b00000000000000000000000000000000;
					kernel_12 = 32'b10000000000000001000000000000000;
					kernel_20 = 32'b00000000000000001000000000000000;
					kernel_21 = 32'b00000000000000000000000000000000;
					kernel_22 = 32'b10000000000000001000000000000000;
				end
			7'b0100000:			// prewitt y
				begin
					kernel_00 = 32'b00000000000000001000000000000000;
					kernel_01 = 32'b00000000000000001000000000000000;
					kernel_02 = 32'b00000000000000001000000000000000;
					kernel_10 = 32'b00000000000000000000000000000000;
					kernel_11 = 32'b00000000000000000000000000000000;
					kernel_12 = 32'b00000000000000000000000000000000;
					kernel_20 = 32'b10000000000000001000000000000000;
					kernel_21 = 32'b10000000000000001000000000000000;
					kernel_22 = 32'b10000000000000001000000000000000;
				end
			default:		// mean
				begin
					kernel_00 = 32'b00000000000000000000111000111001;
					kernel_01 = 32'b00000000000000000000111000111001;
					kernel_02 = 32'b00000000000000000000111000111001;
					kernel_10 = 32'b00000000000000000000111000111001;
					kernel_11 = 32'b00000000000000000000111000111001;
					kernel_12 = 32'b00000000000000000000111000111001;
					kernel_20 = 32'b00000000000000000000111000111001;
					kernel_21 = 32'b00000000000000000000111000111001;
					kernel_22 = 32'b00000000000000000000111000111001;
				end
		endcase
	end 
	
	// Intermediate wires
	wire [FP_WORD_LENGTH-1:0] wire_00; wire [FP_WORD_LENGTH-1:0] wire_01; wire [FP_WORD_LENGTH-1:0] wire_02;
    wire [FP_WORD_LENGTH-1:0] wire_10; wire [FP_WORD_LENGTH-1:0] wire_11; wire [FP_WORD_LENGTH-1:0] wire_12;
    wire [FP_WORD_LENGTH-1:0] wire_20; wire [FP_WORD_LENGTH-1:0] wire_21; wire [FP_WORD_LENGTH-1:0] wire_22;

    // For line buffer
    wire [FP_WORD_LENGTH-1:0] reg_00; wire [FP_WORD_LENGTH-1:0] reg_01; wire [FP_WORD_LENGTH-1:0] reg_02; wire[FP_WORD_LENGTH-1:0] sr_0; 	
    wire [FP_WORD_LENGTH-1:0] reg_10; wire [FP_WORD_LENGTH-1:0] reg_11; wire [FP_WORD_LENGTH-1:0] reg_12; wire[FP_WORD_LENGTH-1:0] sr_1; 
    wire [FP_WORD_LENGTH-1:0] reg_20; wire [FP_WORD_LENGTH-1:0] reg_21; wire [FP_WORD_LENGTH-1:0] reg_22; 
	
	// Row : 1
	mac mac_00(clk, valid_in, pxl_in, kernel_00, 0, wire_00);
	register r_00(clk, reset, valid_in, wire_00, reg_00); 
	
	mac mac_01(clk, valid_in, pxl_in, kernel_01, reg_00, wire_01);
	register r_01(clk, reset, valid_in, wire_01, reg_01); 
    
	mac mac_02r(clk, valid_in, pxl_in, kernel_02, reg_01, wire_02);
	register r_02r(clk, reset, valid_in, wire_02, reg_02); 
    
    shift row_1r(clk, valid_in, reg_02, sr_0);

	// Row : 2
	mac mac_10(clk, valid_in, pxl_in, kernel_10, sr_0, wire_10); 
	register r_10(clk, reset, valid_in, wire_10, reg_10); 
    
	mac mac_11(clk, valid_in, pxl_in, kernel_11, reg_10, wire_11);
	register r_11(clk, reset, valid_in, wire_11, reg_11);
    
    mac mac_12r(clk, valid_in, pxl_in, kernel_12, reg_11, wire_12); 
	register r_12(clk, reset, valid_in, wire_12, reg_12); 
    
	shift row_2(clk, valid_in, reg_12, sr_1);
    
	// Row : 3
	mac mac_20(clk, valid_in, pxl_in, kernel_20, sr_1, wire_20);
	register r_20r(clk, reset, valid_in, wire_20, reg_20); 
    
	mac mac_21(clk, valid_in, pxl_in, kernel_21, reg_20, wire_21); 
	register r_21r(clk, reset, valid_in, wire_21, reg_21); 

	mac mac_22(clk, valid_in, pxl_in, kernel_22, reg_21, wire_22); 
	register r_22r(clk, reset, valid_in, wire_22, reg_22); 
	
    wire [7:0] temp;
	assign temp = reg_22[FP_WORD_LENGTH-1] ? 8'd0 : (reg_22[FP_WORD_LENGTH-2:FP_FRAC_LENGTH+8] ? 8'd255 : reg_22[FP_FRAC_LENGTH+7:FP_FRAC_LENGTH]);        
	
	wire zeros_padding;
	assign zeros_padding = (irow < KERNEL_SIZE-1) | (irow > IMAGE_HEIGHT) | 
						   (irow == KERNEL_SIZE-1 && icol0 < 8+1+1) | (irow == IMAGE_HEIGHT && icol0 > 8+1) |
						   (icol0 == 8+1) | (icol0 == KERNEL_SIZE-1+8);
	always @* 
	begin
		if( zeros_padding ) 
			pxl_out = 24'd0; 
		else 
			pxl_out = {3{temp}};
	end 
	
	reg [9:0] irow;
    reg [9:0] icol0;
    reg [9:0] icol1;
	
    always @( posedge clk )
    begin
        if( reset ) begin 
			irow <= 10'd0;
			icol0 <= 10'd0;
		end
		else if( irow==IMAGE_HEIGHT+1 && icol0==8+1 ) begin 
			irow <= 10'd1;
			if ( valid_in ) 
				icol0 <= 10'd10;
			else 
				icol0 <= 10'd9;
		end
		else if( valid_in ) begin 
            icol0 <= icol0 + 1;
			if( icol0==IMAGE_WIDTH-1 ) begin
                irow <= irow + 1;
				icol0 <= 10'd0;
			end
		end 
    end
	
	always @( posedge clk )
	begin 
		if( reset ) 
			icol1 <= 10'd0;
		else 
			icol1 <= icol0;
	end 
	
	assign ready_in = 1'b1;
	
	reg valid_out_reg;
	always @( posedge clk )
	begin 
		if( icol0 != icol1 ) begin 
			if( irow>KERNEL_SIZE/2-1 && irow<IMAGE_HEIGHT+1 ) begin
				if ( icol0>KERNEL_SIZE-1+8-1 )
					valid_out_reg <= 1'b1;
				else if ( irow>KERNEL_SIZE/2 && icol0<8+1+1 )
					valid_out_reg <= 1'b1;
				else
					valid_out_reg <= 1'b0;
			end 
			else if( irow==IMAGE_HEIGHT+1 ) begin 
			    if ( icol0<8+1+1 )
					valid_out_reg <= 1'b1;
				else
					valid_out_reg <= 1'b0; 
			end
			else 
				valid_out_reg <= 1'b0;
		end
		else 
			valid_out_reg <= 1'b0;
	end
    assign valid_out = valid_out_reg;
    
    reg eop_out_reg;
    always @( posedge clk )
    begin
		if( icol0 != icol1 ) begin 
			if( irow==IMAGE_HEIGHT+1 && icol0==8+1 ) 
				eop_out_reg <= 1'b1;
			else 
				eop_out_reg <= 1'b0; 
		end
		else
		  eop_out_reg <= 1'b0;
    end
    assign eop_out = eop_out_reg;
    
	reg sop_out_reg;
    always @( posedge clk )
    begin
		if( icol0 != icol1 ) begin 
			if( irow==KERNEL_SIZE/2 && icol0==KERNEL_SIZE-1+8 )
				sop_out_reg <= 1'b1;
			else 
				sop_out_reg <= 1'b0;
		end
		else
		  sop_out_reg <= 1'b0;
    end
    assign sop_out = sop_out_reg;
		
endmodule
