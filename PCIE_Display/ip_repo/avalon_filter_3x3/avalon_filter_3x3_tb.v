`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/22/2018 09:03:55 PM
// Design Name: 
// Module Name: axi_conv_fp_3x3_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module avalon_filter_3x3_tb();

    localparam T = 20;
    
    localparam L = 32;
    localparam M = 480;
    localparam N = 640;
    localparam K = 3;
        
    localparam NUM_PIXEL_IN = M*N;
    localparam NUM_PIXEL_OUT = M*N;
	
	reg Clk;
	reg Reset;
	
    // Ports of Avalon Stream Sink
    wire Sink_ready;
    reg [23 : 0] Sink_data;
    reg Sink_valid;
    
    // Ports of Avalon Stream Source
    wire Source_valid;
    wire [23 : 0] Source_data;
    wire Source_eop;
    wire Source_sop;
    reg Source_ready;
    
	// Instantiate the Unit Under Test (UUT)
	avalon_filter_3x3 dut (
		.Clk(Clk),
		.Reset(Reset), 

		.Sink_ready(Sink_ready), 
		.Sink_data(Sink_data),
		.Sink_valid(Sink_valid),
		
		.Source_ready(Source_ready),
		.Source_data(Source_data),
        .Source_valid(Source_valid),
		.Source_sop(Source_sop),
		.Source_eop(Source_eop)
	);

    always 
    begin
        Clk = 1'b0;
        #(T/2);
        Clk = 1'b1;
        #(T/2);
    end

    integer file_out;
    integer i=0;
    reg [23:0] data_reg[NUM_PIXEL_IN-1:0];
    
    initial begin
        //Read all data
        $readmemb("D:\\test2\\image_in.txt", data_reg);
        #10;
        //Open file to write
        file_out = $fopen("D:\\test2\\image_out.txt", "w");
        #10; 
        
        // Reset system
        @(posedge Clk);
        Reset = 1;
        @(posedge Clk);
        Reset = 0;
        
        Source_ready = 1'b1;
        
        while(i < NUM_PIXEL_IN) begin
            @(posedge Clk);
            Sink_data = data_reg[i];
            Sink_valid = 1;
			@(posedge Clk);
			Sink_valid = 0;
			repeat(3) @(posedge Clk);
            if( Sink_ready )
                i = i + 1;
        end
        
        i = 0;
        while(i < NUM_PIXEL_IN) begin
            @(posedge Clk);
            Sink_data = data_reg[i];
            Sink_valid = 1;
            @(posedge Clk);
            Sink_valid = 0;
            repeat(3) @(posedge Clk);
            if( Sink_ready )
                i = i + 1;
        end            
        Sink_valid = 0;
    end 
    
    initial 
    begin
        repeat(30) @(posedge Clk);
        Source_ready = 1'b0;
        repeat(5) @(posedge Clk);
        Source_ready = 1'b1;
        repeat(5) @(posedge Clk);
        Source_ready = 1'b0;
        repeat(5) @(posedge Clk);
        Source_ready = 1'b1;
        repeat(15) @(posedge Clk);
        Source_ready = 1'b1;
        repeat(15) @(posedge Clk);
        Source_ready = 1'b1;
    end
    
    //Write data when valid signal of the axi output is set
    integer count = 0;
    initial 
    begin
        while( count < NUM_PIXEL_OUT ) 
        begin
            @(posedge Clk);
            if( Source_valid ) begin
                $fdisplay(file_out, "%h", Source_data); 
                count = count + 1;
            end
        end
        $fclose(file_out);
        #100;
        $stop;       
    end
    
endmodule
