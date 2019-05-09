`include "instr_mem.v"
`include "data_mem.v"
`include "alu.v"
`include "reg_file.v"
`include "hazard_detection_unit.v"
`include "forward_unit.v"

`ifndef _CPU_V
`define _CPU_V

module cpu(clock, reset, syscall);

input wire reset;
input wire clock;
output reg syscall;

reg  [31:0] pc;
wire [31:0] new_pc;

// Initial (non-pipelined) Control signals
reg c_reg_dst;
reg c_branch;
reg c_branch_ne;
reg c_mem_read;
reg c_mem_to_reg;
reg [1:0] c_alu_op;
reg c_mem_write;
reg [1:0] c_alus_rc;
reg c_reg_write;
reg c_jump;
reg c_link;
reg c_return;
reg c_byte;

// --- Signals for internal connections ---
wire [31:0] alu_result;      // Address for data memory
wire [31:0] reg_read_data_1; // Data read from reg 1
wire [31:0] reg_read_data_2; // Data read from reg 2
wire [31:0] reg_write_data;  // Data to be written

wire [31:0] mem_read_data;
wire [4:0]  write_register;

wire [3:0]  alu_control;

wire [31:0] alu_op_1;
wire [31:0] alu_op_2;
wire [31:0] sign_ext_imm;
wire [31:0] branch_pc;
wire [31:0] jump_mux_out;
wire [31:0] jump_addr;
wire [31:0] pc_inc;

wire alu_zero;
wire branch_pc_src;

wire [31:0] if_instr;

wire hdu_out;

// Fowarding logic
wire [1:0] forward_a;
wire [1:0] forward_b;

wire [31:0] forwad_mux_a_out;
wire [31:0] forwad_mux_b_out;


// --- Pipeline registers and control bits ---

// if/id register
reg [31:0]  pipe_ifid_pc;
reg [31:0]  pipe_ifid_instr;

// id/ex register
reg [31:0]  pipe_idex_pc;
reg [31:0]  pipe_idex_read1;
reg [31:0]  pipe_idex_read2;
reg [31:0]  pipe_idex_signextimm;
reg [4:0]   pipe_idex_rs;
reg [4:0]   pipe_idex_rt;
reg [4:0]   pipe_idex_rd;
reg [4:0]   pipe_idex_shmat;

//  id/ex control bits
reg idex_c_reg_dst;
reg idex_c_branch;
reg idex_c_branch_ne;
reg idex_c_mem_read;
reg idex_c_mem_to_reg;
reg [1:0] idex_c_alu_op;
reg idex_c_mem_write;
reg [1:0] idex_c_alus_rc;
reg idex_c_reg_write;
reg idex_c_link;
reg idex_c_return;
reg idex_c_byte;

// ex/mem register
reg [31:0]  pipe_exmem_alu;
reg [31:0]  pipe_exmem_branch_pc;
reg [31:0]  pipe_exmem_link_pc;
reg [31:0]  pipe_exmem_read2;
reg [4:0]   pipe_exmem_regdst;

// ex/mem control bits
reg exmem_c_branch;
reg exmem_c_branch_ne;
reg exmem_c_mem_read;
reg exmem_c_mem_to_reg;
reg exmem_c_mem_write;
reg exmem_c_reg_write;
reg exmem_c_alu_zero;
reg exmem_c_link;
reg exmem_c_byte;

// mem/wb register
reg [31:0]  pipe_memwb_data;
reg [31:0]  pipe_memwb_alu;
reg [31:0]  pipe_memwb_link_pc;
reg [4:0]   pipe_memwb_regdst;

// mem/wb control
reg memwb_c_mem_to_reg;
reg memwb_c_reg_write;
reg memwb_c_link;

