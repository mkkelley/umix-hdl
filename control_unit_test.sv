
import BusTypes::mem_in_bus_t;
import BusTypes::reg_in_bus_t;

module cmov_test();
	reg clk;
	reg reset_reg;
	reg reset_fsm;
	reg [31:0] instr_word;
	reg enable_fsm_output;

	reg enable_manual;

	reg_in_bus_t manual_reg_in_bus;

	wire [3:0] instr;
	wire [2:0] regA;
	wire [2:0] regB;
	wire [2:0] regC;

	reg_in_bus_t reg_in_bus;
	wire [31:0] reg_data_out;

	wire finished;

	reg_in_bus_t cmov_reg_in_bus;

	reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);

	reg_in_bus_buf cmov_buf(cmov_reg_in_bus, enable_fsm_output, reg_in_bus);

	// reg_bank bank(reg_sel, reg_s, reset_reg, clk, reg_data_in, reg_data_out);
	reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

	instr_decoder idecode(instr_word, instr, regA, regB, regC);

	cmov_fsm cfsm(regA, regB, regC,
		reg_data_out,
		clk, reset_fsm,
		cmov_reg_in_bus,
		finished);

	initial begin
		clk <= 0;

		reset_reg <= 1;
		reset_fsm <= 1;

		instr_word <= 32'b0000_0000000000000000000_001_100_010;
		enable_fsm_output <= 0;

		#10

		reset_fsm <= 0;
		reset_reg <= 0;

		#10

		enable_manual <= 1;
		manual_reg_in_bus.sel <= 3'b010;
		manual_reg_in_bus.data <= 32'b1;
		manual_reg_in_bus.mode <= 1'b1;

		#10

		manual_reg_in_bus.sel <= 3'b100;
		manual_reg_in_bus.data <= 32'h5555;

		#10

		manual_reg_in_bus.sel <= 3'b001;
		manual_reg_in_bus.data <= 32'hcccc;

		#10

		enable_manual <= 0;
		enable_fsm_output <= 1;

		#10

		reset_fsm <= 1;


		#10

		reset_fsm <= 0;
	end


	always begin
		#5
		clk = ~clk;
	end
endmodule

module addr_idx_test();
	reg clk;
	reg reset_reg;
	reg reset_fsm;
	reg [31:0] instr_word;
	reg enable_fsm_output;

	reg enable_manual;

	wire [3:0] instr;
	wire [2:0] regA;
	wire [2:0] regB;
	wire [2:0] regC;
	wire [31:0] reg_data_out;
	wire [31:0] mem_out;
	wire finished;
	wire enable_fsm;

	assign enable_fsm = !reset_fsm;

	reg_in_bus_t manual_reg_in_bus;
	reg_in_bus_t reg_in_bus;
	reg_in_bus_t fsm_reg_in;

	mem_in_bus_t manual_mem_in;
	mem_in_bus_t mem_in;
	mem_in_bus_t idx_mem_in;

	reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);
	reg_in_bus_buf fsm_buf(fsm_reg_in, enable_fsm_output, reg_in_bus);

	mem_in_bus_buf manual_mem_in_buf(manual_mem_in, enable_manual, mem_in);
	mem_in_bus_buf idx_mem_in_buf(idx_mem_in, enable_fsm_output, mem_in);

	reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

	instr_decoder idecode(instr_word, instr, regA, regB, regC);

	mem_sys ms(mem_in, clk, reset_reg, mem_out);

	addr_idx_fsm aifsm(
		regA, regB, regC,
		reg_data_out, mem_out,
		clk, enable_fsm,
		fsm_reg_in,
		idx_mem_in,
		finished
	);

	initial begin
		clk <= 0;

		reset_reg <= 1;
		reset_fsm <= 1;

		// a <- (b)[c]
		// reg1 <- (reg4)[reg2]
		instr_word <= 32'b0001_0000000000000000000_001_100_010;
		enable_fsm_output <= 0;

		#10

		reset_reg <= 0;

		#10

		enable_manual <= 1;
		manual_reg_in_bus.sel <= 3'b010;
		manual_reg_in_bus.data <= 32'b0;
		manual_reg_in_bus.mode <= 1'b1;

		manual_mem_in.mode <= 2'b01;
		manual_mem_in.address <= 32'h5555;
		manual_mem_in.offset <= 32'b0;
		manual_mem_in.data <= 32'h76767676;

		#10

		manual_reg_in_bus.sel <= 3'b100;
		manual_reg_in_bus.data <= 32'h5555;

		manual_mem_in.address <= 32'h5555;
		manual_mem_in.offset <= 32'b1;
		manual_mem_in.data <= 32'h13131313;

		#10

		manual_reg_in_bus.sel <= 3'b001;
		manual_reg_in_bus.data <= 32'hcccc;

		#10

		enable_manual <= 0;
		reset_fsm <= 0;
		enable_fsm_output <= 1;
	end


	always begin
		#5
		clk = ~clk;
	end
