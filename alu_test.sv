module main();
    reg [31:0] a, b, out;
    reg [31:0] mout1;
    reg [31:0] mout2;
    reg cin;
    reg clk;
    reg reset;
    reg load;
    wire cout;
    full_adder_32 fa(a, b, cin, out, cout);
    multiplier_32 mul(a, b, clk, reset, load, mout1, mout2);
    initial begin
        clk <= 0;
        a <= 32'd24;
        b <= 32'd44;
        cin <= 1'b0;
        reset <= 1;
        load <= 0;
        #1
        reset <= 0;
        #4
        #10
        a <= 32'd56;
        load <= 1;
        #10
        load <= 0;
    end

    always begin
        #5
        clk = ~clk;
    end
endmodule