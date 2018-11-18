
module cmov_test();
    reg clk;
    reg reset_reg;
    reg reset_fsm;
    reg [31:0] instr_word;
    reg enable_fsm_output;

    reg enable_manual;
    reg [2:0] manual_sel;
    reg manual_s;
    reg [31:0] manual_data_in;


    wire [3:0] instr;
    wire [2:0] regA;
    wire [2:0] regB;
    wire [2:0] regC;
    
    wire [31:0] reg_data_in;
    wire [31:0] reg_data_out;

    wire [2:0] reg_sel;
    wire reg_s;

    wire finished;

    wire [2:0] cmov_fsm_reg_sel;
    wire cmov_fsm_reg_s;
    wire [31:0] cmov_fsm_reg_in_bus;


    tribuf_n #(3) manual_sel_buf(manual_sel, enable_manual, reg_sel);
    tribuf_n #(1) manual_s_buf(manual_s, enable_manual, reg_s);
    tribuf_32 manual_data_in_buf(manual_data_in, enable_manual, reg_data_in);

    tribuf_n #(3) reg_sel_buf(cmov_fsm_reg_sel, enable_fsm_output, reg_sel);
    tribuf_n #(1) reg_s_buf(cmov_fsm_reg_s, enable_fsm_output, reg_s);
    tribuf_32 reg_data_in_buf(cmov_fsm_reg_in_bus, enable_fsm_output, reg_data_in);


    reg_bank bank(reg_sel, reg_s, reset_reg, clk, reg_data_in, reg_data_out);

    instr_decoder idecode(instr_word, instr, regA, regB, regC);

    cmov_fsm cfsm(regA, regB, regC,
                  reg_data_out,
                  clk, reset_fsm,
                  cmov_fsm_reg_in_bus,
                  cmov_fsm_reg_sel, cmov_fsm_reg_s,
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
        manual_sel <= 3'b010;
        manual_data_in <= 32'b1;
        manual_s <= 1'b1;

        #10

        manual_sel <= 3'b100;
        manual_data_in <= 32'h5555;

        #10

        manual_sel <= 3'b001;
        manual_data_in <= 32'hcccc;

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
