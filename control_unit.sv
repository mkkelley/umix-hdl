
import BusTypes::reg_in_bus_t;
import BusTypes::mem_in_bus_t;

// control unit
// instructions
// 0000 - cmov - a <-b unless c = 0
//        only register unit
// 0001 - array idx - a <- (b)[c]
//        memory unit
//        register unit
// 0010 - array amend - (a)[b] <- c
//        memory unit
//        register unit
// 0011 - addition - a <- b + c
//        register unit
//        alu
// 0100 - multiplication - a <- b * c
//        register unit
//        alu
// 0101 - division - a <- b / c
//        register unit
//        alu
// 0110 - nand - a <- b NAND c (bitwise)
//        register unit
//        alu
// 0111 - halt
// 1000 - allocation - (b) = new array[c]
//        memory unit
//        register unit
// 1001 - abandonment - free(c)
//        memory unit
//        register unit
// 1010 - print(c)
//        register unit
// 1011 - c <- getc()
// 1100 - copy (b), let (0) = (b)

module control_unit(
	input [31:0] mem_data_out,
	input [31:0] reg_data_out,
	input [31:0] alu_result,
	input clk, init,
	output reg_in_bus_t reg_ctrl,
	output mem_in_bus_t mem_ctrl,
	output [31:0] alu_x,
	output [31:0] alu_y,
	output logic [1:0] alu_mode
);
	reg [31:0] instr_word;
	wire [31:0] offset_in;
	wire [1:0] offset_ctrl;
	wire [31:0] offset;
	logic r;
	wire [2:0] regA;
	wire [2:0] regB;
	wire [2:0] regC;
	wire [3:0] instr;

	wire [13:0] instr_finished;
	logic [13:0] enable_fsm;

	instr_decoder idecode(instr_word, instr, regA, regB, regC);

	reg_in_bus_t reg_in;
	reg_in_bus_t fsm_reg_in [13:0];

	mem_in_bus_t mem_in;
	mem_in_bus_t fsm_mem_in [13:0];

	wire [31:0] fsm_alu_x [13:0];
	wire [31:0] fsm_alu_y [13:0];

	assign reg_in = fsm_reg_in[instr];
	assign mem_in = fsm_mem_in[instr];
	assign alu_x = fsm_alu_x[instr];
	assign alu_y = fsm_alu_y[instr];

	accumulator offset_acc(offset_in, offset_ctrl, clk, offset);

	cmov_fsm cmov(regA, regB, regC, reg_data_out, clk, r,
		fsm_reg_in[0], instr_finished[0]
	);

	addr_idx_fsm addr_idx(
		regA, regB, regC,
		reg_data_out, mem_data_out,
		clk, enable_fsm[1],
		fsm_reg_in[1], fsm_mem_in[1],
		instr_finished[1]
	);

	addr_amend_fsm addr_amend(
		regA, regB, regC,
		reg_data_out, mem_data_out,
		clk, r,
		fsm_reg_in[2], fsm_mem_in[2],
		instr_finished[2]
	);

	adder_fsm adder(
		regA, regB, regC,
		reg_data_out,
		alu_result,
		clk, enable_fsm[3],
		fsm_reg_in[3],
		fsm_alu_x[3],
		fsm_alu_y[3],
		instr_finished[3]
	);

	typedef enum logic [1:0] { CTRL_FETCH, CTRL_EXECUTE } ctrl_state_t;
	ctrl_state_t ctrl_state, next_state;

	assign offset_ctrl = (init) ? 2'b11 : (ctrl_state == CTRL_FETCH) ? 2'b01 : 2'b00;

	always_comb
	begin
		next_state = CTRL_FETCH;
		reg_ctrl.data = 'x;
		reg_ctrl.sel = 'x;
		reg_ctrl.mode = 1'b0;
		mem_ctrl.data = 'x;
		mem_ctrl.address = '0;
		mem_ctrl.offset = offset;
		mem_ctrl.mode = 2'b00;
		alu_mode = 'x;
		r = 0;
		enable_fsm = 14'b0;
		case ( ctrl_state )
			CTRL_FETCH: begin
				next_state = CTRL_EXECUTE;
			end
			CTRL_EXECUTE: begin
				mem_ctrl = fsm_mem_in[instr];
				reg_ctrl = fsm_reg_in[instr];
				instr_word = mem_data_out;

				enable_fsm[instr] = 1'b1;

				casez (instr)
					4'bzz11: alu_mode = 2'b00;
					4'bz100: alu_mode = 2'b01;
					4'bz101: alu_mode = 2'b10;
					4'bz110: alu_mode = 2'b11;
					default: alu_mode = 2'bzz;
				endcase
				next_state = instr_finished[instr] ? CTRL_FETCH : CTRL_EXECUTE;
			end
			default: $display("Bad case in control unit fsm");
		endcase
	end

	always_ff@(posedge clk)
	if (init)
		ctrl_state <= CTRL_FETCH;
	else
		ctrl_state <= next_state;
endmodule

// fsm for cmov instruction
// state 00 - select regC to read
// state 01 - select regB to read
// state 10 - write (regB) to regA
// state 11 - finished
// reg_sel is 3 bit which register
// reg_s is register mode select
module cmov_fsm(input [2:0] regA, regB, regC, [31:0] reg_out_bus, [0:0] clk, r,
	output reg_in_bus_t reg_in, output finished);
	wire reg_out_bus_zero;

	reg s1;
	reg s0;

	assign reg_out_bus_zero = reg_out_bus == 32'b0;
	assign finished = s1 && s0;
	assign write_buf_enable = s1 && ~s0;
	assign reg_in.sel = s1 ?
	s0 ? 3'b000 :
	regA :
	s0 ? regB :
	regC;
	assign reg_in.mode = write_buf_enable;

	// I believe that this is not necessary.
	tribuf_32 out_buf(reg_out_bus, write_buf_enable, reg_in.data);

	always_ff@(posedge clk)
	begin
		if (r) begin
			s1 <= 0;
			s0 <= 0;
		end else begin
			s1 <= s1 || s0 || (reg_out_bus_zero && ~s0 && s1);
			s0 <= s1 || ~s0;
		end
	end
