
module full_adder(input x, y, cin, output s, cout);
    assign s = (x ^ y) ^ cin;
    assign cout = (x & y) | (cin & (x ^ y));
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
                     input clk, r,
                     output [31:0] p, q,
                     output reg [0:0] finished);
    logic [1:0] shr_control;
    logic [1:0] q_shr_ctrl;
    wire [31:0] adder_out;
    wire [31:0] product_out;
    wire dummy;
    wire [31:0] product_in;
    wire product_to_q;
    wire [31:0] q_out;
    wire q_so;
    wire [5:0] c;

    assign product_in = (r) ? 32'b0 : adder_out >> 1;
    assign q = q_out;
    assign p = product_out;
    assign q_shr_ctrl = (finished) ? 2'b00 : (r) ? 2'b11 : 2'b10;

    always_ff@(posedge clk iff r == 0 or posedge r)
        if (r)
            finished <= 1'b0;
        else
            finished <= c == 6'b011111 || finished;

    always_comb
        if (finished)
            shr_control = 2'b00;
        else if (r || q_so)
            shr_control = 2'b11;
        else
            shr_control = 2'b10;

    counter count(clk, r, c);
    full_adder_32 fa(product_out, y, 1'b0, adder_out, dummy);
    shift_reg product(1'b0, clk, r, shr_control, product_in, product_to_q, product_out);
    shift_reg q_shr(product_to_q, clk, 1'b0, q_shr_ctrl, x, q_so, q_out);
endmodule

module fast_multiplier_32(input [31:0] a, b, output [31:0] p);
    assign p = a * b;
endmodule

module divider_32(
    input [31:0] numerator,
    input [31:0] denominator,
    input clk, r,
    output [31:0] quotient, remainder,
    output reg [0:0] finished
);
    wire n_to_remainder;
    wire r_gte_denom;
    wire [31:0] inv_denominator;
    wire [31:0] r_prime;

    wire dummy_cout;
    wire dummy_remainder_so;
    wire dummy_quot_so;
    wire dummy_numerator_so;

    wire [31:0] numerator_out;

    reg [1:0] remainder_ctrl;
    reg [1:0] quotient_ctrl;
    reg [1:0] numerator_ctrl;

    wire [5:0] count;

    assign r_gte_denom = remainder >= denominator;
    assign inv_denominator = ~denominator;
    assign n_to_remainder = numerator_out[31];

    counter c(clk, r, count);

    full_adder_32 subtractor(remainder, inv_denominator, 1'b1,
                             r_prime, dummy_cout);

    shift_reg quot(r_gte_denom, clk, r, quotient_ctrl,
                   32'b0, dummy_quot_so, quotient);
    shift_reg remn(n_to_remainder, clk, r, remainder_ctrl,
                   r_prime, dummy_remainder_so, remainder);
    shift_reg n(1'b0, clk, 1'b0, numerator_ctrl,
                numerator, dummy_numerator_so, numerator_out);

    typedef enum logic [2:0] { D_SHIFT, D_CHECK, D_FINISHED } div_fsm_t;
    div_fsm_t fsm_state;

    always_ff@(posedge clk) begin
        if (r) begin
            fsm_state <= D_SHIFT;
            numerator_ctrl <= 2'b11;
            remainder_ctrl <= 2'b00;
            quotient_ctrl <= 2'b00;
        end else begin
            case(fsm_state)
                D_SHIFT: begin
                    remainder_ctrl <= (r_gte_denom) ? 2'b11 : 2'b01;
                    numerator_ctrl <= 2'b01;
                    quotient_ctrl <= 2'b01;
                    fsm_state <= D_CHECK;
                end
                D_CHECK: begin
                    remainder_ctrl <= (remainder_ctrl == 2'b11) ? 2'b01 : 2'b00;
                    numerator_ctrl <= 2'b00;
                    quotient_ctrl <= 2'b00;
                    fsm_state <= D_SHIFT;
                end
                D_FINISHED: begin
                    remainder_ctrl <= 2'b00;
                    numerator_ctrl <= 2'b00;
                    quotient_ctrl <= 2'b00;
                    fsm_state <= D_FINISHED;
                end
                default: $display("Bad divider FSM state.");
            endcase
        end
    end

endmodule


module fast_divider_32(
    input [31:0] numerator,
    input [31:0] denominator,
    output [31:0] quotient, remainder
);
    assign quotient = numerator / denominator;
    assign remainder = numerator % denominator;
endmodule

// s = b00 - x + y MOD 32
// s = b01 - x * y MOD 32
// s = b10 - x / y iff y =/= 0
// s = b11 - x NAND y
module alu (
    input [31:0] x,
    input [31:0] y,
    input [1:0] s,
    input clk,
    output [31:0] out
);
    wire [31:0] adder_out;
    wire [31:0] multiplier_out;
    wire [31:0] divider_out;
    wire [31:0] nand_out;

    // wire [31:0] multiplier_high;

    wire [31:0] div_remainder;
    wire adder_carry_out;
    wire multiplier_finished;
    wire divider_finished;

    mux_4 out_mux(adder_out,
                  multiplier_out,
                  divider_out,
                  nand_out,
                  s,
                  out);

    nand n[31:0](nand_out, x, y);

    full_adder_32 fa(x, y, 1'b0, adder_out, adder_carry_out);

    fast_multiplier_32 mul(x, y, multiplier_out);

    fast_divider_32 div(x, y, divider_out, div_remainder);
    
endmodule