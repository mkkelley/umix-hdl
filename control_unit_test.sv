
import BusTypes::mem_in_bus_t;
import BusTypes::reg_in_bus_t;

module cmov_test();
    reg clk;
    reg reset_reg;
    reg reset_fsm;
    reg [31:0] instr_word;
    reg enable_fsm_output;

    reg enable_manual;

    reg_in_bus_t manual_reg_in_bus;

    wire [3:0] instr;
    wire [2:0] regA;
    wire [2:0] regB;
    wire [2:0] regC;
    
    reg_in_bus_t reg_in_bus;
    wire [31:0] reg_data_out;

    wire finished;

    reg_in_bus_t cmov_reg_in_bus;

    reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);

    reg_in_bus_buf cmov_buf(cmov_reg_in_bus, enable_fsm_output, reg_in_bus);

    // reg_bank bank(reg_sel, reg_s, reset_reg, clk, reg_data_in, reg_data_out);
    reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

    instr_decoder idecode(instr_word, instr, regA, regB, regC);

    cmov_fsm cfsm(regA, regB, regC,
                  reg_data_out,
                  clk, reset_fsm,
                  cmov_reg_in_bus,
                  finished);

    initial begin
        clk <= 0;

        reset_reg <= 1;
        reset_fsm <= 1;

        instr_word <= 32'b0000_0000000000000000000_001_100_010;
        enable_fsm_output <= 0;

        #10

        reset_fsm <= 0;
        reset_reg <= 0;

        #10

        enable_manual <= 1;
        manual_reg_in_bus.sel <= 3'b010;
        manual_reg_in_bus.data <= 32'b1;
        manual_reg_in_bus.mode <= 1'b1;

        #10

        manual_reg_in_bus.sel <= 3'b100;
        manual_reg_in_bus.data <= 32'h5555;

        #10

        manual_reg_in_bus.sel <= 3'b001;
        manual_reg_in_bus.data <= 32'hcccc;

        #10

        enable_manual <= 0;
        enable_fsm_output <= 1;
        
        #10

        reset_fsm <= 1;


        #10

        reset_fsm <= 0;
    end


    always begin
        #5
        clk = ~clk;
    end
endmodule


module addr_idx_test();
    reg clk;
    reg reset_reg;
    reg reset_fsm;
    reg [31:0] instr_word;
    reg enable_fsm_output;

    reg enable_manual;

    wire [3:0] instr;
    wire [2:0] regA;
    wire [2:0] regB;
    wire [2:0] regC;
    wire [31:0] reg_data_out;
    wire [31:0] mem_out;
    wire finished;

    reg_in_bus_t manual_reg_in_bus;
    reg_in_bus_t reg_in_bus;
    reg_in_bus_t fsm_reg_in;

    mem_in_bus_t manual_mem_in;
    mem_in_bus_t mem_in;
    mem_in_bus_t idx_mem_in;

    reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);
    reg_in_bus_buf fsm_buf(fsm_reg_in, enable_fsm_output, reg_in_bus);

    mem_in_bus_buf manual_mem_in_buf(manual_mem_in, enable_manual, mem_in);
    mem_in_bus_buf idx_mem_in_buf(idx_mem_in, enable_fsm_output, mem_in);

    reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

    instr_decoder idecode(instr_word, instr, regA, regB, regC);

    mem_sys ms(mem_in, clk, reset_reg, mem_out);

    addr_idx_fsm aifsm(
        regA, regB, regC,
        reg_data_out, mem_out,
        clk, reset_fsm,
        fsm_reg_in,
        idx_mem_in,
        finished
    );

    initial begin
        clk <= 0;

        reset_reg <= 1;
        reset_fsm <= 1;

        instr_word <= 32'b0001_0000000000000000000_001_100_010;
        enable_fsm_output <= 0;

        #10

        reset_reg <= 0;

        #10

        enable_manual <= 1;
        manual_reg_in_bus.sel <= 3'b010;
        manual_reg_in_bus.data <= 32'b0;
        manual_reg_in_bus.mode <= 1'b1;

        manual_mem_in.mode <= 2'b01;
        manual_mem_in.address <= 32'h5555;
        manual_mem_in.offset <= 32'b0;
        manual_mem_in.data <= 32'h76767676;

        #10

        manual_reg_in_bus.sel <= 3'b100;
        manual_reg_in_bus.data <= 32'h5555;

        manual_mem_in.address <= 32'h5555;
        manual_mem_in.offset <= 32'b1;
        manual_mem_in.data <= 32'h13131313;

        #10

        manual_reg_in_bus.sel <= 3'b001;
        manual_reg_in_bus.data <= 32'hcccc;

        #10

        enable_manual <= 0;
        reset_fsm <= 0;
        enable_fsm_output <= 1;
    end


    always begin
        #5
        clk = ~clk;
    end
endmodule

module addr_amend_test();
    reg clk;
    reg reset_reg;
    reg reset_fsm;
    reg [31:0] instr_word;
    reg enable_fsm_output;

    reg enable_manual;

    wire [3:0] instr;
    wire [2:0] regA;
    wire [2:0] regB;
    wire [2:0] regC;
    wire [31:0] reg_data_out;
    wire [31:0] mem_out;
    wire finished;

    reg_in_bus_t manual_reg_in_bus;
    reg_in_bus_t reg_in_bus;
    reg_in_bus_t fsm_reg_in;

    mem_in_bus_t manual_mem_in;
    mem_in_bus_t mem_in;
    mem_in_bus_t idx_mem_in;

    reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);
    reg_in_bus_buf fsm_buf(fsm_reg_in, enable_fsm_output, reg_in_bus);

    mem_in_bus_buf manual_mem_in_buf(manual_mem_in, enable_manual, mem_in);
    mem_in_bus_buf fsm_mem_in_buf(idx_mem_in, enable_fsm_output, mem_in);

    reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

    instr_decoder idecode(instr_word, instr, regA, regB, regC);

    mem_sys ms(mem_in, clk, reset_reg, mem_out);

    addr_amend_fsm aafsm(
        regA, regB, regC,
        reg_data_out, mem_out,
        clk, reset_fsm,
        fsm_reg_in,
        idx_mem_in,
        finished
    );

    initial begin
        clk <= 0;

        reset_reg <= 1;
        reset_fsm <= 1;

        instr_word <= 32'b0010_0000000000000000000_001_100_010;
        enable_fsm_output <= 0;

        #10

        reset_reg <= 0;

        #10

        enable_manual <= 1;
        manual_reg_in_bus.sel <= 3'b010;
        manual_reg_in_bus.data <= 32'b0;
        manual_reg_in_bus.mode <= 1'b1;

        manual_mem_in.mode <= 2'b01;
        manual_mem_in.address <= 32'h5555;
        manual_mem_in.offset <= 32'b0;
        manual_mem_in.data <= 32'h76767676;

        #10

        manual_reg_in_bus.sel <= 3'b100;
        manual_reg_in_bus.data <= 32'h5555;

        #10

        manual_reg_in_bus.sel <= 3'b001;
        manual_reg_in_bus.data <= 32'hcccc;

        #10

        enable_manual <= 0;
        reset_fsm <= 0;
        enable_fsm_output <= 1;
    end


    always begin
        #5
        clk = ~clk;
    end
endmodule

