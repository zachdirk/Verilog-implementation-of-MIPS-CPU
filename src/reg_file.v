`ifndef _REG_FILE_V
`define _REG_FILE_V

module reg_file (clock, reset, reg_read_addr_1, reg_read_data_1, reg_read_addr_2, reg_read_data_2, reg_write, reg_write_addr, reg_write_data);

input clock;
input reset;

input [4:0] reg_read_addr_1;
input [4:0] reg_read_addr_2;

input reg_write;
input [4:0] reg_write_addr;
input [31:0] reg_write_data;

output reg [31:0] reg_read_data_1;
output reg [31:0] reg_read_data_2;

//32 * 32-bit registers
reg [31:0] registers[31:0];

integer i;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        for ( i = 0; i < 32; i = i + 1 ) begin
            registers[i] = 0;
        end
    end else begin
        if (reg_write) begin
            registers[reg_write_addr] <= reg_write_data;
        end
    end
end

always @(*) begin
    if (reg_read_addr_1 == 0) begin
        reg_read_data_1 = 32'b0;
    end else if (reg_read_addr_1 == reg_write_addr && reg_write) begin
        reg_read_data_1 = reg_write_data;
    end else begin
        reg_read_data_1 = registers[reg_read_addr_1];
    end

    if (reg_read_addr_2 == 0) begin
        reg_read_data_2 = 32'b0;
    end else if (reg_read_addr_2 == reg_write_addr && reg_write) begin
        reg_read_data_2 = reg_write_data;
    end else begin
        reg_read_data_2 = registers[reg_read_addr_2];
    end
end

endmodule

`endif