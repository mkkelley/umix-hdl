
module reg_bank_test();

    reg reset;
    reg [2:0] reg_select;
    reg s;
    reg clk;
    reg [31:0] i_data;
    reg [31:0] out;

    reg_bank b(reg_select, s, reset, clk, i_data, out);

    initial begin
        reset <= 1;
        clk <= 0;
        reg_select = 3'b0;
        s <= 1;
        i_data <= 32'h55555555; 
        #1
        reset <= 0;
        #10
        reg_select = 3'd2;
        i_data <= 32'h33333333;
        #10
        s <= 0;
        reg_select = 3'b0;
    end
    always begin
        #5
        clk = ~clk;
    end

endmodule