endmodule

module addr_amend_test();
	reg clk;
	reg reset_reg;
	reg reset_fsm;
	reg [31:0] instr_word;
	reg enable_fsm_output;

	reg enable_manual;

	wire [3:0] instr;
	wire [2:0] regA;
	wire [2:0] regB;
	wire [2:0] regC;
	wire [31:0] reg_data_out;
	wire [31:0] mem_out;
	wire finished;
	wire enable;

	assign enable = !reset_fsm;

	reg_in_bus_t manual_reg_in_bus;
	reg_in_bus_t reg_in_bus;
	reg_in_bus_t fsm_reg_in;

	mem_in_bus_t manual_mem_in;
	mem_in_bus_t mem_in;
	mem_in_bus_t idx_mem_in;

	reg_in_bus_buf manual_buf(manual_reg_in_bus, enable_manual, reg_in_bus);
	reg_in_bus_buf fsm_buf(fsm_reg_in, enable_fsm_output, reg_in_bus);

	mem_in_bus_buf manual_mem_in_buf(manual_mem_in, enable_manual, mem_in);
	mem_in_bus_buf fsm_mem_in_buf(idx_mem_in, enable_fsm_output, mem_in);

	reg_bank bank(reg_in_bus, reset_reg, clk, reg_data_out);

	instr_decoder idecode(instr_word, instr, regA, regB, regC);

	mem_sys ms(mem_in, clk, reset_reg, mem_out);

	addr_amend_fsm aafsm(
		regA, regB, regC,
		reg_data_out, mem_out,
		clk, enable,
		fsm_reg_in,
		idx_mem_in,
		finished
	);

	initial begin
		clk <= 0;

		reset_reg <= 1;
		reset_fsm <= 1;

		instr_word <= 32'b0010_0000000000000000000_001_100_010;
		enable_fsm_output <= 0;

		#10

		reset_reg <= 0;

		#10

		enable_manual <= 1;
		manual_reg_in_bus.sel <= 3'b010;
		manual_reg_in_bus.data <= 32'h5c5c5c5c;
		manual_reg_in_bus.mode <= 1'b1;

		manual_mem_in.mode <= 2'b01;
		manual_mem_in.address <= 32'h5555;
		manual_mem_in.offset <= 32'b0;
		manual_mem_in.data <= 32'h76767676;

		#10

		manual_reg_in_bus.sel <= 3'b100;
		manual_reg_in_bus.data <= 32'h5555;

		#10

		manual_reg_in_bus.sel <= 3'b001;
		manual_reg_in_bus.data <= 32'hcccc;

		#10

		enable_manual <= 0;
		reset_fsm <= 0;
		enable_fsm_output <= 1;
	end


	always begin
		#5
		clk = ~clk;
	end
endmodule

module alu_testbench(
	input [31:0] instr,
	input [2:0] r,
	input [31:0] expected_val
);
	logic clk;
	logic reset_mem_reg;
	logic reset_ctrl;

	reg enable_manual;
	reg enable_cu;

	wire [31:0] reg_data_out;
	wire [31:0] mem_data_out;

	wire [31:0] alu_x;
	wire [31:0] alu_y;
	wire [31:0] alu_out;
	wire [1:0] alu_s;

	reg_in_bus_t manual_reg_in;
	mem_in_bus_t manual_mem_in;

	reg_in_bus_t cu_reg_in;
	mem_in_bus_t cu_mem_in;

	tri reg_in_bus_t reg_in;
	tri mem_in_bus_t mem_in;

	mem_in_bus_buf m_mem_buf(manual_mem_in, enable_manual, mem_in);
	mem_in_bus_buf cu_mem_buf(cu_mem_in, enable_cu, mem_in);

	reg_in_bus_buf m_reg_buf(manual_reg_in, enable_manual, reg_in);
	reg_in_bus_buf cu_reg_buf(cu_reg_in, enable_cu, reg_in);

	mem_sys ms(
		mem_in,
		clk,
		reset_mem_reg,
		mem_data_out
	);

	reg_bank rb(
		reg_in,
		reset_mem_reg,
		clk,
		reg_data_out
	);

	alu a(
		alu_x, alu_y, alu_s, clk, alu_out
	);

	control_unit cu(
		mem_data_out,
		reg_data_out,
		alu_out,
		clk,
		reset_ctrl,
		cu_reg_in,
		cu_mem_in,
		alu_x,
		alu_y,
		alu_s
	);

	initial begin
		reset_mem_reg <= 1'b1;
		reset_ctrl <= 1'b1;
		enable_manual <= 1'b1;
		enable_cu <= 1'b0;
		clk <= 1'b0;
		#10
		reset_mem_reg <= 1'b0;

		manual_mem_in.address <= 32'b0;
		manual_mem_in.offset <= 32'b0;
		manual_mem_in.data <= instr;
		manual_mem_in.mode <= 2'b01;

		manual_reg_in.sel <= 3'b000;
		manual_reg_in.data <= 32'h56565656;
		manual_reg_in.mode <= 1'b1;

		#10

		manual_reg_in.sel <= 3'b001;
		manual_reg_in.data <= 32'h8f8f;

		#10

		manual_reg_in.sel <= 3'b010;
		manual_reg_in.data <= 32'h2c2c;

		#10

		manual_reg_in.mode <= 1'b0;
		reset_ctrl <= 1'b0;
		enable_manual <= 1'b0;
		enable_cu <= 1'b1;

		#50

		enable_manual <= 1'b1;
		enable_cu <= 1'b0;
		manual_reg_in.mode = 1'b0;
		manual_reg_in.sel <= r;

		#10

		REG_R_HAS_CORRECT_VAL : assert(reg_data_out == expected_val);

	end

	always begin
		#5
		clk = ~clk;
	end
