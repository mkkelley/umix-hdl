
module instr_decoder(input [31:0] word,
                     output [3:0] instr,
                     output [2:0] regA,
                     output [2:0] regB,
                     output [2:0] regC);
    assign instr = word[31:28];
    assign regA = word[8:6];
    assign regB = word[5:3];
    assign regC = word[2:0];
endmodule
