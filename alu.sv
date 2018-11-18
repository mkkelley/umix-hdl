
module full_adder(input x, y, cin, output s, cout);
    assign s = (x ^ y) ^ cin;
    assign cout = (x & y) | (cin & (x ^ y));
endmodule

module full_adder_2(input [1:0] x, y, input cin, output [1:0] s, output out);
    wire inner_c;
    full_adder fa1(x[0],
                   y[0],
                   cin,
                   s[0],
                   inner_c);
    full_adder fa2(x[1],
                   y[1],
                   inner_c,
                   s[1],
                   cout);
endmodule

module full_adder_32(input [31:0] x, y, input cin, output [31:0]s, output cout);
    wire [31:0] cs;
    full_adder fa[31:0] (x,
                         y,
                         {cs[31:1], cin},
                         s,
                         {cout, cs[31:1]});
endmodule

module multiplier_32(input [31:0] x, y,
                     input clk, r, load,
                     output [31:0] p, q,
                     output [0:0] finished);
    wire shr_control;
    wire [31:0] adder_out;
    wire [31:0] product_out;
    wire dummy;
    wire [31:0] product_in;
    wire product_to_q;
    wire [31:0] q_out;
    wire q_so;
    wire [5:0] c;

    assign product_in = (load) ? 32'b0 : adder_out >> 1;
    assign q = q_out;
    assign p = product_out;
    assign shr_control = load || q_so;

    counter count(clk, load, c);

    assign finished = c == 6'b100001;

    full_adder_32 fa(product_out, y, 1'b0, adder_out, dummy);
    shr_right_ar product(1'b0, clk, r, shr_control, product_in, product_to_q, product_out);
    shr_right_ar q_shr(product_to_q, clk, r, load, x, q_so, q_out);
endmodule


// s = b00 - x + y MOD 32
// s = b01 - x * y MOD 32
// s = b10 - x / y iff y =/= 0
// s = b11 - x NAND y
module alu (
    input [31:0] x,
    input [31:0] y,
    input [1:0] s,
    input clk, r,
    output [31:0] out,
    output finished
);
    wire [31:0] adder_out;
    wire [31:0] multiplier_out;
    wire [31:0] divider_out;
    wire [31:0] nand_out;

    wire adder_carry_out;
    wire multiplier_finished;
    wire divider_finished;

    mux_4 out_mux(adder_out,
                  multiplier_out,
                  divider_out,
                  nand_out,
                  s,
                  out);
    
    mux_4 finished_mux(1'b1,
                       multiplier_finished,
                       divider_finished,
                       1'b1);

    nand n[31:0](nand_out, x, y);

    full_adder_32(x, y, 1'b0, adder_out, adder_carry_out);
    
endmodule