
module tristate_buffer(input x, input en, output y);
    assign y = (en) ? x : 1'bz;
endmodule

module tribuf_n #(parameter size = 4)
                (input [size-1:0] xs, input [0:0] en, output [size-1:0] ys);
    tristate_buffer tb[size-1:0] (xs, en, ys);
endmodule

module tribuf_32(input [31:0] xs, input [0:0] en, output [31:0] ys);
    tristate_buffer tb[31:0] (xs, en, ys);
endmodule

module reg_32(input [31:0] in, input clk, r, en, output reg [31:0] q);
    always@(r, posedge clk)
        if (r)
            q <= 32'b0;
        else if (en && clk)
            q <= in;
endmodule

module buffered_reg_32(input in, input clk, r, en, en_out, output q);
    input [31:0] in;
    output [31:0] q;
    wire [31:0] reg_q_to_buf;
    tribuf_32 tb(reg_q_to_buf, en_out, q);
    reg_32 re(in, clk, r, en, reg_q_to_buf);
endmodule

// s = 1 -> Load d into reg[r]
// s = 0 -> Read reg[r] to q
// reset is async 1 -> reset
module reg_bank(input[2:0] r, input s, reset, clk, input[31:0] d, output[31:0] q);
    wire [7:0] read_reg_hot;
    wire [7:0] write_reg_hot;
    wire [7:0] write_reg;
    decoder_c #(3, 8) dec_read_select(r, clk, read_reg_hot);
    decoder #(3, 8) dec_write_select(r, write_reg);
    assign write_reg_hot = s ? write_reg : 8'b0;

    buffered_reg_32 reg_0(d, clk, reset, write_reg_hot[0], read_reg_hot[0], q);
    buffered_reg_32 reg_1(d, clk, reset, write_reg_hot[1], read_reg_hot[1], q);
    buffered_reg_32 reg_2(d, clk, reset, write_reg_hot[2], read_reg_hot[2], q);
    buffered_reg_32 reg_3(d, clk, reset, write_reg_hot[3], read_reg_hot[3], q);
    buffered_reg_32 reg_4(d, clk, reset, write_reg_hot[4], read_reg_hot[4], q);
    buffered_reg_32 reg_5(d, clk, reset, write_reg_hot[5], read_reg_hot[5], q);
    buffered_reg_32 reg_6(d, clk, reset, write_reg_hot[6], read_reg_hot[6], q);
    buffered_reg_32 reg_7(d, clk, reset, write_reg_hot[7], read_reg_hot[7], q);
endmodule