`default_nettype none
`timescale 1ns/1ns
`include "data_mem.v"

module data_mem_tb();

// inputs
reg memwrite;
reg memread;
reg [31:0] write_d;
reg clock;
reg reset;
reg [31:0] addr;

// output
wire [31:0] read_d;

// clock generator
always begin
    #10 clock = ~clock;
end

// data_mem instance
data_mem d0(
    .memwrite(memwrite),
    .memread(memread),
    .write_d(write_d),
    .reset(reset),
    .clock(clock),
    .addr(addr),
    .read_d(read_d)
);

integer i;

initial begin
    $dumpfile("bin/waves.vcd");
    $dumpvars;
    clock = 0; reset = 0;
    #15 reset = 1;
    #20 reset = 0; memwrite = 1; memread = 0; addr = 0; write_d = 32'h1111_1111;
    #25;
    if (d0.d_mem[addr >> 2] != write_d) begin
        $display("FAILED TEST 1 - MEMWRITE");
        $display("mem has: %h\n", d0.d_mem[addr >> 2]);
    end
    #30; reset = 0; memwrite = 0; memread = 1; addr = 0; 
    #35;
    if (d0.read_d != 32'h1111_1111)begin
        $display("FAILED TEST 2 - MEMREAD");
        $display("memread has: %h", d0.read_d);
    end
    #40 reset = 0; memwrite = 1; memread = 0; addr = 32'h0000_0100; write_d = 32'h1234_5678;
    #45;
    if (d0.d_mem[addr >> 2] != 32'h1234_5678) begin
        $display("FAILED TEST 3 - MEMWRITE");
        $display("mem has: %h\n", d0.d_mem[addr >> 2]);
    end
    #50 reset = 0; memwrite = 0; memread = 1; addr = 32'h0000_0100; 
    #55;
    if (d0.read_d != 32'h1234_5678)begin
        $display("FAILED TEST 4 - MEMREAD");
        $display("memread has: %h", d0.read_d);    
    end
    #60 reset = 1; memwrite = 0; memread = 0;
    #65;
    for ( i = 0; i < ('h3000-1) >> 2; i = i + 1)begin
        if(d0.d_mem[i] != 0 ) begin
            $display("FAILED RESET");
        end
    end
    #500 $finish;
end

endmodule