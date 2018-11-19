
import BusTypes::reg_in_bus_t;
import BusTypes::mem_in_bus_t;

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
                output reg_in_bus_t reg_in, output finished);
    wire reg_out_bus_zero;

    reg s1;
    reg s0;

    assign reg_out_bus_zero = reg_out_bus == 32'b0;
    assign finished = s1 && s0;
    assign write_buf_enable = s1 && ~s0;
    assign reg_in.sel = s1 ?
                     s0 ? 3'b000 :
                          regA :
                     s0 ? regB :
                          regC;
    assign reg_in.mode = write_buf_enable;

    tribuf_32 out_buf(reg_out_bus, write_buf_enable, reg_in.data);

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

module addr_idx_fsm (
    input [2:0] regA, regB, regC,
    input [31:0] reg_out_bus,
    input [31:0] mem_data_out_bus,
    input clk, r,
    output reg_in_bus_t reg_in,
    output mem_in_bus_t mem_in,
    output finished
);
    typedef enum logic [5:0] { SELECT_B, SELECT_C, READ_C, SELECT_MEM, WRITE_A, FIN } addr_idx_state_t;
    addr_idx_state_t idx_state;

    assign reg_in.data = mem_data_out_bus;
    assign reg_in.mode = (idx_state == WRITE_A) ? 1'b1 : 1'b0;
    assign reg_in.sel = (idx_state == WRITE_A) ?
                            regA :
                            (idx_state == SELECT_C) ?
                            regC :
                            regB;
    assign mem_in.mode = 2'b00;
    assign finished = (idx_state == FIN);

    always_ff@(posedge clk)
        begin
            if (r) begin
                idx_state <= SELECT_B;
            end else case(idx_state)
                SELECT_B: begin
                    idx_state <= SELECT_C;
                end
                SELECT_C: begin
                    mem_in.address <= reg_out_bus;
                    idx_state <= READ_C;
                end
                READ_C: begin
                    mem_in.offset <= reg_out_bus;
                    idx_state <= SELECT_MEM;
                end
                SELECT_MEM: begin
                    idx_state <= WRITE_A;
                end
                WRITE_A: begin
                    idx_state <= FIN;
                end
                FIN: begin
                    idx_state <= FIN;
                end
                default: $display("Invalid memory idx case.");
            endcase
        end
endmodule