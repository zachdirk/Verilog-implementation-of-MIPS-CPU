`ifndef _HAZARD_DETECTION_UNIT_V
`define _HAZARD_DETECTION_UNIT_V

//module for detecting lw data hazards that cannot be forwarded - hdu_out = 1 means we need to insert a bubble
module hazard_detection_unit(idex_c_mem_read, pipe_ifid_instr, pipe_idex_rt, hdu_out);
	input wire idex_c_mem_read;
	input wire [31:0] pipe_ifid_instr;
	input wire [4:0] pipe_idex_rt;
	
	wire [4:0] pipe_ifid_instr_rt = pipe_ifid_instr[20:16];
	wire [4:0] pipe_ifid_instr_rs = pipe_ifid_instr[25:21];
	
	output reg hdu_out;

	//detect data hazard
	always @(idex_c_mem_read, pipe_idex_rt, pipe_ifid_instr) begin
		if (idex_c_mem_read)
			if ((pipe_idex_rt == pipe_ifid_instr_rt) || (pipe_idex_rt == pipe_ifid_instr_rs))
				hdu_out = 1;
			else
				hdu_out = 0;
		else
			hdu_out = 0;
	end
endmodule

`endif