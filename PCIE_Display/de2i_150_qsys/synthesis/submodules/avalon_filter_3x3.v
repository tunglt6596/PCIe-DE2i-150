`timescale 1 ns / 1 ps

	module avalon_filter_3x3 #
	(
		// Users to add parameters here
        parameter integer IMAGE_HEIGHT = 480,
        parameter integer IMAGE_WIDTH  = 640,
        
        parameter integer KERNEL_SIZE  = 3,
        
        parameter integer FP_WORD_LENGTH = 32,
        parameter integer FP_FRAC_LENGTH = 15,
            
		// User parameters ends
		// Do not modify the parameters beyond this line

		// Parameters of Avalon ST Sink
		parameter integer SINK_DATA_WIDTH	= 24,

		// Parameters of Avalon ST Source
		parameter integer SOURCE_DATA_WIDTH	= 24
	)
	(
		// Users to add ports here
		input wire Clk,
		input wire Reset,
		
		input wire [6:0] Display_mode,
		// User ports ends
		// Do not modify the ports beyond this line

		// Ports of Axi Slave Bus Interface S_AXIS
		output wire Sink_ready,
		input wire Sink_valid,
		input wire Sink_sop,
		input wire Sink_eop,
		input wire [SINK_DATA_WIDTH-1 : 0] Sink_data,
		
		// Ports of Axi Master Bus Interface M_AXIS
		input wire Source_ready,
		output wire Source_valid,
		output wire Source_sop,
		output wire Source_eop,
		output wire [SOURCE_DATA_WIDTH-1 : 0] Source_data
	);
 
	// Add user logic here
    conv #(
        // Image parameters
        .IMAGE_HEIGHT(IMAGE_HEIGHT),
        .IMAGE_WIDTH(IMAGE_WIDTH),
        // Kernel size
        .KERNEL_SIZE(KERNEL_SIZE),
        // Fixed point number
        .FP_WORD_LENGTH(FP_WORD_LENGTH),
        .FP_FRAC_LENGTH(FP_FRAC_LENGTH)
    )conv_unit(
        .clk(Clk),
        .reset(Reset),
		.display_mode(Display_mode),
        .pxl_in(Sink_data[7:0]),
        .pxl_out(Source_data),
        .ready_in(Sink_ready),
		.valid_in(Sink_valid),
        .valid_out(Source_valid),
		.sop_out(Source_sop),
        .eop_out(Source_eop)
    );    
	
	// User logic ends

	endmodule
