`default_nettype none
`timescale 1ns/1ns

`include "src/alu.v"
module alu_tb();

reg [5:0] funct; 
reg [1:0] alu_op;
wire [3:0] alu_control_out;

reg [31:0] data1;
reg [31:0] data2;
reg [3:0] alu_control_in;
wire zero;
wire [31:0] alu_result;

alu_control alu_b(funct, alu_op, alu_control_out);
alu alu(data1, data2, alu_control_out, zero, alu_result);
initial begin
	$dumpfile("alu_waves.vcd");
	$dumpvars;
	data1 = 2;
	data2 = 1;
	#50 funct = 6'bxxxxxx;
	#50 alu_op = 2'b00;
	#50 alu_op = 2'b01;
	#50 alu_op = 2'b10;
	#50 funct = 6'b100000;
	#50 funct = 6'b100010;
	#50 funct = 6'b100100;
	#50 funct = 6'b100101;
	#50 funct = 6'b101010;
	#50	funct = 6'bxxxxxx;
	#100 $finish;
		
end


endmodule