// Combinational logic for connections between sub-modules
assign pc_inc = pc + 4;
assign sign_ext_imm = {{16{pipe_ifid_instr[15]}}, pipe_ifid_instr[15:0]};
assign branch_pc_src = (exmem_c_alu_zero & exmem_c_branch) | (!exmem_c_alu_zero & exmem_c_branch_ne);
assign branch_pc = (pipe_idex_signextimm << 2) + pipe_idex_pc;
assign jump_addr = {pipe_ifid_pc[31:28], pipe_ifid_instr[25:0], 2'b0};

// Instatiation of sub-modules
instr_mem   instr_mem_0(clock, reset, pc, if_instr);
data_mem    data_mem_0(clock, reset, pipe_exmem_alu, exmem_c_mem_read, exmem_c_mem_write, exmem_c_byte, pipe_exmem_read2, mem_read_data);
reg_file    reg_file_0(clock, reset, pipe_ifid_instr[25:21], reg_read_data_1, pipe_ifid_instr[20:16], reg_read_data_2, memwb_c_reg_write, pipe_memwb_regdst, reg_write_data);
alu_control alu_control_0(pipe_idex_signextimm[5:0], idex_c_alu_op, alu_control);
alu         alu_0(alu_op_1, alu_op_2, alu_control, alu_zero, alu_result);

hazard_detection_unit hdu_0(idex_c_mem_read, pipe_ifid_instr, pipe_idex_rt, hdu_out);
forward_unit fwu_0(.ex_mem_rd(pipe_exmem_regdst), .ex_mem_rw(exmem_c_reg_write), .mem_wb_rd(pipe_memwb_regdst), 
                    .mem_wb_rw(memwb_c_reg_write), .id_ex_rs(pipe_idex_rs), .id_ex_rt(pipe_idex_rt), .fa(forward_a), .fb(forward_b));

// Control Muxes
assign write_register = idex_c_link ? 31 : (idex_c_reg_dst ? pipe_idex_rd : pipe_idex_rt);
assign alu_op_1       = idex_c_alus_rc[1] ? {{27{1'b0}}, pipe_idex_shmat} : forwad_mux_a_out;
assign alu_op_2       = idex_c_alus_rc[0] ? pipe_idex_signextimm : forwad_mux_b_out;
assign reg_write_data = memwb_c_link ? (pipe_memwb_link_pc) : (memwb_c_mem_to_reg ? pipe_memwb_data : pipe_memwb_alu);
assign new_pc         = branch_pc_src ? pipe_exmem_branch_pc : jump_mux_out;
assign jump_mux_out   = idex_c_return ? forwad_mux_a_out : (c_jump ? jump_addr : pc_inc);

// Forwarding muxes (3-1)
assign forwad_mux_a_out = forward_a[1] ? pipe_exmem_alu : (forward_a[0] ? reg_write_data : pipe_idex_read1);
assign forwad_mux_b_out = forward_b[1] ? pipe_exmem_alu : (forward_b[0] ? reg_write_data : pipe_idex_read2);

// Main reset and pipeline sequential logic
always @(posedge clock) begin
    if (reset) begin
        pc <= 32'h3000;

        // Control signals low during reset
        c_reg_dst    = 1'b0;
        c_branch     = 1'b0;
        c_branch_ne  = 1'b0;
        c_mem_read   = 1'b0;
        c_mem_to_reg = 1'b0;
        c_alu_op     = 2'b00;
        c_mem_write  = 1'b0;
        c_alus_rc    = 2'b00;
        c_reg_write  = 1'b0;
        c_jump       = 1'b0;
        c_link       = 1'b0;
        c_return     = 1'b0;
        c_byte       = 1'b0;

        // Flush pipe registers during reset
        pipe_ifid_pc    <= 0;
        pipe_ifid_instr <= 0;

        pipe_idex_pc         <= 0;
        pipe_idex_read1      <= 0;
        pipe_idex_read2      <= 0;
        pipe_idex_signextimm <= 0;
        pipe_idex_rd         <= 0;
        pipe_idex_rs         <= 0;
        pipe_idex_rt         <= 0;
        pipe_idex_shmat      <= 0;

        idex_c_reg_dst    <= 1'b0;
        idex_c_branch     <= 1'b0;
        idex_c_branch_ne  <= 1'b0;
        idex_c_mem_read   <= 1'b0;
        idex_c_mem_to_reg <= 1'b0;
        idex_c_alu_op     <= 2'b00;
        idex_c_mem_write  <= 1'b0;
        idex_c_alus_rc    <= 2'b00;
        idex_c_reg_write  <= 1'b0;
        idex_c_link       <= 1'b0;
        idex_c_return     <= 1'b0;
        idex_c_byte       <= 1'b0;

        pipe_exmem_alu       <= 0;
        pipe_exmem_branch_pc <= 0;
        pipe_exmem_link_pc   <= 0;
        pipe_exmem_read2     <= 0;
        pipe_exmem_regdst    <= 0;

        exmem_c_branch     <= 1'b0;
        exmem_c_branch_ne  <= 1'b0;
        exmem_c_mem_read   <= 1'b0;
        exmem_c_mem_to_reg <= 1'b0;
        exmem_c_mem_write  <= 1'b0;
        exmem_c_reg_write  <= 1'b0;
        exmem_c_alu_zero   <= 1'b0;
        exmem_c_link       <= 1'b0;
        exmem_c_byte       <= 1'b0;

        pipe_memwb_data    <= 0;
        pipe_memwb_alu     <= 0;
        pipe_memwb_link_pc <= 0;
        pipe_memwb_regdst  <= 0;

        memwb_c_mem_to_reg <= 1'b0;
        memwb_c_reg_write  <= 1'b0;
        memwb_c_link       <= 1'b0;

    end else begin
        // Hold PC if we must stall on a lw hazard
		if (!hdu_out) begin
			pc <= new_pc;
		end

        // Update pipeline
        // --- Instruction fetch ---
        pipe_ifid_pc    <= pc_inc;
        pipe_ifid_instr <= if_instr;
        
        // --- Instruction decode ---
        pipe_idex_pc         <= pipe_ifid_pc;
        pipe_idex_read1      <= reg_read_data_1;
        pipe_idex_read2      <= reg_read_data_2;
        pipe_idex_signextimm <= sign_ext_imm;
        pipe_idex_rs         <= pipe_ifid_instr[25:21];
        pipe_idex_rt         <= pipe_ifid_instr[20:16];
        pipe_idex_rd         <= pipe_ifid_instr[15:11];
        pipe_idex_shmat      <= pipe_ifid_instr[10:6];
        
        // Update control bits
        idex_c_reg_dst    <= c_reg_dst;
        idex_c_branch     <= c_branch;
        idex_c_branch_ne  <= c_branch_ne;
        idex_c_mem_read   <= c_mem_read;
        idex_c_mem_to_reg <= c_mem_to_reg;
        idex_c_alu_op     <= c_alu_op;
        idex_c_mem_write  <= c_mem_write;
        idex_c_alus_rc    <= c_alus_rc;
        idex_c_reg_write  <= c_reg_write;
        idex_c_link       <= c_link;
        idex_c_return     <= c_return;
        idex_c_byte       <= c_byte;

        // --- Execute ---
        pipe_exmem_alu       <= alu_result;
        pipe_exmem_branch_pc <= branch_pc;
        pipe_exmem_link_pc   <= pipe_idex_pc;
        pipe_exmem_read2     <= forwad_mux_b_out;
        pipe_exmem_regdst    <= write_register;

        // ex/mem control bits
        exmem_c_branch     <= idex_c_branch;
        exmem_c_branch_ne  <= idex_c_branch_ne;
        exmem_c_mem_read   <= idex_c_mem_read;
        exmem_c_mem_to_reg <= idex_c_mem_to_reg;
        exmem_c_mem_write  <= idex_c_mem_write;
        exmem_c_reg_write  <= idex_c_reg_write;
        exmem_c_alu_zero   <= alu_zero;
        exmem_c_link       <= idex_c_link;
        exmem_c_byte       <= idex_c_byte;

        // --- Memory ---
        pipe_memwb_data    <= mem_read_data;
        pipe_memwb_alu     <= pipe_exmem_alu;
        pipe_memwb_link_pc <= pipe_exmem_link_pc;
        pipe_memwb_regdst  <= pipe_exmem_regdst;

        // mem/wb control
        memwb_c_mem_to_reg <= exmem_c_mem_to_reg;
        memwb_c_reg_write  <= exmem_c_reg_write;
        memwb_c_link       <= exmem_c_link;

        // If there is a jump, flush pipe
        if (c_jump) begin
            pipe_ifid_pc    <= 0;
            pipe_ifid_instr <= 0;

        // If there is a return, flush pipe
        end else if (idex_c_return) begin
            pipe_ifid_pc    <= 0;
            pipe_ifid_instr <= 0;

            // --- Instruction decode ---
            pipe_idex_pc         <= 0;
            pipe_idex_read1      <= 0;
            pipe_idex_read2      <= 0;
            pipe_idex_signextimm <= 0;
            pipe_idex_rd         <= 0;
            pipe_idex_rs         <= 0;
            pipe_idex_rt         <= 0;
            pipe_idex_shmat      <= 0;
            
            // Update control bits
            idex_c_reg_dst    <= 1'b0;
            idex_c_branch     <= 1'b0;
            idex_c_branch_ne  <= 1'b0;
            idex_c_mem_read   <= 1'b0;
            idex_c_mem_to_reg <= 1'b0;
            idex_c_alu_op     <= 2'b00;
            idex_c_mem_write  <= 1'b0;
            idex_c_alus_rc    <= 2'b00;
            idex_c_reg_write  <= 1'b0;
            idex_c_link       <= 1'b0;
            idex_c_return     <= 1'b0;
            idex_c_byte       <= 1'b0;
        
        // If there is a branch, flush pipe
        end else if ((exmem_c_alu_zero & exmem_c_branch) | (!exmem_c_alu_zero & exmem_c_branch_ne)) begin
            pipe_ifid_pc    <= 0;
            pipe_ifid_instr <= 0;

            // --- Instruction decode ---
            pipe_idex_pc         <= 0;
            pipe_idex_read1      <= 0;
            pipe_idex_read2      <= 0;
            pipe_idex_signextimm <= 0;
            pipe_idex_rd         <= 0;
            pipe_idex_rs         <= 0;
            pipe_idex_rt         <= 0;
            pipe_idex_shmat      <= 0;
            
            // Update control bits
            idex_c_reg_dst    <= 1'b0;
            idex_c_branch     <= 1'b0;
            idex_c_branch_ne  <= 1'b0;
            idex_c_mem_read   <= 1'b0;
            idex_c_mem_to_reg <= 1'b0;
            idex_c_alu_op     <= 2'b00;
            idex_c_mem_write  <= 1'b0;
            idex_c_alus_rc    <= 2'b00;
            idex_c_reg_write  <= 1'b0;
            idex_c_link       <= 1'b0;
            idex_c_return     <= 1'b0;
            idex_c_byte       <= 1'b0;

            pipe_exmem_alu       <= 0;
            pipe_exmem_branch_pc <= 0;
            pipe_exmem_link_pc   <= 0;
            pipe_exmem_read2     <= 0;
            pipe_exmem_regdst    <= 0;

            // ex/mem control bits
            exmem_c_branch     <= 1'b0;
            exmem_c_branch_ne  <= 1'b0;
            exmem_c_mem_read   <= 1'b0;
            exmem_c_mem_to_reg <= 1'b0;
            exmem_c_mem_write  <= 1'b0;
            exmem_c_reg_write  <= 1'b0;
            exmem_c_alu_zero   <= 1'b0;
            exmem_c_link       <= 1'b0;
            exmem_c_byte       <= 1'b0;

		// if there is a data hazard that cannot be forwarded, insert a bubble
        // This is accomplished by not moving ifid register and holding PC
        end else if (hdu_out) begin
            pipe_ifid_pc    <= pipe_ifid_pc;
            pipe_ifid_instr <= pipe_ifid_instr;
            
            pipe_idex_pc         <= 0;
            pipe_idex_read1      <= 0;
            pipe_idex_read2      <= 0;
            pipe_idex_signextimm <= 0;
            pipe_idex_rd         <= 0;
            pipe_idex_rs         <= 0;
            pipe_idex_rt         <= 0;
            pipe_idex_shmat      <= 0;
            
            // Set control bits to zero and propogate through pipe
            idex_c_reg_dst    <= 1'b0;
            idex_c_branch     <= 1'b0;
            idex_c_branch_ne  <= 1'b0;
            idex_c_mem_read   <= 1'b0;
            idex_c_mem_to_reg <= 1'b0;
            idex_c_alu_op     <= 2'b00;
            idex_c_mem_write  <= 1'b0;
            idex_c_alus_rc    <= 2'b00;
            idex_c_reg_write  <= 1'b0;
            idex_c_link       <= 1'b0;
            idex_c_return     <= 1'b0;
            idex_c_byte       <= 1'b0;
		end
    end
end

// Combinational Control logic
// We use 0's when the output does not matter
// This defines our supported opcodes
always @(pipe_ifid_instr) begin
    
    c_reg_dst    = 1'b0;
    c_branch     = 1'b0;
    c_branch_ne  = 1'b0;
    c_mem_read   = 1'b0;
    c_mem_to_reg = 1'b0;
    c_alu_op     = 2'b00;
    c_mem_write  = 1'b0;
    c_alus_rc    = 2'b00;
    c_reg_write  = 1'b0;
    c_jump       = 1'b0;
    c_link       = 1'b0;
    c_return     = 1'b0;
    c_byte       = 1'b0;
    
    case (pipe_ifid_instr[31:26])
        // R-format or syscall
        6'h00: begin
            // If there is a syscall, indicate this to testbench
            if (pipe_ifid_instr[5:0] == 6'h0C) begin
                syscall = 1;
            end else if (pipe_ifid_instr[5:0] == 6'h08) begin // jr instruction
                c_return = 1;
            end else if (pipe_ifid_instr[5:0] == 6'h00 || pipe_ifid_instr[5:0] == 6'h02) begin // sll / srl instruction
                c_alus_rc = 2'b10;
                c_reg_dst   = 1'b1;
                c_alu_op    = 2'b10;
                c_reg_write = 1'b1;
            end else begin
                c_reg_dst   = 1'b1;
                c_alu_op    = 2'b10;
                c_reg_write = 1'b1;
            end
        end

        // beq
        6'h04: begin
            c_branch = 1'b1;
            c_alu_op = 2'b01;
        end

        // bne
        6'h05: begin
            c_branch_ne = 1'b1;
            c_alu_op    = 2'b01;
        end

        // lw
        6'h23: begin
            c_mem_read   = 1'b1;
            c_mem_to_reg = 1'b1;
            c_alus_rc    = 2'b01;
            c_reg_write  = 1'b1;
        end

        // sw
        6'h2b: begin
            c_mem_write = 1'b1;
            c_alus_rc   = 2'b01;
        end

        // lbu
        6'h24: begin
            c_mem_read   = 1'b1;
            c_mem_to_reg = 1'b1;
            c_alus_rc    = 2'b01;
            c_reg_write  = 1'b1;
            c_byte       = 1'b1;
        end
        
        // sb
        6'h28: begin
            c_mem_write = 1'b1;
            c_alus_rc   = 2'b01;
            c_byte      = 1'b1;
        end

        // j
        6'h02: begin
            c_jump = 1'b1;
        end

        // jal
        6'h03: begin
            c_jump      = 1'b1;
            c_link      = 1'b1;
            c_reg_write = 1'b1;
        end

        // addi, addiu
        6'h08, 6'h09: begin
            c_alus_rc   = 2'b01;
            c_reg_write = 1'b1;
        end

        default: begin
            $display("ERROR: Invalid opcode: %h", pipe_ifid_instr[31:26]);
        end
    endcase
end
endmodule

`endif