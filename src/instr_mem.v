// Verilog MIPS instruction memory module

`ifndef _INSTR_MEM_V
`define _INSTR_MEM_V

module instr_mem (clock, reset, pc, instr);

parameter INSTR_MEM_BYTES = 'h1000; // 4 KB of data memory

input wire [31:0] pc;
input wire clock;
input wire reset;

output wire [31:0] instr;

reg [31:0] mem [0:(INSTR_MEM_BYTES - 1) >> 2];     // 1024 32-bit locations
wire [31:0] internal_pc;

assign internal_pc = pc - 32'h3000;
assign instr = mem[internal_pc[31:2]];   // ignore 2 LSBs, word alignment implies 2 LSBs can only be 00


integer i;
always @(posedge clock)
begin
    if ( reset ) begin
        // zero memory on reset
        for( i = 0; i < 1024; i = i + 1 ) begin
            mem[i] <= 0;
        end
    end
end

endmodule

`endif