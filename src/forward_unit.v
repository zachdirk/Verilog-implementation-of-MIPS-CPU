// A verilog MIPS forwarding unit

`ifndef _FORWARD_UNIT_V
`define _FORWARD_UNIT_V

module forward_unit (ex_mem_rd, ex_mem_rw, mem_wb_rd, mem_wb_rw, id_ex_rs, id_ex_rt, fa, fb);

input ex_mem_rw;    // register write control signal
input mem_wb_rw;    // register write control signal
input wire [4:0] ex_mem_rd;
input wire [4:0] mem_wb_rd;
input wire [4:0] id_ex_rs;
input wire [4:0] id_ex_rt;

output reg [1:0] fa;
output reg [1:0] fb;

always @(*) begin 
   // SLIDE 74 of 04_processor_FINAL.pdf
   // EX hazard
    if(ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs))begin
       
        fa = 2;
    
    // MEM hazard 
    end else if (mem_wb_rw && (mem_wb_rd != 0) 
        && !(ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rs)) 
        && (mem_wb_rd == id_ex_rs))begin
    
        fa = 1;
    
    end else begin
        
        fa = 0;
    end
    
    if(ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rt))begin
    
        fb = 2;

    end else if(mem_wb_rw && (mem_wb_rd != 0) 
        && !(ex_mem_rw && (ex_mem_rd != 0) && (ex_mem_rd == id_ex_rt)) 
        && (mem_wb_rd == id_ex_rt))begin
    
        fb = 1;     
    
    end else begin
        
        fb = 0;
    end
end

endmodule
`endif