endmodule

// states
// SELECT_B - reg_out_bus <- (b) after clock
// SELECT_C - store (b), reg_out_bus <- (c) after clock
// READ_C - store (c), wait
// SELECT_MEM - now address + offset are filled, so mem_data_out_bus will be right next cycle
// WRITE_A - (a) <- mem_data_out_bus
// FIN - end loop state
module addr_idx_fsm (
	input [2:0] regA, regB, regC,
	input [31:0] reg_out_bus,
	input [31:0] mem_data_out_bus,
	input clk, en,
	output reg_in_bus_t reg_in,
	output mem_in_bus_t mem_in,
	output finished
);
	typedef enum logic [5:0] { SELECT_B, SELECT_C, READ_C, SELECT_MEM, WRITE_A, FIN } addr_idx_state_t;
	addr_idx_state_t idx_state;

	assign reg_in.data = mem_data_out_bus;
	assign reg_in.mode = (idx_state == WRITE_A) ? 1'b1 : 1'b0;
	assign reg_in.sel = (idx_state == WRITE_A) ?
	regA :
	(idx_state == SELECT_C) ?
	regC :
	regB;
	assign mem_in.mode = 2'b00;
	assign finished = (idx_state == FIN);

	always_ff@(posedge clk)
	begin
		if ( !en ) begin
			idx_state <= SELECT_B;
		end else case(idx_state)
			SELECT_B: begin
				idx_state <= SELECT_C;
			end
			SELECT_C: begin
				mem_in.address <= reg_out_bus;
				idx_state <= READ_C;
			end
			READ_C: begin
				mem_in.offset <= reg_out_bus;
				idx_state <= SELECT_MEM;
			end
			SELECT_MEM: begin
				idx_state <= WRITE_A;
			end
			WRITE_A: begin
				idx_state <= FIN;
			end
			FIN: begin
				idx_state <= FIN;
			end
		endcase
	end
endmodule

// states
// SELECT_A - get memory address from reg file
// SELECT_B - get memory offset from reg file
// SELECT_C - get data to write from reg file
// WRITE_MEM - a[b] <- (c)
// FIN - looping close state
module addr_amend_fsm (
	input [2:0] regA, regB, regC,
	input [31:0] reg_out_bus,
	input [31:0] mem_data_out_bus,
	input clk, en,
	output reg_in_bus_t reg_in,
	output mem_in_bus_t mem_in,
	output finished
);
	typedef enum logic [4:0] { SELECT_A, SELECT_B, SELECT_C, WRITE_MEM, FIN } addr_amend_state_t;

	addr_amend_state_t amend_state;

	assign mem_in.data = reg_out_bus;
	assign mem_in.mode = (amend_state == WRITE_MEM) ? 2'b01 : 2'b00;

	assign reg_in.mode = 2'b0;
	assign reg_in.sel = (amend_state == SELECT_B) ?
	regB :
	(amend_state == SELECT_C) ? regC : regA;

	assign finished = (amend_state == FIN);

	always_ff@(posedge clk)
	begin
		if ( !en ) begin
			amend_state <= SELECT_A;
		end else begin
			case(amend_state)
				SELECT_A: begin
					amend_state <= SELECT_B;
				end
				SELECT_B: begin
					mem_in.address <= reg_out_bus;
					amend_state <= SELECT_C;
				end
				SELECT_C: begin
					mem_in.offset <= reg_out_bus;
					amend_state <= WRITE_MEM;
				end
				WRITE_MEM: begin
					amend_state <= FIN;
				end
				FIN: begin
					amend_state <= FIN;
				end
				default: $display("Invalid memory amend case.");
			endcase
		end
	end
endmodule

module adder_fsm (
	input [2:0] regA, regB, regC,
	input [31:0] reg_out_bus,
	input [31:0] alu_out,
	input clk, en,
	output reg_in_bus_t reg_in,
	output reg [31:0] alu_x,
	output [31:0] alu_y,
	output logic finished
);

	typedef enum logic [3:0] { SELECT_B, SELECT_C, WRITE_A, FIN } adder_state_t;
	adder_state_t adder_state;

	assign alu_y = reg_out_bus;

	always_comb
	begin
		finished = 1'b0;
		case (adder_state)
			SELECT_B: begin
				reg_in.sel = regB;
				reg_in.mode = 1'b0;
			end
			SELECT_C: begin
				reg_in.sel = regC;
				reg_in.mode = 1'b0;
			end
			WRITE_A: begin
				reg_in.sel = regA;
				reg_in.mode = 1'b1;
				reg_in.data = alu_out;
			end
			FIN: begin
				reg_in.mode = 1'b0;
				finished = 1'b1;
			end
			default: $display("Bad case in adder_fsm");
		endcase
	end
	always_ff@(posedge clk)
	begin
		if ( !en ) begin
			adder_state <= SELECT_B;
		end else begin
			case(adder_state)
				SELECT_B: begin
					adder_state <= SELECT_C;
				end
				SELECT_C: begin
					alu_x <= reg_out_bus;
					adder_state <= WRITE_A;
				end
				WRITE_A: begin
					adder_state <= FIN;
				end
				FIN: begin
					adder_state <= FIN;
				end
				default: $display("Bad state case in adder_fsm");
			endcase
		end
	end
endmodule