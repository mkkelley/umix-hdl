
import BusTypes::reg_in_bus_t;

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

/*
 * This is a reg_32 with a tristate buffer in front.
 * 
 * en enables the inner reg_32, en_out enables the tristate buffer
 */
module buffered_reg_32(input in, input clk, r, en, en_out, output q);
    input [31:0] in;
    output [31:0] q;
    wire [31:0] reg_q_to_buf;
    tribuf_32 tb(reg_q_to_buf, en_out, q);
    reg_32 re(in, clk, r, en, reg_q_to_buf);
endmodule

module reg_in_bus_buf (
    input reg_in_bus_t reg_in,
    input en,
    output reg_in_bus_t out
);
    tribuf_32 data_buf(reg_in.data, en, out.data);
    tribuf_n #(3) sel_buf(reg_in.sel, en, out.sel);
    tribuf_n #(1) mode_buf(reg_in.mode, en, out.mode);
endmodule

// s = 1 -> Load d into reg[r]
// s = 0 -> Read reg[r] to q
// reset is async 1 -> reset
module reg_bank(
    input reg_in_bus_t in_bus,
    input reset, clk,
    output [31:0] q
);
    wire [7:0] read_reg_hot;
    wire [7:0] write_reg_hot;
    wire [7:0] write_reg;
    decoder_c #(3, 8) dec_read_select(in_bus.sel, clk, read_reg_hot);
    decoder #(3, 8) dec_write_select(in_bus.sel, write_reg);
    assign write_reg_hot = in_bus.mode ? write_reg : 8'b0;

    buffered_reg_32 reg_0(in_bus.data, clk, reset, write_reg_hot[0], read_reg_hot[0], q);
    buffered_reg_32 reg_1(in_bus.data, clk, reset, write_reg_hot[1], read_reg_hot[1], q);
    buffered_reg_32 reg_2(in_bus.data, clk, reset, write_reg_hot[2], read_reg_hot[2], q);
    buffered_reg_32 reg_3(in_bus.data, clk, reset, write_reg_hot[3], read_reg_hot[3], q);
    buffered_reg_32 reg_4(in_bus.data, clk, reset, write_reg_hot[4], read_reg_hot[4], q);
    buffered_reg_32 reg_5(in_bus.data, clk, reset, write_reg_hot[5], read_reg_hot[5], q);
    buffered_reg_32 reg_6(in_bus.data, clk, reset, write_reg_hot[6], read_reg_hot[6], q);
    buffered_reg_32 reg_7(in_bus.data, clk, reset, write_reg_hot[7], read_reg_hot[7], q);
endmodule