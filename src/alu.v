`ifndef _ALU_V
`define _ALU_V

module alu_control(funct, alu_op, alu_control_out);

	input wire [5:0] funct;
	input wire [1:0] alu_op;
	
	output reg [3:0] alu_control_out;
	
	always @(alu_op, funct) begin
		case(alu_op)
			0: alu_control_out = 2;
			1: alu_control_out = 6;
			2:	begin
					case(funct)
						6'h00: alu_control_out = 3; 		// sll
						6'h02: alu_control_out = 4; 		// slr
						6'h20, 6'h21: alu_control_out = 2; 	// add,addu
						6'h22, 6'h23: alu_control_out = 6; 	// sub,subu
						6'h24: alu_control_out = 0; 		// and
						6'h25: alu_control_out = 1;			// or
						6'h27: alu_control_out = 12;		// nor
						6'h2A: alu_control_out = 7; 		// slt
						6'h2B: alu_control_out = 8; 		// sltu
					endcase
				end
			default: alu_control_out = 0;
		endcase
	end
	
endmodule

module alu(data1, data2, alu_control_in, zero, alu_result);
	
	input wire [31:0] data1;
	input wire [31:0] data2;
	input wire [3:0] alu_control_in;
	
	output wire zero;
	output reg [31:0] alu_result;
	
	assign zero = (alu_result == 0);
	always @(alu_control_in, data1, data2) begin
		case(alu_control_in)
			0: alu_result = data1 &  data2;
			1: alu_result = data1 |  data2;
			2: alu_result = data1 +  data2;
			3: alu_result = data2 << data1; // slr, sl1 use RT instead of RS
			4: alu_result = data2 >> data1;
			6: alu_result = data1 -  data2;
			7: begin
				if ($signed(data1) < $signed(data2))
					alu_result = 1;
				else 
					alu_result = 0;
				end
			8: begin
				if (data1 < data2)
					alu_result = 1;
				else 
					alu_result = 0;
				end
			12: alu_result = ~(data1 | data2);
			default: alu_result = 0;
		endcase
	end
	
endmodule

`endif