endmodule

module adder_ctrl_test();
	alu_testbench adder_test(
		32'b0011_0000000000000000000_000_001_010,
		3'b000,
		32'hbbbb
	);
endmodule

module mult_ctrl_test();
	alu_testbench mult_test(
		32'b0100_0000000000000000000_000_001_010,
		3'b000,
		32'h18c54094
	);
endmodule

module div_ctrl_test();
	alu_testbench div_test(
		32'b0101_0000000000000000000_000_001_010,
		3'b000,
		32'd3
	);
endmodule

module nand_ctrl_test();
	alu_testbench nand_test(
		32'b0110_0000000000000000000_000_001_010,
		3'b000,
		~(32'h8f8f & 32'h2c2c) 
	);
endmodule

module alloc_ctrl_test();
	alu_testbench alloc_test(
		32'b1000_0000000000000000000_000_001_010,
		3'b001,
		32'b10000
	);
endmodule

module ortho_ctrl_test();
	alu_testbench ortho_test(
		32'b1101_010_0110011001100110011010101,
		3'b010,
		32'b0000000_0110011001100110011010101
	);
endmodule

module display_ctrl_test();
	logic clk;
	logic reset_mem_reg;
	logic reset_ctrl;

	reg enable_manual;
	reg enable_cu;

	wire [31:0] reg_data_out;
	wire [31:0] mem_data_out;

	wire [31:0] alu_x;
	wire [31:0] alu_y;
	wire [31:0] alu_out;
	wire [1:0] alu_s;

	reg_in_bus_t manual_reg_in;
	mem_in_bus_t manual_mem_in;

	reg_in_bus_t cu_reg_in;
	mem_in_bus_t cu_mem_in;

	reg_in_bus_t reg_in;
	mem_in_bus_t mem_in;

	mem_in_bus_buf m_mem_buf(manual_mem_in, enable_manual, mem_in);
	mem_in_bus_buf cu_mem_buf(cu_mem_in, enable_cu, mem_in);

	reg_in_bus_buf m_reg_buf(manual_reg_in, enable_manual, reg_in);
	reg_in_bus_buf cu_reg_buf(cu_reg_in, enable_cu, reg_in);

	mem_sys ms(
		mem_in,
		clk,
		reset_mem_reg,
		mem_data_out
	);

	reg_bank rb(
		reg_in,
		reset_mem_reg,
		clk,
		reg_data_out
	);

	alu a(
		alu_x, alu_y, alu_s, clk, alu_out
	);

	control_unit cu(
		mem_data_out,
		reg_data_out,
		alu_out,
		clk,
		reset_ctrl,
		cu_reg_in,
		cu_mem_in,
		alu_x,
		alu_y,
		alu_s
	);

	initial begin
		reset_mem_reg <= 1'b1;
		reset_ctrl <= 1'b1;
		enable_manual <= 1'b1;
		enable_cu <= 1'b0;
		clk <= 1'b0;
		#10
		reset_mem_reg <= 1'b0;

		manual_mem_in.address <= 32'b0;
		manual_mem_in.offset <= 32'b0;
		manual_mem_in.data <= 32'b1010_0000000000000000000_000_001_000;
		manual_mem_in.mode <= 2'b01;

		manual_reg_in.sel <= 3'b000;
		manual_reg_in.data <= 32'h5a;
		manual_reg_in.mode <= 1'b1;

		#10

		manual_reg_in.mode <= 1'b0;
		reset_ctrl <= 1'b0;
		enable_manual <= 1'b0;
		enable_cu <= 1'b1;
	end

	always begin
		#5
		clk = ~clk;
	end
endmodule