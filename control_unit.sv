
// control unit
// instructions
// 0000 - cmov - a <-b unless c = 0
//        only register unit
// 0001 - array idx - a <- (b)[c]
//        memory unit
//        register unit
// 0010 - array amend - (a)[b] <- c
//        memory unit
//        register unit
// 0011 - addition - a <- b + c
//        register unit
//        alu
// 0100 - multiplication - a <- b * c
//        register unit
//        alu
// 0101 - division - a <- b / c
//        register unit
//        alu
// 0110 - nand - a <- b NAND c (bitwise)
//        register unit
//        alu
// 0111 - halt
// 1000 - allocation - (b) = new array[c]
//        memory unit
//        register unit
// 1001 - abandonment - free(c)
//        memory unit
//        register unit
// 1010 - print(c)
//        register unit
// 1011 - c <- getc()
// 1100 - copy (b), let (0) = (b)


// fsm for cmov instruction
// state 00 - select regC to read
// state 01 - select regB to read
// state 10 - write (regB) to regA
// state 11 - finished
// reg_sel is 3 bit which register
// reg_s is register mode select
module cmov_fsm(input [2:0] regA, regB, regC, [31:0] reg_out_bus, [0:0] clk, r,
                output [31:0] reg_in_bus, [2:0] reg_sel, [0:0] reg_s, finished);
    wire reg_out_bus_zero;

    reg s1;
    reg s0;

    assign reg_out_bus_zero = reg_out_bus == 32'b0;
    assign finished = s1 && s0;
    assign write_buf_enable = s1 && ~s0;
    assign reg_sel = s1 ?
                     s0 ? 3'b000 :
                          regA :
                     s0 ? regB :
                          regC;
    assign reg_s = write_buf_enable;

    tribuf_32 out_buf(reg_out_bus, write_buf_enable, reg_in_bus);

    always_ff@(posedge clk)
        begin
            if (r) begin
                s1 <= 0;
                s0 <= 0;
            end else begin
                s1 <= s1 || s0 || (reg_out_bus_zero && ~s0 && s1);
                s0 <= s1 || ~s0;
            end
        end
endmodule