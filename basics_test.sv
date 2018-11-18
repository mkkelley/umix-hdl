

module basics_test();
    reg si;
    wire so;
    reg clk;
    reg r;
    reg [31:0] shr_q;
    reg s;
    reg [31:0] shr_pi;
    wire [31:0] shr_right_q;
    shr_ar shr(si, clk, r, s, shr_pi, so, shr_q);
    shr_right_ar shr_right(si, clk, r, s, shr_pi, so, shr_right_q);
    initial begin
        clk <= 0;
        s <= 0;
        si <= 1;
        r <= 1;
        shr_pi <= 32'h55555555;
        #1
        r <= 0;
        #10
        si <= 0;
        #10
        si <= 1;
        #10
        si <= 1;
        #320
        s <= 1;
        #10
        s <= 0;
    end
    always begin
        #5
        clk = ~clk;
    end
    reg d;
    wire q;
    dff d2(d, clk, q);
    initial begin 
        d <= 1;
        #10
        d <= 0;
    end
endmodule
