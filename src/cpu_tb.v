`default_nettype none
`timescale 1ns/1ns

`include "cpu.v"

module cpu_tb();
// Declare inputs as regs and outputs as wires
reg clock, reset;
wire syscall;

reg [8*25:1] prog_name;
reg [8*25:1] text_name;
reg [8*25:1] data_name;
reg [8*25:1] output_name;
integer fd;
reg result;
reg [31:0] addr;
reg [29:0] word_addr;

// Initialize all variables
initial begin
    result  =  $value$plusargs("PROG=%s", prog_name);    
    result &=  $value$plusargs("TEXT=%s", text_name);
    result &=  $value$plusargs("DATA=%s", data_name);
    
    if (!result) begin
        $display("Error: No program passed as argument");
        $finish;
    end

    $dumpfile("bin/waves.vcd");
    $dumpvars;

    clock = 0;
    reset = 0;
    #10 reset = 1;
    #10 reset = 0;
    #1;

    // initialize instr_mem with program from text file
    $display("Initializing instruction memory.");
    $readmemh(text_name, cpu_0.instr_mem_0.mem);

    // Mars doesn't create the data segment if there is no .data directive.
    // We therefore have to check if it exists

    fd = $fopen(data_name, "r");
    if (fd) begin
        $fclose(fd);
        $display("Initializing data memory.");
        $readmemh(data_name, cpu_0.data_mem_0.d_mem);
    end

    // initialize $gp to match mars
    cpu_0.reg_file_0.registers[28] = 32'h00001800;
    cpu_0.reg_file_0.registers[29] = 32'h00002ffc;

end

// 100 Mhz Clock generator
always begin
    #10 clock = ~clock;
    if (syscall) begin
		#10 clock = ~clock;
		#10 clock = ~clock;
		#10 clock = ~clock;
		#10 clock = ~clock;
		#10 clock = ~clock;
		#10 clock = ~clock;
		#10 clock = ~clock;
        // Dump registers and memory to file
        output_name = {prog_name, ".out.ours"};
        fd = $fopen(output_name, "w");

        // Format output identical to MARS
        // Should be in a loop, but verilog isn't set up for string arrays
        $fdisplay(fd,"$zero	0x%08h", cpu_0.reg_file_0.registers[0]);        
        $fdisplay(fd,"$at 0x%08h", cpu_0.reg_file_0.registers[1]);
        $fdisplay(fd,"$v0 0x%08h", cpu_0.reg_file_0.registers[2]);
        $fdisplay(fd,"$v1 0x%08h", cpu_0.reg_file_0.registers[3]);
        $fdisplay(fd,"$a0 0x%08h", cpu_0.reg_file_0.registers[4]);
        $fdisplay(fd,"$a1 0x%08h", cpu_0.reg_file_0.registers[5]);
        $fdisplay(fd,"$a2 0x%08h", cpu_0.reg_file_0.registers[6]);
        $fdisplay(fd,"$a3 0x%08h", cpu_0.reg_file_0.registers[7]);
        $fdisplay(fd,"$t0 0x%08h", cpu_0.reg_file_0.registers[8]);
        $fdisplay(fd,"$t1 0x%08h", cpu_0.reg_file_0.registers[9]);
        $fdisplay(fd,"$t2 0x%08h", cpu_0.reg_file_0.registers[10]);
        $fdisplay(fd,"$t3 0x%08h", cpu_0.reg_file_0.registers[11]);
        $fdisplay(fd,"$t4 0x%08h", cpu_0.reg_file_0.registers[12]);
        $fdisplay(fd,"$t5 0x%08h", cpu_0.reg_file_0.registers[13]);
        $fdisplay(fd,"$t6 0x%08h", cpu_0.reg_file_0.registers[14]);
        $fdisplay(fd,"$t7 0x%08h", cpu_0.reg_file_0.registers[15]);
        $fdisplay(fd,"$s0 0x%08h", cpu_0.reg_file_0.registers[16]);
        $fdisplay(fd,"$s1 0x%08h", cpu_0.reg_file_0.registers[17]);
        $fdisplay(fd,"$s2 0x%08h", cpu_0.reg_file_0.registers[18]);
        $fdisplay(fd,"$s3 0x%08h", cpu_0.reg_file_0.registers[19]);
        $fdisplay(fd,"$s4 0x%08h", cpu_0.reg_file_0.registers[20]);
        $fdisplay(fd,"$s5 0x%08h", cpu_0.reg_file_0.registers[21]);
        $fdisplay(fd,"$s6 0x%08h", cpu_0.reg_file_0.registers[22]);
        $fdisplay(fd,"$s7 0x%08h", cpu_0.reg_file_0.registers[23]);
        $fdisplay(fd,"$t8 0x%08h", cpu_0.reg_file_0.registers[24]);
        $fdisplay(fd,"$t9 0x%08h", cpu_0.reg_file_0.registers[25]);
        $fdisplay(fd,"$k0 0x%08h", cpu_0.reg_file_0.registers[26]);
        $fdisplay(fd,"$k1 0x%08h", cpu_0.reg_file_0.registers[27]);
        $fdisplay(fd,"$gp 0x%08h", cpu_0.reg_file_0.registers[28]);
        $fdisplay(fd,"$sp 0x%08h", cpu_0.reg_file_0.registers[29]);
        $fdisplay(fd,"$fp 0x%08h", cpu_0.reg_file_0.registers[30]);
        $fdisplay(fd,"$ra 0x%08h", cpu_0.reg_file_0.registers[31]);

        for (addr = 32'h0000_0000; addr < 32'h0000_3000; addr = addr + 'h10) begin
            word_addr = addr >> 2;
            $fdisplay(fd,"Mem[0x%08h] 0x%08h 0x%08h 0x%08h 0x%08h", addr, 
                cpu_0.data_mem_0.d_mem[word_addr], cpu_0.data_mem_0.d_mem[word_addr + 1], 
                cpu_0.data_mem_0.d_mem[word_addr + 2], cpu_0.data_mem_0.d_mem[word_addr + 3]);
        end

        $fclose(fd);
        $finish;
    end
end

cpu cpu_0(clock,reset, syscall);

endmodule