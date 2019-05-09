// Verilog MIPS data memory module.
`ifndef _DATA_MEM_V
`define _DATA_MEM_V

module data_mem (clock, reset, addr, memread, memwrite, byte_en, write_d, read_d);

parameter DATA_MEM_BYTES = 'h3000; // 12 KB of data memory

input wire memread;           // control signal for memory read
input wire memwrite;          // control signal for memory write
input wire byte_en;
input wire [31:0] addr;       // input address
input wire [31:0] write_d;    // input data to be written
input wire clock;
input wire reset;

output wire [31:0] read_d;

reg [31:0] d_mem [0:(DATA_MEM_BYTES - 1) >> 2];  // 32-bit word addressable memory

integer i;

reg [31:0] new_word;

always @(posedge clock) begin
    if ( reset ) begin
        // zero d_mem
        for( i = 0; i < (DATA_MEM_BYTES >> 2); i = i + 1 ) begin
            d_mem[i] <= 0;
        end 
    end
    if (memwrite === 1'b1) begin
        new_word = (d_mem[addr[31:2]] & ~(8'hFF << addr[1:0]*8)) | (write_d << addr[1:0]*8);
        d_mem[addr[31:2]] <= byte_en ? new_word : write_d;
    end
end
assign read_d = (memread===1'b1) ? (byte_en ? ((d_mem[addr[31:2]] >> addr[1:0]*8) & 32'h0000_00FF) : d_mem[addr[31:2]]) : 32'd0;

endmodule

`endif