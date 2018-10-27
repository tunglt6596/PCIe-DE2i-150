module gpio
(
	input wire clk,
	input wire reset,
	input wire write_n,
	input wire address,
	input wire[31:0] writedata,
	output wire[31:0] readdata,
	
	//signal to control
	output wire en
	
);

reg[31:0] status;

always @(posedge clk)
begin
	if( reset ) 
		status <= 0;
	else if(~write_n && address == 0)
		status <= writedata;
end

assign readdata = status;
assign en = status[0];

endmodule
