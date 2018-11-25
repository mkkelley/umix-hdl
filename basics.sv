
module dff(input d, clk, output reg q);
    always@(posedge clk)
        q <= d;
endmodule

module dff_e(input d, clk, en, output reg q);
    always@(posedge clk)
        if (en)
            q <= d;
endmodule

module dff_ar(input d, clk, r, output reg q);
    always@(r, posedge clk)
        if (r)
            q <= 1'b0;
        else if (clk)
            q <= d;
endmodule

// s = 1 -> load pi
// s = 0 -> shift left
module shr_ar(input si, clk, r, s, input pi, output so, output q);
    parameter size = 32;
    output [size - 1:0] q;
    input [size-1:0] pi;
    wire [size - 1:0] q_internal;
    wire [size - 1:0] d_internal;
    assign q = {so, q_internal[31:1]};
    assign d_internal = s ? pi : {q_internal[size-1:1], si};
    dff_ar ds[size - 1:0](d_internal, clk, r, {so, q_internal[size-1:1]});
endmodule

// s = 0 - shift right
// s = 1 - parallel load
module shr_right_ar(input si, clk, r, s, input pi, output so, q);
    parameter size = 32;
    output [size - 1:0] q;
    input [size-1:0] pi;
    wire [size - 1:0] q_internal;
    wire [size - 1:0] d_internal;
    assign q = {q_internal[1+:size-1], so};
    assign d_internal = s ? pi : {si, q_internal[1+:size-1]};
    dff_ar ds[size - 1:0](d_internal, clk, r, {q_internal[1+:size-1], so});
endmodule

// b00 - no change
// b01 - shift left
// b10 - shift right
// b11 - parallel load
module shift_reg(input si, clk, r, [1:0] s,
                 input pi, output so, q);
    parameter size = 32;
    output [size-1:0] q;
    input [size-1:0] pi;
    wire [size-1:0] q_internal;
    wire [size-1:0] d_internal;
    assign q = q_internal;
    assign so = q_internal[0];

    mux_4 d_mux(q_internal,
                {q_internal[0+:31], si},
                {si, q_internal[1+:31]},
                pi,
                s,
                d_internal);

    dff_ar ds[size-1:0] (d_internal, clk, r, q_internal);
endmodule

// mode == 1'b00 -> read
// mode == 1'b01 -> reg++
// mode == 1'b10 -> write in to reg
// mode == 1'b11 -> zero reg
module accumulator(
	input [31:0] in,
	input [1:0] mode,
	input clk,
	output reg [31:0] out
);
	always_ff@(posedge clk)
		case (mode)
			2'b00: out <= out;
			2'b01: out <= out + 1;
			2'b10: out <= in;
			2'b11: out <= 0;
		endcase
endmodule

module mux_4 #(parameter size = 32)
             (input [size-1:0] a,
              input [size-1:0] b,
              input [size-1:0] c,
              input [size-1:0] d,
              input [1:0] s,
              output logic [size-1:0] y);
    always_comb
        case(s)
            2'b00: y = a;
            2'b01: y = b;
            2'b10: y = c;
            2'b11: y = d;
            default: $display("Error in mux_4 case");
        endcase
endmodule

module mux_n #(
	parameter data_width = 32,
	parameter n_inputs = 4,
	parameter n_select = 2
) (
	input [data_width-1:0] data [n_inputs-1:0],
	input [n_select-1:0] select,
	output [data_width-1:0] q
);
	assign q = data[select];
endmodule


module mux(input data, s, output q);
    parameter data_width = 4;
    parameter select_width = 2;

    input [data_width-1:0] data;
    input [select_width-1:0] s;

    assign q = data[s];
endmodule

module decoder(input s, output q);
    parameter select_width = 2;
    parameter output_width = 4;

    input [select_width-1:0] s;
    output [output_width-1:0] q;

    assign q = 1 << s;
endmodule

module decoder_c #(parameter select_width = 2,
                   parameter output_width = 4)
                 (input [select_width-1:0] s,
                  input clk,
                  output reg [output_width-1:0] q);
    always@(posedge clk)
        q <= 1 << s;
endmodule

module counter #(parameter bits = 6) (input clk, r, output reg[bits-1:0] c);
    always@(r, posedge clk)
        if (r)
            c <= 0;
        else if (clk)
            c <= c + 1;
endmodule
