module main();
    reg [31:0] a, b, out;
    reg [31:0] mout1;
    reg [31:0] mout2;
    reg cin;
    reg clk;
    reg reset;
    wire finished;
    wire cout;
    full_adder_32 fa(a, b, cin, out, cout);
    multiplier_32 mul(a, b, clk, reset, mout1, mout2, finished);
    initial begin
        clk <= 0;
        a <= 32'd24;
        b <= 32'd44;
        cin <= 1'b0;
        reset <= 1;
        #10
        a <= 32'd56;
        #10
        reset <= 0;
    end

    always begin
        #5
        clk = ~clk;
    end
endmodule

module divider_test();
    reg[31:0] n, d;
    wire[31:0] q, r;

    fast_divider_32 div(n, d, q, r);

    initial begin
        n <= 32'd99;
        d <= 32'd3;

        #10

        n <= 32'd64000;
        d <= 32'd10;
    end
endmodule